ARG BASE_IMAGE=alpine:3.18

FROM ${BASE_IMAGE}

ARG TARGETARCH

RUN echo "hosts: files dns" > /etc/nsswitch.conf \
    && adduser --disabled-password --uid=1983 spacelift

RUN apk -U upgrade && apk add --no-cache \
    build-base \
    libffi-dev \
    gcc \
    musl-dev \
    libffi-dev \
    bash \
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
    yarn \
    python3 \
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
RUN pip3 install --upgrade pip && \
    pip3 install packaging==21.3.0 && \
    pip3 install checkov==2.5.19 --config-settings=setup-args="-Dallow-noblas=true"

# Install regula
RUN REGULA_LATEST_VERSION=$(curl -s https://api.github.com/repos/fugue/regula/releases/latest | grep "tag_name" | cut -d'v' -f2 | cut -d'"' -f1) && \
    curl -L https://github.com/fugue/regula/releases/download/v${REGULA_LATEST_VERSION}/regula_${REGULA_LATEST_VERSION}_Linux_x86_64.tar.gz --output /tmp/regula.tar.gz && \
    tar -xzf /tmp/regula.tar.gz -C /bin && \
    mv "/bin/regula" /usr/local/bin/regula && \
    chmod 755 /usr/local/bin/regula && \
    rm /tmp/regula.tar.gz

# Copy AWS CLI binaries (from ghcr.io/spacelift-io/aws-cli-alpine)
COPY --from=ghcr.io/spacelift-io/aws-cli-alpine /usr/local/aws-cli/ /usr/local/aws-cli/
COPY --from=ghcr.io/spacelift-io/aws-cli-alpine /aws-cli-bin/ /usr/local/bin/

# Check versions
RUN echo "Software installed:"; \
    aws --version; \
    echo "CDKTF v$(cdktf --version)"; \
    infracost --version; \
    echo "Checkov v$(checkov --version)"; \
    echo "Prettier v$(prettier --version)"; \
    echo "Regula $(regula version)"

USER spacelift
