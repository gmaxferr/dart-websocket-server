#!/bin/bash

# Define variables
SCREEN_NAME="ws_server"
GIT_REPO_PATH="./" # Replace with the actual path to your Git repository
START_CMD="dart bin/server.dart"
SCREEN_NAME_FILE="lib/screen_name.txt"

# Pull the latest changes from the repository
cd $GIT_REPO_PATH
git pull

GIT_COMMIT_ID_FETCHED=$(git rev-parse HEAD)
export GIT_COMMIT_ID="${GIT_COMMIT_ID_FETCHED}"

# Start the new server in a new screen session with a new name
NEW_SCREEN_NAME="${SCREEN_NAME}_$(date +%s)" # Unique name using a timestamp
# echo $NEW_SCREEN_NAME >> $SCREEN_NAME_FILE
screen -dmS $NEW_SCREEN_NAME bash -c "$START_CMD $NEW_SCREEN_NAME"

# Wait for the new server to start and stabilize
sleep 5

# Read the old screen session name
OLD_SCREEN_NAME=$(tail -n 2 $SCREEN_NAME_FILE | head -n 1)

# Kill the old screen session
if [ ! -z "$OLD_SCREEN_NAME" ]; then
    screen -S $OLD_SCREEN_NAME -X quit
fi
