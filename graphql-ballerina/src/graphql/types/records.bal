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

# Defines the configurations related to Ballerina GraphQL listener
#
# + host - The host name/IP of the GraphQL endpoint
public type ListenerConfiguration record {|
    string host = "0.0.0.0";
|};

public type Data record {
    // Intentionally kept empty
};

# Stores a location for an error in a GraphQL operation.
#
# + line - The line of the document where error occured
# + column - The column of the document where error occurred
public type Location record {
    int line;
    int column;
};

# Represents an error occurred while executing a GraphQL operation.
#
# + locations - Locations of the GraphQL document where the error occurred
# + path - The complete path for the error in the GraphQL document
public type ErrorRecord record {|
    Location[] locations?;
    (int|string)[] path?;
|};

public type OutputObject record {
    Data data?;
    ErrorRecord[] errors?;
};

# Contains the configurations for a GraphQL service.
#
# + basePath - Service base path
public type GraphQlServiceConfiguration record {
    string basePath;
};

public type Operation record {|
    string name;
    OperationType 'type;
    Token[] fields;
|};

public type Document record {|
    map<Operation> operations;
|};

public type Token record {|
    TokenType 'type = CHAR;
    string value;
    Location location;
|};
