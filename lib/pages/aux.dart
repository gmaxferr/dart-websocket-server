const htmlFileContent = '''
<!DOCTYPE html>
<html lang="en">

<head>
    <meta charset="UTF-8">
    <title>WebSocket Server Communication</title>
    <style>
        .sent-message,
        .received-message {
            padding: 5px;
            margin: 5px 0;
            border-radius: 5px;
            cursor: pointer;
            transition: background-color 0.3s;
        }

        .sent-message:hover,
        .received-message:hover {
            background-color: #f0f0f0;
        }

        .sent-message {
            color: blue;
        }

        .received-message {
            color: green;
        }
    </style>
    <script>
        let currentDeviceId = null;
        let intervalId = null;

        function connectToDevice() {
            currentDeviceId = document.getElementById('deviceId').value;
            if (currentDeviceId) {
                getHistory();
                document.getElementById('title').style.display = 'block';
                document.getElementById('title').textContent = "Connected to '" + currentDeviceId + "'";
                document.getElementById('messageControls').style.display = 'block';
                document.getElementById('connectControls').style.display = 'none';
                intervalId = setInterval(getHistory, 5000); // Refresh history every 5 seconds
            } else {
                alert('Please enter a Station ID.');
            }
        }

        function sendMessage() {
            const message = document.getElementById('message').value;
            fetch(`{{API_SCHEMA}}://{{API_ENDPOINT}}:{{API_PORT}}/sendMessage/\${currentDeviceId}`, {
                method: 'POST',
                body: message
            }).then(response => {
                if (response.ok) {
                    getHistory();
                    document.getElementById('message').value = ''; // Clear message input
                } else {
                    alert('Error sending message.');
                }
            });
        }

        function deleteDatabase() {
            if (confirm('Are you sure you want to delete the database?\\nThis will delete all chat history with ALL previous ev chargers.\\nThis action cannot be undone.')) {
                fetch('{{API_SCHEMA}}://{{API_ENDPOINT}}:{{API_PORT}}/deleteDatabase', { method: 'POST' })
                    .then(response => {
                        if (response.ok) {
                            alert('Database successfully deleted.');
                            disconnect(); // Reset the UI
                        } else {
                            alert('Failed to delete the database.');
                        }
                    })
                    .catch((error) => {
                        console.error('Error:', error);
                        alert('An error occurred while deleting the database.');
                    });
            }
        }

        function copyToClipboard(text) {
            navigator.clipboard.writeText(text).then(() => {
                alert('Copied to clipboard: ' + text);
            }, (err) => {
                console.error('Error copying text to clipboard', err);
            });
        }

        function getHistory() {
            fetch(`{{API_SCHEMA}}://{{API_ENDPOINT}}:{{API_PORT}}/getHistory/\${currentDeviceId}`)
                .then(response => response.json())
                .then(data => {
                    const historyElement = document.getElementById('history');
                    historyElement.innerHTML = ''; // Clear existing history
                    data.reverse().forEach(msg => {
                        const msgElement = document.createElement('p');
                        msgElement.textContent = `\${msg.sender === 'server' ? '>>' : ''} \${formatTimestamp(msg.timestamp)} \${msg.sender === 'server' ? 'SENT' : 'RECEIVED'}: \${msg.content}`;
                        msgElement.className = msg.sender === 'server' ? 'sent-message' : 'received-message';
                        msgElement.onclick = () => copyToClipboard(msg.content);
                        historyElement.appendChild(msgElement);
                    });
                });
        }

        function formatTimestamp(timestamp) {
            const date = new Date(timestamp);
            return `\${date.getDate()}/\${date.getMonth() + 1}/\${date.getFullYear()} \${date.getHours()}:\${date.getMinutes()}:\${date.getSeconds()}`;
        }

        function disconnect() {
            clearInterval(intervalId);
            currentDeviceId = null;
            document.getElementById('history').innerHTML = '';
            document.getElementById('messageControls').style.display = 'none';
            document.getElementById('connectControls').style.display = 'block';
        }
    </script>
</head>

<body>
    <div id="connectControls">
        <input type="text" id="deviceId" placeholder="Enter Station ID" />
        <button onclick="connectToDevice()">Connect</button>
    </div>

    <div id="messageControls" style="display: none;">

        <a href="{{API_SCHEMA}}://{{API_ENDPOINT}}:{{API_PORT}}/downloadChatHistory" download="chatHistory.zip"><button>Download Chat History</button></a>
        <button onclick="deleteDatabase()">Delete ALL Database</button>
        </br>
        </br>
        <span id="title" style="font-size: 18px;font-weight: bold;"></span>
        </br>
        <input type="text" id="message" placeholder="Your message" />
        <button onclick="sendMessage()">Send</button>
        <button onclick="disconnect()">Disconnect</button>
        </br>
        </br>
        <button onclick="getHistory()">Refresh History</button>

        <div id="history"></div>
    </div>
</body>

</html>
''';