ARG BASE_IMAGE=alpine:3.18

# hadolint ignore=DL3006
FROM ${BASE_IMAGE} AS common

SHELL ["/bin/ash", "-eo", "pipefail", "-c"]

# hadolint ignore=DL3018
RUN apk --no-cache add \
    ca-certificates \
    curl

FROM common AS base

ARG TARGETARCH

SHELL ["/bin/ash", "-eo", "pipefail", "-c"]

RUN echo "hosts: files dns" > /etc/nsswitch.conf \
    && adduser --disabled-password --uid=1983 spacelift

# hadolint ignore=DL3018
RUN apk -U upgrade && apk add --no-cache \
    build-base \
    gcc \
    musl-dev \
    libffi-dev \
    git \
    jq \
    xz \
    openssh \
    openssh-keygen \
    tzdata \
    bash \
    nodejs \
    npm \
    yarn

# Install latest NPM version, cdktf and prettier
# Note: Remove later or install with bun (also rm npm & yarn)
RUN npm install -g npm@latest && \
    yarn global add cdktf-cli@latest prettier@latest

# Download infracost
ADD "https://github.com/infracost/infracost/releases/latest/download/infracost-linux-${TARGETARCH}.tar.gz" /tmp/infracost.tar.gz
RUN tar -xzf /tmp/infracost.tar.gz -C /bin && \
    mv "/bin/infracost-linux-${TARGETARCH}" /usr/local/bin/infracost && \
    chmod 755 /usr/local/bin/infracost && \
    rm /tmp/infracost.tar.gz

