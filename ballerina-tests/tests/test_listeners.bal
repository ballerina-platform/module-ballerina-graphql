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

import ballerina/graphql;
import ballerina/http;

listener http:Listener httpListener = new (9090, httpVersion = http:HTTP_1_1);
listener graphql:Listener wrappedListener = new (httpListener);

listener graphql:Listener basicListener = new (9091);
listener graphql:Listener serviceTypeListener = new (9092);
listener graphql:Listener timeoutListener = new (9093, {timeout: 1.0});
listener graphql:Listener hierarchicalPathListener = new (9094);
listener graphql:Listener specialTypesTestListener = new (9095);
listener graphql:Listener secureListener = new (9096, secureSocket = {
    key: {
        path: KEYSTORE_PATH,
        password: "ballerina"
    }
});
listener graphql:Listener authTestListener = new (9097);
listener graphql:Listener subscriptionListener = new (9099);

// The mock authorization server, based with https://hub.docker.com/repository/docker/ldclakmal/ballerina-sts
listener http:Listener sts = new (9445, {secureSocket: {key: {path: KEYSTORE_PATH, password: "ballerina"}}});

listener http:Listener http2Listener = new http:Listener(9190);
listener graphql:Listener http2BasedListener = new (http2Listener);

listener http:Listener http1Listener = new http:Listener(9191, httpVersion = http:HTTP_1_0);
listener graphql:Listener http1BasedListener = new (http1Listener);
