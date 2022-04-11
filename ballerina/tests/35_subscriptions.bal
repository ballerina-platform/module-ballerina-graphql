import ballerina/test;
import ballerina/websocket;
import ballerina/lang.value;
@test:Config {
    groups: ["subscriptions"]
}
isolated function testSubscription() returns error? {
    string document = string`subscription getMessages { messages }`;
    string url = "ws://localhost:9091/subscriptions";
    websocket:Client wsClient = check new(url);
    check wsClient->writeTextMessage(document);
    string textResponse = check wsClient->readTextMessage();
    int i = 1;
    while (i < 4) {
        json actualPayload = check value:fromJsonString(textResponse);
        json expectedPayload = { data : { messages: i }};
        i += 1;
        assertJsonValuesWithOrder(actualPayload, expectedPayload);
        textResponse = check wsClient->readTextMessage();
    }
}
@test:Config {
    groups: ["subscriptions"]
}
isolated function testSubscriptionsWithMultipleClients() returns error? {
    string document1 = string`subscription { messages }`;
    string url = "ws://localhost:9091/subscriptions";
    websocket:Client wsClient1 = check new(url);
    websocket:Client wsClient2 = check new(url);
    check wsClient1->writeTextMessage(document1);
    check wsClient2->writeTextMessage(document1);
    string textResponse1 = check wsClient1->readTextMessage();
    string textResponse2 = check wsClient2->readTextMessage();
    int i = 1;
    while (i < 4) {
        json actualPayload1 = check value:fromJsonString(textResponse1);       
        json actualPayload2 = check value:fromJsonString(textResponse2);
        json expectedPayload = { data : { messages: i }};
        i += 1;
        assertJsonValuesWithOrder(actualPayload1, expectedPayload);
        assertJsonValuesWithOrder(actualPayload2, expectedPayload);
        textResponse1 = check wsClient1->readTextMessage();
        textResponse2 = check wsClient2->readTextMessage();
    }
}
@test:Config {
    groups: ["subscriptions"]
}
isolated function testDifferentSubscriptionsWithMultipleClients() returns error? {
    string document1 = string`subscription getMessages { messages }`;
    string document2 = string`subscription getStringMessages { stringMessages }`;
    string url = "ws://localhost:9091/subscriptions";
    websocket:Client wsClient1 = check new(url);
    websocket:Client wsClient2 = check new(url);
    check wsClient1->writeTextMessage(document1);
    check wsClient2->writeTextMessage(document2);
    string textResponse1 = check wsClient1->readTextMessage();
    string textResponse2 = check wsClient2->readTextMessage();
    int i = 1;
    while (i < 4) {
        json actualPayload1 = check value:fromJsonString(textResponse1);
        json expectedPayload1 = { data : { messages: i }};
        
        assertJsonValuesWithOrder(actualPayload1, expectedPayload1);
        textResponse1 = check wsClient1->readTextMessage();

        json actualPayload2 = check value:fromJsonString(textResponse2);
        json expectedPayload2 = { data : { stringMessages: i.toString() }};

        i += 1;
        assertJsonValuesWithOrder(actualPayload2, expectedPayload2);
        textResponse2 = check wsClient2->readTextMessage();
    }


}
@test:Config {
    groups: ["subscriptions"]
}
isolated function testSubscriptionsWithServiceObjects() returns error? {
    string document = string`
    subscription getPeople { 
        people {
            name 
            age  
        } 
    }
    `;
    string url = "ws://localhost:9091/subscriptions";
    websocket:Client wsClient = check new(url);
    check wsClient->writeTextMessage(document);
    string textResponse = check wsClient->readTextMessage();
    json actualPayload = check value:fromJsonString(textResponse);
    json expectedPayload = { data : { people: { name: "Jim Halpert", age: 30 }}};
    assertJsonValuesWithOrder(actualPayload, expectedPayload);

    textResponse = check wsClient->readTextMessage();
    actualPayload = check value:fromJsonString(textResponse);
    expectedPayload = { data : { people: { name: "Dwight Schrute", age: 32 }}};
    assertJsonValuesWithOrder(actualPayload, expectedPayload);

}
@test:Config {
    groups: ["subscriptions"]
}
isolated function testQueryOnServiceWithSubscriptions() returns error? {
    string document = string`query { name }`;
    string url = "http://localhost:9091/subscriptions";
    json actualPayload = check getJsonPayloadFromService(url, document);
    json expectedPayload = { data : { name: "Walter White"}};
    assertJsonValuesWithOrder(actualPayload, expectedPayload);
}

@test:Config {
    groups: ["subscriptions"]
}
isolated function testInvalidSubscriptionRequest() returns error? {
    string document = string`subscription { name }`;
    string url = "ws://localhost:9091/subscriptions";
    websocket:Client wsClient = check new(url);
    check wsClient->writeTextMessage(document);
    string textResponse = check wsClient->readTextMessage();
    json actualPayload = check value:fromJsonString(textResponse);
    json expectedPayload = {
        errors: [
            {
                message: string`Cannot query field "name" on type "Subscription".`,
                locations: [
                    {
                        line: 1,
                        column: 16
                    }
                ]
            }
        ]
    };
    assertJsonValuesWithOrder(actualPayload, expectedPayload);
}
@test:Config {
    groups: ["fragments", "subscriptions"]
}
isolated function testSubscriptionsWithFragments() returns error? {
    string document = string`
    subscription getPeople { 
        ...peopleFields
    }
    fragment peopleFields on Subscription {
        ...personFields 
    }
    fragment personFields on Subscription {
        people {
            name
            age       
        } 
    }
    `;
    string url = "ws://localhost:9091/subscriptions";
    websocket:Client wsClient = check new(url);
    check wsClient->writeTextMessage(document);
    string textResponse = check wsClient->readTextMessage();
    json actualPayload = check value:fromJsonString(textResponse);
    json expectedPayload = { data : { people: { name: "Jim Halpert", age: 30 }}};
    assertJsonValuesWithOrder(actualPayload, expectedPayload);

    textResponse = check wsClient->readTextMessage();
    actualPayload = check value:fromJsonString(textResponse);
    expectedPayload = { data : { people: { name: "Dwight Schrute", age: 32 }}};
    assertJsonValuesWithOrder(actualPayload, expectedPayload);
}
