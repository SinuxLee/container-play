#!/usr/bin/env bash
set -ueo pipefail

export DOCKER_BUILDKIT=1

# REGISTRY='localhost:5000'
REGISTRY='ffa-db.dd.info:5000'
TARGET='ffb'
VERSION='1.1.200'

# compat mac "sed -i"
sedi=(-i)
case "$(uname)" in Darwin*)
  sedi=(-i "")
  ;;
esac

WORK_DIR=$(
  cd "$(dirname "$0")/" || exit 1
  pwd
)
cd "${WORK_DIR}" || exit 1

function incr_sub_ver() {
  # shellcheck disable=SC2206
  declare -a part=(${1//\./ })
  declare new
  declare -i carry=1
  max_idx=${#part[@]}-1
  new=$((part[max_idx] + carry))
  part[max_idx]=${new}
  new="${part[*]}"
  echo "${new// /.}"
}

function build() {
  # forward ssh request
  ssh-add ~/.ssh/id_rsa
  tag="${REGISTRY}"/ffa/${TARGET}:${VERSION}
  printf "build tag: %s\n" ${tag}
  docker buildx  build --progress=plain --ssh default -t $tag -f ./Dockerfile .
}

function push() {
  version_tag="${REGISTRY}"/ffa/${TARGET}:${VERSION}
  latest_tag="${REGISTRY}"/ffa/${TARGET}:latest
  printf "push... , image tag: %s\n" ${version_tag}
  docker push "${version_tag}"

  docker tag "${version_tag}" "${latest_tag}"
  docker push "${latest_tag}"

  new=$(incr_sub_ver ${VERSION})
  sed "${sedi[@]}" "s/${VERSION}/${new}/g" dockery.sh
}

function clean() {
  docker image prune -f -a
}

function status() {
  docker images | grep ${TARGET}
}

function help_me() {
  echo "$0 build|push|clean|status|release"
}


case "$1" in
  "" )
    help_me
    ;;
  release )
    build
    push
    ;;
  build )
    build
    ;;
  push )
    push
    ;;
  clean )
    clean
    ;;
  status )
    status
    ;;
  * )
    help_me
    ;;
esac

