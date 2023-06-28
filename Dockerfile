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
ADD "https://github.com/tfsec/tfsec/releases/latest/download/tfsec-linux-amd64" /usr/local/bin/tfsec
RUN chmod 755 /usr/local/bin/tfsec

# Install Checkov
RUN pip3 install --upgrade pip && \
    pip3 install packaging==21.3.0 && \
    pip3 install checkov

# Install Prettier
RUN yarn global add prettier

FROM base AS aws

COPY --from=ghcr.io/spacelift-io/aws-cli-alpine /usr/local/aws-cli/ /usr/local/aws-cli/
COPY --from=ghcr.io/spacelift-io/aws-cli-alpine /aws-cli-bin/ /usr/local/bin/

RUN aws --version && \
    cdktf --version && \
    infracost --version && \
    tfsec --version && \
    checkov --version && \
    prettier --version

USER spacelift

FROM base AS gcp

RUN gcloud components install gke-gcloud-auth-plugin

RUN gcloud --version && \
    cdktf --version && \
    infracost --version && \
    tfsec --version && \
    checkov --version && \
    prettier --version

USER spacelift

FROM base AS azure

RUN az --version && \
    cdktf --version && \
    infracost --version && \
    tfsec --version && \
    checkov --version && \
    prettier --version

USER spacelift
