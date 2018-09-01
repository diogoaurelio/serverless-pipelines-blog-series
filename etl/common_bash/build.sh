#!/usr/bin/env bash

##############################################################################################
#
#   Utility functions that support CI/CD bureaucracies in lambda setups
#
#
##############################################################################################


installDependenciesLambda(){
    # params
    LAMBDA_NAME=${1}
    ROOT_DIR=${2}
    CLEANUP=${3:-true}

    # Creation of variables for every needed directory level in the project.
    LAMBDA_DIR=${ROOT_DIR}/${LAMBDA_NAME}
    SRC_DIR=${LAMBDA_DIR}/src

    if [ -d $SRC_DIR ]; then
        printf "Found lambda dir. Proceeding."

        # Remove any possible previous virtualenv.
        cd ${LAMBDA_DIR} && rm -rf ${LAMBDA_NAME}_env && rm -rf ${LAMBDA_NAME}

        # Adding python dependencies to target (from virtual environment)
        PYTHON3_PATH=`which python3.6`
        cd ${LAMBDA_DIR} && virtualenv -p $PYTHON3_PATH ${LAMBDA_NAME}_env
        printf "Successfully installed pip virtualenv, sourcing it"

        cd ${LAMBDA_DIR} && source ${LAMBDA_NAME}_env/bin/activate
        # Installation all needed dependencies and libraries
        cd ${LAMBDA_DIR} && pip3 install -r requirements.txt

        echo "copying all packages into src"
        cd ${LAMBDA_DIR} && cp -r ${LAMBDA_NAME}_env/lib/python3.6/site-packages/* ${SRC_DIR}

        echo "copying shared packages across lambda functions"
        mkdir -p ${SRC_DIR}/common && cp -r ${ROOT_DIR}/common/* ${SRC_DIR}/common/

        echo "Clean up"
        cd ${LAMBDA_DIR} && rm -rf ${LAMBDA_NAME}_env && rm -rf ${LAMBDA_NAME}

        if [ ${CLEANUP} = true ]; then
            echo "Making lambda slimmer..."
            # Cleanup unrequired packages for prod to slim the zip file size.
            if [ -d ${SRC_DIR}/__pycache__ ]; then
                rm -rf ${SRC_DIR}/__pycache__
            fi

            if [ -d ${SRC_DIR}/_pytest ]; then
                rm -rf ${SRC_DIR}/_pytest
            fi

            if ls ${SRC_DIR}/pip* 1> /dev/null 2>&1; then
                rm -r ${SRC_DIR}/pip*
            fi

            if ls ${SRC_DIR}/setuptools* 1> /dev/null 2>&1; then
                rm -r ${SRC_DIR}/setuptools*
            fi

            if ls ${SRC_DIR}/*.dist-info 1> /dev/null 2>&1; then
                rm -r ${SRC_DIR}/*.dist-info
            fi

        fi

    else
       printf "\nERROR: Unable to build lambda funcion '$LAMBDA_NAME' -  provided path NOT found \n"
    fi
}
