// Copyright (c) 2021 WSO2 Inc. (http://www.wso2.org) All Rights Reserved.
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

// NOTE: All the tokens/credentials used in this test are dummy tokens/credentials and used only for testing purposes.

import ballerina/http;
import ballerina/regex;
import ballerina/test;

const string KEYSTORE_PATH = "tests/resources/keystore/ballerinaKeystore.p12";
const string TRUSTSTORE_PATH = "tests/resources/keystore/ballerinaTruststore.p12";

//{
//  "alg": "RS256",
//  "typ": "JWT",
//  "kid": "NTAxZmMxNDMyZDg3MTU1ZGM0MzEzODJhZWI4NDNlZDU1OGFkNjFiMQ"
//}
//{
//  "sub": "admin",
//  "iss": "wso2",
//  "exp": 1925955724,
//  "jti": "100078234ba23",
//  "aud": [
//    "ballerina"
//  ],
//  "scp": "write"
//}
const string JWT1 = "eyJhbGciOiJSUzI1NiIsICJ0eXAiOiJKV1QiLCAia2lkIjoiTlRBeFptTXhORE15WkRnM01UVTFaR00wTXpFek9ESmhaV0k" +
                    "0TkRObFpEVTFPR0ZrTmpGaU1RIn0.eyJzdWIiOiJhZG1pbiIsICJpc3MiOiJ3c28yIiwgImV4cCI6MTkyNTk1NTcyNCwgIm" +
                    "p0aSI6IjEwMDA3ODIzNGJhMjMiLCAiYXVkIjpbImJhbGxlcmluYSJdLCAic2NwIjoid3JpdGUifQ.H99ufLvCLFA5i1gfCt" +
                    "klVdPrBvEl96aobNvtpEaCsO4v6_EgEZYz8Pg0B1Y7yJPbgpuAzXEg_CzowtfCTu3jUFf5FH_6M1fWGko5vpljtCb5Xknt_" +
                    "YPqvbk5fJbifKeXqbkCGfM9c0GS0uQO5ss8StquQcofxNgvImRV5eEGcDdybkKBNkbA-sJFHd1jEhb8rMdT0M0SZFLnhrPL" +
                    "8edbFZ-oa-ffLLls0vlEjUA7JiOSpnMbxRmT-ac6QjPxTQgNcndvIZVP2BHueQ1upyNorFKSMv8HZpATYHZjgnJQSpmt3Oa" +
                    "oFJ6pgzbFuniVNuqYghikCQIizqzQNfC7JUD8wA";

//{
//  "alg": "RS256",
//  "typ": "JWT",
//  "kid": "NTAxZmMxNDMyZDg3MTU1ZGM0MzEzODJhZWI4NDNlZDU1OGFkNjFiMQ"
//}
//{
//  "sub": "admin",
//  "iss": "wso2",
//  "exp": 1925955876,
//  "jti": "100078234ba23",
//  "aud": [
//    "ballerina"
//  ],
//  "scp": "read"
//}
const string JWT2 = "eyJhbGciOiJSUzI1NiIsICJ0eXAiOiJKV1QiLCAia2lkIjoiTlRBeFptTXhORE15WkRnM01UVTFaR00wTXpFek9ESmhaV0k" +
                    "0TkRObFpEVTFPR0ZrTmpGaU1RIn0.eyJzdWIiOiJhZG1pbiIsICJpc3MiOiJ3c28yIiwgImV4cCI6MTkyNTk1NTg3NiwgIm" +
                    "p0aSI6IjEwMDA3ODIzNGJhMjMiLCAiYXVkIjpbImJhbGxlcmluYSJdLCAic2NwIjoicmVhZCJ9.MVx_bJJpRyQryrTZ1-WC" +
                    "1BkJdeBulX2CnxYN5Y4r1XbVd0-rgbCQ86jEbWvLZOybQ8Hx7MB9thKaBvidBnctgMM1JzG-ULahl-afoyTCv_qxMCS-5B7" +
                    "AUA1f-sOQHzq-n7T3b0FKsWtmOEXbGmRxQFv89_v8xwUzIItXtZ6IjkoiZn5GerGrozX0DEBDAeG-2BOj8gSlsFENdPB5Sn" +
                    "5oEM6-Chrn6KFLXo3GFTwLQELgYkIGjgnMQfbyLLaw5oyJUyOCCsdMZ4oeVLO2rdKZs1L8ZDnolUfcdm5mTxxP9A4mTOTd-" +
                    "xC404MKwxkRhkgI4EJkcEwMHce2iCInZer10Q";

//{
//  "alg": "HS256",
//  "typ": "JWT"
//}
//{
//  "sub": "1234567890",
//  "name": "John Doe",
//  "iat": 1516239022
//}
const string JWT3 = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiIxMjM0NTY3ODkwIiwibmFtZSI6IkpvaG4gRG9lIiwiaWF0Ij" +
                    "oxNTE2MjM5MDIyfQ.SflKxwRJSMeKKF2QT4fwpMeJf36POk6yJV_adQssw5c";

const string ACCESS_TOKEN_1 = "2YotnFZFEjr1zCsicMWpAA";
const string ACCESS_TOKEN_2 = "1zCsicMWpAA2YotnFZFEjr";
const string ACCESS_TOKEN_3 = "invalid-token";

