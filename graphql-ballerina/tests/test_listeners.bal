// Copyright (c) 2021, WSO2 Inc. (http://www.wso2.org) All Rights Reserved.
//
// WSO2 Inc. licenses this file to you under the Apache License,
// Version 2.0 (the "License"); you may not use this file except
// in compliance with the License.
// You may obtain a copy of the License at
//
// http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing,
// software distributed under the License is distributed on an
// "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
// KIND, either express or implied.  See the License for the
// specific language governing permissions and limitations
// under the License.

import ballerina/http;

listener http:Listener httpListener = new(9090);
listener Listener wrappedListener = new(httpListener);

listener Listener basicListener = new(9091);
listener Listener serviceTypeListener = new(9092);
listener Listener timeoutListener = new(9093, { timeout: 1.0 });
listener Listener hierarchicalPathListener = new Listener(9094);
listener Listener specialTypesTestListener = new Listener(9095);
listener Listener secureListener = new Listener(9096,
    secureSocket = { key: { path: KEYSTORE_PATH, password: "ballerina" } });
listener Listener authTestListener = new Listener(9097);

// The mock authorization server, based with https://hub.docker.com/repository/docker/ldclakmal/ballerina-sts
listener http:Listener sts = new(9445, { secureSocket: { key: { path: KEYSTORE_PATH, password: "ballerina" } } });
