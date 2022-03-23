// Copyright (c) 2022, WSO2 Inc. (http://www.wso2.org) All Rights Reserved.
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

@test:Config {
    groups: ["client"]
}
isolated function testClientExecuteWithTypeWithJson() returns error? {
    string url = "http://localhost:9091/inputs";
    string query = string `query Greeting ($userName:String!){ greet (name: $userName) }`;
    string userName = "Roland";
    map<anydata> variables = {"userName": userName};

    Client graphqlClient = check new (url);
    json actualPayload = check graphqlClient->executeWithType(query, variables);
    json expectedPayload = {
        "data": {
            "greet": "Hello, Roland"
        }
    };
    assertJsonValuesWithOrder(actualPayload, expectedPayload);
}

@test:Config {
    groups: ["client"]
}
isolated function testClientExecuteWithTypeWithOpenRecord() returns error? {
    string url = "http://localhost:9091/inputs";
    string query = string `query Greeting ($userName:String!){ greet (name: $userName) }`;
    string userName = "Roland";
    map<anydata> variables = {"userName": userName};

    Client graphqlClient = check new (url);
    record{} actualPayload = check graphqlClient->executeWithType(query, variables);
    record{} expectedPayload = {
        "data": {
            "greet": "Hello, Roland"
        }
    };
    assertJsonValuesWithOrder(actualPayload.toJson(), expectedPayload.toJson());
}

@test:Config {
    groups: ["client"]
}
isolated function testClientExecuteWithTypeWithKnownRecord() returns error? {
    string url = "http://localhost:9091/inputs";
    string query = string `query Greeting ($userName:String!){ greet (name: $userName) }`;
    string userName = "Roland";
    map<anydata> variables = {"userName": userName};

    Client graphqlClient = check new (url);
    GreetingResponse actualPayload = check graphqlClient->executeWithType(query, variables);
    GreetingResponse expectedPayload = {
        data: {
            greet: "Hello, Roland"
        }
    };
    assertJsonValuesWithOrder(actualPayload.toJson(), expectedPayload.toJson());
}

@test:Config {
    groups: ["client"]
}
isolated function testClientExecuteWithTypeWithGenericRecord() returns error? {
    string url = "http://localhost:9091/inputs";
    string query = string `query Greeting ($userName:String!){ greet (name: $userName) }`;
    string userName = "Roland";
    map<anydata> variables = {"userName": userName};

    Client graphqlClient = check new (url);
    GenericGreetingResponse actualPayload = check graphqlClient->executeWithType(query, variables);
    GenericGreetingResponse expectedPayload = {
        data: {
            greet: "Hello, Roland"
        }
    };
    assertJsonValuesWithOrder(actualPayload.toJson(), expectedPayload.toJson());
}

@test:Config {
    groups: ["client"]
}
isolated function testClientExecuteWithJson() returns error? {
    string url = "http://localhost:9091/inputs";
    string query = string `query Greeting ($userName:String!){ greet (name: $userName) }`;
    string userName = "Roland";
    map<anydata> variables = {"userName": userName};

    Client graphqlClient = check new (url);
    json actualPayload = check graphqlClient->execute(query, variables);
    json expectedPayload = {
        "data": {
            "greet": "Hello, Roland"
        }
    };
    assertJsonValuesWithOrder(actualPayload, expectedPayload);
}

@test:Config {
    groups: ["client"]
}
isolated function testClientExecuteWithOpenRecord() returns error? {
    string url = "http://localhost:9091/inputs";
    string query = string `query Greeting ($userName:String!){ greet (name: $userName) }`;
    string userName = "Roland";
    map<anydata> variables = {"userName": userName};

    Client graphqlClient = check new (url);
    record{} actualPayload = check graphqlClient->execute(query, variables);
    record{} expectedPayload = {
        "data": {
            "greet": "Hello, Roland"
        }
    };
    assertJsonValuesWithOrder(actualPayload.toJson(), expectedPayload.toJson());
}

@test:Config {
    groups: ["client"]
}
isolated function testClientExecuteWithKnownRecord() returns error? {
    string url = "http://localhost:9091/inputs";
    string query = string `query Greeting ($userName:String!){ greet (name: $userName) }`;
    string userName = "Roland";
    map<anydata> variables = {"userName": userName};

    Client graphqlClient = check new (url);
    GreetingResponseWithErrors actualPayload = check graphqlClient->execute(query, variables);
    GreetingResponseWithErrors expectedPayload = {
        data: {
            greet: "Hello, Roland"
        }
    };
    assertJsonValuesWithOrder(actualPayload.toJson(), expectedPayload.toJson());
}

