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

isolated function getNoSubfieldsErrorMessage(__Field 'field) returns string {
    string typeName = getTypeNameFromType('field.'type);
    return string`Field "${'field.name}" must not have a selection since type "${typeName}" has no subfields.`;
}

isolated function getUnknownArgumentErrorMessage(string argName, string parentName, string fieldName)
returns string {
    return string`Unknown argument "${argName}" on field "${parentName}.${fieldName}".`;
}

isolated function getMissingSubfieldsErrorFromType(__Field 'field) returns string {
    string typeName = getTypeNameFromType('field.'type);
    return getMissingSubfieldsError('field.name, typeName);
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
    return string`Cannot query field "${fieldName}" on type "${unionType.name.toString()}". Did you mean to use a fragment on ${onTypes}?`;
}

isolated function getFragmetCannotSpreadError(parser:FragmentNode fragmentNode, string fragmentName, __Type ofType)
returns string {
    string fragmentOnTypeName = fragmentNode.getOnType();
    if fragmentNode.isInlineFragment() {
        return string`Fragment cannot be spread here as objects of type "${ofType.name.toString()}" can never be of type "${fragmentOnTypeName}".`;
    }
    return string`Fragment "${fragmentName}" cannot be spread here as objects of type "${ofType.name.toString()}" can never be of type "${fragmentOnTypeName}".`;
}

isolated function getMissingRequiredArgError(parser:FieldNode node, __InputValue input) returns string {
    string typeName = getTypeNameFromType(input.'type);
    return string`Field "${node.getName()}" argument "${input.name}" of type "${typeName}" is required, but it was not provided.`;
}

isolated function getOutputObject(Data data, ErrorDetail[] errors) returns OutputObject {
    OutputObject outputObject = {};
    if data.length() > 0 {
        outputObject.data = data;
    } else if errors.length() == 0 {
        outputObject.data = {};
    } else {
        outputObject.data = ();
    }
    if errors.length() > 0 {
        outputObject.errors = errors;
    }
    return outputObject;
}

isolated function getTypeName(parser:ArgumentNode argumentNode) returns string {
    parser:ArgumentType kind = argumentNode.getKind();
    if kind == parser:T_INT {
        return INT;
    } else if kind == parser:T_FLOAT {
        return FLOAT;
    } else if kind == parser:T_BOOLEAN {
        return BOOLEAN;
    } else if kind == parser:T_STRING {
        return STRING;
    } else if kind == parser:T_INPUT_OBJECT {
        return INPUT_OBJECT;
    } else {
        return ENUM;
    }
}

isolated function getArgumentTypeKind(string argType) returns parser:ArgumentType {
    if argType == INT {
        return parser:T_INT;
    } else if argType == STRING {
        return parser:T_STRING;
    } else if argType == FLOAT {
        return parser:T_FLOAT;
    } else if argType == BOOLEAN {
        return parser:T_BOOLEAN;
    } else if argType == INPUT_OBJECT {
        return parser:T_INPUT_OBJECT;
    } else {
        return parser:T_IDENTIFIER;
    }
}

isolated function getOfType(__Type schemaType) returns __Type {
    __Type? ofType = schemaType?.ofType;
    if ofType is () {
        return schemaType;
    } else {
        return getOfType(ofType);
    }
}

isolated function getTypeNameFromType(__Type schemaType) returns string {
    if schemaType.kind == NON_NULL {
        return string`${getTypeNameFromType(<__Type>schemaType?.ofType)}!`;
    } else if schemaType.kind == LIST {
        return string`[${getTypeNameFromType(<__Type>schemaType?.ofType)}]`;
    }
    return schemaType.name.toString();
}

isolated function getTypeNameFromValue(Scalar value) returns string {
    if value is float {
        return FLOAT;
    } else if value is boolean {
        return BOOLEAN;
    } else if value is int {
        return INT;
    } else {
        return STRING;
    }
}

isolated function getErrorDetailRecord(string message, Location|Location[] location) returns ErrorDetail {
    if location is Location[] {
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
