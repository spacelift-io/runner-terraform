FROM python:3.9-alpine3.14 as aws-cli-builder

RUN apk add --no-cache git \
        unzip \
        groff \
        build-base \
        libffi-dev \
        cmake

ENV AWS_CLI_VERSION=2.7.25

RUN mkdir /aws && \
    git clone --single-branch --depth 1 -b ${AWS_CLI_VERSION} https://github.com/aws/aws-cli.git /aws && \
    cd /aws && \
    sed -i'' 's/PyInstaller.*/PyInstaller==5.2/g' requirements-build.txt && \
    python -m venv venv && \
    . venv/bin/activate && \
    ./scripts/installers/make-exe

RUN unzip /aws/dist/awscli-exe.zip && \
    ./aws/install --bin-dir /aws-cli-bin && \
    /aws-cli-bin/aws --version

FROM alpine:3.14.8 as runner

RUN apk -U upgrade && apk add --no-cache \
    bash \
    ca-certificates \
    curl \
    git \
    jq \
    openssh \
    openssh-keygen \
    tzdata \
    groff # for aws-cli

# AWS CLI
COPY --from=aws-cli-builder /usr/local/aws-cli/ /usr/local/aws-cli/
COPY --from=aws-cli-builder /aws-cli-bin/ /usr/local/bin/

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
