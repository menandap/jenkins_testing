#!/bin/bash
WAKTU=$(date '+%Y-%m-%d.%H')
echo "$SSH_KEY" > key.pem
chmod 400 key.pem

if [ "$1" == "BUILD" ];then
echo '[*] Building Program To Docker Images'
echo "[*] Waktu : $WAKTU"
echo "[*] Tag : $CI_COMMIT_SHA"
docker build -t menandap/devopsgitlab:$CI_COMMIT_SHA .
docker tag menandap/devopsgitlab:$CI_COMMIT_SHA menandap/devopsgitlab:$CI_COMMIT_BRANCH
docker login --username=$DOCKER_USER --password=$DOCKER_PASS
docker push menandap/devopsgitlab:$CI_COMMIT_SHA
echo $CI_PIPELINE_ID

elif [ "$1" == "DEPLOY" ];then
echo "[*] Tag $WAKTU"
echo "[*] Deploy to production server in version $CI_COMMIT_SHA"
echo '[*] Generate SSH Identity'
HOSTNAME=`hostname` ssh-keygen -t rsa -C "$HOSTNAME" -f "$HOME/.ssh/id_rsa" -P "" && cat ~/.ssh/id_rsa.pub
echo '[*] Execute Remote SSH'
ssh -i key.pem -o "StrictHostKeyChecking no" root@20.213.164.175 "sed -ie "s/CI_COMMIT_SHA/$CI_COMMIT_SHA/g" service-nginx-nodeport.yaml"
ssh -i key.pem -o "StrictHostKeyChecking no" root@20.213.164.175 "sudo microk8s.kubectl delete -f service-nginx-nodeport.yaml"
ssh -i key.pem -o "StrictHostKeyChecking no" root@20.213.164.175 "sudo microk8s.kubectl create -f service-nginx-nodeport.yaml"
ssh -i key.pem -o "StrictHostKeyChecking no" root@20.213.164.175 "rm service-nginx-nodeport.yaml"
ssh -i key.pem -o "StrictHostKeyChecking no" root@20.213.164.175 "mv service-nginx-nodeport.yamle service-nginx-nodeport.yaml"
echo $CI_PIPELINE_ID
fi