# ================================================
# DS2API - Dockerfile optimized for Render.com
# Multi-stage build: Node (WebUI) + Go (Backend)
# ================================================

# -------- Stage 1: Build WebUI --------
FROM node:24-alpine AS webui-builder

WORKDIR /app/webui
COPY webui/package.json webui/package-lock.json* ./
RUN npm install
COPY config.example.json /app/config.example.json
COPY webui ./
RUN npm run build

# -------- Stage 2: Build Go Binary --------
FROM golang:1.26-alpine AS go-builder

WORKDIR /app
COPY go.mod go.sum ./
RUN go mod download
COPY . .
ARG BUILD_VERSION
RUN CGO_ENABLED=0 GOOS=linux GOARCH=amd64 go build \
    -buildvcs=false \
    -ldflags="-s -w -X ds2api/internal/version.BuildVersion=${BUILD_VERSION:-render}" \
    -o /out/ds2api ./cmd/ds2api

# -------- Stage 3: Runtime --------
FROM alpine:3.20 AS runtime

WORKDIR /app

# Install ca-certificates for HTTPS requests to DeepSeek
RUN apk add --no-cache ca-certificates tzdata python3 \
    && adduser -D -s /sbin/nologin ds2api \
    && mkdir -p /app/data /app/static/admin \
    && chown -R ds2api:ds2api /app

# Copy built artifacts
COPY --from=go-builder /out/ds2api /usr/local/bin/ds2api
COPY --from=go-builder /app/config.example.json /app/config.example.json
COPY --from=webui-builder /app/static/admin /app/static/admin

# Copy scripts
COPY scripts/render-entrypoint.sh /usr/local/bin/render-entrypoint.sh
COPY scripts/generate_config.py /usr/local/bin/generate_config.py
RUN chmod +x /usr/local/bin/render-entrypoint.sh

# Create non-root user
USER ds2api

# Expose port (Render uses $PORT env var, defaults to 5001)
EXPOSE 5001

# Health check
HEALTHCHECK --interval=30s --timeout=5s --start-period=10s --retries=3 \
    CMD wget --no-verbose --tries=1 --spider http://localhost:${PORT:-5001}/healthz || exit 1

# Use entrypoint to generate config from env vars before starting
ENTRYPOINT ["/usr/local/bin/render-entrypoint.sh"]
CMD ["/usr/local/bin/ds2api"]
