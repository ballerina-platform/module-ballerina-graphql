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

public isolated class DocumentNode {
    *Node;

    private map<OperationNode> operations;
    private map<FragmentNode> fragments;
    private ErrorDetail[] errors;
    private boolean isFirstAnonymousOperationErrorPushed;

    public isolated function init() {
        self.operations = {};
        self.fragments = {};
        self.errors = [];
        self.isFirstAnonymousOperationErrorPushed = false;
    }

    public isolated function accept(Visitor visitor, anydata data = ()) {
        visitor.visitDocument(self, data);
    }

    public isolated function addOperation(OperationNode operation) {
        lock {
            if self.operations.hasKey(ANONYMOUS_OPERATION) {
                if !self.isFirstAnonymousOperationErrorPushed {
                    OperationNode originalOperation = <OperationNode>self.operations[ANONYMOUS_OPERATION];
                    self.errors.push(getAnonymousOperationInMultipleOperationsError(originalOperation));
                    self.isFirstAnonymousOperationErrorPushed = true;
                }
                if operation.getName() == ANONYMOUS_OPERATION {
                    self.errors.push(getAnonymousOperationInMultipleOperationsError(operation));
                }
                return;
            } else if operation.getName() == ANONYMOUS_OPERATION && self.operations.length() > 0 {
                self.errors.push(getAnonymousOperationInMultipleOperationsError(operation));
                self.isFirstAnonymousOperationErrorPushed = true;
                return;
            } else if self.operations.hasKey(operation.getName()) {
                OperationNode originalOperation = <OperationNode>self.operations[operation.getName()];
                string message = string `There can be only one operation named "${operation.getName()}".`;
                Location l1 = originalOperation.getLocation();
                Location l2 = operation.getLocation();
                self.errors.push({message: message, locations: [l1, l2]});
                return;
            }
            self.operations[operation.getName()] = operation;
        }
    }

    public isolated function addFragment(FragmentNode fragment) {
        lock {
            if self.fragments.hasKey(fragment.getName()) {
                FragmentNode originalFragment = <FragmentNode>self.fragments[fragment.getName()];
                if fragment.isInlineFragment() {
                    self.appendDuplicateInlineFragment(fragment, originalFragment);
                } else {
                    string message = string `There can be only one fragment named "${fragment.getName()}".`;
                    Location l1 = originalFragment.getLocation();
                    Location l2 = fragment.getLocation();
                    self.errors.push({message: message, locations: [l1, l2]});
                    self.fragments[fragment.getName()] = fragment;
                }
            } else {
                self.fragments[fragment.getName()] = fragment;
            }
        }

    }

    private isolated function appendDuplicateInlineFragment(FragmentNode duplicate, FragmentNode original) {
        foreach SelectionNode selection in duplicate.getSelections() {
            original.addSelection(selection);
        }
    }

    public isolated function getOperations() returns OperationNode[] {
        OperationNode[] operationNodes = [];
        lock {
            OperationNode[] operations = self.operations.toArray();
            foreach int i in 0 ..< operations.length() {
                operationNodes[i] = operations[i];
            }
        }
        return operationNodes;
    }

    public isolated function getErrors() returns ErrorDetail[] {
        lock {
            return self.errors.cloneReadOnly();
        }
    }

    public isolated function getFragments() returns map<FragmentNode> {
        map<FragmentNode> fragmentNodeMap = {};
        lock {
            foreach [string, FragmentNode] [name, node] in self.fragments.entries() {
                fragmentNodeMap[name] = node;
            }
        }
        return fragmentNodeMap;
    }

    public isolated function getFragment(string name) returns FragmentNode? {
        lock {
            return self.fragments[name];
        }
    }
}
