ARG BASE_IMAGE=alpine:3.18

# hadolint ignore=DL3006
FROM ${BASE_IMAGE} as base

ARG TARGETARCH

SHELL ["/bin/ash", "-o", "pipefail", "-o", "errexit", "-o", "nounset", "-o"]

RUN echo "hosts: files dns" > /etc/nsswitch.conf \
    && adduser --disabled-password --uid=1983 spacelift

# hadolint ignore=DL3018
RUN apk -U upgrade && apk add --no-cache \
    build-base \
    libffi-dev \
    gcc=12.2.1_git20220924 \
    musl-dev \
    libffi-dev \
    bash=5.2.15 \
    ca-certificates \
    curl=8.4.0 \
    git=2.40.1 \
    jq=1.6 \
    xz=5.4.3 \
    openssh=9.3_p2 \
    openssh-keygen \
    tzdata=2023c \
    nodejs=18.18.2 \
    npm=9.6.6 \
    yarn=1.22.19 \
    python3=3.11.6 \
    python3-dev \
    py3-pip

# Install latest NPM version, cdktf and prettier
RUN npm install -g npm@latest && \
    yarn global add cdktf-cli@latest prettier@latest

# Download infracost
ADD "https://github.com/infracost/infracost/releases/latest/download/infracost-linux-${TARGETARCH}.tar.gz" /tmp/infracost.tar.gz
RUN tar -xzf /tmp/infracost.tar.gz -C /bin && \
    mv "/bin/infracost-linux-${TARGETARCH}" /usr/local/bin/infracost && \
    chmod 755 /usr/local/bin/infracost && \
    rm /tmp/infracost.tar.gz

# Install checkov
# hadolint ignore=DL3013
RUN pip3 install --upgrade pip --no-cache-dir && \
    pip3 install packaging==21.3.0 --no-cache-dir && \
    pip3 install checkov==2.5.19 --config-settings=setup-args="-Dallow-noblas=true" --no-cache-dir

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
    echo "Checkov v$(checkov --version)"; \
    echo "Prettier v$(prettier --version)"; \
    echo "Regula $(regula version)"

USER spacelift
