ARG GO_VERSION

FROM golang:${GO_VERSION} as builder

ARG CHAIN_NAME
ARG DAEMON_NAME
ARG DAEMON_HOME
ARG VERSION="master"
ARG CHAIN_REPO
ARG LIBWASM_VERSION

RUN apk add --no-cache \
	git \
	make \
	linux-headers \
	ca-certificates \
	build-base \
	libc6-compat

RUN git clone --depth=1 ${CHAIN_REPO} /go/chain

WORKDIR /go/chain

RUN git fetch --all --tags
RUN git checkout ${VERSION}

# Cosmwasm - Download correct libwasmvm version
RUN --mount=type=cache,target=/root/.cache/go-build \
    --mount=type=cache,target=/root/go/pkg/mod \
    set -eux; \
    export ARCH=$(uname -m); \
    WASM_VERSION=$(go list -m all | grep github.com/CosmWasm/wasmvm | awk '{print $2}'); \
    [ -z ${WASM_VERSION} ] || wget -O /lib/libwasmvm_muslc.a https://github.com/CosmWasm/wasmvm/releases/download/${WASM_VERSION}/libwasmvm_muslc.${ARCH}.a; \
    [ -f "/lib/libwasmvm_muslc.a" ] && cp -v /lib/libwasmvm_muslc.a /lib/libwasmvm_muslc.${ARCH}.a; \
    go mod download;

# Build chain binary
RUN --mount=type=cache,target=/root/.cache/go-build \
    --mount=type=cache,target=/root/go/pkg/mod \
    COMMIT_SHA="$(git log -1 --format='%H')" && \
    GOWORK=off go build \
        -mod=readonly \
        -tags "netgo,ledger,muslc" \
        -ldflags \
            "-X github.com/cosmos/cosmos-sdk/version.Name=${CHAIN_NAME} \
            -X github.com/cosmos/cosmos-sdk/version.AppName=${DAEMON_NAME} \
            -X github.com/cosmos/cosmos-sdk/version.Version=${VERSION} \
            -X github.com/cosmos/cosmos-sdk/version.Commit=${COMMIT_SHA} \
            -X github.com/cosmos/cosmos-sdk/version.BuildTags=netgo,ledger,muslc \
            -w -s -linkmode=external -extldflags '-Wl,-z,muldefs -static'" \
        -trimpath \
        -o /usr/bin/${DAEMON_NAME} \
        ./cmd/${DAEMON_NAME}


FROM alpine:3.18

ARG DAEMON_NAME
ENV DAEMON_NAME="${DAEMON_NAME}"

RUN apk add --no-cache bash jq supervisor curl lz4

WORKDIR /root

COPY --from=builder /usr/bin/${DAEMON_NAME} /usr/bin/

RUN /usr/bin/${DAEMON_NAME} version

RUN echo "#!/bin/sh" > /entrypoint.sh && \
    echo "exec /usr/bin/${DAEMON_NAME} \$@" >> /entrypoint.sh && \
    chmod +x /entrypoint.sh

ENTRYPOINT [ "/entrypoint.sh" ]
