# Use the official Dart image from Docker Hub as the base image for the build stage
FROM dart:stable AS build

# Set the working directory inside the container
WORKDIR /app

# Copy the entire project directory into the container
# Adjusted the COPY command to ensure it works in all contexts
COPY . /app/

# Get dependencies
RUN dart pub get

# Compile the Dart server application
RUN dart compile exe bin/server.dart -o bin/server

# Use dart:stable for the runtime stage
FROM dart:stable AS runtime

# Install SQLite
RUN apt-get update && apt-get install -y sqlite3 libsqlite3-dev

# Copy the compiled server and pubspec files
COPY --from=build /app/bin/server /app/bin/
COPY --from=build /app/pubspec.yaml /app/
COPY --from=build /app/pubspec.lock /app/

# Set the working directory and get dependencies
WORKDIR /app
RUN dart pub get

# Capture the current Git commit ID
ARG GIT_COMMIT_ID=unknown
ENV GIT_COMMIT_ID=${GIT_COMMIT_ID}

CMD ["./bin/server"]
