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
    python3 \
    tzdata \
    nodejs \
    npm

RUN [ -e /usr/bin/python ] || ln -s python3 /usr/bin/python

# Download infracost
ADD "https://github.com/infracost/infracost/releases/latest/download/infracost-linux-${TARGETARCH}.tar.gz" /tmp/infracost.tar.gz
RUN tar -xzf /tmp/infracost.tar.gz -C /bin && \
    mv "/bin/infracost-linux-${TARGETARCH}" /bin/infracost && \
    chmod 755 /bin/infracost && \
    rm /tmp/infracost.tar.gz

# Install latest NPM version
RUN npm install -g npm

# Install CDK-TF
RUN npm install -g cdktf-cli typescript

RUN echo "hosts: files dns" > /etc/nsswitch.conf \
    && adduser --disabled-password --uid=1983 spacelift

FROM base AS aws

COPY --from=ghcr.io/spacelift-io/aws-cli-alpine /usr/local/aws-cli/ /usr/local/aws-cli/
COPY --from=ghcr.io/spacelift-io/aws-cli-alpine /aws-cli-bin/ /usr/local/bin/

RUN aws --version && \
    python --version && \
    infracost --version

USER spacelift

FROM base AS gcp

RUN gcloud components install gke-gcloud-auth-plugin

RUN gcloud --version && \
    python --version && \
    infracost --version

USER spacelift

FROM base AS azure

RUN az --version && \
    python --version && \
    infracost --version

USER spacelift
