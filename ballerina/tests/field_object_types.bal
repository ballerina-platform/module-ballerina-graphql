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

readonly & __Field id = {
    name: "id",
    args: [],
    'type: NonNullScalarInt
};

readonly & __Field designation = {
    name: "designation",
    args: [],
    'type: ScalarString
};

readonly & __Field startDate = {
    name: "startDate",
    args: [],
    'type: ScalarString
};

readonly & __Field endDate = {
    name: "endDate",
    args: [],
    'type: ScalarString
};

readonly & __Field name = {
    name: "name",
    args: [],
    'type: ScalarString
};

readonly & __Field missions = {
    name: "missions",
    args: [],
    'type: MissionNonNullList
};

readonly & __Type ScalarString = {
    kind: "SCALAR",
    name: "String",
    description: "The `String` scalar type represents textual data, represented as UTF-8 character sequences." +
    "The String type is most often used by GraphQL to represent free-form human-readable text."
};

readonly & __Type ScalarInt = {
    kind: "SCALAR",
    name: "Int",
    description: "The `Int` scalar type represents non-fractional signed whole numeric values." +
    "Int can represent values between -(2^31) and 2^31 - 1."
};

readonly & __Type NonNullScalarInt = {
    kind: "NON_NULL",
    ofType: ScalarInt
};

readonly & __Type Mission = {
    kind: "OBJECT",
    name: "Mission",
    fields: [
        id,
        designation,
        startDate,
        endDate
    ],
    interfaces: []
};

readonly & __Type Astronaut = {
    kind: "OBJECT",
    name: "Astronaut",
    fields: [
        id,
        name,
        missions
    ],
    interfaces: []
};

readonly & __Type MissionNonNullList = {
    kind: "LIST",
    ofType: {
        kind: "NON_NULL",
        ofType: Mission
    }
};

readonly & __Type AstronautQuery = {
    kind: "OBJECT",
    name: "Query",
    fields: [
        {
            name: "astronauts",
            args: [],
            'type: AstronautNonNullList
        },
        {
            name: "missions",
            args: [],
            'type: MissionNonNullList
        }
    ]
};

readonly & __Type AstronautNonNullList = {
    kind: "LIST",
    ofType: {
        kind: "NON_NULL",
        ofType: Astronaut
    }
};

readonly & __Type PersonQuery = {
    kind: "OBJECT",
    name: "Query",
    fields: [
        {
            name: "person",
            args: [{
                name: "id",
                'type: {
                    kind: "NON_NULL",
                    ofType: {
                        kind: "SCALAR",
                        name: "Int"
                    }
                }
            }],
            'type: Person
        }
    ]
};

readonly & __Type Person = {
    kind: "OBJECT",
    name: "Person",
    fields: [
        name,
        address
    ],
    interfaces: []
};

readonly & __Type Address = {
    kind: "OBJECT",
    name: "Address",
    fields: [
        city
    ],
    interfaces: []
};

readonly & __Field person = {
    name: "person",
    args: [inputId],
    'type: Person
};

readonly & __InputValue inputId = {
    name: "id",
    'type: NonNullScalarInt
};

readonly & __Field address = {
    name: "address",
    args: [includeCity],
    'type: Address
};

readonly & __InputValue includeCity = {
    name: "includeCity",
    'type: NonNullScalarBoolean
};

readonly & __Type NonNullScalarBoolean = {
    kind: "SCALAR",
    name: "Boolean"
};

readonly & __Field city = {
    name: "city",
    args: [],
    'type: ScalarString
};
