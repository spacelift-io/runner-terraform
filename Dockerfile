FROM alpine:3.15

RUN apk -U upgrade && apk add --no-cache \
    aws-cli \
    bash \
    ca-certificates \
    curl \
    git \
    jq \
    openssh \
    openssh-keygen

# Download infracost
RUN wget -q -c https://github.com/infracost/infracost/releases/latest/download/infracost-linux-amd64.tar.gz -O - | \
    tar xz -C /tmp && \
    mv /tmp/infracost-linux-amd64 /bin/infracost

# Download Terragrunt.
RUN wget -q -O /bin/terragrunt https://github.com/gruntwork-io/terragrunt/releases/latest/download/terragrunt_linux_amd64 \
    && chmod +x /bin/terragrunt

RUN echo "hosts: files dns" > /etc/nsswitch.conf \
    && adduser --disabled-password --uid=1983 spacelift

USER spacelift
