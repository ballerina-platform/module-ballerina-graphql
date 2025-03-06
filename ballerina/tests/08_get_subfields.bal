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
    groups: ["field", "getSubfields"],
    dataProvider: fieldObjectProvider1
}
function testGetSubfields1(string fileName, readonly & __Type fieldType, string[] path) returns error? {
    parser:FieldNode[] fields = check getFieldNodesFromDocumentFile(fileName);
    test:assertTrue(fields.length() == 1);
    Field 'field = getField(fields[0], fieldType, AstronautQuery, [path[0]]);

    Field[]? subfields = 'field.getSubfields();
    string[] subfieldNames = 'field.getSubfieldNames();
    test:assertFalse(subfields == ());
    test:assertEquals((<Field[]>subfields).length(), subfieldNames.length());

    foreach Field subfield in <Field[]>subfields {
        test:assertFalse(subfieldNames.indexOf(subfield.getName()) == (), msg = "subfield name not found");
        test:assertTrue(subfield.getSubfields() == (), msg = "subfields of subfield is not null");
        test:assertEquals(subfield.getPath(), [...path, subfield.getName()]);
    }
}

function fieldObjectProvider1() returns [string, __Type, string[]][] {
    return [
        ["field_object_mission", Mission, ["mission"]],
        ["field_object_mission_with_fragment", Mission, ["mission"]],
        ["field_object_missions", MissionNonNullList, ["missions", "@"]],
        ["field_object_missions_with_fragment", MissionNonNullList, ["missions", "@"]]
    ];
}

@test:Config {
    groups: ["field", "getSubfields"],
    dataProvider: fieldObjectProvider2
}
function testGetSubfields2(string fileName, readonly & __Type fieldType, string[] path) returns error? {
    parser:FieldNode[] fields = check getFieldNodesFromDocumentFile(fileName);
    test:assertTrue(fields.length() == 1);
    Field 'field = getField(fields[0], fieldType, AstronautQuery, [path[0]]);

    Field[]? subfields = 'field.getSubfields();
    string[] subfieldNames = 'field.getSubfieldNames();
    test:assertFalse(subfields == ());
    test:assertEquals((<Field[]>subfields).length(), subfieldNames.length());

    foreach Field subfield in <Field[]>subfields {
        test:assertFalse(subfieldNames.indexOf(subfield.getName()) == (), msg = "subfield name not found");
        Field[]? subSubFields = subfield.getSubfields();
        string[] subSubfieldNames = subfield.getSubfieldNames();
        test:assertFalse(subSubFields == ());
        test:assertEquals((<Field[]>subSubFields).length(), subSubfieldNames.length());
        foreach Field subSubField in <Field[]>subSubFields {
            test:assertTrue(subSubField.getSubfields() == ());
            test:assertEquals(subSubField.getPath(), [...path, subSubField.getName()]);
        }
    }
}

function fieldObjectProvider2() returns [string, __Type, string[]][] {
    return [
        ["field_object_astronauts", AstronautNonNullList, ["astronauts", "@", "missions", "@"]],
        ["field_object_astronauts_with_fragments", AstronautNonNullList, ["astronauts", "@", "missions", "@"]]
    ];
}

@test:Config {
    groups: ["field", "qualifiedName"],
    dataProvider: fieldObjectProvider3
}
function testQualifiedName(string fileName, readonly & __Type fieldType) returns error? {
    parser:FieldNode[] fields = check getFieldNodesFromDocumentFile(fileName);
    test:assertTrue(fields.length() == 1);
    Field 'field = getField(fields[0], fieldType, AstronautQuery, []);
    Field[]? subfields = 'field.getSubfields();
    if subfields == () {
        return error("Expected subfields");
    }
    foreach Field subfield in subfields {
        string expectedQualifiedName = string `${fieldType.name.toString()}.${subfield.getName()}`;
        test:assertEquals(subfield.getQualifiedName(), expectedQualifiedName);
    }
}

function fieldObjectProvider3() returns [string, __Type][] {
    return [
        ["field_object_mission", Mission],
        ["field_object_mission_with_fragment", Mission]
    ];
}
