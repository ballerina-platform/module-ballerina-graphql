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

import ballerina/io;

type ArgName record {
    string value;
    Location location;
};

type ArgValue record {
    Scalar value;
    Location location;
};

type Argument record {
    ArgName name;
    ArgValue value;
    ArgumentType kind;
};

type Field record {
    string name;
    Argument[] arguments;
    Field[] selections;
    Location location;
};

type Operation record {
    string name;
    OperationType kind;
    Field[] selections;
    Location location;
};

type Document record {
    Operation[] operations;
};

public class PrintVisitor {
    *Visitor;

    public isolated function visitDocument(DocumentNode documentNode) {
        io:println("Document");
    }

    public isolated function visitOperation(OperationNode operationNode) {
        io:println("Operation Name: " + operationNode.name);
    }

    public isolated function visitField(FieldNode fieldNode, ParentType? parent = ()) {
        io:println("\tField Name: " + fieldNode.name);
    }

    public isolated function visitArgument(ArgumentNode argumentNode) {
        io:println("\t\tArgument Name: " + argumentNode.name.value + " | Argument Value: " + argumentNode.value.value
        .toString());
    }
}
