// Copyright (c) 2020, WSO2 Inc. (http://www.wso2.org) All Rights Reserved.
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

import ballerina/test;

@test:Config{}
function testLiftCount() returns error? {
    string document = "query { trailCount(status: OPEN) }";
    json actualPayload = check getJsonPayloadFromService(document);
    json expectedPayload = {
        data: {
            trailCount: 2
        }
    };
    test:assertEquals(actualPayload, expectedPayload);
}

@test:Config{}
function testAllLifts() returns error? {
    string document = "query { allLifts { name status } }";
    json actualPayload = check getJsonPayloadFromService(document);
    json expectedPayload = {
        data: {
            allLifts: [
                {
                    name: "Astra Express",
                    status: "OPEN"
                },
                {
                    name: "Jazz Cat",
                    status: "CLOSED"
                },
                {
                    name: "Jolly Roger",
                    status: "CLOSED"
                }
            ]
        }
    };
    test:assertEquals(actualPayload, expectedPayload);
}

@test:Config{}
function testAllTrails() returns error? {
    string document = "query { allTrails { id name difficulty } }";
    json actualPayload = check getJsonPayloadFromService(document);
    json expectedPayload = {
        data: {
            allTrails: [
                {
                    id: "blue-bird",
                    name: "Blue Bird",
                    difficulty: "intermediate"
                },
                {
                    id: "blackhawk",
                    name: "Blackhawk",
                    difficulty: "intermediate"
                },
                {
                    id: "ducks-revenge",
                    name: "Duck's Revenge",
                    difficulty: "expert"
                }
            ]
        }
    };
    test:assertEquals(actualPayload, expectedPayload);
}

@test:Config{}
function testSearch() returns error? {
    string document = string
    `query {
        search(status: CLOSED) {
            ... on Trail {
                name
                trees
            }
            ... on Lift {
                name
                capacity
            }
        }
    }`;
    json actualPayload = check getJsonPayloadFromService(document);
    json expectedPayload = {
        data: {
            search: [
                {
                    name: "Duck's Revenge",
                    trees: false
                },
                {
                    name: "Jazz Cat",
                    capacity: 5
                },
                {
                    name: "Jolly Roger",
                    capacity: 8
                }
            ]
        }
    };
    test:assertEquals(actualPayload, expectedPayload);
}
