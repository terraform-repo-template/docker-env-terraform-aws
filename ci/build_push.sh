#!/bin/bash -e

COLOR_RED="\033[31m"
COLOR_GREEN="\033[32m"
COLOR_NON="\033[39m"

function error() {
  echo -e "$COLOR_RED$1$COLOR_NON"
}
function info() {
  echo -e "$COLOR_GREEN$1$COLOR_NON"
}

TERRAFORM_VERSION=${1:-1.5.0}
AWS_CLI_VERSION=${2:-2.12.1}
DOCKER_REGISTRY=johnzen
REPOSITORY=env-terraform-aws

BRANCH=$(git rev-parse --abbrev-ref HEAD)

source .env
echo "${DOCKERHUB_PASSWORD}" | docker login --username "${DOCKERHUB_USERNAME}" --password-stdin

COMMIT_SHORT=$(git rev-parse --short HEAD)
if [[ "${BRANCH}" == "main" ]] || [[ "${BRANCH}" == "master" ]]; then
  info "Docker build and push ${DOCKER_REGISTRY}/${REPOSITORY}:${TERRAFORM_VERSION}-${AWS_CLI_VERSION}"
  docker buildx build \
                --build-arg TERRAFORM_VERSION="${TERRAFORM_VERSION}" \
                --build-arg AWS_CLI_VERSION="${AWS_CLI_VERSION}" \
                -t "${DOCKER_REGISTRY}/${REPOSITORY}:${TERRAFORM_VERSION}-${AWS_CLI_VERSION}" \
                -t "${DOCKER_REGISTRY}/${REPOSITORY}:${COMMIT_SHORT}" \
                --platform linux/arm64,linux/amd64 \
                --push \
                .
else
  info "Docker build and push ${DOCKER_REGISTRY}/${REPOSITORY}:tmp_${BRANCH//\//_}"
  docker buildx build \
                --build-arg TERRAFORM_VERSION="${TERRAFORM_VERSION}" \
                --build-arg AWS_CLI_VERSION="${AWS_CLI_VERSION}" \
                -t "${DOCKER_REGISTRY}/${REPOSITORY}:tmp_${BRANCH//\//_}" \
                -t "${DOCKER_REGISTRY}/${REPOSITORY}:tmp_${COMMIT_SHORT}" \
                --platform linux/arm64,linux/amd64 \
                --push \
                 .
#  docker push "${DOCKER_REGISTRY}/${REPOSITORY}:tmp_${BRANCH//\//_}"
fi
# linux/arm64, linux/amd64, linux/amd64/v2, linux/riscv64, linux/ppc64le, linux/s390x, linux/386, linux/mips64le, linux/mips64, linux/arm/v7, linux/arm/v6