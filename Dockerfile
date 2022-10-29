FROM alpine:3.16

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
RUN curl -s -L "https://github.com/infracost/infracost/releases/latest/download/infracost-linux-${TARGETARCH}.tar.gz" | \
    tar xz -C /tmp && \
    mv "/tmp/infracost-linux-${TARGETARCH}" /bin/infracost

# Download Terragrunt.
RUN wget -O /bin/terragrunt "https://github.com/gruntwork-io/terragrunt/releases/latest/download/terragrunt_linux_${TARGETARCH}" \
    && chmod +x /bin/terragrunt

RUN echo "hosts: files dns" > /etc/nsswitch.conf \
    && adduser --disabled-password --uid=1983 spacelift

USER spacelift