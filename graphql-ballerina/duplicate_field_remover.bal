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

class DuplicateFieldRemover {
    *parser:Visitor;

    private parser:DocumentNode documentNode;

    public isolated function init(parser:DocumentNode documentNode) {
        self.documentNode = documentNode;
    }

    public isolated function remove() {
        self.visitDocument(self.documentNode);
    }

    public isolated function visitDocument(parser:DocumentNode documentNode) {
        parser:OperationNode[] operations = documentNode.getOperations();
        foreach parser:OperationNode operationNode in operations {
            self.visitOperation(operationNode);
        }
    }

    public isolated function visitOperation(parser:OperationNode operationNode) {
        self.removeDuplicateSelections(operationNode.getSelections());
        self.removeDuplicateFields(operationNode.getFields());
        self.removeDuplicateFragments(operationNode.getFragments());
        foreach parser:Selection selection in operationNode.getSelections() {
            self.visitSelection(selection);
        }
    }

    public isolated function visitSelection(parser:Selection selection, anydata data = ()) {
        if (selection.isFragment) {
            parser:FragmentNode fragmentNode = self.documentNode.getFragments().get(selection.name);
            self.visitFragment(fragmentNode);
        } else {
            parser:FieldNode fieldNode = <parser:FieldNode>selection?.node;
            self.visitField(fieldNode);
        }
    }

    public isolated function visitField(parser:FieldNode fieldNode, anydata data = ()) {
        self.removeDuplicateSelections(fieldNode.getSelections());
        self.removeDuplicateFields(fieldNode.getFields());
        self.removeDuplicateFragments(fieldNode.getFragments());
        foreach parser:Selection selection in fieldNode.getSelections() {
            self.visitSelection(selection);
        }
    }

    public isolated function visitFragment(parser:FragmentNode fragmentNode, anydata data = ()) {
        self.removeDuplicateSelections(fragmentNode.getSelections());
        self.removeDuplicateFields(fragmentNode.getFields());
        self.removeDuplicateFragments(fragmentNode.getFragments());
        foreach parser:Selection selection in fragmentNode.getSelections() {
            self.visitSelection(selection);
        }
    }

    public isolated function visitArgument(parser:ArgumentNode argumentNode, anydata data = ()) {
        // Do nothing
    }

    private isolated function removeDuplicateSelections(parser:Selection[] selections) {
        map<parser:Selection> visitedSelections = {};
        map<parser:Selection> visitedFragmentOnTypes = {};
        parser:Selection[] duplicateSelections = [];
        foreach parser:Selection selection in selections {
            if(selection.isFragment) {
                parser:FragmentNode fragmentNode = self.documentNode.getFragments().get(selection.name);
                if (visitedFragmentOnTypes.hasKey(fragmentNode.getOnType())) {
                    if (fragmentNode.isInlineFragment()) {
                        duplicateSelections.push(selection);
                    } else {
                        self.appendDuplicateSelections(selection, visitedFragmentOnTypes.get(fragmentNode.getOnType()));
                        duplicateSelections.push(selection);
                    }
                } else {
                    visitedFragmentOnTypes[fragmentNode.getOnType()] = selection;
                }
            } else {
                if (visitedSelections.hasKey(selection.name)) {
                    self.appendDuplicateSelections(selection, visitedSelections.get(selection.name));
                    duplicateSelections.push(selection);
                } else {
                    visitedSelections[selection.name] = selection;
                }
            }
        }
        int i = 0;
        while (i < selections.length()) {
            foreach parser:Selection duplicate in duplicateSelections {
                if (selections[i] === duplicate) {
                    parser:Selection remove = selections.remove(i);
                    i -= 1;
                }
            }
            i += 1;
        }
    }

    private isolated function removeDuplicateFields(parser:FieldNode[] fields) {
        string[] visitedFields = [];
        parser:FieldNode[] duplicateFields = [];
        foreach parser:FieldNode fieldNode in fields {
            if (visitedFields.indexOf(fieldNode.getName()) == ()) {
                visitedFields.push(fieldNode.getName());
            } else {
                duplicateFields.push(fieldNode);
            }
        }
        int i = 0;
        while (i < fields.length()) {
            foreach parser:FieldNode duplicate in  duplicateFields {
                if (fields[i] === duplicate) {
                    parser:FieldNode remove = fields.remove(i);
                    i -= 1;
                }
            }
            i += 1;
        }
    }

    private isolated function removeDuplicateFragments(string[] fragments) {
        string[] visitedFragmentOnTypes = [];
        string[] duplicateFragments = [];
        foreach string fragment in fragments {
            parser:FragmentNode fragmentNode = self.documentNode.getFragments().get(fragment);
            if (visitedFragmentOnTypes.indexOf(fragmentNode.getOnType()) == ()) {
                visitedFragmentOnTypes.push(fragmentNode.getOnType());
            } else {
                if (!fragmentNode.isInlineFragment()) {
                    parser:FragmentNode removed = self.documentNode.getFragments().remove(fragment);
                }
                duplicateFragments.push(fragment);
            }
        }
        foreach string duplicate in duplicateFragments {
            string removed = fragments.remove(<int>fragments.indexOf(duplicate));
        }
    }

    private isolated function appendDuplicateSelections(parser:Selection duplicate, parser:Selection original) {
        if (duplicate.isFragment) {
            parser:FragmentNode duplicateFragmentNode = self.documentNode.getFragments().get(duplicate.name);
            parser:FragmentNode originalFragmentNode = self.documentNode.getFragments().get(original.name);
            self.appendDuplicateFragments(duplicateFragmentNode, originalFragmentNode);
        } else {
            self.appendDuplicateFields(<parser:FieldNode>duplicate?.node, <parser:FieldNode>original?.node);
        }
    }

    private isolated function appendDuplicateFields(parser:FieldNode duplicate, parser:FieldNode original) {
        foreach parser:FieldNode fields in duplicate.getFields() {
            original.addField(fields);
        }
        foreach string fragments in duplicate.getFragments() {
            original.addFragment(fragments);
        }
        foreach parser:Selection selections in duplicate.getSelections() {
            original.addSelection(selections);
        }
        foreach parser:ArgumentNode arguments in duplicate.getArguments() {
            original.addArgument(arguments);
        }
    }

    private isolated function appendDuplicateFragments(parser:FragmentNode duplicate, parser:FragmentNode original) {
        foreach parser:FieldNode fields in duplicate.getFields() {
            original.addField(fields);
        }
        foreach string fragments in duplicate.getFragments() {
            original.addFragment(fragments);
        }
        foreach parser:Selection selections in duplicate.getSelections() {
            original.addSelection(selections);
        }
    }
}
