import ballerina/graphql_test_common as common;
import ballerina/test;
import ballerina/websocket;

@test:Config {
    groups: ["subscriptions", "service"]
}
isolated function testConnectionClousureWhenPongNotRecived() returns error? {
    string url = "ws://localhost:9091/subscription_interceptor1";
    websocket:ClientConfiguration config = {subProtocols: [common:GRAPHQL_TRANSPORT_WS]};
    websocket:Client wsClient = check new (url, config);
    check common:initiateGraphqlWsConnection(wsClient);
    json|error response;
    while true {
        response = wsClient->readMessage();
        if response is json {
            test:assertTrue(response.'type == common:WS_PING);
            continue;
        }
        break;
    }
    test:assertTrue(response is error, "Expected connection clousure error");
    test:assertEquals((<error>response).message(), "Request timeout: Status code: 4408");
}