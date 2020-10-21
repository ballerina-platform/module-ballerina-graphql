//// Copyright (c) 2020, WSO2 Inc. (http://www.wso2.org) All Rights Reserved.
////
//// WSO2 Inc. licenses this file to you under the Apache License,
//// Version 2.0 (the "License"); you may not use this file except
//// in compliance with the License.
//// You may obtain a copy of the License at
////
//// http://www.apache.org/licenses/LICENSE-2.0
////
//// Unless required by applicable law or agreed to in writing,
//// software distributed under the License is distributed on an
//// "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
//// KIND, either express or implied.  See the License for the
//// specific language governing permissions and limitations
//// under the License.
//
//import ballerina/test;
//
//Token[] fields = [
//    {
//        value: "name",
//        location: {
//            line: 2,
//            column: 5
//        }
//    },
//    {
//        value: "id",
//        location: {
//            line: 3,
//            column: 5
//        }
//    },
//    {
//        value: "birthdate",
//        location: {
//            line: 4,
//            column: 5
//        }
//    }
//];
//
//@test:Config{
//    groups: ["parser", "unit"]
//}
//function testParseShorthandDocument() returns error? {
//    string document = getInvalidShorthandNotationDocument();
//    Document parsedDocument = check parse(document);
//    Operation expectedOperation = {
//        name: ANONYMOUS_OPERATION,
//        'type: OPERATION_QUERY,
//        fields: fields
//    };
//    map<Operation> operations = {};
//    operations[ANONYMOUS_OPERATION] = expectedOperation;
//    Document expectedDocument = {
//        operations: operations
//    };
//    test:assertEquals(parsedDocument, expectedDocument);
//}
//
//@test:Config{
//    groups: ["parser", "unit"]
//}
//function testParseGeneralNotationDocument() returns error? {
//    string document = getGeneralNotationDocument();
//    Document parsedDocument = check parse(document);
//    string expectedOperationName = "getData";
//    Operation expectedOperation = {
//        'type: OPERATION_QUERY,
//        name: expectedOperationName,
//        fields: fields
//    };
//    map<Operation> operations = {};
//    operations[expectedOperationName] = expectedOperation;
//    Document expectedDocument = {
//        operations: operations
//    };
//    test:assertEquals(parsedDocument, expectedDocument);
//}
//
//@test:Config{
//    groups: ["parser", "unit"]
//}
//function testParseAnonymousOperation() returns error? {
//    string document = getAnonymousOperationDocument();
//    Document result = check parse(document);
//    Operation expectedOperation = {
//        name: ANONYMOUS_OPERATION,
//        'type: OPERATION_QUERY,
//        fields: fields
//    };
//    map<Operation> operations = {};
//    operations[ANONYMOUS_OPERATION] = expectedOperation;
//    Document expected = {
//        operations: operations
//    };
//    test:assertEquals(result, expected);
//}
//
//@test:Config{
//    groups: ["parser", "unit"]
//}
//function testParseDocumentWithNoCloseBrace() returns error? {
//    string document = getNoCloseBraceDocument();
//    Document|Error result = parse(document);
//    if (result is Document) {
//        test:assertFail("Expected error, received document");
//    } else {
//        test:assertEquals(result.message(), "Syntax Error: Expected Name, found <EOF>.");
//    }
//}
