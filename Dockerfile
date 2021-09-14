FROM ubuntu:16.04

ENV MAJOR_VERSION 1.5

RUN ln -s http /usr/lib/apt/methods/https \
    && DEBIAN_FRONTEND=noninteractive apt-get update \
    && apt-get install -y apt-transport-https

RUN echo "deb http://ppa.launchpad.net/ansible/ansible/ubuntu xenial main" | tee /etc/apt/sources.list.d/ansible.list \
    && echo "deb-src http://ppa.launchpad.net/ansible/ansible/ubuntu xenial main" | tee -a /etc/apt/sources.list.d/ansible.list \
    && apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv-keys 7BB9C367 \
    && DEBIAN_FRONTEND=noninteractive apt-get update \
    && apt-get install -y \
         ansible=2.9.* \
         python-pip \
         sshpass \
         openssh-client \
         groff \
         unzip \
         libffi-dev \
         libssl-dev \
         bzip2 \
         wget

RUN pip install boto passlib awscli bcrypt==3.1.7 --upgrade --user

RUN wget -q https://github.com/github-release/github-release/releases/download/v0.10.0/linux-amd64-github-release.bz2 \
    && bzip2 -ckd linux-amd64-github-release.bz2 > /usr/local/bin/github-release \
    && chmod 755 /usr/local/bin/github-release \
    && rm linux-amd64-github-release.bz2

ENV TERRAFORM_VERSION 0.13.5

RUN wget -q https://releases.hashicorp.com/terraform/${TERRAFORM_VERSION}/terraform_${TERRAFORM_VERSION}_linux_amd64.zip \
    && unzip -oq terraform_${TERRAFORM_VERSION}_linux_amd64.zip -d /usr/local/bin \
    && rm terraform_${TERRAFORM_VERSION}_linux_amd64.zip

ENV PATH="/root/.local/bin:${PATH}"
