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

final readonly & string[] missionSubFieldNames = ["id", "designation", "startDate", "endDate"];
final readonly & string[] astronautSubFieldNames = ["id", "name", "missions"];

@test:Config {
    groups: ["getSubfields"],
    dataProvider: fieldObjectProvider1
}
function testGetSubfields1(Field 'field) {
    Field[]? subFields = 'field.getSubfields();
    if subFields is () {
        test:assertFail(msg = "subfields of 'field is null");
    }
    test:assertEquals(subFields.length(), missionSubFieldNames.length());

    foreach Field subField in subFields {
        test:assertFalse(missionSubFieldNames.indexOf(subField.getName()) is (), msg = "subfield name not found");
        test:assertTrue(subField.getSubfields() is (), msg = "subfields of subfield is not null");
        test:assertTrue(subField.getPath() == ["mission", subField.getName()], msg = "path of subfield is not correct");
    }
}

function fieldObjectProvider1() returns (Field[][]) {
    return [
        [field_object1],
        [field_object4]
    ];
}

@test:Config {
    groups: ["getSubfields"],
    dataProvider: fieldObjectProvider2
}
function testGetSubfields2(Field 'field) {
    Field[]? subFields = field_object2.getSubfields();
    if subFields is () {
        test:assertFail(msg = "subfields of 'field is null");
    }
    test:assertEquals(subFields.length(), missionSubFieldNames.length());

    foreach Field subField in subFields {
        test:assertFalse(missionSubFieldNames.indexOf(subField.getName()) is (), msg = "subfield name not found");
        test:assertTrue(subField.getSubfields() is (), msg = "subfields of subfield is not null");
        test:assertTrue(subField.getPath() == ["missions", "@", subField.getName()],
        msg = "path of subfield is not correct");
    }
}

function fieldObjectProvider2() returns (Field[][]) {
    return [
        [field_object2],
        [field_object5]
    ];
}

@test:Config {
    groups: ["getSubfields"],
    dataProvider: fieldObjectProvider3
}
function testGetSubfields3(Field 'field) {
    Field[]? subFields = field_object3.getSubfields();
    if subFields is () {
        test:assertFail(msg = "subfields of 'field is null");
    }
    test:assertEquals(subFields.length(), astronautSubFieldNames.length());

    foreach Field subField in subFields {
        test:assertFalse(astronautSubFieldNames.indexOf(subField.getName()) is (), msg = "subfield name not found");

        if subField.getName() == "missions" {
            Field[]? subSubFields = subField.getSubfields();
            if subSubFields is () {
                test:assertFail(msg = "subfields of subfield is null");
            }
            test:assertEquals(subSubFields.length(), missionSubFieldNames.length());
            foreach Field subSubField in subSubFields {
                test:assertTrue(subSubField.getSubfields() is (), msg = "subfields of subfield is null");
                test:assertTrue(subSubField.getPath() == ["astronauts", "@", "missions", "@", subSubField.getName()],
                msg = "path of subfield is not correct");
            }
        } else {
            test:assertTrue(subField.getSubfields() is (), msg = "subfields of subfield is not null");
            test:assertTrue(subField.getPath() == ["astronauts", "@", subField.getName()],
            msg = "path of subfield is not correct");
        }
    }
}

function fieldObjectProvider3() returns (Field[][]) {
    return [
        [field_object3],
        [field_object6]
    ];
}
