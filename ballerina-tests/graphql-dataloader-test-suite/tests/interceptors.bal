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

readonly service class AuthorInterceptor {
    *graphql:Interceptor;

    isolated remote function execute(graphql:Context context, graphql:Field 'field) returns anydata {
        var data = context.resolve('field);
        // Return only the first author
        return ('field.getName() == "authors" && data is anydata[]) ? [data[0]] : data;
    }
}

readonly service class BookInterceptor {
    *graphql:Interceptor;

    isolated remote function execute(graphql:Context context, graphql:Field 'field) returns anydata {
        var books = context.resolve('field);
        // Return only the first book
        return (books is anydata[]) ? [books[0]] : books;
    }
}