@test:Config {
    groups: ["client"]
}
isolated function testClientExecuteWithGenericRecord() returns error? {
    string url = "http://localhost:9091/inputs";
    string query = string `query Greeting ($userName:String!){ greet (name: $userName) }`;
    string userName = "Roland";
    map<anydata> variables = {"userName": userName};

    Client graphqlClient = check new (url);
    GenericGreetingResponseWithErrors actualPayload = check graphqlClient->execute(query, variables);
    GenericGreetingResponseWithErrors expectedPayload = {
        data: {
            greet: "Hello, Roland"
        }
    };
    assertJsonValuesWithOrder(actualPayload.toJson(), expectedPayload.toJson());
}

@test:Config {
    groups: ["client"]
}
isolated function testClientExecuteWithTypeWithInvalidRequest() returns error? {
    string url = "http://localhost:9091/inputs";
    string query = string `query Greeting ($userName:String!){ gree (name: $userName) }`;
    string userName = "Roland";
    map<anydata> variables = {"userName": userName};

    Client graphqlClient = check new (url);
    json|ClientError actualPayload = graphqlClient->executeWithType(query, variables);
    if actualPayload is ClientError {
        if actualPayload is RequestError {
            test:assertEquals(actualPayload.message(), "GraphQL Client Error");
        }
    }
}

@test:Config {
    groups: ["client"]
}
isolated function testClientExecuteWithInvalidRequest() returns error? {
    string url = "http://localhost:9091/inputs";
    string query = string `query Greeting ($userName:String!){ gree (name: $userName) }`;
    string userName = "Roland";
    map<anydata> variables = {"userName": userName};

    Client graphqlClient = check new (url);
    json|ClientError actualPayload = graphqlClient->execute(query, variables);
    if actualPayload is ClientError {
        if actualPayload is RequestError {
            test:assertEquals(actualPayload.message(), "GraphQL Client Error");
        }
    }
}

@test:Config {
    groups: ["client"]
}
isolated function testClientExecuteWithTypeWithInvalidBindingType() returns error? {
    string url = "http://localhost:9091/inputs";
    string query = string `query Greeting ($userName:String!){ greet (name: $userName) }`;
    string userName = "Roland";
    map<anydata> variables = {"userName": userName};

    Client graphqlClient = check new (url);
    string|ClientError actualPayload = graphqlClient->executeWithType(query, variables);
    if actualPayload is ClientError {
        if actualPayload is RequestError {
            test:assertEquals(actualPayload.message(), "GraphQL Client Error");
        }
    }
}

@test:Config {
    groups: ["client"]
}
isolated function testClientExecuteWithTypeWithMutation() returns error? {
    string url = "http://localhost:9091/mutations";
    string query = string `mutation { setName(name: "Heisenberg") { name } }`;

    Client graphqlClient = check new (url);
    SetNameResponse actualPayload = check graphqlClient->executeWithType(query);
    SetNameResponse expectedPayload = {
        data: {
            setName: {
                name: "Heisenberg"
            }
        }
    };
    assertJsonValuesWithOrder(actualPayload.toJson(), expectedPayload.toJson());
}

@test:Config {
    groups: ["client"]
}
isolated function testClientExecuteWithMutation() returns error? {
    string url = "http://localhost:9091/mutations";
    string query = string `mutation { setName(name: "Heisenberg") { name } }`;

    Client graphqlClient = check new (url);
    SetNameResponseWithErrors actualPayload = check graphqlClient->execute(query);
    SetNameResponseWithErrors expectedPayload = {
        data: {
            setName: {
                name: "Heisenberg"
            }
        }
    };
    assertJsonValuesWithOrder(actualPayload.toJson(), expectedPayload.toJson());
}

type GreetingResponse record {|
    map<json?> extensions?;
    record {|
        string greet;
    |} data;
|};

type GenericGreetingResponse record {|
    map<json?> extensions?;
    map<json?> data?;
|};

type GreetingResponseWithErrors record {|
    map<json?> extensions?;
    record {|
        string greet;
    |} data;
    ErrorDetail[] errors?;
|};

type GenericGreetingResponseWithErrors record {|
    map<json?> extensions?;
    map<json?> data?;
    ErrorDetail[] errors?;
|};

type SetNameResponse record {|
    map<json?> extensions?;
    record {|
        record {|
            string name;
        |} setName;
    |} data;
|};

type SetNameResponseWithErrors record {|
    map<json?> extensions?;
    record {|
        record {|
            string name;
        |} setName;
    |} data;
    ErrorDetail[] errors?;
|};
