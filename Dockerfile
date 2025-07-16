# Build Stage
FROM elixir:1.18.4-otp-28-alpine AS angela-builder

# Set environment variables
ENV APP_NAME=angela
ENV MIX_ENV=prod

# Install build dependencies
RUN apk add --no-cache build-base git

# Create app directory
WORKDIR /app

# Copy mix files for dependency caching
COPY mix.exs mix.lock ./

# Install hex and rebar
RUN mix local.hex --force && \
    mix local.rebar --force

# Install dependencies
RUN mix deps.get --only prod

# Copy only necessary files for production
# Here we use the conditional copy trick: <https://stackoverflow.com/a/70096420>
COPY li[b] ./lib
COPY confi[g] ./config
COPY pri[v] ./priv

# Compile the application
RUN mix compile

# Create release
RUN mix release

# Run Stage
FROM alpine:3 AS angela

# Set environment variables
ENV APP_NAME=angela
ENV MIX_ENV=prod

# Install runtime dependencies required by the BEAM VM
RUN apk add --no-cache ncurses-libs libstdc++ libgcc

# Create app user
RUN addgroup -g 1000 -S appgroup && \
    adduser -u 1000 -S appuser -G appgroup

# Create app directory
WORKDIR /app

# Copy release from builder stage
COPY --from=angela-builder --chown=appuser:appgroup /app/_build/prod/rel/angela ./

# Change to app user
USER appuser

# Expose application port (uncomment if needed)
# EXPOSE 8081

# Start app
CMD ["./bin/angela", "start"]
