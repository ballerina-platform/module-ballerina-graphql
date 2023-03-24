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
import ballerina/lang.runtime;
import ballerina/websocket;

@test:Config {}
function testHero() returns error? {
    string document = check getGraphqlDocumentFromFile("hero");
    json actualPayload = check getJsonPayloadFromService(document);
    json expectedPayload = {
        data: {
            hero: {
                name: "Luke Skywalker",
                mass: 77,
                homePlanet: "Tatooine"
            }
        }
    };
    test:assertEquals(actualPayload, expectedPayload);
}

@test:Config {}
function testHeroWithAlias() returns error? {
    string document = check getGraphqlDocumentFromFile("heroWithAlias");
    json actualPayload = check getJsonPayloadFromService(document);
    json expectedPayload = {
        data: {
            luke: {
                name: "Luke Skywalker",
                mass: 77
            },
            hero1: {
                name: "R2-D2"
            }
        }
    };
    test:assertEquals(actualPayload, expectedPayload);
}

@test:Config {}
function testHeroWithDirectives() returns error? {
    string document = check getGraphqlDocumentFromFile("heroWithDirectives");
    json actualPayload = check getJsonPayloadFromService(document);
    json expectedPayload = {
        data: {
            hero: {
                mass: 77,
                friends: [
                    {},
                    {},
                    {
                        name: "C-3PO"
                    },
                    {
                        name: "R2-D2"
                    }
                ]
            }
        }
    };
    test:assertEquals(actualPayload, expectedPayload);
}

@test:Config {}
function testCharacters() returns error? {
    string document = check getGraphqlDocumentFromFile("characters");
    json actualPayload = check getJsonPayloadFromService(document);
    json expectedPayload = {
        data: {
            characters: [
                {
                    name: "Luke Skywalker",
                    homePlanet: "Tatooine"
                },
                {
                    name: "C-3PO",
                    primaryFunction: "Protocol"
                }
            ]
        }
    };
    test:assertEquals(actualPayload, expectedPayload);
}

@test:Config {}
function testReviews() returns error? {
    string document = check getGraphqlDocumentFromFile("reviews");
    json actualPayload = check getJsonPayloadFromService(document);
    json expectedPayload = {
        data: {
            reviews: [
                {
                    stars: 5,
                    commentary: "This is a great movie!"
                }
            ]
        }
    };
    test:assertEquals(actualPayload, expectedPayload);
}

@test:Config {}
function testDroid() returns error? {
    string document = check getGraphqlDocumentFromFile("droid");
    json actualPayload = check getJsonPayloadFromService(document);
    json expectedPayload = {
        data: {
            droid: {
                name: "C-3PO",
                appearsIn: ["NEWHOPE", "EMPIRE", "JEDI"]
            }
        }
    };
    test:assertEquals(actualPayload, expectedPayload);
}

@test:Config {}
function testHuman() returns error? {
    string document = check getGraphqlDocumentFromFile("human");
    json variables = {
        id: "1000"
    };
    json actualPayload = check getJsonPayloadFromService(document, variables);
    json expectedPayload = {
        data: {
            human: {
                name: "Luke Skywalker",
                friends: [
                    {},
                    {},
                    {
                        name: "C-3PO"
                    },
                    {
                        name: "R2-D2"
                    }
                ]
            }
        }
    };
    test:assertEquals(actualPayload, expectedPayload);
}

@test:Config {}
function testSearch() returns error? {
    string document = check getGraphqlDocumentFromFile("search");
    json variables = {
        text: "humanInstarship"
    };
    json actualPayload = check getJsonPayloadFromService(document, variables);
    json expectedPayload = {
        data: {
            search: [
                {
                    __typename: "Human"
                },
                {
                    __typename: "Human"
                },
                {
                    __typename: "Human"
                },
                {
                    __typename: "Human"
                },
                {
                    __typename: "Human"
                },
                {
                    __typename: "Starship"
                },
                {
                    __typename: "Starship"
                },
                {
                    __typename: "Starship"
                },
                {
                    __typename: "Starship"
                }
            ]
        }
    };
    test:assertEquals(actualPayload, expectedPayload);
}

@test:Config {}
function testCreateReview() returns error? {
    string document = check getGraphqlDocumentFromFile("createReview");
    json variables = {
        epi: "EMPIRE",
        review: {
            stars: 5,
            commentary: "Nice!"
        }
    };
    json actualPayload = check getJsonPayloadFromService(document, variables);
    json expectedPayload = {
        data: {
            createReview:
                {
                stars: 5,
                commentary: "Nice!"
            }
        }
    };
    test:assertEquals(actualPayload, expectedPayload);
}

@test:Config {}
function testFriends() returns error? {
    string document = check getGraphqlDocumentFromFile("friends");
    json actualPayload = check getJsonPayloadFromService(document);
    json expectedPayload = {
        data: {
            characters: [
                {
                    friends: [
                        {
                            name: "Han Solo"
                        },
                        {
                            name: "Leia Organa"
                        },
                        {},
                        {}
                    ]
                },
                {
                    friends: [
                        {
                            name: "Luke Skywalker"
                        },
                        {
                            name: "Han Solo"
                        },
                        {
                            name: "Leia Organa"
                        },
                        {
                            name: "R2-D2",
                            primaryFunction: "Astromech"
                        }
                    ]
                }
            ]
        }
    };
    test:assertEquals(actualPayload, expectedPayload);
}

@test:Config {
    enable: false // Disabled the test becasue the service is not closing when this test is done.
}
function testReviewAdded() returns error? {
    string document = check getGraphqlDocumentFromFile("reviewAdded");
    future<error?> subscribeResult = start subscribeReviewAdded(document);
    runtime:sleep(1);
    future<error?> addReviewResult = start addReview(document);

    check wait addReviewResult;
    check wait subscribeResult;
}

function addReview(string document) returns error? {
    json variables = {
        episode: "EMPIRE",
        review: {
            stars: 5,
            commentary: "Nice!"
        }
    };
    json actualPayload = check getJsonPayloadFromService(document, variables, operationName = "CreateReview");
    json expectedPayload = {
        data: {
            review:
                {
                stars: 5,
                commentary: "Nice!"
            }
        }
    };
    test:assertEquals(actualPayload, expectedPayload);
}

function subscribeReviewAdded(string document) returns error? {
    json variables = {
        episode: "EMPIRE",
        // TODO: This field is not required. We can remove the `review` field from the `variables` map after fixing #4206
        review: {
            stars: 5,
            commentary: "Nice!"
        }
    };
    websocket:ClientConfiguration config = {subProtocols: ["graphql-transport-ws"]};
    websocket:Client wsClient = check new ("ws://localhost:9090/graphql", config);
    check initiateGraphqlWsConnection(wsClient);
    check sendSubscriptionMessage(wsClient, document, variables = variables, operationName = "ReviewAdded");

    json expectedMsgPayload = {data: {review: {stars: 5, commentary: "Nice!"}}};
    check validateNextMessage(wsClient, expectedMsgPayload);
    check closeConnection(wsClient);
}
