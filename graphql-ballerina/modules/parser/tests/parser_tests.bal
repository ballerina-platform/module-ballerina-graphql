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

@test:Config {
    groups: ["parse", "parser", "unit"]
}
function testComplexDocument() returns error? {
    string documentString = string
    `,,,




query getData, {
    # Line comment
    name(id: 132,,, name: "Prof. Moriarty", negative: -123, weight: 75.4) { # Inline Comment {
        first
        last
    }
    id {
        prefix {
            sample
        }
        suffix
    }
    birthdate (format: "DD/MM/YYYY")
},`;
    Parser parser = new(documentString);
    DocumentNode documentNode = check parser.parse();
    RecordCreatorVisitor v = new;
    var document = v.visitDocument(documentNode);
    test:assertEquals(document, expectedDocumentWithParameters);
}

@test:Config {
    groups: ["parse", "parser", "unit"]
}
function testShorthandDocument() returns error? {
    string documentString = string
`{
    name
    id
}`;
    Parser parser = new(documentString);
    DocumentNode documentNode = check parser.parse();
    RecordCreatorVisitor v = new;
    var document = v.visitDocument(documentNode);
    test:assertEquals(document, shorthandDocument);
}

@test:Config {
    groups: ["parse", "parser", "unit"]
}
function testDocumentWithNamedOperations() returns error? {
    string documentString = string
`query getData {
    name
    birthdate
}`;
    Parser parser = new(documentString);
    DocumentNode documentNode = check parser.parse();
    RecordCreatorVisitor v = new;
    var document = v.visitDocument(documentNode);
    test:assertEquals(document, namedOperation);
}

@test:Config {
    groups: ["parse", "parser", "unit"]
}
function testDocumentWithTwoNamedOperations() returns error? {
    string documentString = string
`query getName {
    name
}

query getBirthDate {
    birthdate
}

`;
    Parser parser = new(documentString);
    DocumentNode documentNode = check parser.parse();
    RecordCreatorVisitor v = new;
    var document = v.visitDocument(documentNode);
    test:assertEquals(document, documentWithTwoNamedOperations);
}
