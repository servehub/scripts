FROM ubuntu:16.04

RUN echo "deb http://ppa.launchpad.net/ansible/ansible/ubuntu xenial main" | tee /etc/apt/sources.list.d/ansible.list \
    && echo "deb-src http://ppa.launchpad.net/ansible/ansible/ubuntu xenial main" | tee -a /etc/apt/sources.list.d/ansible.list \
    && apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv-keys 7BB9C367 \
    && DEBIAN_FRONTEND=noninteractive apt-get update \
    && apt-get install -y \
         ansible=2.5.* \
         python-pip \
         sshpass \
         openssh-client \
         unzip \
         wget

RUN pip install --upgrade pip \
    && pip install boto passlib awscli

ENV TERRAFORM_VERSION 0.11.6

RUN wget -q https://releases.hashicorp.com/terraform/${TERRAFORM_VERSION}/terraform_${TERRAFORM_VERSION}_linux_amd64.zip \
    && unzip -oq terraform_${TERRAFORM_VERSION}_linux_amd64.zip -d /usr/local/bin \
    && rm terraform_${TERRAFORM_VERSION}_linux_amd64.zip
