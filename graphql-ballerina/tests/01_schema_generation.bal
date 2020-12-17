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

@test:Config {
    groups: ["schema_generation", "engine", "unit"]
}
function testSchemaGenerationForMultipleResources() {
    __Schema actualSchema = createSchema(serviceWithMultipleResources);
    test:assertEquals(actualSchema, expectedSchemaForMultipleResources);
}

@test:Config {
    groups: ["schema_generation", "engine", "unit"]
}
function testSchemaGenerationForResourcesReturningRecords() {
    __Schema actualSchema = createSchema(serviceWithResourcesReturningRecords);
    test:assertEquals(actualSchema, expectedSchemaForResourcesReturningRecords);
}

Service serviceWithMultipleResources = service object {
    isolated resource function get name() returns string {
        return "John Doe";
    }

    isolated resource function get id() returns int {
        return 1;
    }

    isolated resource function get birthdate(string format) returns string {
        return "01-01-1980";
    }
};

service object {} serviceWithResourcesReturningRecords = service object {
    isolated resource function get person() returns Person {
        return {
            name: "Sherlock Holmes",
            age: 20,
            address: {
                number: "221/B",
                street: "Baker Street",
                city: "London"
            }
        };
    }
};
