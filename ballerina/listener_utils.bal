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

import ballerina/http;
import ballerina/io;
import ballerina/jballerina.java;
import ballerina/mime;

import graphql.parser;

isolated function handleGetRequests(Engine engine, Context context, http:Request request) returns http:Response {
    string? query = request.getQueryParamValue(PARAM_QUERY);
    if query is string && query != "" {
        string? operationName = request.getQueryParamValue(PARAM_OPERATION_NAME);
        json? variables = request.getQueryParamValue(PARAM_VARIABLES);
        if variables is map<json> || variables == () {
            return getResponseFromQuery(engine, query, operationName, variables, context);
        } else {
            return createResponse("Invalid format in request parameter: variables", http:STATUS_BAD_REQUEST);
        }
    } else {
        return createResponse("Query not found", http:STATUS_BAD_REQUEST);
    }
}

isolated function handlePostRequests(Engine engine, Context context, http:Request request) returns http:Response {
    string contentType = request.getContentType();
    if contentType == CONTENT_TYPE_JSON {
        return getResponseFromJsonPayload(engine, context, request);
    } else if contentType == CONTENT_TYPE_GQL {
        return createResponse("Content-Type 'application/graphql' is not yet supported", http:STATUS_BAD_REQUEST);
    } else if contentType.includes(CONTENT_TYPE_MULTIPART_FORM_DATA) {
        return getResponseFromMultipartPayload(engine, context, request);
    } else {
        return createResponse("Invalid 'Content-type' received", http:STATUS_BAD_REQUEST);
    }
}

isolated function getResponseFromJsonPayload(Engine engine, Context context, http:Request request,
                                             map<Upload|Upload[]> fileInfo = {}) returns http:Response {
    var payload = request.getJsonPayload();
    if payload is json {
        var document = payload.query;
        var variables = payload.variables;
        variables = variables is error ? () : variables;
        if document is string && document != "" {
            if variables is map<json> || variables is () {
                return getResponseFromQuery(engine, document, getOperationName(payload), variables, context, fileInfo);
            } else {
                return createResponse("Invalid format in request parameter: variables", http:STATUS_BAD_REQUEST);
            }
        }
    }
    return createResponse("Invalid request body", http:STATUS_BAD_REQUEST);
}

isolated function getResponseFromQuery(Engine engine, string document, string? operationName, map<json>? variables,
                                       Context context, map<Upload|Upload[]> fileInfo = {}) returns http:Response {
    parser:OperationNode|OutputObject validationResult = engine.validate(document, operationName, variables);
    if validationResult is parser:OperationNode {
        return getResponseFromExecution(engine, validationResult, context, fileInfo);
    } else {
        return createResponse(validationResult.toJson(), http:STATUS_BAD_REQUEST);
    }
}

isolated function getResponseFromExecution(Engine engine, parser:OperationNode operationNode, Context context,
                                           map<Upload|Upload[]> fileInfo) returns http:Response {
    OutputObject outputObject = engine.execute(operationNode, context, fileInfo);
    return createResponse(outputObject.toJson());
}

isolated function createResponse(json payload, int? statusCode = ()) returns http:Response {
    http:Response response = new;
    if statusCode is int {
        response.statusCode = statusCode;
    }
    response.setPayload(payload);
    return response;
}

isolated function getOperationName(json payload) returns string? {
    var operationName = payload.operationName;
    if operationName is string {
        return operationName;
    }
    return;
}

isolated function addDefaultDirectives(__Schema schema) {
    foreach __Directive directive in defaultDirectives {
        schema.directives.push(directive);
    }
}

isolated function getResponseFromMultipartPayload(Engine engine, Context context, http:Request request)
    returns http:Response {
    map<Upload> fileInfo = {};
    map<json> pathMap = {};
    map<json> variables = {};
    json payload = ();
    mime:Entity[]|http:ClientError bodyParts = request.getBodyParts();
    if bodyParts is mime:Entity[] {
        foreach mime:Entity part in bodyParts {
            mime:ContentDisposition contentDisposition = part.getContentDisposition();
            if contentDisposition.name == MULTIPART_OPERATIONS {
                json|mime:ParserError operation = part.getJson();
                if operation is json {
                    payload = operation;
                    json|error variableValues = operation.variables;
                    if variableValues is map<json> {
                        variables = variableValues;
                    } else {
                        return createResponse("Invlaid Mulitpart Request", http:STATUS_BAD_REQUEST);
                    }
                } else {
                    return createResponse(operation.message(), http:STATUS_BAD_REQUEST);
                }
            } else if contentDisposition.name == MULITPART_MAP {
                json|mime:ParserError paths = part.getJson();
                if paths is json {
                    if paths is map<json> {
                        pathMap = paths;
                    } else {
                        return createResponse("Invalid type for multipart request field ‘map’",
                            http:STATUS_BAD_REQUEST);
                    }
                } else {
                    return createResponse(paths.message(), http:STATUS_BAD_REQUEST);
                }
            } else {
                Upload|error handleFileFieldResult = handleFileField(part);
                if handleFileFieldResult is Upload {
                    fileInfo[part.getContentDisposition().name] = handleFileFieldResult;
                } else {
                    return createResponse(handleFileFieldResult.message(), http:STATUS_BAD_REQUEST);
                }
            }
        }
        if fileInfo.length() == 0 {
            return createResponse("File content is missing in multipart request", http:STATUS_BAD_REQUEST);
        }
        map<Upload|Upload[]>|http:Response fileInfoResult = getUploadValues(fileInfo, pathMap, variables);
        if fileInfoResult is map<Upload|Upload[]> {
            return forwardMultipartRequestToExecution(fileInfoResult, engine, context, payload);
        }
        return fileInfoResult;
    } else {
        return createResponse((<http:ClientError>bodyParts).message(), http:STATUS_BAD_REQUEST);
    }
}

