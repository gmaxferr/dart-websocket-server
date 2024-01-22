# Dart Websocket Server

This project implements a Dart WebSocket server with an HTTP server for managing device connections, messages, and storing chat history in a SQLite database.

## Getting Started

These instructions will get your copy of the project up and running on your local machine for development and testing purposes.

### Prerequisites

 * Dart SDK: Ensure you have the Dart SDK installed on your machine. To install Dart, follow the instructions on the official Dart website.
 * SQLite: This project uses SQLite for storing chat history. Make sure SQLite is installed and properly set up on your machine.

### Installing

Clone the repository to your local machine:

```bash
    git clone https://github.com/gmaxferr/dart-websocket-server
    cd dart-websocket-server
```
Fetch and get all dependencies:

```bash
    dart pub get
```

-----

## Running the Servers

Before running the servers, you should be aware that some settings are configurable through setting environment variables (below are the default valuesm change depending on your needs):

```bash
    export WEBSOCKET_PORT=9000;
    export HTTP_PORT=9001;
    export HTTP_SCHEMA="http";
    export SHOW_PORT="y";
    export SERVER_HOST="evcore.demo.glcharge.com";
    export DISABLE_TESTING="n";
```

 * **WEBSOCKET_PORT** - The port running the websocket server.
 * **HTTP_PORT** - The port running the http server API.
 * **HTTP_SCHEMA** - The schema for the HTTP API endpoints, needed to specify on the client (injected on _/simple-client_ endpoint).
 * **SHOW_PORT** - If in the client overrides hostname with or without including the Port. May be needed in some server configurations. Defaults to adding the port, to remove it, SHOW_PORT must have as value the letter "n" instead of "y".
 * **SERVER_HOST** - The server hostname (could be an IP, or domain), currenlty is needed to specify on the client (injected on _/simple-client_ endpoint).
 * **DISABLE_TESTING** - If the testing features should be enabled or not. Set to 'n' if you want to activate the features.

### Via Command Line

To run the WebSocket and HTTP servers directly through the command line:

```bash
    dart run bin/server.dart
```

This will start the WebSocket server and the HTTP server on their respective ports as configured in your application.

### Using Docker
To run the servers using Docker, first build the Docker image:

```bash
    docker build -t dev .
```

Then, run the Docker container:

```bash
    docker run -d -p 9000:9000 -p 9001:9001 --name my-dart-server-app my-dart-server
```

This will start the servers inside a Docker container.
You can also use the docker-compose file to start the container.

```shell
    docker-compose up -d
```

### Publish docker image to DockerHub

```shell
    docker build -t dev .
    docker tag dev gplmaxferr/dart-websocketserver:latest
    docker push gplmaxferr/dart-websocketserver:latest
```

-----

## Usage

### WebSocket Server

Devices can connect to the WebSocket server at ws://<domainOrIP>:<WEBSOCKET_PORT>/<deviceID>.

-----

### HTTP Server Endpoints

 * POST /sendMessage/<deviceId>: Send a message to a connected device.
 * GET /getHistory/<deviceId>: Retrieve the message history for a specific device.
 * GET /downloadChatHistory: Download a ZIP file containing chat histories of all devices.
 * POST /deleteDatabase: Deletes all entries in the Messages table in SQLite.
 * GET /simple-client: Returns a HTML+JS client that uses the endpoints above to communicate with a Charger. This client has no business login included.
 * GET /ocpp-client: Returns a HTML+JS client that uses the endpoints above to communicate with a Charger. This client uses minimal OCPP login the frontend to facilitate sending messages and replies to messages.
 * GET /getAllClients: Returns a ZIP file containing all the clients (*.html files), in this way, clients can be fetched an run on the local machine to avoid SSL errors when SSL is not configured.
 * GET /device-status/<deviceId>: Returns `200 OK` if device with <deviceId> is connected to the server, `404 Not Found` otherwise.

#### System Endpoints

 * GET /server-version: Returns the server's current git commit id.
 * GET /force-update: Forces the server to stop, make a git pull, and then start again.
 
#### Testing Endpoints

 * GET /testPlan/<id>: Retrieves a test plan by its ID, including all associated test cases.
 * GET /testCases/<testPlanId>: Fetches all test cases associated with a given test plan ID.
 * GET /getTestPlanByStatus/<deviceId>/<status>: Retrieves all test plans for a specific device that match a given status, including their test cases.
 * GET /getTestCaseById/<id>: Fetches a specific test case by its ID.
 * POST /getTestPlansByIds: Accepts a JSON list of test plan IDs in the request body and returns the corresponding test plans, each with its associated test cases.
 * GET /getTestPlansByDeviceId/<deviceId>: Retrieves all test plans associated with a given device ID, including their test cases.

-----

## Authors

 * Guilherme Ferreira - guilherme.ferreira@iskraemeco.com

-----

## License
This project is licensed under the MIT License - see the [LICENSE.md](./LICENSE.md) file for details.