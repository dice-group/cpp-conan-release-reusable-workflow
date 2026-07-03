FROM mcr.microsoft.com/devcontainers/base:ubuntu

ARG CONAN_VERSION="2.28.1"
ARG JFROG_VERSION="2.104.0"

RUN curl --retry 5 --retry-all-errors -fLsSLO https://github.com/conan-io/conan/releases/download/${CONAN_VERSION}/conan-${CONAN_VERSION}-amd64.deb && \
    dpkg -i conan-${CONAN_VERSION}-amd64.deb && \
    rm conan-${CONAN_VERSION}-amd64.deb && \
    conan --version

RUN curl --retry 5 --retry-all-errors -fLsSLO https://releases.jfrog.io/artifactory/jfrog-cli/v2-jf/${JFROG_VERSION}/jfrog-cli-linux-amd64/jf && \
    mv jf /usr/local/bin/ && \
    chmod +x /usr/local/bin/jf && \
    jf --version

RUN apt-get update && \
    apt-get install -y cmake build-essential && \
    rm -rf /var/lib/apt/lists/*

USER vscode
RUN curl -fsSL https://claude.ai/install.sh | bash

RUN conan --version && \
    jf --version && \
    cmake --version && \
    g++ --version
