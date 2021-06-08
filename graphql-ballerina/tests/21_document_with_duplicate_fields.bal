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

service /graphql on new Listener(9114) {
    resource function get people() returns Person[] {
        return people;
    }

    resource function get students() returns Student[] {
        return students;
    }

    isolated resource function get profile() returns Profile {
        return new;
    }

    resource function get teacher() returns Person {
        return p2;
    }

    resource function get student() returns Person {
        return p4;
    }
}

@test:Config {
    groups: ["duplicate", "service", "unit"]
}
isolated function testDuplicateFieldWithResourceReturningRecord() returns error? {
    string document = string
`query getPerson {
    profile {
        name,
        address {
            city
            street
        }
        address {
            number
            street
        }
        address {
            number
            city
        }
    }
}`;
    string url = "http://localhost:9094/graphql";
    json actualPayload = check getJsonPayloadFromService(url, document);

    json expectedPayload = {
        data: {
            profile: {
                name: "Sherlock Holmes",
                address: {
                    city: "London",
                    street: "Baker Street",
                    number: "221/B"
                }
            }
        }
    };
    test:assertEquals(actualPayload, expectedPayload);
}

@test:Config {
    groups: ["duplicate", "fragments", "unit"]
}
isolated function testDuplicateFieldWithResourcesReturningServices() returns error? {
    string document = string
`query {
    ...greetingFragment
}

fragment greetingFragment on Query {
    profile {
        name {
            ...firstNameFragment
        }
        name {
            ...lastNameFragment
        }
    }
}

fragment firstNameFragment on Name {
    first
}

fragment lastNameFragment on Name {
    last
}`;
    string url = "http://localhost:9114/graphql";
    json actualPayload = check getJsonPayloadFromService(url, document);

    json expectedPayload = {
        data: {
            profile: {
                name: {
                    first: "Sherlock",
                    last: "Holmes"
                }
            }
        }
    };
    test:assertEquals(actualPayload, expectedPayload);
}

@test:Config {
    groups: ["duplicate", "fragments", "unit"]
}
isolated function testNamedFragmentsWithDuplicateFields() returns error? {
    string document = string
`query {
    ...data
}

fragment data on Query {
    people {
        ...people
    }

    students {
        ...student
    }
}

fragment people on Person {
    address {
        city
    }
    address {
        street
    }
    address {
        city
        number
    }
    address {
        city
    }
}

fragment student on Student {
    name
}`;
    string url = "http://localhost:9114/graphql";
    json actualPayload = check getJsonPayloadFromService(url, document);

    json expectedPayload = {
        data: {
            people: [
                {
                    address: {
                        city: "London",
                        street:"Baker Street",
                        number:"221/B"
                    }
                },
                {
                    address: {
                        city: "Albuquerque",
                        street:"Negra Arroyo Lane",
                        number:"308"
                    }
                },
                {
                    address: {
                        city: "Hogwarts",
                        street: "Unknown",
                        number:"Uknown"
                    }
                }
            ],
            students: [
                {
                    name: "John Doe"
                },
                {
                    name: "Jane Doe"
                },
                {
                    name: "Jonny Doe"
                }
            ]
        }
    };
    test:assertEquals(actualPayload, expectedPayload);
}

@test:Config {
    groups: ["duplicate", "fragments", "unit", "inline"]
}
isolated function testDuplicateInlineFragment() returns error? {
    string document = string
`query {
   ...on Query {
       people {
           ... on Person {
               address {
                   street
               }
               address {
                  number
                  street
               }
               address {
                 number
                 street
                 city
              }
           }
       }
   }
   ... on Query {
       students {
           name
       }
   }
}`;
    string url = "http://localhost:9114/graphql";
    json actualPayload = check getJsonPayloadFromService(url, document);
    json expectedPayload = {
        data: {
             people: [
                 {
                     address: {
                         street: "Baker Street",
                         number: "221/B",
                         city: "London"
                     }
                 },
                 {
                     address: {
                         street: "Negra Arroyo Lane",
                         number: "308",
                         city: "Albuquerque"
                     }
                 },
                 {
                     address: {
                         street: "Unknown",
                         number: "Uknown",
                         city: "Hogwarts"
                     }
                 }
             ],
             students: [
                 {
                     name: "John Doe"
                 },
                 {
                     name: "Jane Doe"
                 },
                 {
                     name: "Jonny Doe"
                 }
             ]
        }
    };
    test:assertEquals(actualPayload, expectedPayload);
}
