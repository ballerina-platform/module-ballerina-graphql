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

__Field id = {
    name: "id",
    args: [],
    'type: NonNullScalarInt
};

__Field designation = {
    name: "designation",
    args: [],
    'type: ScalarString
};

__Field startDate = {
    name: "startDate",
    args: [],
    'type: ScalarString
};

__Field endDate = {
    name: "endDate",
    args: [],
    'type: ScalarString
};

__Field name = {
    name: "name",
    args: [],
    'type: ScalarString
};

__Field missions = {
    name: "missions",
    args: [],
    'type: MissionNonNullList
};

__Type ScalarString = {
    kind: "SCALAR",
    name: "String",
    description: "The `String` scalar type represents textual data, represented as UTF-8 character sequences." +
    "The String type is most often used by GraphQL to represent free-form human-readable text."
};

__Type ScalarInt = {
    kind: "SCALAR",
    name: "Int",
    description: "The `Int` scalar type represents non-fractional signed whole numeric values." +
    "Int can represent values between -(2^31) and 2^31 - 1."
};

__Type NonNullScalarInt = {
    kind: "NON_NULL",
    ofType: ScalarInt
};

__Type Mission = {
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

__Type Astronaut = {
    kind: "OBJECT",
    name: "Astronaut",
    fields: [
        id,
        name,
        missions
    ],
    interfaces: []
};

__Type MissionNonNullList = {
    kind: "LIST",
    ofType: {
        kind: "NON_NULL",
        ofType: Mission
    }
};

__Type AstronautNonNullList = {
    kind: "LIST",
    ofType: {
        kind: "NON_NULL",
        ofType: Astronaut
    }
};