isolated function sendNoTokenRequest(int port, string path) returns http:Response|http:ClientError {
    http:Client clientEP = checkpanic new("https://localhost:" + port.toString(), {
        secureSocket: {
            cert: {
                path: TRUSTSTORE_PATH,
                password: "ballerina"
            }
        }
    });
    json payload = { "query": "{ greeting }" };
    return clientEP->post(path, payload);
}

isolated function sendBasicTokenRequest(int port, string path, string username, string password) returns http:Response|http:ClientError {
    http:Client clientEP = checkpanic new("https://localhost:" + port.toString(), {
        auth: {
            username: username,
            password: password
        },
        secureSocket: {
            cert: {
                path: TRUSTSTORE_PATH,
                password: "ballerina"
            }
        }
    });
    json payload = { "query": "{ greeting }" };
    return clientEP->post(path, payload);
}

isolated function sendBearerTokenRequest(int port, string path, string token) returns http:Response|http:ClientError {
    http:Client clientEP = checkpanic new("https://localhost:" + port.toString(), {
        auth: {
            token: token
        },
        secureSocket: {
            cert: {
                path: TRUSTSTORE_PATH,
                password: "ballerina"
            }
        }
    });
    json payload = { "query": "{ greeting }" };
    return clientEP->post(path, payload);
}

isolated function sendJwtRequest(int port, string path) returns http:Response|http:ClientError {
    http:Client clientEP = checkpanic new("https://localhost:" + port.toString(), {
        auth: {
            username: "admin",
            issuer: "wso2",
            audience: ["ballerina"],
            jwtId: "100078234ba23",
            keyId: "NTAxZmMxNDMyZDg3MTU1ZGM0MzEzODJhZWI4NDNlZDU1OGFkNjFiMQ",
            customClaims: { "scp": "write" },
            signatureConfig: {
                config: {
                    keyStore: {
                        path: KEYSTORE_PATH,
                        password: "ballerina"
                    },
                    keyAlias: "ballerina",
                    keyPassword: "ballerina"
                }
            }
        },
        secureSocket: {
            cert: {
                path: TRUSTSTORE_PATH,
                password: "ballerina"
            }
        }
    });
    json payload = { "query": "{ greeting }" };
    return clientEP->post(path, payload);
}

isolated function sendOAuth2TokenRequest(int port, string path) returns http:Response|http:ClientError {
    http:Client clientEP = checkpanic new("https://localhost:" + port.toString(), {
        auth: {
            tokenUrl: "https://localhost:9445/oauth2/token",
            clientId: "3MVG9YDQS5WtC11paU2WcQjBB3L5w4gz52uriT8ksZ3nUVjKvrfQMrU4uvZohTftxStwNEW4cfStBEGRxRL68",
            clientSecret: "9205371918321623741",
            clientConfig: {
                secureSocket: {
                   cert: {
                       path: TRUSTSTORE_PATH,
                       password: "ballerina"
                   }
                }
            }
        },
        secureSocket: {
            cert: {
                path: TRUSTSTORE_PATH,
                password: "ballerina"
            }
        }
    });
    json payload = { "query": "{ greeting }" };
    return clientEP->post(path, payload);
}

isolated function assertSuccess(http:Response|http:ClientError response) {
    if (response is http:Response) {
        test:assertEquals(response.statusCode, 200);
    } else {
        test:assertFail(msg = "Test Failed!");
    }
}

isolated function assertForbidden(http:Response|http:ClientError response) {
    if (response is http:Response) {
        test:assertEquals(response.statusCode, 400);
        json expectedPayload = {
            errors: [
                {
                    message: "Access is denied to the requested resource. The user might not have enough permission."
                }
            ]
        };
        json|http:ClientError payload = response.getJsonPayload();
        if (payload is json) {
            assertJsonValuesWithOrder(payload, expectedPayload);
        } else {
            test:assertFail(msg = "Test Failed!");
        }
    } else {
        test:assertFail(msg = "Test Failed!");
    }
}

isolated function assertUnauthorized(http:Response|http:ClientError response) {
    if (response is http:Response) {
        test:assertEquals(response.statusCode, 400);
        json expectedPayload = {
            errors: [
                {
                    message: "Required authentication information is either missing or not valid for the resource."
                }
            ]
        };
        json|http:ClientError payload = response.getJsonPayload();
        if (payload is json) {
            assertJsonValuesWithOrder(payload, expectedPayload);
        } else {
            test:assertFail(msg = "Test Failed!");
        }
    } else {
        test:assertFail(msg = "Test Failed!");
    }
}

service /oauth2 on sts {
    isolated resource function post token() returns json {
        json response = {
            "access_token": ACCESS_TOKEN_1,
            "token_type": "example",
            "expires_in": 3600,
            "example_parameter": "example_value"
        };
        return response;
    }

    isolated resource function post introspect(http:Request request) returns json {
        string|http:ClientError payload = request.getTextPayload();
        if (payload is string) {
            string[] parts = regex:split(payload, "&");
            foreach string part in parts {
                if (part.indexOf("token=") is int) {
                    string token = regex:split(part, "=")[1];
                    if (token == ACCESS_TOKEN_1) {
                        json response = { "active": true, "exp": 3600, "scp": "write update" };
                        return response;
                    } else if (token == ACCESS_TOKEN_2) {
                        json response = { "active": true, "exp": 3600, "scp": "read" };
                        return response;
                    } else {
                        json response = { "active": false };
                        return response;
                    }
                }
            }
        }
    }
}
