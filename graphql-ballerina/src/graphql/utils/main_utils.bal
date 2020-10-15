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

import ballerina/log;

isolated function logAndPanicError(string message, error e) {
    log:printError(message, e);
    panic e;
}

isolated function getExpectedSyntaxError(Token token, string expected, string foundType = "") returns
InvalidDocumentError {
    string message = "Syntax Error: Expected \"" + expected + "\", found " + foundType + " \"" + token.value + "\".";
    ErrorRecord errorRecord = getErrorRecordFromToken(token);
    return InvalidDocumentError(message, errorRecord = errorRecord);
}

isolated function getUnexpectedSyntaxError(Token token, string unexpectedType) returns InvalidDocumentError {
    string message = "Syntax Error: Unexpected " + unexpectedType + " \"" + token.value + "\".";
    ErrorRecord errorRecord = getErrorRecordFromToken(token);
    return InvalidDocumentError(message, errorRecord = errorRecord);
}

isolated function getErrorRecordFromToken(Token token) returns ErrorRecord {
    Location location = {
        line: token.line,
        column: token.column
    };
    return {
        locations: [location]
    };
}

isolated function getErrorJson(string message) returns json {
    return {
        errors: [
            {
                massage: message
            }
        ]
    };
}
