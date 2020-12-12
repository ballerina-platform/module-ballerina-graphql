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

Person p1 = {
    name: "Sherlock Holmes",
    age: 40,
    address: {
        number: "221/B",
        street: "Baker Street",
        city: "London"
    }
};

Person p2 = {
    name: "Walter White",
    age: 50,
    address: {
        number: "308",
        street: "Negra Arroyo Lane",
        city: "Albuquerque"
    }
};

Person p3 = {
    name: "Tom Marvolo Riddle",
    age: 100,
    address: {
        number: "Uknown",
        street: "Unknown",
        city: "Hogwarts"
    }
};

service /graphql on new Listener(port = 9095) {
    resource function get profile(int id) returns Person {
        Person[] people = [p1, p2, p3];
        return people[id];
    }
}

@test:Config {
    groups: ["client", "unit"]
}
public function testClient() returns @tainted error? {
    Client graphqlClient = new("http://localhost:9095/graphql");
    string document = "{ profile(id: 1) { name age address { city } } }";

    json expectedPayload = {
        data: {
            profile: {
                name: "Walter White",
                age: 50,
                address: {
                    city: "Albuquerque"
                }
            }
        }
    };
    json result = check graphqlClient->query(document);
    test:assertEquals(result, expectedPayload);
}
