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

import ballerina/crypto;
import ballerina/http;

// Error messages
const UNABLE_TO_PERFORM_DATA_BINDING = "Unable to perform data binding";

isolated function getFieldNotFoundErrorMessageFromType(string fieldName, __Type rootType) returns string {
    string typeName = getTypeNameFromType(rootType);
    if rootType.kind == UNION {
        return getInvalidFieldOnUnionTypeError(fieldName, rootType);
    }
    if rootType.kind == INTERFACE {
        return getInvalidFieldOnInterfaceError(fieldName, typeName);
    }
    return getFieldNotFoundErrorMessage(fieldName, typeName);
}

isolated function getFieldNotFoundErrorMessage(string fieldName, string rootType) returns string {
    return string`Cannot query field "${fieldName}" on type "${rootType}".`;
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

isolated function getInvalidFieldOnInterfaceError(string fieldName, string typeName) returns string {
    return string`Cannot query field "${fieldName}" on type "${typeName}". Did you mean to use a fragment on a subtype?`;
}

isolated function getFragmentCannotSpreadError(parser:FragmentNode fragmentNode, string fragmentName, __Type ofType)
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

isolated function getInvalidDefaultValueError(string variableName, string typeName, parser:ArgumentNode value) returns string {
    string errorValue = getErrorValueInString(value);
    return string`Variable "${variableName}" expected value of type "${typeName}", found ${errorValue}`;
}

isolated function getInvalidArgumentValueError(string listIndexOfError, string expectedTypeName,
                                               parser:ArgumentValue value) returns string {
    if value is parser:ArgumentNode {
        string errorValue = getErrorValueInString(value);
        return string`${listIndexOfError}${expectedTypeName} cannot represent non ${expectedTypeName} value: ${errorValue}`;
    } else if value is () {
        return string`${listIndexOfError}${expectedTypeName} cannot represent non ${expectedTypeName} value: null`;
    } else {
        return string`${listIndexOfError}${expectedTypeName} cannot represent non ${expectedTypeName} value: ${value}`;
    }
}

isolated function getCycleRecursiveFragmentError(parser:FragmentNode spread, map<parser:FragmentNode> visitedSpreads)
    returns ErrorDetail {
    Location[] locations = [];
    string spreadPath = "";
    int listIndex = <int>visitedSpreads.keys().indexOf(spread.getName());
    string[] spreadPathArray = visitedSpreads.keys().slice(listIndex);
    if spreadPathArray.length() == 1 {
        string message = string `Cannot spread fragment "${spread.getName()}" within itself.`;
        return getErrorDetailRecord(message, <Location>spread.getSpreadLocation());
    }
    foreach int i in 1 ..< spreadPathArray.length() {
        parser:FragmentNode fragmentSpread = visitedSpreads.get(spreadPathArray[i]);
        locations.push(<Location>fragmentSpread.getSpreadLocation());
        spreadPath += string ` "${spreadPathArray[i]}"`;
        if i == spreadPathArray.length() - 1 {
            locations.push(<Location>spread.getSpreadLocation());
            break;
        }
        spreadPath += ",";
    }
    string message = string `Cannot spread fragment "${spread.getName()}" within itself via${spreadPath}.`;
    return getErrorDetailRecord(message, locations);
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
    } else if argType == FLOAT || argType == DECIMAL {
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

isolated function getUnwrappedPath(__Type schemaType) returns string[] {
    if schemaType.kind == NON_NULL {
        return getUnwrappedPath(<__Type>schemaType?.ofType);
    } else if schemaType.kind == LIST {
        return ["@", ...getUnwrappedPath(<__Type>schemaType?.ofType)];
    }
    return [];
}

isolated function getOfTypeName(__Type schemaType) returns string {
    return <string>getOfType(schemaType).name;
}

isolated function getTypeNameFromType(__Type schemaType) returns string {
    if schemaType.kind == NON_NULL {
        return string`${getTypeNameFromType(<__Type>schemaType?.ofType)}!`;
    } else if schemaType.kind == LIST {
        return string`[${getTypeNameFromType(<__Type>schemaType?.ofType)}]`;
    }
    return schemaType.name.toString();
}

isolated function getTypeNameFromScalarValue(Scalar value) returns string {
    if value is float {
        return FLOAT;
    } else if value is decimal {
        return DECIMAL;
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
    parser:ArgumentValue|parser:ArgumentValue[] argValue = argNode.getValue();
    if argValue is parser:ArgumentValue[] {
        if argNode.getKind() is parser:T_INPUT_OBJECT {
            return getInputObjectErrorValueInString(argValue, errorValue);
        } else if argNode.getKind() is parser:T_LIST {
            return getListErrorValueInString(argValue, errorValue);
        }
    } else {
        return appendScalarValues(argValue, errorValue);
    }
    return errorValue;
}

isolated function getInputObjectErrorValueInString(parser:ArgumentValue[] argValue, string errorValue = "") returns string {
    string inputFields = errorValue;
    inputFields += "{";
    foreach int i in 0..< argValue.length() {
        parser:ArgumentValue value = argValue[i];
        if value is parser:ArgumentNode {
            parser:ArgumentValue|parser:ArgumentValue[] fieldValue = value.getValue();
            if fieldValue is parser:ArgumentValue[] {
                if value.getKind() is parser:T_LIST {
                    inputFields += string`${value.getName()}:`;
                }
                inputFields = getErrorValueInString(value, inputFields);
            } else if fieldValue is string {
                inputFields += string`${value.getName()}: "${fieldValue}"`;
            } else if fieldValue is () {
                inputFields += string`${value.getName()}: null`;
            } else if fieldValue is Scalar {
                inputFields += string`${value.getName()}: ${fieldValue}`;
            }
        } else {
            inputFields = appendScalarValues(value, inputFields);
        }
        if argValue.length() > i + 1 {
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
            parser:ArgumentValue|parser:ArgumentValue[] listItemValue = value.getValue();
            if listItemValue is parser:ArgumentValue[] {
                listItems = getErrorValueInString(value, listItems);
            } else if listItemValue is string {
                listItems += string`"${listItemValue}"`;
            } else if listItemValue is () {
                listItems += "null";
            } else if listItemValue is Scalar {
                listItems += string`${listItemValue}`;
            }
        } else {
            listItems = appendScalarValues(value, listItems);
        }
        if argValue.length() > i + 1 {
            listItems += ", ";
        }
    }
    listItems += "]";
    return listItems;
}

isolated function appendScalarValues(parser:ArgumentValue argValue, string errorValue = "") returns string {
    if argValue is Scalar {
        return string`${errorValue}${argValue}`;
    } else if argValue is () {
        return string`${errorValue}null`;
    }
    return errorValue;
}

isolated function getInputObjectFieldFormPath((string|int)[] path, string name) returns string {
    int? index = path.indexOf(name);
    if index is int {
        if index > 0 {
            string|int pathValue = path[index-1];
            if pathValue is string {
                return string`${getInputObjectFieldFormPath(path, pathValue)}.${name}`;
            }
        }
    }
    return name;
}

isolated function getGraphqlPayload(string query, map<anydata>? variables = (), string? operationName = ())
                                    returns json {
    return {
        query: query,
        variables: variables.toJson(),
        operationName: operationName
    };
}

isolated function handleHttpClientErrorResponse(http:ClientError clientError) returns RequestError {
    if clientError is http:ApplicationResponseError {
        anydata body = clientError.detail().get("body");
        if hasGraphqlErrors(clientError) {
            ErrorDetail[] errorDetails = checkpanic (<json>body).errors.ensureType();
            return error InvalidDocumentError("Invalid GraphQL document provided", errors = errorDetails);
        }
        return error HttpError("GraphQL Client Error", body = body);
    }
    return error HttpError("GraphQL Client Error", clientError, body = ());
}

isolated function hasGraphqlErrors(http:ApplicationResponseError applicationResponseError) returns boolean {
    anydata body = applicationResponseError.detail().get("body");
    json|error data = body.ensureType();
    return applicationResponseError.detail().statusCode == 400 && data is json && data.errors is json;
}

isolated function handleGraphqlErrorResponse(map<json> responseMap) returns RequestError|ServerError {
    ErrorDetail[]|error errors = responseMap.get("errors").cloneWithType();
    if errors is error {
        return error RequestError("GraphQL Client Error", errors);
    }
    json? data = (responseMap.hasKey("data")) ? responseMap.get("data") : ();
    map<json>? extensions = (responseMap.hasKey("extensions")) ? (responseMap.get("extensions") is () ? () :
        <map<json>> responseMap.get("extensions")) : ();
    return error ServerError("GraphQL Server Error", errors = errors, data = data, extensions = extensions);
}

isolated function performDataBinding(typedesc<GenericResponse|record{}|json> targetType, json graphqlResponse)
                                     returns GenericResponse|record{}|json|RequestError {
    do {
        if targetType is typedesc<GenericResponse> {
            GenericResponse response = check graphqlResponse.cloneWithType(targetType);
            return response;
        } else if targetType is typedesc<record{}> {
            record{} response = check graphqlResponse.cloneWithType(targetType);
            return response;
        } else if targetType is typedesc<json> {
            json response = check graphqlResponse.cloneWithType(targetType);
            return response;
        }
    } on fail error e {
        return error RequestError("GraphQL Client Error",  e);
    }
    return error RequestError("GraphQL Client Error, Invalid binding type.");
}

isolated function performDataBindingWithErrors(typedesc<GenericResponseWithErrors|record{}|json> targetType,
                                               json graphqlResponse)
                                               returns GenericResponseWithErrors|record{}|json|PayloadBindingError {
    do {
        if targetType is typedesc<GenericResponseWithErrors> {
            GenericResponseWithErrors response = check graphqlResponse.cloneWithType(targetType);
            return response;
        } else if targetType is typedesc<record{}> {
            record{} response = check graphqlResponse.cloneWithType(targetType);
            return response;
        } else if targetType is typedesc<json> {
            json response = check graphqlResponse.cloneWithType(targetType);
            return response;
        }
    } on fail error e {
        map<json>|error responseMap = graphqlResponse.ensureType();
        if responseMap is error || !responseMap.hasKey("errors") {
            return error PayloadBindingError(UNABLE_TO_PERFORM_DATA_BINDING, e, errors = ());
        }
        ErrorDetail[] errorDetails = checkpanic responseMap.get("errors").cloneWithType();
        return error PayloadBindingError(UNABLE_TO_PERFORM_DATA_BINDING, e, errors = errorDetails);
    }
    return error PayloadBindingError(string `${UNABLE_TO_PERFORM_DATA_BINDING}, Invalid binding type.`, errors = ());
}

isolated function getFieldTypeFromParentType(__Type parentType, __Type[] typeArray, parser:FieldNode fieldNode) returns __Type {
    __TypeKind typeKind = parentType.kind;
    if typeKind == NON_NULL {
        return getFieldTypeFromParentType(unwrapNonNullype(parentType), typeArray, fieldNode);
    } else if typeKind == OBJECT {
        __Field requiredFieldValue = <__Field>getRequiredFieldFromType(parentType, typeArray, fieldNode);
        return requiredFieldValue.'type;
    } else if typeKind == LIST {
        return getFieldTypeFromParentType(<__Type>parentType.ofType, typeArray, fieldNode);
    } else if typeKind == UNION {
        foreach __Type possibleType in <__Type[]>parentType.possibleTypes {
            __Field? fieldValue = getRequiredFieldFromType(possibleType, typeArray, fieldNode);
            if fieldValue is __Field {
                return fieldValue.'type;
            }
        }
    } else if typeKind == INTERFACE {
        __Field? requiredFieldValue = getRequiredFieldFromType(parentType, typeArray, fieldNode);
        if requiredFieldValue is () {
            foreach __Type possibleType in <__Type[]>parentType.possibleTypes {
                __Field? fieldValue = getRequiredFieldFromType(possibleType, typeArray, fieldNode);
                if fieldValue is __Field {
                    return fieldValue.'type;
                }
            }
        } else {
            return requiredFieldValue.'type;
        }
    }
    return parentType;
}

// TODO: This returns () for the hierarchiacal paths. Find a better way to handle this.
isolated function getKeyArgument(parser:FieldNode fieldNode) returns string? {
    if fieldNode.getArguments().length() == 0 {
        return;
    }
    parser:ArgumentNode argumentNode = fieldNode.getArguments()[0];
    if argumentNode.getName() != KEY_ARGUMENT {
        return;
    }
    if argumentNode.isVariableDefinition() {
        return <string>argumentNode.getVariableValue();
    } else {
        return <string>argumentNode.getValue();
    }
}

# Adds an error to the GraphQL response. Using this to add an error is not recommended.
#
# + context - The context of the GraphQL request.
# + errorDetail - The error to be added to the response.
public isolated function __addError(Context context, ErrorDetail errorDetail) {
    context.addError(errorDetail);
}

isolated function generateArgHash(parser:ArgumentNode[] arguments, string[] parentArgHashes = [],
                                  string[] optionalFields = []) returns string {
    any[] argValues = [...parentArgHashes, ...optionalFields];
    argValues.push(...arguments.'map((arg) => getValueArrayFromArgumentNode(arg)));
    byte[] hash = crypto:hashMd5(argValues.toString().toBytes());
    return hash.toBase64();
}

isolated function getValueArrayFromArgumentNode(parser:ArgumentNode argumentNode) returns anydata[] {
    anydata[] valueArray = [];
    if argumentNode.isVariableDefinition() {
        valueArray.push(argumentNode.getVariableValue());
    } else {
        parser:ArgumentValue|parser:ArgumentValue[] argValue = argumentNode.getValue();
        if argValue is parser:ArgumentValue[] {
            foreach parser:ArgumentValue argField in argValue {
                parser:ArgumentNode|Scalar? argFieldNode = argField;
                if argFieldNode is parser:ArgumentNode {
                    valueArray.push(getValueArrayFromArgumentNode(argFieldNode));
                } else {
                    valueArray.push(argFieldNode);
                }
            }
        } else {
            parser:ArgumentNode|Scalar? argFieldNode = argValue;
            if argFieldNode is parser:ArgumentNode {
                valueArray.push(getValueArrayFromArgumentNode(argFieldNode));
            } else {
                valueArray.push(argFieldNode);
            }
        }
    }
    return valueArray;
}

isolated function getNullableFieldsFromType(__Type fieldType) returns string[] {
    string[] nullableFields = [];
    __Field[]? fields = unwrapNonNullype(fieldType).fields;
    if fields is __Field[] {
        foreach __Field 'field in fields {
            if isNullableField('field.'type) {
                nullableFields.push('field.name);
            }
        }
    }
    return nullableFields;
}

isolated function isNullableField(__Type 'type) returns boolean {
    if 'type.kind == NON_NULL {
        return false;
    }
    return true;
}
