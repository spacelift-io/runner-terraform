FROM alpine:3.14.0

# 3rd party soft dependency versions
ARG INFRACOST_VERSION=0.9.13
ARG TERRAGRUNT_VERSION=0.35.4

RUN apk -U upgrade && apk add --no-cache \
    aws-cli \
    ca-certificates \
    curl \
    git \
    jq \
    openssh \
    openssh-keygen

# Download infracost
RUN curl -s -L https://github.com/infracost/infracost/releases/latest/download/infracost-linux-amd64.tar.gz | \
    tar xz -C /tmp && \
    mv /tmp/infracost-linux-amd64 /bin/infracost

# Download Terragrunt.
RUN wget -O /bin/terragrunt https://github.com/gruntwork-io/terragrunt/releases/latest/download/terragrunt_linux_amd64 \
    && chmod +x /bin/terragrunt

RUN echo "hosts: files dns" > /etc/nsswitch.conf \
    && adduser --disabled-password --uid=1983 spacelift

USER spacelift
