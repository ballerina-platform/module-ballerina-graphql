import ballerina/test;

@test:Config {
    groups: ["query"]
}
function testUser() returns error? {
    string query = "query { user { login } }";
    json expectedResult = {
        "data": {
            "user": {
                "login": owner
            }
        }
    };
    json actualResult = check testClient->execute(query);
    test:assertEquals(expectedResult, actualResult, "Invalid user name");
}

@test:Config {
    groups: ["query"]
}
function testRepositories() returns error? {
    string query = "query { repositories { name }}";
    json jsonResponse = check testClient->execute(query);
    test:assertTrue(jsonResponse is map<json>, "Invalid response type");
    map<json> actualResult = check jsonResponse.ensureType();
    test:assertTrue(actualResult.hasKey("data"));
    test:assertFalse(actualResult.hasKey("errors"));
}

@test:Config {
    groups: ["query"]
}
function testRepository() returns error? {
    string repoName = "Module-Ballerina-GraphQL";
    string query = string `query { repository(repositoryName: "${repoName}"){ defaultBranch } }`;
    json expectedResult = {
        "data": {
            "repository": {
                "defaultBranch": "master"
            }
        }
    };
    json actualResult = check testClient->execute(query);
    test:assertEquals(actualResult, expectedResult);
}

@test:Config {
    groups: ["query"]
}
function testBranches() returns error? {
    string repoName = "Module-Ballerina-GraphQL";
    string username = "gqlUser";
    string query = string `query { branches(repositoryName: "${repoName}", perPageCount: 10, username: "${username}"){ name } }`;
    json expectedResult = {
        "data": {
            "branches": [
                {
                    "name": "master"
                }
            ]
        }
    };
    json actualResult = check testClient->execute(query);
    test:assertEquals(expectedResult, actualResult);
}

@test:Config {
    groups: ["mutation"]
}
function createRepository() returns error? {
    string repoName = "Test-Repo";
    string query = string `mutation {createRepository(createRepoInput: {name: "${repoName}"}) {name} }`;
    json expectedResult = {
        "errors":[
            {
                "message":"Unprocessable Entity",
                "locations":[
                    {
                        "line":1,
                        "column":11
                    }
                ],
            "path":["createRepository"]
            }
        ],
        "data": null
    };
    json actualResult = check testClient->execute(query);
    test:assertEquals(expectedResult, actualResult);
}
