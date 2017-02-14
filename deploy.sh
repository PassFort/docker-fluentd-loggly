#!/bin/bash
set -e
export PROJECT_ID=core-gearbox-112418
export RUST_BUILD_IMAGE=clux/muslrust:1.13.0-nightly-2016-09-16
export TREE_HASH=`git cat-file -p HEAD`
export TREE_HASH=${TREE_HASH:5:7}
export CONTAINER_TAG=$TREE_HASH
export CLUSTER=${1:-staging}

BUILD=false
DEPLOY=false

while test $# -gt 0
do
    case "$1" in
        --build) BUILD=true
            ;;
        --deploy) DEPLOY=true
            ;;
    esac
    shift
done

printer ()
{
    echo -e "\033[0;33m$1\033[0m"
    echo $1 | slacker -c dev-releases -t xoxp-11239767985-11233063075-26572878627-8d835d7a28
}

build_container ()
{
    printer "Building $CONTAINER_TAG"
    docker build -t eu.gcr.io/$PROJECT_ID/passfort-loggly:$CONTAINER_TAG -f Dockerfile .
    gcloud docker push eu.gcr.io/$PROJECT_ID/passfort-loggly:$CONTAINER_TAG
}

deploy_container()
{
    printer "Deploying $1 $CONTAINER_TAG"

    envsubst < $1-deployment.yaml | kubectl replace --record -f - || envsubst < $1-deployment.yaml | kubectl create --record -f -
}

case $CLUSTER in
    staging)
        CLUSTER_NAME="staging-2"
        ;;
    production)
        CLUSTER_NAME="production"
        ;;
    *)
        echo "Unrecognised cluster name" && exit 1
        ;;
esac

# Switch to the correct cluster
gcloud config set container/cluster $CLUSTER_NAME
gcloud container clusters get-credentials $CLUSTER_NAME

if $BUILD ; then
    printer "Building Release *$CONTAINER_TAG*"
    build_container
    printer "Build completed"
fi

if $DEPLY ; then
    printer "Deploying Release *$CONTAINER_TAG* to cluster *$CLUSTER* ($CLUSTER_NAME)."
    deploy_container
    printer "Deploy completed"
fi
