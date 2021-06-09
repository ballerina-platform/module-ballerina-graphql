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
        self.visitSelection(operationNode.getSelections());
        self.visitField(operationNode.getFields());
        self.visitFragment(operationNode.getFragments());
    }

    public isolated function visitSelection(parser:Selection[] selections) {
        self.removeDuplicateSelections(selections);
        foreach parser:Selection selection in selections {
            if (selection.isFragment) {
                parser:FragmentNode subFragmentNode = self.documentNode.getFragments().get(selection.name);
                self.visitSelection(subFragmentNode.getSelections());
            } else {
                parser:FieldNode subFieldNode = <parser:FieldNode>selection?.node;
                self.visitSelection(subFieldNode.getSelections());
            }
        }
    }

    public isolated function visitField(parser:FieldNode[] fields) {
        self.removeDuplicateFields(fields);
        foreach parser:FieldNode fieldNode in fields {
            self.visitField(fieldNode.getFields());
            self.visitFragment(fieldNode.getFragments());
        }
    }

    public isolated function visitFragment(string[] fragments) {
        self.removeDuplicateFragments(fragments);
        foreach string fragment in fragments {
            parser:FragmentNode fragmentNode = self.documentNode.getFragments().get(fragment);
            self.visitFragment(fragmentNode.getFragments());
            self.visitField(fragmentNode.getFields());
        }
    }

    private isolated function removeDuplicateSelections(parser:Selection[] selections) {
        map<parser:Selection> visitedSelections = {};
        map<parser:Selection> visitedFragmentOnTypes = {};
        int[] duplicateIndexes = [];
        int i = 0;
        while (i < selections.length()) {
            parser:Selection subSelection = selections[i];
            if(subSelection.isFragment) {
                parser:FragmentNode subFragmentNode = self.documentNode.getFragments().get(subSelection.name);
                if (visitedFragmentOnTypes.hasKey(subFragmentNode.getOnType())) {
                    if (subFragmentNode.isInlineFragment()) {
                        duplicateIndexes.push(i);
                    } else {
                        self.appendDuplicateSelections(selections[i], visitedFragmentOnTypes.get(subFragmentNode.getOnType()));
                    }
                } else {
                    visitedFragmentOnTypes[subFragmentNode.getOnType()] = selections[i];
                }
            } else {
                if (visitedSelections.hasKey(subSelection.name)) {
                    self.appendDuplicateSelections(selections[i], visitedSelections.get(subSelection.name));
                    duplicateIndexes.push(i);
                } else {
                    visitedSelections[subSelection.name] = selections[i];
                }
            }
            i += 1;
        }
        foreach int index in duplicateIndexes.reverse() {
            var remove = selections.remove(index);
        }
    }

    private isolated function removeDuplicateFields(parser:FieldNode[] fields) {
        string[] visitedFields = [];
        int[] duplicateIndexes = [];
        int i = 0;
        while (i < fields.length()) {
            parser:FieldNode subField = fields[i];
            if (visitedFields.indexOf(subField.getName()) == ()) {
                visitedFields.push(subField.getName());
            } else {
                duplicateIndexes.push(i);
            }
            i += 1;
        }
        foreach int index in duplicateIndexes.reverse() {
            var remove = fields.remove(index);
        }
    }

    private isolated function removeDuplicateFragments(string[] fragments) {
        string[] visitedFragmentOnTypes = [];
        int[] duplicateIndexes = [];
        int i = 0;
        while (i < fragments.length()) {
            parser:FragmentNode fragmentNode = self.documentNode.getFragments().get(fragments[i]);
            if (visitedFragmentOnTypes.indexOf(fragmentNode.getOnType()) == ()) {
                visitedFragmentOnTypes.push(fragmentNode.getOnType());
            } else {
                if (!fragmentNode.isInlineFragment()) {
                   var remove = self.documentNode.getFragments().remove(fragments[i]);
                }
                duplicateIndexes.push(i);
            }
            i += 1;
        }
        foreach int index in duplicateIndexes.reverse() {
            var remove = fragments.remove(index);
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
        foreach var fields in duplicate.getFields() {
            original.addField(fields);
        }
        foreach var fragments in duplicate.getFragments() {
            original.addFragment(fragments);
        }
        foreach var selections in duplicate.getSelections() {
            original.addSelection(selections);
        }
        foreach var arguments in duplicate.getArguments() {
            original.addArgument(arguments);
        }
    }

    private isolated function appendDuplicateFragments(parser:FragmentNode duplicate, parser:FragmentNode original) {
        foreach var fields in duplicate.getFields() {
            original.addField(fields);
        }
        foreach var fragments in duplicate.getFragments() {
            original.addFragment(fragments);
        }
        foreach var selections in duplicate.getSelections() {
            original.addSelection(selections);
        }
    }
}
