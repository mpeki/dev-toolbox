ARG DEBIAN_VERSION=buster-slim
ARG DOCKER_VERSION=20.10.11


FROM docker:${DOCKER_VERSION} AS docker-cli

FROM debian:${DEBIAN_VERSION}

ARG USERNAME=jenkins_oci
ARG USER_UID=1009
ARG USER_GID=1009

ARG AWSCLI_VERSION=2.4.7
ARG MAVEN_VERSION=3.8.4
ARG MAVEN_SHA=a9b2d825eacf2e771ed5d6b0e01398589ac1bfa4171f36154d1b5787879605507802f699da6f7cfc80732a5282fd31b28e4cd6052338cbef0fa1358b48a5e3c8
ARG SHELLCHECK_VERSION=0.8.0

ENV DOCKER_BUILDKIT=1

# Setup user
RUN addgroup --gid ${USER_GID} ${USERNAME} && \
    useradd ${USERNAME} --shell /bin/bash --create-home --uid ${USER_UID} --gid ${USER_GID} && \
    mkdir -p /etc/sudoers.d && \
    echo ${USERNAME} ALL=\(root\) NOPASSWD:ALL > /etc/sudoers.d/${USERNAME} && \
    chmod 0440 /etc/sudoers.d/${USERNAME} && \
    rm /var/log/faillog /var/log/lastlog && \
# Install Debian packages and jre 11
    mkdir -p /usr/share/man/man1 && \
    apt-get update -y && \
    apt-get install -y --no-install-recommends sudo ca-certificates make git openssh-client curl tzdata locales procps \
    openjdk-11-jdk-headless python make g++ unzip zip jq xz-utils gnupg gosu && \
    apt-get autoremove -y && \
    apt-get clean -y && \
    rm -r /var/cache/* /var/lib/apt/lists/* && \
    git config --global user.email "jenkins@tiatechnology.com" && \
    git config --global user.name "jenkins"


COPY --from=docker-cli --chown=${USER_UID}:${USER_GID} /usr/local/bin/docker /usr/local/bin/docker

USER jenkins_oci

# Install Node
ENV NVM_VERSION=0.39.1
ENV NODE_VERSION=16.13.1
ENV NVM_DIR=/opt/nvm
ENV PATH="${NVM_DIR}/versions/node/v${NODE_VERSION}/bin:${PATH}"

RUN sudo mkdir ${NVM_DIR} && \
    sudo chown ${USER_UID}:${USER_GID} ${NVM_DIR} && \
    sudo curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v${NVM_VERSION}/install.sh | bash && \
    sudo chmod +x ${NVM_DIR}/nvm.sh && \
    . "${NVM_DIR}/nvm.sh" && nvm install ${NODE_VERSION} && \
    . "${NVM_DIR}/nvm.sh" && nvm use v${NODE_VERSION} && \
    . "${NVM_DIR}/nvm.sh" && nvm alias default v${NODE_VERSION} && \
# Install semantic-release
    npm install -g semantic-release \
    @semantic-release/gitlab-config \
    @semantic-release/changelog \
    @semantic-release/git \
    @semantic-release/gitlab \
    @semantic-release/exec \
#Install bats
    bats yarn && npm cache clean --force

# Install AWS CLI
RUN sudo curl -fsSL "https://awscli.amazonaws.com/awscli-exe-linux-x86_64-${AWSCLI_VERSION}.zip" -o "awscliv2.zip" && \
      sudo unzip awscliv2.zip && \
      sudo ./aws/install && \
      sudo chown ${USER_UID}:${USER_GID} /usr/local/bin/aws && \
      sudo rm -rf awscliv2.zip ./aws/install
# Install Maven
RUN sudo mkdir -p /usr/share/maven /usr/share/maven/ref && \
    sudo curl -fsSL -o /tmp/apache-maven.tar.gz -- https://mirrors.dotsrc.org/apache/maven/maven-3/${MAVEN_VERSION}/binaries/apache-maven-${MAVEN_VERSION}-bin.tar.gz && \
    echo "${MAVEN_SHA} /tmp/apache-maven.tar.gz" | sha512sum -c - && \
    sudo tar -xzf /tmp/apache-maven.tar.gz -C /usr/share/maven --strip-components=1 && \
    sudo rm -f /tmp/apache-maven.tar.gz && \
    sudo ln -s /usr/share/maven/bin/mvn /usr/bin/mvn && \
    sudo chown ${USER_UID}:${USER_GID} /usr/bin/mvn && \
#Install shellcheck
    sudo curl -fsSL -o /tmp/shellcheck.tar.xz -- https://github.com/koalaman/shellcheck/releases/download/v${SHELLCHECK_VERSION}/shellcheck-v${SHELLCHECK_VERSION}.linux.x86_64.tar.xz && \
    sudo tar -xvf /tmp/shellcheck.tar.xz -C /tmp/ --strip-components=1 && \
    sudo cp /tmp/shellcheck /usr/local/bin/shellcheck && \
    sudo chown ${USER_UID}:${USER_GID} /usr/local/bin/shellcheck && \
    sudo rm -rf /tmp/*
USER root
COPY entrypoint.sh /usr/local/bin/entrypoint.sh
RUN chmod +x /usr/local/bin/entrypoint.sh

ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]

