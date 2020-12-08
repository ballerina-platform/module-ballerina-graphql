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
//import graphql.commons;

@test:Config{
    groups: ["engine", "unit"]
}
function testInvokeResource() {
    string document = getInvalidShorthandNotationDocument();
    Schema? result = createSchema(invokeResourceTestService);
    test:assertTrue(result is Schema);
    Schema actualSchema = <Schema>result;

    Schema expectedSchema = {
        fields: [
            {
                name: "name",
                kind: string
            },
            {
                name: "id",
                kind: int
            },
            {
                name: "birthdate",
                kind: string,
                inputs: [
                    {
                        name: "format",
                        kind: string
                    }
                ]
            }
        ]
    };
    test:assertTrue(compareSchema(actualSchema, expectedSchema));
}


service object {} invokeResourceTestService = service object {
    isolated resource function get name() returns string {
        return "John Doe";
    }

    isolated resource function get id() returns int {
        return 1;
    }

    isolated resource function get birthdate(string format) returns string {
        return "01-01-1980";
    }
};

isolated function compareSchema(Schema actualSchema, Schema expectedSchema) returns boolean {
    return isEqualFields(actualSchema.fields, expectedSchema.fields);
}

isolated function isEqualFields(Field[]? actual, Field[]? expected) returns boolean {
    // Can't use equality with typedescs
    if (actual is () && expected is ()) {
        return true;
    }
    if ((actual is () && expected is Field[]) || (actual is Field[] && expected is ())) {
        return false;
    }

    Field[] actualFields = <Field[]> actual;
    Field[] expectedFields = <Field[]> expected;

    if (actualFields.length() != expectedFields.length()) {
        return false;
    }
    int length = actualFields.length() - 1;

    foreach int i in 0 ... length {
        if (!isEqualField(actualFields[i], expectedFields[i])) {
            return false;
        }
    }
    return true;
}

isolated function isEqualField(Field actualField, Field expectedField) returns boolean {
    if (actualField.name != expectedField.name) {
        return false;
    }
    if (!isEqualFields(actualField?.fields, expectedField?.fields)) {
        return false;
    }
    if (!isEqualInputs(actualField?.inputs, expectedField?.inputs)) {
        return false;
    }
    if (!compareTypedesc(actualField.kind, expectedField.kind)) {
        return false;
    }
    return true;
}

isolated function isEqualInputs(Input[]? actual, Input[]? expected) returns boolean {
    if (actual is () && expected is ()) {
        return true;
    }
    if ((actual is () && expected is Input[]) || (actual is Input[] && expected is ())) {
        return false;
    }
    Input[] actualInputs = <Input[]> actual;
    Input[] expectedInputs = <Input[]> expected;
    if (actualInputs.length() != expectedInputs.length()) {
        return false;
    }

    int length = actualInputs.length() - 1;
    foreach int i in 0 ... length {
        if (!isEqualInput(actualInputs[i], expectedInputs[i])) {
            return false;
        }
    }
    return true;
}

isolated function isEqualInput(Input actualInput, Input expectedInput) returns boolean {
    if (actualInput.name != expectedInput.name) {
        return false;
    }
    if (!compareTypedesc(actualInput.kind, expectedInput.kind)) {
        return false;
    }
    return true;
}
