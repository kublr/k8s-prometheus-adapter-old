#!/bin/bash

set -o errexit
set -o nounset
set -o pipefail

export ARCH=amd64

# if 'publish' parameter is specified, do publish
DO_PUBLISH=""
if [[ " $* " =~ ' publish ' ]]; then
    DO_PUBLISH=yes
fi

# this script is expected to be located in the same directory as the directory containing Dockerfiles
readonly ROOT="$(dirname "$(readlink -f "${BASH_SOURCE}")")"

# It is expected that CHART_NAME and CHART_VERSION variables are loaded from main.properties file
source "${ROOT}"/main.properties
export REGISTRY IMAGE VERSION

# Build procedure may also set PUBLISH_VERSION variable, which will be used as a version for the image
PUBLISH_VERSION="${PUBLISH_VERSION:-"${VERSION}"}"

# Target package name
TAG="${REGISTRY}/${IMAGE}-${ARCH}:${PUBLISH_VERSION}"

if [[ -n "${DO_PUBLISH}" ]]; then
    # avoid overwriting image in the repository
    if docker pull "${TAG}" &>/dev/null; then
        echo "The tag ${TAG} is already published"
        exit 1
    fi
fi

# cleanup
docker rmi -f "${TAG}" || true

# build docker image
make docker-build

if [[ -n "${DO_PUBLISH}" ]]; then
    # publish
    docker push "${TAG}"
fi
