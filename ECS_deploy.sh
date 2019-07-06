#!/bin/bash
set -e
CURRENT_DIR=$PWD
export AWS_PROFILE=ecsuser
APP_REPO=$IMAGE_NAME:$DOCKER_IMAGE_VERSION

buildimages()
{
echo "-----------------------------"
echo "Docker Image Version --- $DOCKER_IMAGE_VERSION ---"
echo "-----------------------------"
echo "[INFO] --- Building Docker Image for ttmp-zookeeper ---"
docker image build -t $APP_REPO .
pushimages
}
pushimages()
{
echo 'y' | $(aws ecr get-login | sed -e 's/-e\ none/''/g') #login to AWS ECR
echo "[INFO] --- ECR LOGIN SUCCESS ---"
docker image push $APP_REPO
registertask
}
registertask()
{
sed -i 's@IMGNAME_ZOOKEEPER@'"$ZKEEPER_REPO"'@g' $CURRENT_DIR/task-definitions/APP.json
echo "[INFO] --- Task definition's docker image name has been updated ---"
aws ecs register-task-definition --cli-input-json file://$CURRENT_DIR/task-definitions/APP.json
echo "[INFO] --- All the task definitions has been registered ---"
removeimage_local
}
removeimage_local()
{
docker image rm -f $APP_REPO

echo "[INFO] --- Removed all the images from jenkins server ---"
removeservices
}
removeservices()
{
  aws ecs update-service --cluster ttmp-qa --service APP --task-definition app_td --desired-count 0

  runservices
}
runservices()
{
echo "[INFO] --- Running task ttmp-pgdataload ---"
aws ecs run-task --cluster ttmp-qa --task-definition APP_td --count 1

}
