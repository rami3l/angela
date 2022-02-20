# TODO: Fix this file for Rust

# Build Stage
FROM golang:1.17-alpine as angela-builder

# Set environment variable
ENV APP_NAME angela
ENV CMD_PATH main.go

# Copy application data into image
COPY . $GOPATH/src/$APP_NAME
WORKDIR $GOPATH/src/$APP_NAME

# Budild application
RUN CGO_ENABLED=0 go build -v -o /$APP_NAME $GOPATH/src/$APP_NAME/$CMD_PATH

# Run Stage
FROM alpine:3.15 AS angela

# Set environment variable
ENV APP_NAME angela

# Copy only required data into this image
COPY --from=angela-builder /$APP_NAME .

# Expose application port
#EXPOSE 8081

# Start app
CMD ./$APP_NAME