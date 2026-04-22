// Copyright (c) 2024 WSO2 LLC. (http://www.wso2.com) All Rights Reserved.
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

import ballerina/lang.runtime; import ballerina/graphql; import ballerina/http; service / on new http:Listener(9090) { resource function get greet() returns string { return "Hello from global http service"; } } public function main() returns error? { graphql:Service gqlService = service object { resource function get greet() returns string { return "Hello from gql service"; } }; http:Service httpService = service object { resource function get greet() returns string { return "Hello from local http service"; } }; graphql:Listener gqlListener = check new(9091); http:Listener httpListener = check new(9092); check gqlListener.attach(gqlService); check httpListener.attach(httpService); check gqlListener.'start(); check httpListener.'start(); runtime:registerListener(gqlListener); runtime:registerListener(httpListener); }
