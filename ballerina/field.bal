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

# Represents the information about a particular field of a GraphQL document.
public class Field {
    private final parser:FieldNode internalNode;
    private final service object {} serviceObject;
    private (string|int)[] path;

    isolated function init(parser:FieldNode internalNode, service object {} serviceObject, (string|int)[] path = []) {
        self.internalNode = internalNode;
        self.serviceObject = serviceObject;
        self.path = path;
    }

    # Returns the name of the field.
    # + return - The name of the field
    public isolated function getName() returns string {
        return self.internalNode.getName();
    }

    # Returns the effective alias of the field.
    # + return - The alias of the field. If an alias is not present, the field name will be returned.
    public isolated function getAlias() returns string {
        return self.internalNode.getAlias();
    }

    isolated function getInternalNode() returns parser:FieldNode {
        return self.internalNode;
    }

    isolated function getServiceObject() returns service object {} {
        return self.serviceObject;
    }

    isolated function getPath() returns (string|int)[] {
        return self.path;
    }
}
