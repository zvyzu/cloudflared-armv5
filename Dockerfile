# Stage 1: Use Debian base for building cloudflared
FROM debian:stable AS builder

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && apt-get install -y --no-install-recommends \
    git \
    pkg-config \
    libssl-dev \
    ca-certificates \
    curl \
    tzdata \
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

RUN CGO_ENABLED=0 GOOS=linux GOARCH=arm GOARM=5 go build -o /cloudflared/cloudflared ./cmd/cloudflared

# Stage 2: Minimal runtime image
FROM busybox:stable-glibc

ENV PATH=/usr/local/bin:/usr/local/sbin:/usr/sbin:/usr/bin:/sbin:/bin

RUN addgroup -g 65532 cloudflared && \
    adduser -D -H -u 65532 -G cloudflared cloudflared

RUN mkdir -p /etc/cloudflared && \
    chown 65532:65532 /etc/cloudflared

# Copy root CA certificates from the builder stage
COPY --from=builder /etc/ssl/certs/ca-certificates.crt /etc/ssl/certs/

COPY --from=builder /usr/share/zoneinfo /usr/share/zoneinfo

COPY --from=builder --chown=65532:65532 /cloudflared/cloudflared /usr/local/bin/cloudflared

ENV TZ=UTC

USER 65532:65532

# command / entrypoint of container
ENTRYPOINT ["cloudflared"]
CMD ["tunnel", "--no-autoupdate", "run"]
