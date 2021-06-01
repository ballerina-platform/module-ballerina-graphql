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

import ballerina/http;
import ballerina/test;
import ballerina/url;
//import ballerina/io;

listener Listener simpleResourceListener = new(9092);

@test:Config {
    groups: ["listener", "unit"]
}
isolated function testShortHandQueryResult() returns error? {
    string document = string
    `{
    name
    birthdate
}`;
    string url = "http://localhost:9092/graphql";
    json actualPayload = check getJsonPayloadFromService(url, document);
    json expectedPayload = {
        data: {
            name: "James Moriarty",
            birthdate: "15-05-1848"
        }
    };
    test:assertEquals(actualPayload, expectedPayload);
}

@test:Config {
    groups: ["listener", "unit"]
}
isolated function testGetRequestResult() returns error? {
    string document = "query getPerson { profile(id: 1) { address { city } } }";
    string encodedDocument = check url:encode(document, "UTF-8");
    json expectedPayload = {
        data: {
            profile: {
                address: {
                    city: "Albuquerque"
                }
            }
        }
    };
    http:Client httpClient = check new("http://localhost:9095");
    string path = "/graphql?query=" + encodedDocument;
    json actualPayload = check httpClient->get(path, targetType = json);
    test:assertEquals(actualPayload, expectedPayload);
}

@test:Config {
    groups: ["listener", "negative"]
}
isolated function testInvalidJsonPayload() returns error? {
    http:Client httpClient = check new("http://localhost:9092/graphql");
    json|error result = httpClient->post("/", {}, targetType = json);
    test:assertTrue(result is http:ClientRequestError);
    http:ClientRequestError err = <http:ClientRequestError> result;
    test:assertEquals(err.detail()?.statusCode, 400);
    test:assertEquals(err.message(), "Bad Request");
}

@test:Config {
    groups: ["listener", "negative"]
}
isolated function testInvalidTextPayload() returns error? {
    http:Client httpClient = check new("http://localhost:9092/graphql");
    json actualPayload = check httpClient->post("/", "", targetType = json);
    json expectedPayload = {
        errors: [
            {
                massage: "Invalid 'Content-type' received"
            }
        ]
    };
    test:assertEquals(actualPayload, expectedPayload);
}

service /graphql on simpleResourceListener {
    isolated resource function get name() returns string {
        return "James Moriarty";
    }

    isolated resource function get birthdate() returns string {
        return "15-05-1848";
    }
}
