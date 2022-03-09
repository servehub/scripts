FROM ubuntu:20.04

# ENV MAJOR_VERSION 1.5
ENV TERRAFORM_VERSION 1.1.7

ARG DEBIAN_FRONTEND=noninteractive

env pip_packages "ansible boto boto3 passlib awscli bcrypt mitogen"

RUN apt-get update \
    && apt-get install -y apt-transport-https

RUN apt-get update \
    && apt-get install -y --no-install-recommends \
        apt-utils \
        sshpass \
        openssh-client \
        groff \
        unzip \
        libffi-dev \
        libssl-dev \
        python3-dev \
        python3-setuptools \
        python3-pip \
        python3-yaml \
        software-properties-common \
        bzip2 \
        wget \
        git \
    && apt-get clean

RUN pip3 install $pip_packages --upgrade --user




RUN wget -q https://github.com/github-release/github-release/releases/download/v0.10.0/linux-amd64-github-release.bz2 \
    && bzip2 -ckd linux-amd64-github-release.bz2 > /usr/local/bin/github-release \
    && chmod 755 /usr/local/bin/github-release \
    && rm linux-amd64-github-release.bz2



RUN wget -q https://releases.hashicorp.com/terraform/${TERRAFORM_VERSION}/terraform_${TERRAFORM_VERSION}_linux_amd64.zip \
    && unzip -oq terraform_${TERRAFORM_VERSION}_linux_amd64.zip -d /usr/local/bin \
    && rm terraform_${TERRAFORM_VERSION}_linux_amd64.zip

ENV PATH="/root/.local/bin:${PATH}"
