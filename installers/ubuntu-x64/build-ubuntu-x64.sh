#!/bin/bash
# ----------------------------------------------------------------------------------
# Copyright (c) 2018, WSO2 Inc. (http://www.wso2.org) All Rights Reserved.
#
# WSO2 Inc. licenses this file to you under the Apache License,
# Version 2.0 (the "License"); you may not use this file except
# in compliance with the License.
# You may obtain a copy of the License at
#
# http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing,
# software distributed under the License is distributed on an
# "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
# KIND, either express or implied.  See the License for the
# specific language governing permissions and limitations
# under the License.
# ----------------------------------------------------------------------------------
#
#Generate WSO2 Product Installers for Ubuntu OS.

#Configuration Variables and Parameters

function printUsage() {
    echo -e "\033[1mUsage:\033[0m"
    echo "$0 [VERSION]"
    echo
    echo -e "\033[1mOptions:\033[0m"
    echo "  -h (--help)"
    echo
    echo -e "\033[1mExample::\033[0m"
    echo "$0 1.0.0"

}

if [ -z "$1" ]; then
    echo "Please enter the version of the cellery distribution."
    printUsage
    exit 1
fi

#Parameters
TARGET_DIRECTORY="target"
INSTALLATION_DIRECTORY="cellery-ubuntu-x64-"${1}
DATE=`date +%Y-%m-%d`
TIME=`date +%H:%M:%S`
LOG_PREFIX="[$DATE $TIME]"
BINARY_SIZE="0 MB"

#Functions
go_to_dir() {
    pushd $1 >/dev/null 2>&1
}

log_info() {
    echo "${LOG_PREFIX}[INFO]" $1
}

log_warn() {
    echo "${LOG_PREFIX}[WARN]" $1
}

log_error() {
    echo "${LOG_PREFIX}[ERROR]" $1
}

getBallerinaHome() {
    if [ -z "${HOME_BALLERINA}" ]; then
        BALLERINA_VERSION=$(ballerina version | awk '{print $2}')
        BALLERINA_DEFAULT_HOME_PREFIX="/usr/lib/ballerina/"
        HOME_BALLERINA=${BALLERINA_DEFAULT_HOME_PREFIX}/ballerina-${BALLERINA_VERSION}
        if [ ! -d $HOME_BALLERINA ]; then
            log_error "BALLERINA_HOME cannot be found."
            exit 1
        fi
    fi
}

buildBallerinaNatives() {
    go_to_dir ../../ballerina-natives
    mvn clean install
    popd >/dev/null 2>&1
}

createInstallationDirectory() {
    if [ -d ${TARGET_DIRECTORY} ]; then
        deleteInstallationDirectory
    fi
    mkdir $TARGET_DIRECTORY

    if [[ $? != 0 ]]; then
        log_error "Failed to create $TARGET_DIRECTORY directory" $?
        exit 1
    fi
}

deleteInstallationDirectory() {
    log_info "Cleaning $TARGET_DIRECTORY directory."
    rm -rf $TARGET_DIRECTORY

    if [[ $? != 0 ]]; then
        log_error "Failed to clean $TARGET_DIRECTORY directory" $?
        exit 1
    fi
}

buildCelleryCLI() {
    go_to_dir ../../
    bash build.sh

    if [ $? != 0 ]; then
        log_error "Failed to build cellery CLI." $?
        exit 1
    fi
    popd >/dev/null 2>&1
}

getProductSize() {
    CELLERY_SIZE=$(du -s ../../cellery | awk '{print $1}')
    CELLERY_JAR_SIZE=$(du -s ../../ballerina-natives/target/cellery-0.0.0.jar | awk '{print $1}')
    CELLERY_REPO_SIZE=$(du -s ../../ballerina-natives/target/generated-balo/ | awk '{print $1}')

    BINARY_SIZE_KB=$((CELLERY_SIZE + CELLERY_JAR_SIZE + CELLERY_REPO_SIZE))
    BINARY_SIZE_MB=$((BINARY_SIZE_KB/1024))

    BINARY_SIZE=${BINARY_SIZE_MB}
}

copyDebianDirectory() {
    createInstallationDirectory
    cp -R resources ${TARGET_DIRECTORY}/${INSTALLATION_DIRECTORY}
    chmod -R 755 ${TARGET_DIRECTORY}/${INSTALLATION_DIRECTORY}/DEBIAN
    mkdir -p ${TARGET_DIRECTORY}/${INSTALLATION_DIRECTORY}/usr/share/
    cp resources/copyright  ${TARGET_DIRECTORY}/${INSTALLATION_DIRECTORY}/usr/share/
    sed -i -e 's/__BINARY_SIZE__/'${BINARY_SIZE}'/g' ${TARGET_DIRECTORY}/${INSTALLATION_DIRECTORY}/DEBIAN/control
}

copyBuildDirectories() {
    getBallerinaHome
    mkdir -p ${TARGET_DIRECTORY}/${INSTALLATION_DIRECTORY}/${HOME_BALLERINA}/bre/lib/
    mkdir -p ${TARGET_DIRECTORY}/${INSTALLATION_DIRECTORY}/${HOME_BALLERINA}/lib/repo
    cp ../../ballerina-natives/target/cellery-*.jar ${TARGET_DIRECTORY}/${INSTALLATION_DIRECTORY}/${HOME_BALLERINA}/bre/lib/
    cp -R ../../ballerina-natives/target/generated-balo/repo/celleryio ${TARGET_DIRECTORY}/${INSTALLATION_DIRECTORY}/${HOME_BALLERINA}/lib/repo

    mkdir -p ${TARGET_DIRECTORY}/${INSTALLATION_DIRECTORY}/usr/local/bin
    cp ../../cellery ${TARGET_DIRECTORY}/${INSTALLATION_DIRECTORY}/usr/local/bin
}

createInstaller() {
    fakeroot dpkg-deb --build target/${INSTALLATION_DIRECTORY}
}

#Pre-requisites
command -v mvn -v >/dev/null 2>&1 || {
    log_warn "Apache Maven was not found. Please install Maven first."
    exit 1
}
#Pre-requisites
command -v git >/dev/null 2>&1 || {
    log_warn "Git was not found. Please install git first."
    exit 1
}
command -v docker >/dev/null 2>&1 || {
    log_warn "Docker was not found. Please install docker first."
    exit 1
}
command -v ballerina >/dev/null 2>&1 || {
    log_warn "Ballerina was not found. Please install ballerina first."
    exit 1
}

#Main script
log_info "Installer Generating process started."

buildBallerinaNatives
buildCelleryCLI

getProductSize

copyDebianDirectory
copyBuildDirectories

createInstaller
log_info "Build completed."
exit 0
