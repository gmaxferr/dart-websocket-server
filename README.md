# MyWebSocketServer

This project implements a Dart WebSocket server with an HTTP server for managing device connections, messages, and storing chat history in a SQLite database.

## Getting Started

These instructions will get your copy of the project up and running on your local machine for development and testing purposes.

### Prerequisites

 * Dart SDK: Ensure you have the Dart SDK installed on your machine. To install Dart, follow the instructions on the official Dart website.
 * SQLite: This project uses SQLite for storing chat history. Make sure SQLite is installed and properly set up on your machine.

### Installing

Clone the repository to your local machine:

```bash
git clone https://github.com/your-username/mywebsocketserver.git
cd mywebsocketserver
```
Fetch and get all dependencies:

```bash
dart pub get
```

## Running the Servers

### Via Command Line

To run the WebSocket and HTTP servers directly through the command line:

```bash
dart run bin/server.dart
```

This will start the WebSocket server and the HTTP server on their respective ports as configured in your application.

### Using Docker
To run the servers using Docker, first build the Docker image:

```bash
docker build -t my-dart-server -f docker/Dockerfile .
```

Then, run the Docker container:

```bash
docker run -d -p 9000:9000 -p 9001:9001 --name my-dart-server-app my-dart-server
```

This will start the servers inside a Docker container.

## Usage

### WebSocket Server

Devices can connect to the WebSocket server at ws://localhost:<WEBSOCKET_PORT>/<deviceID>.

### HTTP Server Endpoints
POST /sendMessage/<deviceId>: Send a message to a connected device.
GET /getHistory/<deviceId>: Retrieve the message history for a specific device.
GET /downloadChatHistory: Download a ZIP file containing chat histories of all devices.


## Authors

 * Guilherme Ferreira - guilherme.ferreira@iskraemeco.com

## License
This project is licensed under the MIT License - see the [LICENSE.md](./LICENSE.md) file for details.