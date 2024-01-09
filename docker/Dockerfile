# Use the official Dart image from Docker Hub as the base image
FROM dart:stable AS build

# Copy over the project files
WORKDIR /app
COPY pubspec.* /app/
RUN dart pub get

COPY . /app
RUN dart compile exe bin/server.dart -o /app/bin/server

# Build runtime image
FROM subfuzion/dart:slim
COPY --from=build /app/bin/server /app/bin/
COPY --from=build /app/pubspec.yaml /app/
COPY --from=build /app/pubspec.lock /app/
RUN dart pub get --offline
WORKDIR /app
CMD ["../bin/server"]
