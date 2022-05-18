FROM debian:stable-slim

RUN apt-get update && \
    apt-get install \
    jq \
    ca-certificates \
    curl \
    wget \
    openssh-client \
    -y 

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
