// Copyright (c) 2023, WSO2 LLC. (http://www.wso2.org) All Rights Reserved.
//
// WSO2 LLC. licenses this file to you under the Apache License,
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
import graphql.parser;

@test:Config {
    groups: ["field-object"]
}
function testFieldObjectFromDocument() returns error? {
    __Type profileType = {
        kind: NON_NULL,
        ofType: {
            kind: OBJECT,
            name: "Profile",
            fields: [
                {
                    name: "id",
                    args: [],
                    'type: {kind: NON_NULL, ofType: {kind: SCALAR, name: "ID"}}
                },
                {
                    name: "address",
                    args: [],
                    'type: {
                        kind: NON_NULL,
                        ofType: {
                            kind: OBJECT,
                            name: "Address",
                            fields: [
                                {
                                    name: "number",
                                    args: [],
                                    'type: {kind: NON_NULL, ofType: {kind: SCALAR, name: "Int"}}
                                },
                                {
                                    name: "city",
                                    args: [],
                                    'type: {kind: NON_NULL, ofType: {kind: SCALAR, name: "String"}}
                                }
                            ]
                        }
                    }
                }
            ]
        }
    };

    string document = "query { profile { id address { number city } } }";
    parser:Parser parser = new (document);
    parser:DocumentNode documentNode = check parser.parse();

    parser:SelectionNode fieldNode = documentNode.getOperations()[0].getSelections()[0];
    if fieldNode !is parser:FieldNode {
        return error("Invalid node type found. Expected a FieldNode");
    }
    Field 'field = new (fieldNode, profileType);

    string expectedName = "profile";
    string actualName = 'field.getName();
    test:assertEquals(actualName, expectedName, msg = "Expected name to be " + expectedName + " but found " + actualName);

    string expectedAlias = "profile";
    string actualAlias = 'field.getAlias();
    test:assertEquals(actualAlias, expectedAlias, msg = "Expected alias to be " + expectedAlias + " but found " + actualAlias);

    string[] expectedSubfieldNames = ["id", "address"];
    string[] actualSubfieldNames = 'field.getSubfieldNames();
    test:assertEquals(actualSubfieldNames, expectedSubfieldNames);

    __Type actualType = 'field.getType();
    test:assertEquals(actualType, profileType);
}
