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

import ballerina/stringutils;
import graphql.parser;

isolated function getFieldNotFoundErrorMessage(string requiredFieldName, string rootType) returns string {
    return "Cannot query field \"" + requiredFieldName + "\" on type \"" + rootType + "\".";
}

isolated function getNoSubFieldsErrorMessage(__Type 'type) returns string {
    string typeName = 'type.kind.toString();
    return "Field \"" + 'type.name + "\" must not have a selection since type \"" + typeName + "\" has no subfields.";
}

isolated function getUnknownArgumentErrorMessage(string argName, __Field parent, parser:ArgumentNode argument)
returns string {
    return "Unknown argument \"" + argName + "\" on field \"" + parent.name + "." + argument.getName().value + "\".";
}

isolated function getTypeName(parser:ArgumentValue value) returns string {
    typedesc kind = typeof value.value;
    return stringutils:split(kind.toString(), " ")[1];
}

isolated function getErrorDetailRecord(string message, Location|Location[] location) returns ErrorDetail {
    if (location is Location[]) {
        return {
            message: message,
            locations: location
        };
    }
    return {
        message: message,
        locations: [<Location>location]
    };
}
