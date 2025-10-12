# Stage 1: Use Debian base for building cloudflared
FROM debian:bookworm AS builder

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && apt-get install -y --no-install-recommends \
    git \
    pkg-config \
    libssl-dev \
    ca-certificates \
    curl \
    && rm -rf /var/lib/apt/lists/*

# Copy the Go toolchain built for ARMv5, with version auto-detected by build script
# The filename is dynamic, use a build ARG to pass it in
ARG GO_TOOLCHAIN_TARBALL
COPY ${GO_TOOLCHAIN_TARBALL} /tmp/

RUN mkdir -p /usr/local/go && \
    tar -C /usr/local/go -xzf /tmp/${GO_TOOLCHAIN_TARBALL} && \
    if [ -d /usr/local/go/bin/linux_arm ]; then \
        mv -f /usr/local/go/bin/linux_arm/* /usr/local/go/bin/ && \
        rmdir /usr/local/go/bin/linux_arm; \
    fi && \
    rm /tmp/${GO_TOOLCHAIN_TARBALL}

ENV GOROOT=/usr/local/go
ENV PATH=$GOROOT/bin:$PATH
ENV GOPATH=/go
ENV GO111MODULE=on
ENV GOPROXY=https://proxy.golang.org,direct

# Use a build argument to specify the cloudflared version
ARG CLOUDFLARED_VERSION=master

RUN git clone https://github.com/cloudflare/cloudflared.git /cloudflared

WORKDIR /cloudflared

# Checkout the specified version
RUN git checkout $CLOUDFLARED_VERSION

# Ensure Go is executable
RUN chmod +x /usr/local/go/bin/go

RUN go mod download

RUN GOOS=linux GOARCH=arm GOARM=5 go build -o /cloudflared/cloudflared ./cmd/cloudflared

# Stage 2: Minimal runtime image
FROM debian:bookworm-slim

ENV PATH=/usr/local/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin

RUN apt-get update && apt-get install -y --no-install-recommends ca-certificates curl && rm -rf /var/lib/apt/lists/*

COPY --from=builder /cloudflared/cloudflared /usr/local/bin/cloudflared

ENV TUNNEL_TOKEN=""

CMD ["sh", "-c", "cloudflared tunnel --no-autoupdate run --token $TUNNEL_TOKEN"]