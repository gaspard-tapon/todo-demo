# Stage 1: Build Flutter web
FROM ghcr.io/cirruslabs/flutter:stable AS flutter-build
WORKDIR /app
COPY pubspec.yaml pubspec.lock ./
COPY lib/ lib/
COPY web/ web/
RUN flutter pub get
RUN flutter build web --release

# Stage 2: Build Dart server
FROM dart:stable AS server-build
WORKDIR /app/server
COPY server/pubspec.yaml server/pubspec.lock* ./
RUN dart pub get
COPY server/ .
RUN dart compile exe bin/server.dart -o bin/server

# Stage 3: Runtime
FROM debian:bookworm-slim
RUN apt-get update && apt-get install -y ca-certificates && rm -rf /var/lib/apt/lists/*
WORKDIR /app
COPY --from=server-build /app/server/bin/server ./server
COPY --from=flutter-build /app/build/web ./public
EXPOSE 8080
ENV PORT=8080
CMD ["./server"]
