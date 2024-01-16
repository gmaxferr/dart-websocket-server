#!/bin/bash

# Define variables
DEFAULT_SCREEN_NAME="ws_server"
START_CMD="dart bin/server.dart"
SERVER_NAME_FILE="lib/server_name.txt"

# Delete the `server_name.txt` file if it exists
if [ -f "$SERVER_NAME_FILE" ]; then
    rm $SERVER_NAME_FILE
fi

# Start the new server in a new screen session with the default name
screen -dmS $DEFAULT_SCREEN_NAME bash -c "$START_CMD $DEFAULT_SCREEN_NAME"