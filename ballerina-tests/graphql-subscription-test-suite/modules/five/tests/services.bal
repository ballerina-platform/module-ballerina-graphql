// Copyright (c) 2024 WSO2 LLC. (http://www.wso2.com).
//
// WSO2 LLC. licenses this file to you under the Apache License,
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

import ballerina/graphql;
import ballerina/http;

graphql:Service subscriptionService = service object {
    isolated resource function get name() returns string {
        return "Walter White";
    }

    isolated resource function subscribe messages() returns stream<int, error?> {
        int[] intArray = [1, 2, 3, 4, 5];
        return intArray.toStream();
    }
};

isolated service /service_with_http1 on subscriptionListener {
    isolated resource function get greet() returns string {
        return "welcome!";
    }

    isolated resource function subscribe messages() returns stream<int, error?> {
        int[] intArray = [1, 2, 3, 4, 5];
        return intArray.toStream();
    }
}

@graphql:ServiceConfig {
    contextInit:
    isolated function(http:RequestContext requestContext, http:Request request) returns graphql:Context|error {
        graphql:Context context = new;
        context.set("scope", check request.getHeader("scope"));
        return context;
    }
}
service /context on subscriptionListener {
    isolated resource function get greet() returns string {
        return "welcome!";
    }

    isolated resource function subscribe messages(graphql:Context context) returns stream<int, error?>|error {
        var scope = context.get("scope");
        if scope is string && scope == "admin" {
            int[] intArray = [1, 2, 3, 4, 5];
            return intArray.toStream();
        }
        return error("You don't have permission to retrieve data");
    }
}

service /constraints on subscriptionListener {
    isolated resource function get greet() returns string {
        return "welcome!";
    }

    isolated resource function subscribe movie(MovieDetails movie) returns stream<Reviews?, error?> {
        return movie.reviews.toStream();
    }
}
