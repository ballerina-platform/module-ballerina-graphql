// Copyright (c) 2022, WSO2 Inc. (http://www.wso2.org) All Rights Reserved.
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

class SubscriptionVisitor {
    *parser:Visitor;

    private ErrorDetail[] errors;
    private parser:DocumentNode documentNode;

    public isolated function init(parser:DocumentNode documentNode) {
        self.errors = [];
        self.documentNode = documentNode;
    }

    public isolated function validate() returns ErrorDetail[]? {
        self.visitDocument(self.documentNode);
        if self.errors.length() > 0 {
            return self.errors;
        }
        return;
    }

    public isolated function visitDocument(parser:DocumentNode documentNode, anydata data = ()) {
        parser:OperationNode[] operations = documentNode.getOperations();
        foreach parser:OperationNode operationNode in operations {
            self.visitOperation(operationNode);
        }
    }

    public isolated function visitOperation(parser:OperationNode operationNode, anydata data = ()) {
        if operationNode.getKind() == parser:OPERATION_SUBSCRIPTION {
            parser:Selection[] selections = operationNode.getSelections();
            if selections.length() > 1 {
                self.addErrorDetail(selections[1], operationNode.getName()); 
            }            
            foreach parser:Selection selection in selections {
                self.visitSelection(selection, operationNode.getName());
            }
        }
    }

    public isolated function visitSelection(parser:Selection selection, anydata data = ()) {
        if selection is parser:FragmentNode {
            self.visitFragment(selection, data);
        } else if selection is parser:FieldNode {
            self.visitField(selection, data);
        }
    }

    public isolated function visitField(parser:FieldNode fieldNode, anydata data = ()) {
        if fieldNode.getName() == SCHEMA_FIELD || fieldNode.getName() == TYPE_FIELD || 
           fieldNode.getName() == TYPE_NAME_FIELD {
            self.addIntrospectionErrorDetail(fieldNode, <string>data);              
        }
    }

    public isolated function visitFragment(parser:FragmentNode fragmentNode, anydata data = ()) {
        if fragmentNode.getSelections().length() > 1 {
            self.addErrorDetail(fragmentNode.getSelections()[1], <string>data);
        } else {
            self.visitSelection(fragmentNode.getSelections()[0], data);
        }
    }

    public isolated function visitArgument(parser:ArgumentNode argumentNode, anydata data = ()) {
        // Do nothing
    }

    public isolated function addErrorDetail(parser:Selection selection, string operationName) {
        string message = operationName != "<anonymous>"  
                         ? string`Subscription "${operationName}" must select only one top level field.`
                         : string`Anonymous Subscription must select only one top level field.`;   
        if selection is parser:FragmentNode {
            ErrorDetail errorDetail = getErrorDetailRecord(message, selection.getLocation());
            self.errors.push(errorDetail);
        } else if selection is parser:FieldNode {
            ErrorDetail errorDetail = getErrorDetailRecord(message, selection.getLocation());
            self.errors.push(errorDetail);
        }
    }

    public isolated function addIntrospectionErrorDetail(parser:FieldNode fieldNode, string operationName) {
        string message = operationName != "<anonymous>"  
                         ? string`Subscription "${operationName}" must not select an introspection top level field.`
                         : string`Anonymous Subscription must not select an introspection top level field.`;   
        ErrorDetail errorDetail = getErrorDetailRecord(message, fieldNode.getLocation());
        self.errors.push(errorDetail);
    }
}
