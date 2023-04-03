#!/bin/bash -e
# Copyright 2023 WSO2 LLC. (http://wso2.org)
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#
# ----------------------------------------------------------------------------
# Pre run script for ballerina performance tests
# ----------------------------------------------------------------------------
set -e

echo "----------Downloading websocket plugin tool----------"
wget -O JMeterWebSocketSamplers-1.2.8.jar https://bitbucket.org/pjtr/jmeter-websocket-samplers/downloads/JMeterWebSocketSamplers-1.2.8.jar
sudo cp JMeterWebSocketSamplers-1.2.8.jar /opt/apache-jmeter-5.4/lib/ext
