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
