ARG BASE_IMAGE=alpine:3.17

FROM ${BASE_IMAGE}

ARG TARGETARCH

RUN apk -U upgrade && apk add --no-cache \
    aws-cli \
    bash \
    ca-certificates \
    curl \
    git \
    jq \
    openssh \
    openssh-keygen \
    tzdata

# Download infracost
ADD "https://github.com/infracost/infracost/releases/latest/download/infracost-linux-${TARGETARCH}.tar.gz" /tmp/infracost.tar.gz
RUN tar -xzf /tmp/infracost.tar.gz -C /bin && \
    mv "/bin/infracost-linux-${TARGETARCH}" /bin/infracost && \
    chmod 755 /bin/infracost && \
    rm /tmp/infracost.tar.gz

# Download Terragrunt.
ADD "https://github.com/gruntwork-io/terragrunt/releases/latest/download/terragrunt_linux_${TARGETARCH}" /bin/terragrunt
RUN chmod 755 /bin/terragrunt

RUN echo "hosts: files dns" > /etc/nsswitch.conf \
    && adduser --disabled-password --uid=1983 spacelift

USER spacelift
