// Copyright (c) 2021 WSO2 Inc. (http://www.wso2.org) All Rights Reserved.
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

import ballerina/graphql;
import ballerina/io;

stream<io:Block, io:Error?> byteStream = check io:fileReadBlocksAsStream("./invalid_service_27/sample.txt");

graphql:FileUpload file = {
   fileName: "image.jpg",
   mimeType: "application/jpeg",
   encoding: "UTF-8",
   byteStream: byteStream
};

public type File record {
    string fileName;
    graphql:FileUpload file;
};

service /graphql on new graphql:Listener(4000) {

    resource function get getImage() returns graphql:FileUpload {
        return file;
    }
}

service /graphql on new graphql:Listener(4000) {

    isolated resource function get getImageIfExist() returns graphql:FileUpload? {
        return;
    }
}

service /graphql on new graphql:Listener(4000) {

    resource function get getImages() returns graphql:FileUpload[] {
        return [file];
    }
}

service /graphql on new graphql:Listener(4000) {

    isolated resource function get upload(graphql:FileUpload p) returns string {
        return "Successful";
    }
}

service /graphql on new graphql:Listener(4000) {

    isolated resource function get uploadMultiple(graphql:FileUpload[] p) returns string {
        return "Successful";
    }
}

service /graphql on new graphql:Listener(4000) {

    isolated resource function get uploadFile(graphql:FileUpload? p) returns string {
        return "Successful";
    }
}

service /graphql on new graphql:Listener(4000) {

    isolated resource function get uploadFile() returns string {
        return "Successful";
    }

    remote function uploadAndGet() returns graphql:FileUpload {
        return file;
    }
}

service /graphql on new graphql:Listener(4000) {

    isolated resource function get uploadFile() returns string {
        return "Successful";
    }

    isolated remote function uploadAndGet() returns graphql:FileUpload? {
        return;
    }
}

service /graphql on new graphql:Listener(4000) {

    isolated resource function get uploadFile() returns string {
        return "Successful";
    }

    remote function uploadAndGetMultiple() returns graphql:FileUpload[] {
        return [file];
    }
}

isolated service /graphql on new graphql:Listener(4000) {

    isolated resource function get uploadFile() returns string {
        return "Successful";
    }

    isolated remote function upload(graphql:FileUpload[][] p) returns string {
        return "Invalid Input";
    }
}

isolated service /graphql on new graphql:Listener(4000) {

    isolated resource function get uploadFile(File f) returns string {
        return "Successful";
    }

    remote function upload(File f) returns string {
        return "successful";
    }
}

isolated service /graphql on new graphql:Listener(4000) {

    resource function get uploadFile() returns File {
        return {
            fileName: "sample.txt",
            file: file
        };
    }
}

isolated service /graphql on new graphql:Listener(4000) {

    isolated resource function get uploadFileName() returns string {
        return "sample.txt";
    }

    remote function upload() returns File {
        return {
            fileName: "sample.txt",
            file: file
        };
    }
}
