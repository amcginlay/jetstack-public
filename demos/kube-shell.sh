#!/bin/sh

SCRIPTDIR=$(dirname $(realpath $0))
WORKDIR=$(realpath ${1:-.} --relative-base $0)
[ "$(uname -s)" = "Linux" ] && JSCTL_CONFIG="${HOME}/.config" || JSCTL_CONFIG="${HOME}/Library/Application Support"

docker build -t kube-shell:1.0 ${SCRIPTDIR}

docker run -it --net host \
  -v ${HOME}/.aws/:/root/.aws/ \
  -v ${HOME}/.kube/:/root/.kube/ \
  -v "${JSCTL_CONFIG}/jsctl/":/root/.config/jsctl/ \
  -v /var/run/docker.sock:/var/run/docker.sock \
  -v ${WORKDIR}:/work -w /work \
  kube-shell:1.0 /bin/bash
