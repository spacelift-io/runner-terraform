ARG BASE_IMAGE=alpine:3.18

FROM ${BASE_IMAGE} AS base

ARG TARGETARCH

RUN apk -U upgrade && apk add --no-cache \
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
    yarn

# Install CDKTF CLI
RUN yarn global add cdktf-cli

# Download infracost
ADD "https://github.com/infracost/infracost/releases/latest/download/infracost-linux-${TARGETARCH}.tar.gz" /tmp/infracost.tar.gz
RUN tar -xzf /tmp/infracost.tar.gz -C /bin && \
    mv "/bin/infracost-linux-${TARGETARCH}" /bin/infracost && \
    chmod 755 /bin/infracost && \
    rm /tmp/infracost.tar.gz

# Install latest NPM version
RUN npm install -g npm

# Install CDKTF CLI
RUN npm install -g cdktf-cli

RUN echo "hosts: files dns" > /etc/nsswitch.conf \
    && adduser --disabled-password --uid=1983 spacelift

FROM base AS aws

COPY --from=ghcr.io/spacelift-io/aws-cli-alpine /usr/local/aws-cli/ /usr/local/aws-cli/
COPY --from=ghcr.io/spacelift-io/aws-cli-alpine /aws-cli-bin/ /usr/local/bin/

RUN aws --version && \
    cdktf --version && \
    infracost --version

USER spacelift

FROM base AS gcp

RUN gcloud components install gke-gcloud-auth-plugin

RUN gcloud --version && \
    cdktf --version && \
    infracost --version

USER spacelift

FROM base AS azure

RUN az --version && \
    cdktf --version && \
    infracost --version

USER spacelift
