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

isolated function getFieldNotFoundErrorMessageFromType(string requiredFieldName, __Type rootType) returns string {
    string typeName = getTypeNameFromType(rootType);
    return getFieldNotFoundErrorMessage(requiredFieldName, typeName);
}

isolated function getFieldNotFoundErrorMessage(string requiredFieldName, string rootType) returns string {
    return string`Cannot query field "${requiredFieldName}" on type "${rootType}".`;
}

isolated function getNoSubfieldsErrorMessage(string fieldName, __Type schemaType) returns string {
    string typeName = getTypeNameFromType(schemaType);
    return string`Field "${fieldName}" must not have a selection since type "${typeName}" has no subfields.`;
}

isolated function getUnknownArgumentErrorMessage(string argName, string parentName, string fieldName)
returns string {
    return string`Unknown argument "${argName}" on field "${parentName}.${fieldName}".`;
}

isolated function getMissingSubfieldsErrorFromType(string fieldName, __Type schemaType) returns string {
    string typeName = getTypeNameFromType(schemaType);
    return getMissingSubfieldsError(fieldName, typeName);
}

isolated function getMissingSubfieldsError(string fieldName, string typeName) returns string {
    return string`Field "${fieldName}" of type "${typeName}" must have a selection of subfields. Did you mean "${fieldName} { ... }"?`;
}

isolated function getInvalidFieldOnUnionTypeError(string fieldName, __Type unionType) returns string {
    __Type[] possibleTypes = <__Type[]>unionType?.possibleTypes;
    string onTypes = string`"${getOfType(possibleTypes[0]).name.toString()}"`;
    foreach int i in 1...possibleTypes.length() - 1 {
        onTypes += string` or "${getOfType(possibleTypes[i]).name.toString()}"`;
    }
    return string`Cannot query field "${fieldName}" on type "${unionType?.name.toString()}". Did you mean to use a fragment on ${onTypes}?`;
}

isolated function getFragmetCannotSpreadError(parser:FragmentNode fragmentNode, string fragmentName, __Type ofType)
returns string {
    string fragmentOnTypeName = fragmentNode.getOnType();
    return string`Fragment "${fragmentName}" cannot be spread here as objects of type "${ofType.name.toString()}" can never be of type "${fragmentOnTypeName}".`;
}

isolated function getMissingRequiredArgError(parser:FieldNode node, __InputValue input) returns string {
    string typeName = getTypeNameFromType(input.'type);
    return string`Field "${node.getName()}" argument "${input.name}" of type "${typeName}" is required, but it was not provided.`;
}

isolated function getOutputObject(map<anydata> data, ErrorDetail[] errors) returns OutputObject {
    OutputObject outputObject = {};
    if (data.length() > 0) {
        outputObject.data = <Data> checkpanic data.cloneWithType(Data);
    }
    if (errors.length() > 0) {
        outputObject.errors = errors;
    }
    return outputObject;
}

isolated function getTypeName(parser:ArgumentNode argumentNode) returns string {
    parser:ArgumentType kind = argumentNode.getKind();
    if (kind == parser:T_INT) {
        return "Int";
    } else if (kind == parser:T_FLOAT) {
        return "Float";
    } else if (kind == parser:T_BOOLEAN) {
        return "Boolean";
    } else {
        return "String";
    }
}

isolated function getOfType(__Type schemaType) returns __Type {
    __Type? ofType = schemaType?.ofType;
    if (ofType is ()) {
        return schemaType;
    } else {
        return getOfType(ofType);
    }
}

isolated function getTypeNameFromType(__Type schemaType) returns string {
    string typeName = getOfType(schemaType).name.toString();
    if (schemaType.kind == NON_NULL) {
        typeName = string`${typeName}!`;
        __Type ofType = <__Type>schemaType?.ofType;
        if (ofType.kind == LIST) {
            typeName = string`[${typeName}]`;
        }
    } else if (schemaType.kind == LIST) {
        typeName = string`[${typeName}]`;
    }
    return typeName;
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
