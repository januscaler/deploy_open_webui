# Use Go 1.23 (or newer) as build base
FROM golang:1.24-alpine AS builder

# Install git (required for go modules)
RUN apk add --no-cache git

# Set working directory
WORKDIR /src

# Get Caddy source and cloudflare plugin
RUN go install github.com/caddyserver/caddy/v2/cmd/caddy@latest

# Enable Cloudflare DNS plugin via env variable (if using xcaddy)
RUN go install github.com/caddyserver/xcaddy/cmd/xcaddy@latest

# Build Caddy with Cloudflare DNS plugin using xcaddy
RUN xcaddy build --with github.com/caddy-dns/cloudflare

# Use a lightweight image to run Caddy
FROM alpine:latest

# Copy caddy binary from build stage
COPY --from=builder /src/caddy /usr/bin/caddy

# Create Caddy user and necessary dirs
RUN adduser -D -g 'Caddy User' caddy && \
    mkdir -p /data /config && \
    chown -R caddy:caddy /data /config

USER caddy

EXPOSE 80 443

ENTRYPOINT ["/usr/bin/caddy"]
CMD ["run", "--config", "/etc/caddy/Caddyfile", "--adapter", "caddyfile"]

