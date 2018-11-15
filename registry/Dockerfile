# --------------------------------------------------------------------
# Copyright (c) 2018, WSO2 Inc. (http://wso2.com) All Rights Reserved.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
# http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
# -----------------------------------------------------------------------

FROM ballerina/ballerina:0.983.0
LABEL maintainer="cellery.io"

ARG WORK_DIR="/home/ballerina"
WORKDIR ${WORK_DIR}

COPY init-container.sh .
COPY target/registry.api.balx .
COPY registry.api/resources/registry.toml .
COPY resources/security/ security/

USER root

RUN mkdir -p /mnt/cellery-registry-data && chown -R ballerina:troupe /mnt/cellery-registry-data
VOLUME ["/mnt/cellery-registry-data"]

USER ballerina

ENV WORKING_DIRECTORY=${WORK_DIR}

EXPOSE 9090

ENTRYPOINT ${WORKING_DIRECTORY}/init-container.sh