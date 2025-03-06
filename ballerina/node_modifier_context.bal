// Copyright (c) 2022 WSO2 LLC. (http://www.wso2.com) All Rights Reserved.
//
// WSO2 LLC. licenses this file to you under the Apache License,
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

isolated class NodeModifierContext {
    private map<()> fragmentWithCycles = {};
    private map<()> unknownFragments = {};
    private map<parser:FragmentNode> modifiedFragments = {};
    private map<parser:ArgumentNode> modifiedArgumentNodes = {};
    private map<()> nonConfiguredOperations = {};

    isolated function addFragmentWithCycles(parser:FragmentNode fragmentNode) {
        string hashCode = parser:getHashCode(fragmentNode);
        lock {
            self.fragmentWithCycles[hashCode] = ();
        }
    }

    isolated function isFragmentWithCycles(parser:FragmentNode fragmentNode) returns boolean {
        string hashCode = parser:getHashCode(fragmentNode);
        lock {
            return self.fragmentWithCycles.hasKey(hashCode);
        }
    }

    isolated function addUnknownFragment(parser:FragmentNode fragmentNode) {
        string hashCode = parser:getHashCode(fragmentNode);
        lock {
            self.unknownFragments[hashCode] = ();
        }
    }

    isolated function isUnknownFragment(parser:FragmentNode fragmentNode) returns boolean {
        string hashCode = parser:getHashCode(fragmentNode);
        lock {
            return self.unknownFragments.hasKey(hashCode);
        }
    }

    isolated function addNonConfiguredOperation(parser:OperationNode operationNode) {
        string hashCode = parser:getHashCode(operationNode);
        lock {
            self.nonConfiguredOperations[hashCode] = ();
        }
    }

    isolated function isNonConfiguredOperation(parser:OperationNode operationNode) returns boolean {
        string hashCode = parser:getHashCode(operationNode);
        lock {
            return self.nonConfiguredOperations.hasKey(hashCode);
        }
    }

    isolated function addModifiedArgumentNode(parser:ArgumentNode originalNode, parser:ArgumentNode modifiedNode) {
        string hashCode = parser:getHashCode(originalNode);
        lock {
            self.modifiedArgumentNodes[hashCode] = modifiedNode;
        }
    }

    isolated function getModifiedArgumentNode(parser:ArgumentNode originalNode) returns parser:ArgumentNode {
        string hashCode = parser:getHashCode(originalNode);
        lock {
            return self.modifiedArgumentNodes.hasKey(hashCode) ? self.modifiedArgumentNodes.get(hashCode) : originalNode;
        }
    }

    isolated function addModifiedFragmentNode(parser:FragmentNode originalNode, parser:FragmentNode modifiedNode) {
        string hashCode = parser:getHashCode(originalNode);
        lock {
            self.modifiedFragments[hashCode] = modifiedNode;
        }
    }

    isolated function getModifiedFragmentNode(parser:FragmentNode originalNode) returns parser:FragmentNode {
        string hashCode = parser:getHashCode(originalNode);
        lock {
            return self.modifiedFragments.hasKey(hashCode) ? self.modifiedFragments.get(hashCode) : originalNode;
        }
    }
}
