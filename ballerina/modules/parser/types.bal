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

public type Scalar int|float|decimal|string|boolean;

type CharIteratorNode record {
    string:Char value;
};

type CharIterator object {
    public isolated function next() returns CharIteratorNode?;
};

type Boolean TRUE|FALSE;

public type ArgumentValue ArgumentNode|Scalar?;

# Represents the types of operations valid in Ballerina GraphQL.
public enum RootOperationType {
    OPERATION_QUERY = "query",
    OPERATION_MUTATION = "mutation",
    OPERATION_SUBSCRIPTION = "subscription"
}

public enum DirectiveLocation {
    //executable directive locations
    QUERY,
    MUTATION,
    SUBSCRIPTION,
    FIELD,
    FRAGMENT_DEFINITION,
    FRAGMENT_SPREAD,
    INLINE_FRAGMENT,
    VARIABLE_DEFINITION,
    SCHEMA,
    SCALAR,
    OBJECT,
    FIELD_DEFINITION,
    ARGUMENT_DEFINITION,
    INTERFACE,
    UNION,
    ENUM,
    ENUM_VALUE,
    INPUT_OBJECT,
    INPUT_FIELD_DEFINITION
}
