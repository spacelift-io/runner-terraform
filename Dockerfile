ARG BASE_IMAGE=alpine:3.22

FROM ${BASE_IMAGE} AS base

ARG TARGETARCH

RUN apk -U upgrade && apk add --no-cache \
    bash \
    ca-certificates \
    curl \
    git \
    jq \
    openssh-client \
    openssh-keygen \
    python3 \
    py3-pip \
    tzdata

RUN [ -e /usr/bin/python ] || ln -s python3 /usr/bin/python

# Breaking system packages should be fine sice tofu does not use python
RUN python3 -m pip install spaceforge --break-system-packages

# Download infracost
ADD "https://github.com/infracost/infracost/releases/latest/download/infracost-linux-${TARGETARCH}.tar.gz" /tmp/infracost.tar.gz
RUN tar -xzf /tmp/infracost.tar.gz -C /bin && \
    mv "/bin/infracost-linux-${TARGETARCH}" /bin/infracost && \
    chmod 755 /bin/infracost && \
    rm /tmp/infracost.tar.gz

# Download Terragrunt.
ADD "https://github.com/gruntwork-io/terragrunt/releases/download/v0.93.3/terragrunt_linux_${TARGETARCH}" /bin/terragrunt
RUN chmod 755 /bin/terragrunt

RUN echo "hosts: files dns" > /etc/nsswitch.conf \
    && adduser --disabled-password --uid=1983 spacelift

FROM base AS aws

COPY --from=ghcr.io/spacelift-io/aws-cli-alpine /usr/local/aws-cli/ /usr/local/aws-cli/
COPY --from=ghcr.io/spacelift-io/aws-cli-alpine /aws-cli-bin/ /usr/local/bin/

RUN aws --version && \
    terragrunt --version && \
    python --version && \
    infracost --version && \
    spaceforge --version

USER spacelift

FROM base AS gcp

RUN gcloud components install gke-gcloud-auth-plugin

RUN gcloud --version && \
    terragrunt --version && \
    python --version && \
    infracost --version && \
    spaceforge --version

USER spacelift

FROM base AS azure-build

ENV PATH="/opt/venv/bin:$PATH"

RUN apk add --virtual=build --no-cache gcc musl-dev python3-dev libffi-dev openssl-dev cargo make && \
    python3 -m venv /opt/venv && \
    pip install --no-cache-dir azure-cli && \
    apk del --purge build

FROM base AS azure

ENV PATH="/opt/venv/bin:$PATH"

COPY --from=azure-build /opt/venv /opt/venv

RUN apk add --no-cache py3-pip && \
    az --version && \
    terragrunt --version && \
    python --version && \
    infracost --version && \
    spaceforge --version

USER spacelift
