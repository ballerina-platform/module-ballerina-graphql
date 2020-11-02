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

# Represents a GraphQL ID field
public type Id int|string;

# Represents the supported Scalar types in Ballerina GraphQL module
public type Scalar boolean|int|float|string|Id;

# The annotation which is used to configure a GraphQL service.
public annotation GraphQlServiceConfiguration ServiceConfiguration on service;

# Represents the types of operations valid for Ballerina GraphQL.
public enum OperationType {
    QUERY = "query",
    MUTATION = "mutation",
    SUBSCRIPTION = "subscription"
}

type UnsupportedOperation MUTATION|SUBSCRIPTION;
