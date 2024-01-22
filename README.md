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


 * POST /createTestPlan: Creates a new test plan along with its associated test cases.

    * **Request Body**: A JSON object that contains the details of the test plan and a list of associated test cases. The testPlan key should have the test plan details, and the testCases key should contain an array of test case details.
    * **Response**:
        200 OK if the test plan and its test cases are successfully created.
        500 Internal Server Error if there's an error during creation.
    * **Example Request Body**:
```json
    {
    "testPlan": {
        "name": "New Test Plan",
        "type": "sequential", // or "generic"
        "variables": {
        "variable1": "value1",
        "variable2": "value2"
        }
    },
    "testCases": [
        {
        "description": "First test case",
        "defaultMessage": "Message content",
        "validationPath": "path.to.validate",
        "expectedValue": "Expected Value",
        "extractionMacro": "ExtractionMacroName"
        },
        {
        "description": "Second test case",
        // ... other test case details ...
        }
    ]
    }
```

 * GET /testPlan/<id>: Retrieves a test plan by its ID, including all associated test cases.

    * **Path Parameter**: <id> - The ID of the test plan to be fetched.
    * **Response**:
        200 OK with JSON representation of the test plan, including its associated test cases.
        404 Not Found if no test plan is found with the given ID.

 * GET /testCases/<testPlanId>: Fetches all test cases associated with a specific test plan ID.

    * **Path Parameter**: <testPlanId> - The ID of the test plan for which test cases are being requested.
    * **Response**:
        200 OK with a JSON array containing all test cases associated with the test plan.
        404 Not Found if no test plan exists with the provided ID or if there are no test cases associated with the test plan.

 * GET /getTestPlanByStatus/<deviceId>/<status>: Retrieves all test plans for a specific device that match a given status.

    * **Path Parameters**:
        <deviceId> - The ID of the device.
        <status> - The status of the test plans to be fetched.
    * **Response**:
        200 OK with a JSON array of test plans (including their test cases) matching the specified status for the given device.
        404 Not Found if no matching test plans are found.

 * GET /getAllTestPlans: Retrieves all TestPlans stored in the database, with respective TestCases populated.

    * **Response**:
        200 OK with a JSON array of all test plans, each including its associated test cases.
        404 Not Found if no test plans are available in the database.

 * GET /getTestCaseById/<id>: Retrieves a specific test case by its ID.

    * **Path Parameter**: <id> - The ID of the test case to be fetched.
    * **Response**:
        200 OK with JSON representation of the test case if found.
        404 Not Found if no test case is found with the given ID.

 * POST /getTestPlansByIds: Accepts a list of test plan IDs and returns the corresponding test plans.

    * **Request Body**: JSON array of integers representing the IDs of the test plans to be fetched.
    * **Response**:
        200 OK with a JSON array containing the requested test plans and their associated test cases.
    * **Example Request Body**:
```json
    [1, 2, 3]
```

 * GET /getTestPlansByDeviceId/<deviceId>: Retrieves all test plans associated with a specific device ID.

    * **Path Parameter**: <deviceId> - The ID of the device for which test plans are being requested.
    * **Response**:
        200 OK with JSON representation of all test plans (including their test cases) associated with the given device ID.
        404 Not Found if no test plans are associated with the given device ID.

 * POST /addTestCaseToTestPlan/<testPlanId>: Adds a new test case to a specific test plan.

    * **Path Parameter**: <testPlanId> - The ID of the test plan to which the test case will be added.
    * **Request Body**: JSON object representing the TestCase to be added. The format should match the TestCase class structure.
    * **Response**:
        200 OK if the test case is successfully added.
        500 Internal Server Error if there's an error processing the request.

    * **Example Request Body**:
```json
    {
        "description": "Test Case Description",
        "defaultMessage": "Message content",
        "validationPath": "path.to.validate",
        "expectedValue": "Expected Value",
        "extractionMacro": "ExtractionMacroName"
    }
```
 * DELETE /deleteTestCase/<id>: Deletes a test case based on its ID.

    * **Path Parameter**: <id> - The ID of the test case to be deleted.
    * **Response**:
        200 OK if the test case is successfully deleted.
        500 Internal Server Error if there's an error processing the request.


 * POST /updateTestPlanMacros/<testPlanId>: Updates the macros of a specific test plan.

    * **Path Parameter**: <testPlanId> - The ID of the test plan whose macros are to be updated.
    * **Request Body**: A JSON object representing the new set of macros (key-value pairs) for the test plan.
    * **Response**:
        200 OK if the macros are successfully updated.
        500 Internal Server Error if there's an error during the update process.
  
    * **Example Request Body**:
```json
    {
    "macroKey1": "macroValue1",
    "macroKey2": "macroValue2"
    }
```

    * **Usage**: This endpoint allows users to update the macro variables associated with a test plan. The request body should contain a JSON object with key-value pairs representing the macros. Each key-value pair will replace or add to the existing set of macros for the specified test plan.

-----

## Authors

 * Guilherme Ferreira - guilherme.ferreira@iskraemeco.com

-----

## License
This project is licensed under the MIT License - see the [LICENSE.md](./LICENSE.md) file for details.