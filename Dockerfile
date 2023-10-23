ARG BASE_IMAGE=alpine:3.18

FROM ${BASE_IMAGE} AS base

ARG TARGETARCH

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

# Install latest NPM version
RUN npm install -g npm

# Install CDKTF CLI
RUN yarn global add cdktf-cli

RUN echo "hosts: files dns" > /etc/nsswitch.conf \
    && adduser --disabled-password --uid=1983 spacelift

# Download infracost
ADD "https://github.com/infracost/infracost/releases/latest/download/infracost-linux-${TARGETARCH}.tar.gz" /tmp/infracost.tar.gz
RUN tar -xzf /tmp/infracost.tar.gz -C /bin && \
    mv "/bin/infracost-linux-${TARGETARCH}" /usr/local/bin/infracost && \
    chmod 755 /usr/local/bin/infracost && \
    rm /tmp/infracost.tar.gz

# Install tfsec
ADD "https://github.com/tfsec/tfsec/releases/latest/download/tfsec-linux-${TARGETARCH}" /usr/local/bin/tfsec
RUN chmod 755 /usr/local/bin/tfsec

# Install checkov
RUN pip3 install --upgrade pip && \
    pip3 install packaging==21.3.0 && \
    pip3 install checkov --config-settings=setup-args="-Dallow-noblas=true"

# Install Prettier
RUN yarn global add prettier

# Install regula
RUN REGULA_LATEST_VERSION=$(curl -s https://api.github.com/repos/fugue/regula/releases/latest | grep "tag_name" | cut -d'v' -f2 | cut -d'"' -f1) && \
    curl -L https://github.com/fugue/regula/releases/download/v${REGULA_LATEST_VERSION}/regula_${REGULA_LATEST_VERSION}_Linux_x86_64.tar.gz --output /tmp/regula.tar.gz && \
    tar -xzf /tmp/regula.tar.gz -C /bin && \
    mv "/bin/regula" /usr/local/bin/regula && \
    chmod 755 /usr/local/bin/regula && \
    rm /tmp/regula.tar.gz


FROM base AS aws

COPY --from=ghcr.io/spacelift-io/aws-cli-alpine /usr/local/aws-cli/ /usr/local/aws-cli/
COPY --from=ghcr.io/spacelift-io/aws-cli-alpine /aws-cli-bin/ /usr/local/bin/

RUN aws --version && \
    cdktf --version && \
    infracost --version && \
    tfsec --version && \
    checkov --version && \
    prettier --version && \
    regula version

USER spacelift

FROM base AS gcp

RUN gcloud components install gke-gcloud-auth-plugin

RUN gcloud --version && \
    cdktf --version && \
    infracost --version && \
    tfsec --version && \
    checkov --version && \
    prettier --version && \
    regula version

USER spacelift

FROM base AS azure

RUN az --version && \
    cdktf --version && \
    infracost --version && \
    tfsec --version && \
    checkov --version && \
    prettier --version && \
    regula version

USER spacelift
