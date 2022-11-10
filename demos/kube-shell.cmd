@ECHO OFF
REM this script needs testing
docker build -t kube-shell:1.0 ${PWD} # <-- can do better than this, want to force this to use the director the Dockerfile is in (which may not be $PWD)
docker run -it --net host -v ${USERPROFILE}/.kube/:/root/.kube -v ${CD}:/work -w /work kube-shell:1.0 /bin/bash
