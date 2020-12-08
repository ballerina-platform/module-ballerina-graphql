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

# Defines the configurations related to Ballerina GraphQL listener
#
# + host - The host name/IP of the GraphQL endpoint
public type ListenerConfiguration record {|
    string host = "0.0.0.0";
|};

public type Data record {
    // Intentionally kept empty
};

public type ErrorDetail record {|
    string message;
    parser:Location[] locations;
    (int|string)[] path?;
|};

public type OutputObject record {
    Data data?;
    parser:ErrorRecord[] errors?;
};

public type __Schema record {|
    __Type[] types;
    __Type queryType;

    // TODO: Add the following
    //__Type mutationType?;
    //__Type subscriptionType?;
    //__Directive[] directives;
|};

public type __Type record {
    __TypeKind kind;
    string name;
    __Field[] fields?;

    // TODO: Add following: description, inputFields, interfaces, possibleTypes, enumValues, ofType
};

public type __Field record {|
    string name;
    __Type 'type;
    __InputValue[] args?;
    // TODO: Add following
    //string description?;
    //boolean isDeprecated = true;
    //string deprecationReason = "";
|};

public type __InputValue record {|
	string name;
	__Type 'type;
	string defaultValue?;

	// TODO:
	//string description?;
|};

public enum __TypeKind {
    SCALAR,
    OBJECT,
    ENUM
    // TODO: Support the following
    //INTERFACE,
    //UNION,
    //INPUT_OBJECT,
    //LIST,
    //NON_NULL
}

type __Directive record {|
    string name;
    string description?;
    // TODO: Add other fields
|};
