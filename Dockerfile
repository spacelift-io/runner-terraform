ARG BASE_IMAGE=alpine:3.21
ARG NODE_VERSION=20.19.1
ARG TERRAFORM_VERSION=1.11.4
ARG BUN_VERSION=1.2.11 

ARG BUN_RUNTIME_TRANSPILER_CACHE_PATH=0    
# Ensure `bun install -g` works    
ARG BUN_INSTALL_BIN=/usr/local/bin    

# hadolint ignore=DL3006
FROM ${BASE_IMAGE} AS common

SHELL ["/bin/ash", "-eo", "pipefail", "-c"]

# hadolint ignore=DL3018
RUN apk --no-cache add \
    ca-certificates \
    curl

FROM common AS base

ARG TARGETARCH
SHELL ["/bin/ash", "-eo", "pipefail", "-c"]

RUN echo "hosts: files dns" > /etc/nsswitch.conf \
    && adduser --disabled-password --uid=1983 spacelift

# hadolint ignore=DL3018
RUN apk -U upgrade && apk add --no-cache \
    build-base \
    gcc \
    musl-dev \
    libffi-dev \
    git \
    jq \
    xz \
    openssh \
    openssh-keygen \
    tzdata \
    bash \
    yarn \
    python3

RUN [ -e /usr/bin/python ] || ln -s python3 /usr/bin/python

# Download infracost
ADD "https://github.com/infracost/infracost/releases/latest/download/infracost-linux-${TARGETARCH}.tar.gz" /tmp/infracost.tar.gz
RUN tar -xzf /tmp/infracost.tar.gz -C /bin && \
    mv "/bin/infracost-linux-${TARGETARCH}" /usr/local/bin/infracost && \
    chmod 755 /usr/local/bin/infracost && \
    rm /tmp/infracost.tar.gz

# Install regula
RUN REGULA_LATEST_VERSION=$(curl -s https://api.github.com/repos/fugue/regula/releases/latest | grep "tag_name" | cut -d'v' -f2 | cut -d'"' -f1) && \
    curl -L "https://github.com/fugue/regula/releases/download/v${REGULA_LATEST_VERSION}/regula_${REGULA_LATEST_VERSION}_Linux_x86_64.tar.gz" --output /tmp/regula.tar.gz && \
    tar -xzf /tmp/regula.tar.gz -C /bin && \
    mv "/bin/regula" /usr/local/bin/regula && \
    chmod 755 /usr/local/bin/regula && \
    rm /tmp/regula.tar.gz

FROM oven/bun:${BUN_VERSION}-alpine AS bun

FROM node:${NODE_VERSION}-alpine AS node

# hadolint ignore=DL3007
FROM ghcr.io/spacelift-io/aws-cli-alpine:latest AS aws-cli

FROM hashicorp/terraform:${TERRAFORM_VERSION} AS terraform

FROM base

# Copy AWS CLI binaries (from ghcr.io/spacelift-io/aws-cli-alpine)
COPY --from=aws-cli /usr/local/aws-cli/ /usr/local/aws-cli/
COPY --from=aws-cli /aws-cli-bin/ /usr/local/bin/

# Copy node binaries
COPY --from=node /usr/local/bin/node /usr/local/bin/node
COPY --from=node /usr/local/bin/npm /usr/local/bin/npm
COPY --from=node /usr/local/lib/node_modules /usr/local/lib/node_modules

RUN ln -sf /usr/local/lib/node_modules/npm/bin/npm-cli.js /usr/local/bin/npm 

RUN npm install -g npm@latest && \
    yarn global add cdktf-cli@latest prettier@latest
    
# Copy the latest terraform version into the base layer
COPY --from=terraform /bin/terraform /usr/local/bin/

# Disable the runtime transpiler cache by default inside Docker containers.
# On ephemeral containers, the cache is not useful
ENV BUN_RUNTIME_TRANSPILER_CACHE_PATH=0

# Ensure `bun install -g` works
ENV BUN_INSTALL_BIN=/usr/local/bin

# Copy Bun binary
COPY --from=bun /usr/local/bin/bun /usr/local/bin/

RUN ln -s /usr/local/bin/bun /usr/local/bin/bunx

SHELL ["/bin/ash", "-o", "pipefail", "-c"]

# Check versions
RUN echo "Software installed:"; \
    aws --version; \
    echo "CDKTF v$(cdktf --version)"; \
    infracost --version; \
    echo "Prettier v$(prettier --version)"; \
    echo "Regula $(regula version)"; \
    echo "Bun v$(bun --version)"; \
    echo "Terraform v$(terraform version -json | jq -r '.terraform_version')"

USER spacelift
