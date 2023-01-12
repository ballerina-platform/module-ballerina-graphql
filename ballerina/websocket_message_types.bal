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

type ConnectionInitMessage record {|
    WS_INIT 'type;
    map<json> payload?;
|};

type ConnectionAckMessage record {|
    WS_ACK 'type;
    map<json> payload?;
|};

type PingMessage record {|
    WS_PING 'type;
    map<json> payload?;
|};

type PongMessage record {|
    WS_PONG 'type;
    map<json> payload?;
|};

type SubscribeMessage record {|
    WS_SUBSCRIBE 'type;
    string id;
    record {|
        string? operationName?;
        string query;
        map<json>? variables?;
        map<json>? extensions?;
    |} payload;
|};

type NextMessage record {|
    WS_NEXT 'type;
    string id;
    json payload;
|};

type ErrorMessage record {|
    WS_ERROR 'type;
    string id;
    json payload;
|};

type CompleteMessage record {|
    WS_COMPLETE 'type;
    string id;
|};

type Message ConnectionInitMessage|PingMessage|PongMessage|SubscribeMessage|CompleteMessage;
