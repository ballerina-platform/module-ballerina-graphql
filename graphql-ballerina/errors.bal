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

import graphql.parser;

// General errors
# Represents an error occurred while a listener operation
public type ListenerError distinct error;

# Represents a non-implemented feature error
public type NotImplementedError distinct error;

# Represents an unsupported functionality error
public type NotSupportedError distinct error;

// Validation errors
# Represents an error where multiple operations with the same name exists
public type DuplicateOperationError distinct error;

# Represents an error occurred when a required field not found in graphql service resources
public type FieldNotFoundError distinct error;

# Represents an error occurred when a required field not found in graphql service resources
public type InvalidDocumentError distinct error;

# Represents an error occurred when the provided argument type mismatched with the expected type
public type InvalidArgumentTypeError distinct error;

# Represents an error occurred when the provided selection is invalid
public type InvalidSelectionError distinct error;

# Represents an error occurred when a required argument is missing
public type MissingRequiredArgumentError distinct error;

# Represents the errors occurred while validating a GraphQL document
public type ValidationError DuplicateOperationError|FieldNotFoundError|InvalidDocumentError|NotImplementedError|
                            InvalidArgumentTypeError|InvalidSelectionError|MissingRequiredArgumentError;

// Execution errors

# Represents an error occurred while parsing a document
public type ParsingError distinct error<parser:Location>;

# Represents an error where the provided operation is not found in a document
public type OperationNotFoundError distinct error;

# Represents the errors occurred while executing a GraphQL document
public type ExecutionError OperationNotFoundError;

# Represents any error related to the Ballerina GraphQL module
public type Error ParsingError|ValidationError|ExecutionError|ListenerError;

// Client Errors
# Represents an error occurred in client while connecting with the GraphQL server.
public type ConnectionError distinct error;

# Represents all the errors related to the GraphQL client.
public type ClientError ConnectionError;
