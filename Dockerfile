# TODO: Fix this file for Rust

# Build Stage
FROM rust:1.58.1-alpine as angela-builder

# Set environment variable
ENV APP_NAME angela
WORKDIR /app/${APP_NAME}

COPY . /app/${APP_NAME}

# build with to make it run with alpine.
RUN apk add --no-cache musl-dev
RUN cargo install --path .

# Run Stage
FROM alpine:3.15 AS angela

# Set environment variable
ENV APP_NAME angela

# Copy only required data into this image
COPY --from=angela-builder /usr/local/cargo/bin/$APP_NAME .

# Expose application port
#EXPOSE 8081

# Start app
CMD ./$APP_NAME