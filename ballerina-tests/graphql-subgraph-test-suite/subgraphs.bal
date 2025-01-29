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
// specific language gove

import ballerina/graphql;
import ballerina/graphql.subgraph;

@subgraph:Subgraph
service /subgraph on new graphql:Listener(9088) {
    resource function get greet() returns string => "welcome";
}

public graphql:Service subgraphService = @subgraph:Subgraph service object {
    resource function get greeting() returns string => "welcome";
};

listener graphql:Listener graphqlListener = new (9098);

@subgraph:Subgraph
service /reviews on graphqlListener {
    resource function get reviews() returns ReviewData[] {
        return [];
    }
}

public isolated service class ReviewData {
    isolated resource function get id() returns string => "123";
}
