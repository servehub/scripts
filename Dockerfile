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
         wget

RUN pip install boto passlib awscli bcrypt --upgrade --user

RUN wget -q https://github.com/aktau/github-release/releases/download/v0.7.2/linux-amd64-github-release.tar.bz2 \
    && tar -jxf linux-amd64-github-release.tar.bz2 -C /usr/local/bin --strip=3 bin/linux/amd64/github-release \
    && rm linux-amd64-github-release.tar.bz2

ENV TERRAFORM_VERSION 0.13.5

RUN wget -q https://releases.hashicorp.com/terraform/${TERRAFORM_VERSION}/terraform_${TERRAFORM_VERSION}_linux_amd64.zip \
    && unzip -oq terraform_${TERRAFORM_VERSION}_linux_amd64.zip -d /usr/local/bin \
    && rm terraform_${TERRAFORM_VERSION}_linux_amd64.zip

ENV PATH="/root/.local/bin:${PATH}"
