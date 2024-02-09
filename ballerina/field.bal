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
    private final parser:RootOperationType operationType;
    private final parser:FieldNode internalNode;
    private final service object {}? serviceObject;
    private final any|error fieldValue;
    private final __Type fieldType;
    private (string|int)[] path;
    private string[] resourcePath;
    private readonly & Interceptor[] fieldInterceptors;
    private final ServerCacheConfig? cacheConfig;
    private final readonly & string[] parentArgHashes;
    private final boolean cacheEnabled;
    private final decimal cacheMaxAge;
    private boolean hasRequestedNullableFields;

    isolated function init(parser:FieldNode internalNode, __Type fieldType, service object {}? serviceObject = (),
                           (string|int)[] path = [], parser:RootOperationType operationType = parser:OPERATION_QUERY,
                           string[] resourcePath = [], any|error fieldValue = (), ServerCacheConfig? cacheConfig = (),
                           readonly & string[] parentArgHashes = []) {
        self.internalNode = internalNode;
        self.serviceObject = serviceObject;
        self.fieldType = fieldType;
        self.path = path;
        self.operationType = operationType;
        self.resourcePath = resourcePath;
        self.fieldValue = fieldValue;
        self.resourcePath.push(internalNode.getName());
        self.fieldInterceptors = serviceObject is service object {} ?
            getFieldInterceptors(serviceObject, operationType, internalNode.getName(), self.resourcePath) : [];
        ServerCacheConfig? fieldCache = serviceObject is service object {} ?
            getFieldCacheConfig(serviceObject, operationType, internalNode.getName(), self.resourcePath) : ();
        ServerCacheConfig? updatedCacheConfig = fieldCache is ServerCacheConfig ? fieldCache : cacheConfig;
        self.cacheConfig = updatedCacheConfig;
        self.parentArgHashes = parentArgHashes;
        if updatedCacheConfig is ServerCacheConfig {
            self.cacheEnabled = updatedCacheConfig.enabled;
            self.cacheMaxAge = updatedCacheConfig.maxAge;
        } else {
            self.cacheEnabled = false;
            self.cacheMaxAge = 0d;
        }
        self.hasRequestedNullableFields = self.cacheEnabled && serviceObject is service object {}
            && hasFields(getOfType(self.fieldType)) && hasRecordReturnType(serviceObject, self.resourcePath);
    }

    # Returns the name of the field.
    # + return - The name of the field
    public isolated function getName() returns string {
        return self.internalNode.getName();
    }

    # Returns the effective alias of the field.
    # + return - The alias of the field. If an alias is not present, the field name will be returned
    public isolated function getAlias() returns string {
        return self.internalNode.getAlias();
    }

    # Returns the current path of the field. If the field returns an array, the path will include the index of the
    # element.
    # + return - The path of the field
    public isolated function getPath() returns (string|int)[] {
        return self.path;
    }

    # Returns the subfields of this field as a `Field` object array.
    # + return - The subfield objects of this field
    public isolated function getSubfields() returns Field[]? {
        Field[] fields = self.getFieldObjects(self.internalNode, self.fieldType);
        if fields.length() > 0 {
            return fields;
        }
        return;
    }

    # Returns the names of the subfields of this field as a string array.
    # + return - The names of the subfields of this field
    public isolated function getSubfieldNames() returns string[] {
        return self.getFieldNames(self.internalNode);
    }

    # Returns the type of the field.
    # + return - The type of the field
    public isolated function getType() returns __Type {
        return self.fieldType;
    }

    # Returns the location of the field in the GraphQL document.
    # + return - The location of the field
    public isolated function getLocation() returns Location {
        return self.internalNode.getLocation();
    }

    isolated function getInternalNode() returns parser:FieldNode {
        return self.internalNode;
    }

    isolated function getServiceObject() returns service object {}? {
        return self.serviceObject;
    }

    isolated function getOperationType() returns parser:RootOperationType {
        return self.operationType;
    }

    isolated function getResourcePath() returns string[] {
        return self.resourcePath;
    }

    isolated function getFieldType() returns __Type {
        return self.fieldType;
    }

    isolated function getFieldValue() returns any|error {
        return self.fieldValue;
    }

    isolated function getFieldObjects(parser:SelectionNode selectionNode, __Type 'type) returns Field[] {
        string[] currentPath = self.path.clone().'map((item) => item is int ? "@" : item);
        string[] unwrappedPath = getUnwrappedPath('type);
        __Type unwrappedType = getOfType('type);

        __Field[]? typeFields = unwrappedType.fields;
        if typeFields is () {
            return [];
        }

        Field[] result = [];
        foreach parser:SelectionNode selection in selectionNode.getSelections() {
            if selection is parser:FieldNode {
                foreach __Field 'field in typeFields {
                    if 'field.name == selection.getName() {
                        result.push(new Field(selection, 'field.'type, (),[...currentPath, ...unwrappedPath, 'field.name],
                            self.operationType.clone(), self.resourcePath.clone(), cacheConfig = self.cacheConfig,
                            parentArgHashes = self.parentArgHashes));
                        break;
                    }
                }
            } else {
                foreach parser:SelectionNode fragmentSelectionNode in selectionNode.getSelections() {
                    Field[] fields = self.getFieldObjects(fragmentSelectionNode, 'type);
                    result.push(...fields);
                }
            }
        }
        return result;
    }

    isolated function getFieldNames(parser:SelectionNode selectionNode) returns string[] {
        string[] result = [];
        foreach parser:SelectionNode selection in selectionNode.getSelections() {
            if selection is parser:FieldNode {
                result.push(selection.getName());
            } else {
                foreach parser:SelectionNode fragmentSelectionNode in selectionNode.getSelections() {
                    result.push(...self.getFieldNames(fragmentSelectionNode));
                }
            }
        }
        return result;
    }

    isolated function getFieldInterceptors() returns readonly & Interceptor[] {
        return self.fieldInterceptors;
    }

    isolated function isCacheEnabled() returns boolean {
        return self.cacheEnabled;
    }

    isolated function getCacheConfig() returns ServerCacheConfig? {
        return self.cacheConfig;
    }

    isolated function getCacheKey() returns string {
        return self.generateCacheKey();
    }

    isolated function getCacheMaxAge() returns decimal {
        return self.cacheMaxAge;
    }

    isolated function getParentArgHashes() returns readonly & string[] {
        return self.parentArgHashes;
    }

    private isolated function generateCacheKey() returns string {
        string[] requestedNullableFields = [];
        if self.hasRequestedNullableFields {
            requestedNullableFields = self.getRequestedNullableFields();
        }
        string resourcePath = "";
        foreach string|int path in self.path {
            resourcePath += string `${path}.`;
        }
        string hash = generateArgHash(self.internalNode.getArguments(), self.parentArgHashes, requestedNullableFields);
        return string `${resourcePath}${hash}`;
    }

    private isolated function getRequestedNullableFields() returns string[] {
        string[] nullableFields = getNullableFieldsFromType(self.fieldType);
        string[] requestedNullableFields = [];
        foreach string 'field in nullableFields {
            if self.getSubfieldNames().indexOf('field) is int {
                requestedNullableFields.push('field);
            }
        }
        return requestedNullableFields.sort();
    }
}
