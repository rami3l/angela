FROM lukemathwalker/cargo-chef:latest-rust-alpine AS chef

# ===== Plan Stage =====
FROM chef as angela-planner
ENV APP_NAME angela
WORKDIR /app/${APP_NAME}
COPY . .
RUN cargo chef prepare --recipe-path recipe.json

# ===== Build Stage =====
FROM chef as angela-builder
ENV APP_NAME angela
WORKDIR /app/${APP_NAME}
COPY --from=angela-planner /app/${APP_NAME}/recipe.json recipe.json
# Build dependencies - this is the caching Docker layer!
RUN cargo chef cook --release --recipe-path recipe.json
COPY . .
# This is not needed as it's included in `chef` already.
# RUN apk add --no-cache musl-dev
RUN cargo install --path .

# ===== Run Stage =====
FROM alpine:3.15 AS angela
ENV APP_NAME angela

# Copy only required data into this image
COPY --from=angela-builder /usr/local/cargo/bin/$APP_NAME .

# Expose application port
# EXPOSE 8081

# Start app
CMD ./$APP_NAME