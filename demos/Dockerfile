FROM ubuntu:22.04
ENV EKSCTL_VERSION=0.115.0
ENV KUBECTL_VERSION=1.25.3
ENV KIND_VERSION=0.11.1
ENV JSCTL_VERSION=0.1.13
ENV CMCTL_VERSION=1.10.0
ENV DEBIAN_FRONTEND=noninteractive
RUN apt update \
 && apt upgrade -y \
 && apt install -y git curl unzip vim less pv bash-completion gettext-base docker-compose \
 && curl --silent "https://awscli.amazonaws.com/awscli-exe-linux-$(uname -m).zip" -o "awscliv2.zip" \
 && unzip awscliv2.zip \
 && ./aws/install \
 && curl --silent --location "https://github.com/weaveworks/eksctl/releases/download/v${EKSCTL_VERSION}/eksctl_Linux_amd64.tar.gz" | tar xz -C /tmp \
 && mv /tmp/eksctl /usr/local/bin \
 && curl -LO https://storage.googleapis.com/kubernetes-release/release/v${KUBECTL_VERSION}/bin/linux/amd64/kubectl \
 && chmod +x ./kubectl \
 && mv ./kubectl /usr/local/bin/kubectl \
 && curl -sSL https://raw.githubusercontent.com/helm/helm/master/scripts/get-helm-3 | bash \
 && curl -Lo ./kind https://kind.sigs.k8s.io/dl/v${KIND_VERSION}/kind-linux-amd64 \
 && chmod +x ./kind \
 && mv ./kind /usr/local/bin/kind \
 && echo "jsctl-$JSCTL_VERSION-$(uname -s)-$(uname -m)" | tr '[:upper:]' '[:lower:]' > /tmp/JSCTL_ASSET_REF \
 && echo "$(cat /tmp/JSCTL_ASSET_REF).tar.gz" > /tmp/JSCTL_ARCHIVE \
 && curl -LO https://github.com/jetstack/jsctl/releases/download/v$JSCTL_VERSION/$(cat /tmp/JSCTL_ARCHIVE) \
 && tar -zxvf $(cat /tmp/JSCTL_ARCHIVE) \
 && mv ./$(cat /tmp/JSCTL_ASSET_REF)/jsctl /usr/local/bin/jsctl \
 && curl -sSL -o cmctl.tar.gz https://github.com/cert-manager/cert-manager/releases/download/v${CMCTL_VERSION}/cmctl-$(uname -s)-$(uname -m | sed s/aarch64/arm64/g).tar.gz \
 && tar xzf cmctl.tar.gz \
 && mv cmctl /usr/local/bin \
 && rm -rf awscliv2.zip aws cmctl.tar.gz \
 && echo "source /usr/share/bash-completion/bash_completion" >> ~/.bashrc \
 && echo "source <(kubectl completion bash)" >> ~/.bashrc \
 && echo "alias k=kubectl" >> ~/.bashrc \
 && echo "complete -o default -F __start_kubectl k" >> ~/.bashrc \
 && echo "export PS1='k8sh $ '" >> ~/.bashrc
