#!/bin/bash

#######################################################################
# OnlyOffice Package Builder

# Copyright (C) 2024 BTACTIC, SCCL

# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.

# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.

# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.
#######################################################################

usage() {
cat <<EOF

  $0
  Copyright BTACTIC, SCCL
  Licensed under the GNU PUBLIC LICENSE 3.0

  Usage: $0 --product-version=PRODUCT_VERSION --build-number=BUILD_NUMBER --unlimited-organization=ORGANIZATION --tag-suffix=-TAG_SUFFIX --debian-package-suffix=-DEBIAN_PACKAGE_SUFFIX
  Example: $0 --product-version=7.4.1 --build-number=36 --unlimited-organization=btactic-oo --tag-suffix=-btactic --debian-package-suffix=-btactic

  For Github actions you might want to either build only binaries or build only deb so that it's easier to prune containers
  Example: $0 --product-version=7.4.1 --build-number=36 --unlimited-organization=btactic-oo --tag-suffix=-btactic --debian-package-suffix=-btactic --binaries-only
  Example: $0 --product-version=7.4.1 --build-number=36 --unlimited-organization=btactic-oo --tag-suffix=-btactic --debian-package-suffix=-btactic --deb-only

EOF

}

BINARIES_ONLY="false"
DEB_ONLY="false"

# Check the arguments.
for option in "$@"; do
  case "$option" in
    -h | --help)
      usage
      exit 0
    ;;
    --product-version=*)
      PRODUCT_VERSION=`echo "$option" | sed 's/--product-version=//'`
    ;;
    --build-number=*)
      BUILD_NUMBER=`echo "$option" | sed 's/--build-number=//'`
    ;;
    --unlimited-organization=*)
      UNLIMITED_ORGANIZATION=`echo "$option" | sed 's/--unlimited-organization=//'`
    ;;
    --tag-suffix=*)
      TAG_SUFFIX=`echo "$option" | sed 's/--tag-suffix=//'`
    ;;
    --debian-package-suffix=*)
      DEBIAN_PACKAGE_SUFFIX=`echo "$option" | sed 's/--debian-package-suffix=//'`
    ;;
    --binaries-only)
      BINARIES_ONLY="true"
    ;;
    --deb-only)
      DEB_ONLY="true"
    ;;
  esac
done

BUILD_BINARIES="true"
BUILD_DEB="true"

if [ ${BINARIES_ONLY} == "true" ] ; then
  BUILD_BINARIES="true"
  BUILD_DEB="false"
fi

if [ ${DEB_ONLY} == "true" ] ; then
  BUILD_BINARIES="false"
  BUILD_DEB="true"
fi

if [ "x${PRODUCT_VERSION}" == "x" ] ; then
    cat << EOF
    --product-version option must be informed.
    Aborting...
EOF
    usage
    exit 1
fi

if [ "x${BUILD_NUMBER}" == "x" ] ; then
    cat << EOF
    --build-number option must be informed.
    Aborting...
EOF
    usage
    exit 1
fi

if [ "x${UNLIMITED_ORGANIZATION}" == "x" ] ; then
    cat << EOF
    --unlimited-organization option must be informed.
    Aborting...
EOF
    usage
    exit 1
fi

if [ "x${TAG_SUFFIX}" == "x" ] ; then
    cat << EOF
    --tag-suffix option must be informed.
    Aborting...
EOF
    usage
    exit 1
fi

if [ "x${DEBIAN_PACKAGE_SUFFIX}" == "x" ] ; then
    cat << EOF
    --debian-package-suffix option must be informed.
    Aborting...
EOF
    usage
    exit 1
fi

PRUNE_DOCKER_CONTAINERS_ACTION="false"
if [ "x${PRUNE_DOCKER_CONTAINERS}" != "x" ] ; then
  if [ ${PRUNE_DOCKER_CONTAINERS} == "true" ] -o [ ${PRUNE_DOCKER_CONTAINERS} == "TRUE" ] ; then
    PRUNE_DOCKER_CONTAINERS_ACTION="true"
    cat << EOF
    WARNING !
    WARNING !
    --prune-docker-containers has been set to true
    This will erase all of your docker containers
    after the binaries build.

    Waiting for 30s so that you can CTRL+C
EOF
    sleep 30s
  fi
fi


if [ "${BUILD_DEB}" == "true" ] ; then
    cd deb_build
    docker build --tag onlyoffice-deb-builder . -f Dockerfile-manual-debian-11
    docker run \
      --env PRODUCT_VERSION=${PRODUCT_VERSION} \
      --env BUILD_NUMBER=${BUILD_NUMBER} \
      --env TAG_SUFFIX=${TAG_SUFFIX} \
      --env UNLIMITED_ORGANIZATION=${UNLIMITED_ORGANIZATION} \
      --env DEBIAN_PACKAGE_SUFFIX=${DEBIAN_PACKAGE_SUFFIX} \
      -v $(pwd):/usr/local/unlimited-onlyoffice-package-builder:ro \
      -v $(pwd):/root:rw \
      -v $(pwd)/../build_tools:/root/build_tools:ro \
      onlyoffice-deb-builder /bin/bash -c "/usr/local/unlimited-onlyoffice-package-builder/onlyoffice-deb-builder.sh --product-version ${PRODUCT_VERSION} --build-number ${BUILD_NUMBER} --tag-suffix ${TAG_SUFFIX} --unlimited-organization ${UNLIMITED_ORGANIZATION} --debian-package-suffix ${DEBIAN_PACKAGE_SUFFIX}"
    cd ..
fi
