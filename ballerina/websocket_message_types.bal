// Copyright (c) 2023 WSO2 LLC. (http://www.wso2.com) All Rights Reserved.
//
// WSO2 LLC. licenses this file to you under the Apache License,
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

import ballerina/websocket;

type ConnectionInit record {|
    WS_INIT 'type;
    map<json> payload?;
|};

type ConnectionAck record {|
    WS_ACK 'type;
    map<json> payload?;
|};

type Ping record {|
    WS_PING 'type;
    map<json> payload?;
|};

type Pong record {|
    WS_PONG 'type;
    map<json> payload?;
|};

type Subscribe record {|
    WS_SUBSCRIBE 'type;
    string id;
    record {|
        string? operationName?;
        string query;
        map<json>? variables?;
        map<json>? extensions?;
    |} payload;
|};

type Next record {|
    WS_NEXT 'type;
    string id;
    json payload;
|};

type ErrorMessage record {|
    WS_ERROR 'type;
    string id;
    json payload;
|};

type Complete record {|
    WS_COMPLETE 'type;
    string id;
|};

type ConnectionInitializationTimeout record {|
    *websocket:CustomCloseFrame;
    4408 status = 4408;
    string reason = "Connection initialization timeout";
|};

type TooManyInitializationRequests record {|
    *websocket:CustomCloseFrame;
    4429 status = 4429;
    string reason = "Too many initialization requests";
|};

type Unauthorized record {|
    *websocket:CustomCloseFrame;
    4401 status = 4401;
    string reason = "Unauthorized";
|};

type SubscriberAlreadyExists record {|
    *websocket:CustomCloseFrame;
    4409 status = 4409;
|};

public final readonly & ConnectionInitializationTimeout CONNECTION_INITIALISATION_TIMEOUT = {};
public final readonly & TooManyInitializationRequests TOO_MANY_INITIALIZATION_REQUESTS = {};
public final readonly & Unauthorized UNAUTHORIZED = {};

type InboundMessage ConnectionInit|Ping|Pong|Subscribe|Complete;

type OutboundMessage ConnectionAck|Ping|Pong|Next|ErrorMessage|Complete;
