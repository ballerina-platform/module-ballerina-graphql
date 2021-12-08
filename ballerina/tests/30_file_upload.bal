// Copyright (c) 2021, WSO2 Inc. (http://www.wso2.org) All Rights Reserved.
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
import ballerina/mime;
import ballerina/test;
import ballerina/io;

@test:Config {
    groups: ["file_upload"]
}
isolated function testFileUpload() returns error? {
    string document = string`mutation($file: FileUpload!){ singleFileUpload(file: $file) { fileName, mimeType, encoding } }`;
    json variables = {"file": null} ;

    json op = {
        "query":document,
        "variables": variables
    }; 

    json pathMap =  { "0": ["file"]};

    mime:Entity operations = new;
    mime:ContentDisposition contentDisposition1 = new;
    contentDisposition1.name = "operations";
    contentDisposition1.disposition = "form-data";
    operations.setContentDisposition(contentDisposition1);
    operations.setJson(op);

    mime:Entity path = new;
    mime:ContentDisposition contentDisposition2 = new;
    contentDisposition2.name = "map";
    contentDisposition2.disposition = "form-data";
    path.setContentDisposition(contentDisposition2);
    path.setJson(pathMap);

    mime:Entity jsonBodyPart = new;
    mime:ContentDisposition contentDisposition3 = new;
    contentDisposition3.name = "0";
    contentDisposition3.disposition = "form-data";
    jsonBodyPart.setContentDisposition(contentDisposition3);
    jsonBodyPart.setJson({"name": "wso2"});
    mime:Entity[] bodyParts = [operations, path, jsonBodyPart];
    http:Request request = new;
    request.setBodyParts(bodyParts, contentType = mime:MULTIPART_FORM_DATA);

    http:Client httpClient = check new("http://localhost:9091");
    http:Response response = check httpClient->post("/fileUpload", request);
    int statusCode = response.statusCode;
    test:assertEquals(statusCode, 200);
    string actualPaylaod = check response.getTextPayload();
    io:println(actualPaylaod);
}


@test:Config {
    groups: ["file_upload1"]
}
isolated function testMultipleFileUpload() returns error? {
    string document = string`mutation($files: [FileUpload!]!){ multipleFileUpload(files: $files) }`;
    json variables = {"files": [null, null, null]} ;

    json op = {
        "query":document,
        "variables": variables
    }; 

    json pathMap =  {
        "0": ["files.0"],
        "1": ["files.1"],
        "2": ["files.2"]
    };

    mime:Entity operations = new;
    mime:ContentDisposition contentDisposition1 = new;
    contentDisposition1.name = "operations";
    contentDisposition1.disposition = "form-data";
    operations.setContentDisposition(contentDisposition1);
    operations.setJson(op);

    mime:Entity path = new;
    mime:ContentDisposition contentDisposition2 = new;
    contentDisposition2.name = "map";
    contentDisposition2.disposition = "form-data";
    path.setContentDisposition(contentDisposition2);
    path.setJson(pathMap);

    mime:Entity jsonBodyPart1 = new;
    mime:ContentDisposition contentDisposition3 = new;
    contentDisposition3.name = "0";
    contentDisposition3.disposition = "form-data";
    jsonBodyPart1.setContentDisposition(contentDisposition3);
    jsonBodyPart1.setJson({"name": "wso2"});

    mime:Entity jsonBodyPart2 = new;
    mime:ContentDisposition contentDisposition4 = new;
    contentDisposition4.name = "1";
    contentDisposition4.disposition = "form-data";
    jsonBodyPart2.setContentDisposition(contentDisposition4);
    jsonBodyPart2.setJson({"name": "This is the second file"});

    mime:Entity jsonBodyPart3 = new;
    mime:ContentDisposition contentDisposition5 = new;
    contentDisposition5.name = "2";
    contentDisposition5.disposition = "form-data";
    jsonBodyPart3.setContentDisposition(contentDisposition5);
    jsonBodyPart3.setJson({"name": "This is the 3rd file"});

    mime:Entity[] bodyParts = [operations, path, jsonBodyPart1, jsonBodyPart2, jsonBodyPart3];
    http:Request request = new;
    request.setBodyParts(bodyParts, contentType = mime:MULTIPART_FORM_DATA);

    http:Client httpClient = check new("http://localhost:9091");
    http:Response response = check httpClient->post("/fileUpload", request);
    int statusCode = response.statusCode;
    test:assertEquals(statusCode, 200);
    string actualPaylaod = check response.getTextPayload();
    io:println(actualPaylaod);
}
