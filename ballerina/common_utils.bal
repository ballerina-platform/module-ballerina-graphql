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

isolated function getInvalidDefaultValueError(string variableName, string typeName, parser:ArgumentValue value) returns string {
    if value is parser:ArgumentNode {
        string errorValue = getErrorValueInString(value);
        return string`Variable ${variableName} expected value of type "${typeName}", found ${errorValue}`;
    } else if value is string {
        return string`Variable ${variableName} expected value of type "${typeName}", found "${value}"`;
    } else if value is () {
        return string`Variable ${variableName} expected value of type "${typeName}", found null`;
    } else {
        return string`Variable ${variableName} expected value of type "${typeName}", found ${value}`;
    }
}

isolated function getInvalidArgumentValueError(string listError, string expectedTypeName, parser:ArgumentValue value) returns string {
    if value is parser:ArgumentNode {
        string errorValue = getErrorValueInString(value);
        return string`${listError}${expectedTypeName} cannot represent non ${expectedTypeName} value: ${errorValue}`;
    } else if value is string {
        return string`${listError}${expectedTypeName} cannot represent non ${expectedTypeName} value: "${value}"`;
    } else if value is () {
        return string`${listError}${expectedTypeName} cannot represent non ${expectedTypeName} value: null`;
    } else {
        return string`${listError}${expectedTypeName} cannot represent non ${expectedTypeName} value: ${value}`;
    }
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
    } else if kind == parser:T_LIST {
        return LIST;
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

isolated function getArgumentTypeIdentifierFromType(__Type argType) returns parser:ArgumentType {
    if argType.kind == NON_NULL {
        return getArgumentTypeIdentifierFromType(<__Type> argType?.ofType);
    } else if argType.kind == LIST {
        return parser:T_LIST;
    } else if argType.kind == INPUT_OBJECT {
        return parser:T_INPUT_OBJECT;
    } else if argType.kind == ENUM {
        return parser:T_IDENTIFIER;
    } else {
        return getArgumentTypeKind(<string> argType.name);
    }
}

isolated function getTypeKind(__Type argType) returns __TypeKind {
    if argType.kind == NON_NULL {
        return (<__Type>argType?.ofType).kind;
    }
    return argType.kind;
}

isolated function getListElementError((string|int)[] path) returns string {
    string errorMsg = "";
    if path.length() > 1 {
        string listIndex = "";
        string argName = "";
        foreach int i in 0..< path.length() {
            string|int pathSegment = path[i];
            if pathSegment is int && argName.length() > 0 {
                listIndex += string`: In element #${pathSegment.toString()}`;
            } else if pathSegment is string && i == 0 {
                argName = pathSegment;
            } else if pathSegment is string && pathSegment == argName {
                // skip the nested list name
                continue;
            } else {
                break;
            }
        }
        if listIndex.length() > 1 {
            errorMsg = string`${argName}${listIndex}:`;
        }
    }
    return errorMsg;
}

isolated function getListMemberTypeFromType(__Type argType) returns __Type {
    if argType.kind == NON_NULL {
        return getListMemberTypeFromType((<__Type>argType?.ofType));
    }
    return <__Type>argType?.ofType;
}

isolated function getErrorValueInString(parser:ArgumentNode argNode, string errorValue = "") returns string {
    string stringErrorValue = errorValue;
    parser:ArgumentValue|parser:ArgumentValue[] argValue = argNode.getValue();
    if argValue is parser:ArgumentValue[] {
        if argNode.getKind() is parser:T_INPUT_OBJECT {
            stringErrorValue = getInputObjectErrorValueInString(argValue, stringErrorValue);
        } else if argNode.getKind() is parser:T_LIST {
            stringErrorValue = getListErrorValueInString(argValue, stringErrorValue);
        }
    } else if argValue is parser:ArgumentValue {
        stringErrorValue = appendScalarValues(argValue, stringErrorValue);
    }
    return stringErrorValue;
}

isolated function getInputObjectErrorValueInString(parser:ArgumentValue[] argValue, string errorValue = "") returns string {
    string inputFields = errorValue;
    inputFields += "{";
    foreach int i in 0..< argValue.length() {
        parser:ArgumentValue value = argValue[i];
        if value is parser:ArgumentNode {
            if value.getValue() is parser:ArgumentValue[] {
                if value.getKind() is parser:T_LIST {
                    inputFields += string`${value.getName()}:`;
                }
                inputFields = getErrorValueInString(value, inputFields);
            } else if value.getValue() is string {
                inputFields += string`${value.getName()}: "${value.getValue().toString()}"`;
            } else if value.getValue() is Scalar {
                inputFields += string`${value.getName()}: ${value.getValue().toString()}`;
            } else if value.getValue() is () {
                inputFields += string`${value.getName()}: null`;
            }
        } else {
            inputFields = appendScalarValues(value, inputFields);
        }
        if argValue.length() > i+1 {
            inputFields += ", ";
        }
    }
    inputFields += "}";
    return inputFields;
}

isolated function getListErrorValueInString(parser:ArgumentValue[] argValue, string errorValue = "") returns string {
    string listItems = errorValue;
    listItems += "[";
    foreach int i in 0..< argValue.length() {
        parser:ArgumentValue value = argValue[i];
        if value is parser:ArgumentNode {
            if value.getValue() is parser:ArgumentValue[] {
                listItems = getErrorValueInString(value, listItems);
            } else if value.getValue() is string {
                listItems += string`"${value.getValue().toString()}"`;
            } else if value.getValue() is Scalar {
                listItems += value.getValue().toString();
            } else if value.getValue() is () {
                listItems += "null";
            }
        } else {
            listItems = appendScalarValues(value, listItems);
        }
        if argValue.length() > i+1 {
            listItems += ", ";
        }
    }
    listItems += "]";
    return listItems;
}

isolated function appendScalarValues(parser:ArgumentValue argValue, string errorValue = "") returns string {
    string scalarValue = errorValue;
    if argValue is string {
        scalarValue += string`${argValue.toString()}`;
    } else if argValue is Scalar {
        scalarValue += string`${argValue}`;
    } else if argValue is () {
        scalarValue += "null";
    }
    return scalarValue;
}

isolated function getInputObjectFieldFormPath((string|int)[] path, string name) returns string {
    int? index = path.indexOf(name);
    string inputObjectField = name;
    if index is int {
        if index > 0 {
            string|int pathValue = path[index-1];
            if pathValue is string {
                inputObjectField = string`${getInputObjectFieldFormPath(path, pathValue)}.${inputObjectField}`;
                return inputObjectField;
            }
        }
    }
    return inputObjectField;
}
