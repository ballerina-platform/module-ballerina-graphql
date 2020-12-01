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

import ballerina/test;
import ballerina/time;

import graphql.commons;

@test:Config {
    groups: ["parse", "parser", "unit"]
}
function testComplexDocument() returns error? {
    string documentString = getDocumentWithParameters();
    Parser parser = new(documentString);
    time:Time t1 = time:currentTime();
    DocumentNode documentNode = check parser.parse();
    time:Time t2 = time:currentTime();
    int t1Millis = t1.time;
    int t2Millis = t2.time;
    int t = t2Millis - t1Millis;
    commons:println("Complex Time: " + t.toString());

    RecordCreatorVisitor v = new;
    var document = v.visitDocument(documentNode);
    test:assertEquals(document, expectedDocumentWithParameters);
}

@test:Config {
    groups: ["parse", "parser", "unit"]
}
function testShorthandDocument() returns error? {
    string documentString = getShorthandNotationDocument();
    Parser parser = new(documentString);
    time:Time t1 = time:currentTime();
    DocumentNode documentNode = check parser.parse();
    time:Time t2 = time:currentTime();
    int t1Millis = t1.time;
    int t2Millis = t2.time;
    int t = t2Millis - t1Millis;
    commons:println("Shorthand Time: " + t.toString());

    RecordCreatorVisitor v = new;
    var document = v.visitDocument(documentNode);
    test:assertEquals(document, shorthandDocument);
}

@test:Config {
    groups: ["parse", "parser", "unit"]
}
function testDocumentWithNamedOperations() returns error? {
    string documentString = getGeneralNotationDocument();
    Parser parser = new(documentString);
    time:Time t1 = time:currentTime();
    DocumentNode documentNode = check parser.parse();
    time:Time t2 = time:currentTime();
    int t1Millis = t1.time;
    int t2Millis = t2.time;
    int t = t2Millis - t1Millis;
    commons:println("Named Operations Time: " + t.toString());

    RecordCreatorVisitor v = new;
    var document = v.visitDocument(documentNode);
    test:assertEquals(document, namedOperation);
}

@test:Config {
    groups: ["parse", "parser", "unit"]
}
function testDocumentWithTwoNamedOperations() returns error? {
    string documentString = getDocumentWithTwoNamedOperations();
    Parser parser = new(documentString);
    time:Time t1 = time:currentTime();
    DocumentNode documentNode = check parser.parse();
    time:Time t2 = time:currentTime();
    int t1Millis = t1.time;
    int t2Millis = t2.time;
    int t = t2Millis - t1Millis;
    commons:println("Two Named Operations Time: " + t.toString());

    RecordCreatorVisitor v = new;
    var document = v.visitDocument(documentNode);
    test:assertEquals(document, documentWithTwoNamedOperations);
}
