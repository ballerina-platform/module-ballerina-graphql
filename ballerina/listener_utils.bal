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
import ballerina/jballerina.java;
import ballerina/mime;

import graphql.parser;
import ballerina/io;

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
    io:println(contentType);
    if contentType == CONTENT_TYPE_JSON {
        return getResponseFromJsonPayload(engine, context, {},request);
    } else if contentType == CONTENT_TYPE_GQL {
        return createResponse("Content-Type 'application/graphql' is not yet supported", http:STATUS_BAD_REQUEST);
    } else if contentType.includes(CONTENT_TYPE_MULTIPART_FORM_DATA) {
        // io:println("mutlipart");
        return getResponseFromMultipartPayload(engine, context, request);
    } else {
        // io:println(request.getBodyParts());
        return createResponse("Invalid 'Content-type' received", http:STATUS_BAD_REQUEST);
    }
}

isolated function getResponseFromJsonPayload(Engine engine, Context context, map<FileUpload|FileUpload[]> fileInfo, http:Request request)
returns http:Response {
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
    Context context, map<FileUpload|FileUpload[]>? fileInfo = ()) returns http:Response {
    parser:OperationNode|OutputObject validationResult = engine.validate(document, operationName, variables);
    if validationResult is parser:OperationNode {
        return getResponseFromExecution(engine, validationResult, context, fileInfo);
    } else {
        return createResponse(validationResult.toJson(), http:STATUS_BAD_REQUEST);
    }
}

isolated function getResponseFromExecution(Engine engine, parser:OperationNode operationNode, Context context,
                                           map<FileUpload|FileUpload[]>? fileInfo) returns http:Response {
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
    http:Response response = new;
    map<FileUpload> fileInfo = {};
    map<json> pathMap = {};
    map<json> variables = {};
    json payload = ();
    map<FileUpload|FileUpload[]> files = {};

    mime:Entity[]|http:ClientError bodyParts = request.getBodyParts();
    if bodyParts is mime:Entity[] {
        foreach mime:Entity part in bodyParts {
            mime:ContentDisposition contentDisposition = part.getContentDisposition();
            io:println(contentDisposition.name);
            if contentDisposition.name == MULTIPART_OPERATIONS {
                json|mime:ParserError operation = part.getJson();
                if operation is json {
                    var variableValues = operation.variables;
                    payload = operation;
                    variableValues = variableValues is error ? () : variableValues;
                    if variableValues is map<json> {
                        variables = variableValues;
                    } else {
                        response.statusCode = http:STATUS_BAD_REQUEST;
                        response.setPayload("Invlaid Mulitpart Request");
                        return response;
                    }
                } else {
                    response.statusCode = http:STATUS_BAD_REQUEST;
                    response.setPayload(operation.message());
                    return response;
                }
            } else if contentDisposition.name == MULITPART_MAP {
                json|mime:ParserError paths = part.getJson();
                if paths is json {
                    pathMap = <map<json>> paths;
                } else {
                    response.statusCode = http:STATUS_BAD_REQUEST;
                    response.setPayload(paths.message());
                    return response;
                }
            } else {
                FileUpload|error handleFileFieldResult = handleFileField(part);
                if handleFileFieldResult is FileUpload {
                    fileInfo[part.getContentDisposition().name] = handleFileFieldResult;
                } else {
                    response.statusCode = http:STATUS_BAD_REQUEST;
                    response.setPayload(handleFileFieldResult.message());
                    return response;
                }
            }
        }
    } else {
        response.statusCode = http:STATUS_BAD_REQUEST;
        response.setPayload((<http:ClientError>bodyParts).message());
        return response;
    }

    map<FileUpload|FileUpload[]>|string fileInfoResult = getFileUploadValues(fileInfo, pathMap, variables);
    if fileInfoResult is map<FileUpload|FileUpload[]> {
        files = fileInfoResult;
    } else {
        response.statusCode = http:STATUS_BAD_REQUEST;
        response.setPayload(<string> fileInfoResult);
        return response;
    }
    return forwardMultipartRequestToExecution(engine, context, files, payload);
}

isolated function handleFileField(mime:Entity bodyPart) returns FileUpload|error {
    var mediaType = mime:getMediaType(bodyPart.getContentType());
    string mimeType = "";
    if mediaType is mime:MediaType {
        mimeType = mediaType.getBaseType();
    }
    string fileName = bodyPart.getContentDisposition().fileName;
    string encoding = bodyPart.getContentType();
    io:println("encoding - ", encoding);
    stream<byte[], io:Error?>|mime:ParserError byteStream = bodyPart.getByteStream();
    if byteStream is stream<byte[], io:Error?> {
        FileUpload file = {
            fileName: fileName,
            mimeType: mimeType,
            encoding: encoding,
            byteStream: byteStream
        };
        return file;
    }
    return byteStream;
}

isolated function getFileUploadValues(map<FileUpload> fileInfo, map<json> pathMap, map<json> variables) returns map<FileUpload|FileUpload[]>|string {
    map<FileUpload> files = {};
    if pathMap.length() > 0 {
        foreach var item in pathMap.entries() {
            string key = item[0];
            if item[1] is json[] {
                json[] value = <json[]>item[1];
                if value.length() > 0 {
                    foreach json path in value {
                        if path is string {
                            if checkAndReplaceVariablePosition(variables, path) {
                                if fileInfo.hasKey(key) {
                                    files[path] = <FileUpload> fileInfo[key];
                                } else {
                                    return  "File content is missing in multipart request";
                                }
                            } else {
                                return "Undefined variable found in multipart request";
                            }
                        } else {
                            return "Invalid type for multipart request field ‘map’ value";
                        }
                    }
                } else {
                    return "Missing multipart request field ‘map’ values";
                }
            } else {
                return "Invalid type for multipart request field ‘map’";
            }
        }
    } else {
        return "Missing multipart request field ‘map’";
    }
    return createFileUploadInfoMap(files, variables);
}

isolated function checkAndReplaceVariablePosition(map<json> variables, string name) returns boolean {
    string varName = name;
    if name.includes(".") {
        varName = name.substring(0, <int> name.indexOf("."));
        string indexPart = name.substring((<int> name.indexOf(".") + 1), name.length());
        int|error index = 'int:fromString(indexPart);
        if variables.hasKey(varName) && variables.get(varName) is json[] && index is int {
            json[] arrayValue = <json[]> variables.get(varName);
            if index < arrayValue.length() {
                arrayValue[index] = name;
                variables[varName] = arrayValue;
                return true;
            }
            return false;
        }
        return false;
    }
    return variables.hasKey(varName);
}

isolated function createFileUploadInfoMap(map<FileUpload> files, map<json> variables) returns map<FileUpload|FileUpload[]> {
    map<FileUpload|FileUpload[]> fileInfo = {};
    foreach var entry in variables.entries() {
        string key = entry[0];
        json value = entry[1];
        if value is json[] {
            FileUpload[] fileArray = [];
            foreach json item in value {
                if item is string {
                    fileArray.push(<FileUpload> files[item]);
                }
            }
            fileInfo[key] = fileArray;
        } else {
            fileInfo[key] = <FileUpload>files[key];
        }
    }
    return fileInfo;
}

isolated function forwardMultipartRequestToExecution(Engine engine, Context context, map<FileUpload|FileUpload[]> fileInfo, json payload) returns http:Response {
    if payload != () {
        http:Request request = new;
        request.setJsonPayload(payload, CONTENT_TYPE_JSON);
        return getResponseFromJsonPayload(engine, context, fileInfo, request);
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
