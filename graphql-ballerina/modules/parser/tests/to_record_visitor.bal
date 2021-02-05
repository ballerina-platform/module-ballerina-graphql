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

public type ArgName record {
    string value;
    Location location;
};

public type ArgValue record {
    Scalar value;
    Location location;
};

public type Argument record {
    ArgName name;
    ArgValue value;
    ArgumentType kind;
};

public type Field record {
    string name;
    Argument[] arguments;
    Field[] selections;
    Location location;
};

public type Operation record {
    string name;
    RootOperationType kind;
    Field[] selections;
    Location location;
};

public type Document record {
    Operation[] operations;
};

class RecordCreatorVisitor {
    *Visitor;

    public isolated function visitDocument(DocumentNode documentNode) returns Document {
        Operation[] operations = [];
        OperationNode[] operationNodes = documentNode.getOperations();
        foreach OperationNode operationNode in operationNodes {
            operations.push(self.visitOperation(operationNode));
        }

        return {
            operations: operations
        };
    }

    public isolated function visitOperation(OperationNode operationNode) returns Operation {
        Field[] selections = [];
        FieldNode[] fieldNodes = operationNode.getSelections();
        foreach FieldNode selection in fieldNodes {
            selections.push(self.visitField(selection));
        }

        return {
            name: operationNode.getName(),
            kind: operationNode.getKind(),
            selections: selections,
            location: operationNode.getLocation()
        };
    }

    public isolated function visitField(FieldNode fieldNode, anydata data = ()) returns Field {
        Argument[] arguments = [];
        ArgumentNode[] argumensNodes = fieldNode.getArguments();
        foreach ArgumentNode argumentNode in argumensNodes {
            arguments.push(<Argument>self.visitArgument(argumentNode));
        }

        Field[] fields = [];
        FieldNode[] fieldNodes = fieldNode.getSelections();
        foreach FieldNode selection in fieldNodes {
            fields.push(self.visitField(selection));
        }

        return {
            name: fieldNode.getName(),
            arguments: arguments,
            selections: fields,
            location: fieldNode.getLocation()
        };
    }

    public isolated function visitArgument(ArgumentNode argumentNode, anydata data = ()) returns Argument {
        ArgName name = {
            value: argumentNode.getName().value,
            location: argumentNode.getName().location
        };
        ArgValue value = {
            value: argumentNode.getValue().value,
            location: argumentNode.getValue().location
        };

        return {
            name: name,
            value: value,
            kind: argumentNode.getKind()
        };
    }
}
