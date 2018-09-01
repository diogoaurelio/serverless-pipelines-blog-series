#!/usr/bin/env bash

set -e -x

# PATH
ORIGIN_DIR=${PWD}
LAMBDA_NAME="redshift"
LAMBDAS_DIR=$(dirname "${PWD}")

echo "Building Redshift data loader Lambda..."

# load common funcs
source ${LAMBDAS_DIR}/../common_bash/build.sh

installDependenciesLambda ${LAMBDA_NAME} ${LAMBDAS_DIR} true
