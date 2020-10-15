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

# Represents an error occurred when validating a GraphQL document
public type InvalidDocumentError distinct error;

# Represents an error occurred when a required field not found in graphql service resources
public type FieldNotFoundError distinct error;

# Represents an error occurred while a listener operation
public type ListenerError distinct error;

# Represents not-implemented feature error
public type NotImplementedError distinct error;

# Represents any error related to the Ballerina GraphQL module
type Error InvalidDocumentError|ListenerError|FieldNotFoundError|NotImplementedError;

# Represents a GraphQL ID field
type Id int|string;

# Represents the supported Scalar types in Ballerina GraphQL module
type Scalar int|string|float|boolean|Id;

# The annotation which is used to configure a GraphQL service.
public annotation GraphQlServiceConfiguration ServiceConfiguration on service;

# Represents the types of operations valid for Ballerina GraphQL.
public enum OperationType {
    Query = "query",
    Mutation = "mutation",
    Subscription = "subscription"
}
