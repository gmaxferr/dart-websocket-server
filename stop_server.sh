#!/bin/bash

# Define the file containing the server name
SERVER_NAME_FILE="lib/screen_name.txt"

# Check if the file exists
if [ -f "$SERVER_NAME_FILE" ]; then
    # Read the last line from the file to get the screen name
    SCREEN_NAME=$(tail -n 1 $SERVER_NAME_FILE)

    # Stop the screen session with the obtained screen name
    screen -S $SCREEN_NAME -X quit
else
    echo "Error: $SERVER_NAME_FILE does not exist."
fi

# Find the PID of the server process
PID=$(ps aux | grep 'bin/server.dart' | grep -v 'grep' | awk '{print $2}')

# Check if the PID was found
if [ -z "$PID" ]; then
    echo "Server process not found."
    exit 1
fi

# Kill the server process
kill -9 $PID
echo "Server process terminated."