isolated function handleFileField(mime:Entity bodyPart) returns Upload|error {
    string encoding = bodyPart.getContentType();
    string fileName = bodyPart.getContentDisposition().fileName;
    mime:MediaType mediaType = check mime:getMediaType(bodyPart.getContentType());
    string|mime:HeaderNotFoundError contentEncoding = bodyPart.getHeader(CONTENT_ENCODING);
    if contentEncoding is string {
        encoding = contentEncoding;
    }
    stream<byte[], io:Error?> byteStream = check bodyPart.getByteStream();
    return {
        fileName: fileName,
        mimeType: mediaType.getBaseType(),
        encoding: encoding,
        byteStream: byteStream
    };
}

isolated function getUploadValues(map<Upload> fileInfo, map<json> pathMap, map<json> variables)
    returns map<Upload|Upload[]>|http:Response {
    map<Upload> files = {}; //map of file path and file value
    if pathMap.length() == 0 {
        return createResponse("Missing multipart request field ‘map’", http:STATUS_BAD_REQUEST);
    }
    foreach string key in pathMap.keys() {
        json value = pathMap[key];
        if value is json[] {
            http:Response? validateResult = validateRequestPathArray(fileInfo, variables, files, value, key);
            if validateResult is http:Response {
                return validateResult;
            }
        } else {
            return createResponse("Invalid type for multipart request field ‘map’ value", http:STATUS_BAD_REQUEST);
        }
    }
    return createUploadInfoMap(files, variables);
}

isolated function validateRequestPathArray(map<Upload> fileInfo, map<json> variables, map<Upload> files,
                                           json[] paths, string key) returns http:Response? {
    if paths.length() == 0 {
        return createResponse("Missing file path in multipart request ‘map’", http:STATUS_BAD_REQUEST);
    }
    foreach json path in paths {
        if !fileInfo.hasKey(key) {
            return createResponse("Undefine file path found in multipart request ‘map’", http:STATUS_BAD_REQUEST);
        }
        if path is string {
            http:Response? validateVariablePathResult = validateVariablePath(variables, path);
            if validateVariablePathResult is () {
                files[path] = <Upload> fileInfo[key];
                continue;
            }
            return validateVariablePathResult;
        }
        return createResponse("Invalid file path value found in multipart request ‘map’", http:STATUS_BAD_REQUEST);
    }
    return;
}

isolated function validateVariablePath(map<json> variables, string path) returns http:Response? {
    //replace variable's null value with file path
    string varName = path;
    if path.includes(".") {
        varName = path.substring(0, <int> path.indexOf("."));
        string indexPart = path.substring((<int> path.indexOf(".") + 1), path.length());
        int|error index = 'int:fromString(indexPart);
        if variables.hasKey(varName) && variables.get(varName) is json[] && index is int {
            json[] arrayValue = <json[]> variables.get(varName);
            if index < arrayValue.length() {
                if arrayValue[index] == null {
                    arrayValue[index] = path;
                    variables[varName] = arrayValue;
                    return;
                }
                return createResponse("Variable value should be `null`", http:STATUS_BAD_REQUEST);
            }
        }
        return createResponse("Undefined variable found in multipart request `map`", http:STATUS_BAD_REQUEST);
    } else if !variables.hasKey(varName) {
        return createResponse("Undefined variable found in multipart request `map`", http:STATUS_BAD_REQUEST);
    } else if variables.get(varName) != null {
        return createResponse("Variable value should be `null`", http:STATUS_BAD_REQUEST);
    }
    return;
}

isolated function createUploadInfoMap(map<Upload> files, map<json> variables)
    returns map<Upload|Upload[]>|http:Response {
    map<Upload|Upload[]> fileInfo = {};
    foreach string key in variables.keys() {
        json value = variables[key];
        if value is json[] {
            Upload[] fileArray = [];
            foreach json filePath in value {
                if filePath is string {
                    fileArray.push(<Upload> files[filePath]);
                } else {
                    return createResponse("File content is missing in multipart request", http:STATUS_BAD_REQUEST);
                }
            }
            fileInfo[key] = fileArray;
        } else {
            fileInfo[key] = <Upload>files[key];
        }
    }
    return fileInfo;
}

isolated function forwardMultipartRequestToExecution(map<Upload|Upload[]> fileInfo, Engine engine,
                                                     Context context, json payload) returns http:Response {
    if payload != () {
        http:Request request = new;
        request.setJsonPayload(payload);
        return getResponseFromJsonPayload(engine, context, request, fileInfo);
    } else {
        http:Response response = new;
        response.statusCode = http:STATUS_BAD_REQUEST;
        response.setPayload("Invalid type for the ‘operations’ multipart field");
        return response;
    }
}

isolated function attachHttpServiceToGraphqlService(Service s, HttpService httpService) = @java:Method {
    'class: "io.ballerina.stdlib.graphql.runtime.engine.ListenerUtils"
} external;

isolated function getHttpServiceFromGraphqlService(Service s) returns HttpService? =
@java:Method {
    'class: "io.ballerina.stdlib.graphql.runtime.engine.ListenerUtils"
} external;
