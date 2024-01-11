ARG BASE_IMAGE=alpine:3.18

# hadolint ignore=DL3006
FROM ${BASE_IMAGE} as base

ARG TARGETARCH

SHELL ["/bin/ash", "-eo", "pipefail", "-c"]

RUN echo "hosts: files dns" > /etc/nsswitch.conf \
    && adduser --disabled-password --uid=1983 spacelift

# hadolint ignore=DL3018
RUN apk -U upgrade && apk add --no-cache \
    build-base \
    bash \
    gcc \
    musl-dev \
    libffi-dev \
    ca-certificates \
    curl \
    git \
    jq \
    xz \
    openssh \
    openssh-keygen \
    tzdata \
    nodejs \
    npm \
    yarn

# Install latest NPM version, cdktf and prettier
RUN npm install -g npm@latest && \
    yarn global add cdktf-cli@latest prettier@latest

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

FROM ghcr.io/spacelift-io/aws-cli-alpine:2.13.28 AS aws-cli

FROM base

# Copy AWS CLI binaries (from ghcr.io/spacelift-io/aws-cli-alpine)
COPY --from=aws-cli /usr/local/aws-cli/ /usr/local/aws-cli/
COPY --from=aws-cli /aws-cli-bin/ /usr/local/bin/

# Check versions
RUN echo "Software installed:"; \
    aws --version; \
    echo "CDKTF v$(cdktf --version)"; \
    infracost --version; \
    echo "Prettier v$(prettier --version)"; \
    echo "Regula $(regula version)"

USER spacelift