# Install regula
RUN REGULA_LATEST_VERSION=$(curl -s https://api.github.com/repos/fugue/regula/releases/latest | grep "tag_name" | cut -d'v' -f2 | cut -d'"' -f1) && \
    curl -L "https://github.com/fugue/regula/releases/download/v${REGULA_LATEST_VERSION}/regula_${REGULA_LATEST_VERSION}_Linux_x86_64.tar.gz" --output /tmp/regula.tar.gz && \
    tar -xzf /tmp/regula.tar.gz -C /bin && \
    mv "/bin/regula" /usr/local/bin/regula && \
    chmod 755 /usr/local/bin/regula && \
    rm /tmp/regula.tar.gz

# From https://github.com/oven-sh/bun/blob/main/dockerhub/alpine/Dockerfile
FROM common AS bun

ARG BUN_VERSION=latest
ARG GLIBC_VERSION=2.34-r0
ARG GLIBC_VERSION_AARCH64=2.26-r1

SHELL ["/bin/ash", "-eo", "pipefail", "-c"]

# hadolint ignore=DL3018,DL3003,SC2043
RUN apk --no-cache add \
      dirmngr \
      gpg \
      gpg-agent \
      unzip \
    && arch="$(apk --print-arch)" \
    && case "${arch##*-}" in \
      x86_64) build="x64-baseline";; \
      aarch64) build="aarch64";; \
      *) echo "error: unsupported architecture: $arch"; exit 1 ;; \
    esac \
    && version="$BUN_VERSION" \
    && case "$version" in \
      latest | canary | bun-v*) tag="$version"; ;; \
      v*)                       tag="bun-$version"; ;; \
      *)                        tag="bun-v$version"; ;; \
    esac \
    && case "$tag" in \
      latest) release="latest/download"; ;; \
      *)      release="download/$tag"; ;; \
    esac \
    && curl "https://github.com/oven-sh/bun/releases/$release/bun-linux-$build.zip" \
      -fsSLO \
      --compressed \
      --retry 5 \
      || (echo "error: failed to download: $tag" && exit 1) \
    && for key in \
      "F3DCC08A8572C0749B3E18888EAB4D40A7B22B59" \
    ; do \
      gpg --batch --keyserver hkps://keys.openpgp.org --recv-keys "$key" \
      || gpg --batch --keyserver keyserver.ubuntu.com --recv-keys "$key" ; \
    done \
    && curl "https://github.com/oven-sh/bun/releases/$release/SHASUMS256.txt.asc" \
      -fsSLO \
      --compressed \
      --retry 5 \
    && gpg --batch --decrypt --output SHASUMS256.txt SHASUMS256.txt.asc \
      || (echo "error: failed to verify: $tag" && exit 1) \
    && grep " bun-linux-$build.zip\$" SHASUMS256.txt | sha256sum -c - \
      || (echo "error: failed to verify: $tag" && exit 1) \
    && unzip "bun-linux-$build.zip" \
    && mv "bun-linux-$build/bun" /usr/local/bin/bun \
    && rm -f "bun-linux-$build.zip" SHASUMS256.txt.asc SHASUMS256.txt \
    && chmod +x /usr/local/bin/bun \
    && cd /tmp \
    && case "${arch##*-}" in \
      x86_64) curl "https://github.com/sgerrand/alpine-pkg-glibc/releases/download/${GLIBC_VERSION}/glibc-${GLIBC_VERSION}.apk" \
        -fsSLO \
        --compressed \
        --retry 5 \
        || (echo "error: failed to download: glibc v${GLIBC_VERSION}" && exit 1) \
      && mv "glibc-${GLIBC_VERSION}.apk" glibc.apk \
      && curl "https://github.com/sgerrand/alpine-pkg-glibc/releases/download/${GLIBC_VERSION}/glibc-bin-${GLIBC_VERSION}.apk" \
        -fsSLO \
        --compressed \
        --retry 5 \
        || (echo "error: failed to download: glibc-bin v${GLIBC_VERSION}" && exit 1) \
      && mv "glibc-bin-${GLIBC_VERSION}.apk" glibc-bin.apk ;; \
      aarch64) curl "https://raw.githubusercontent.com/squishyu/alpine-pkg-glibc-aarch64-bin/master/glibc-${GLIBC_VERSION_AARCH64}.apk" \
        -fsSLO \
        --compressed \
        --retry 5 \
        || (echo "error: failed to download: glibc v${GLIBC_VERSION_AARCH64}" && exit 1) \
      && mv "glibc-${GLIBC_VERSION_AARCH64}.apk" glibc.apk \
      && curl "https://raw.githubusercontent.com/squishyu/alpine-pkg-glibc-aarch64-bin/master/glibc-bin-${GLIBC_VERSION_AARCH64}.apk" \
        -fsSLO \
        --compressed \
        --retry 5 \
        || (echo "error: failed to download: glibc-bin v${GLIBC_VERSION_AARCH64}" && exit 1) \
      && mv "glibc-bin-${GLIBC_VERSION_AARCH64}.apk" glibc-bin.apk ;; \
      *) echo "error: unsupported architecture '$arch'"; exit 1 ;; \
    esac


FROM ghcr.io/spacelift-io/aws-cli-alpine:2.13.28 AS aws-cli

FROM base

# Copy AWS CLI binaries (from ghcr.io/spacelift-io/aws-cli-alpine)
COPY --from=aws-cli /usr/local/aws-cli/ /usr/local/aws-cli/
COPY --from=aws-cli /aws-cli-bin/ /usr/local/bin/

# Copy Bun binary
COPY --from=bun /usr/local/bin/bun /usr/local/bin/

RUN --mount=type=bind,from=bun,source=/tmp,target=/tmp \
      apk --no-cache --force-overwrite --allow-untrusted add \
      /tmp/glibc.apk \
      /tmp/glibc-bin.apk \
    && ln -s /usr/local/bin/bun /usr/local/bin/bunx

# Check versions
RUN echo "Software installed:"; \
    aws --version; \
    echo "CDKTF v$(cdktf --version)"; \
    infracost --version; \
    echo "Prettier v$(prettier --version)"; \
    echo "Regula $(regula version)"; \
    echo "Bun v$(bun --version)"

USER spacelift
