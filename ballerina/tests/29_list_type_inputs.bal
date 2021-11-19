// Copyright (c) 2021, WSO2 Inc. (http://www.wso2.org) All Rights Reserved.
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
    groups: ["list", "input"]
}
isolated function testListTypeInput() returns error? {
    string document = string`query { concat(words: ["Hello!", "This", "is", "Ballerina", "GraphQL"]) }`;
    string url = "http://localhost:9091/list_inputs";
    json actualPayload = check getJsonPayloadFromService(url, document);
    json expectedPayload = {
        data: {
            concat: "Hello! This is Ballerina GraphQL"
        }
    };
    assertJsonValuesWithOrder(actualPayload, expectedPayload);
}

@test:Config {
    groups: ["list", "input"]
}
isolated function testListTypeInputWithEmptyValue() returns error? {
    string document = string`query { concat(words: []) }`;
    string url = "http://localhost:9091/list_inputs";
    json actualPayload = check getJsonPayloadFromService(url, document);
    json expectedPayload = {
        data: {
            concat: "Word list is empty"
        }
    };
    assertJsonValuesWithOrder(actualPayload, expectedPayload);
}

@test:Config {
    groups: ["list", "input"]
}
isolated function testListTypeInputWithNullValue() returns error? {
    string document = string`query { concat(words: ["Hello!", "This", "is", "a", "Null", "Value", "->", null]) }`;
    string url = "http://localhost:9091/list_inputs";
    json actualPayload = check getJsonPayloadFromService(url, document);
    json expectedPayload = {
        data: {
            concat: "Hello! This is a Null Value ->"
        }
    };
    assertJsonValuesWithOrder(actualPayload, expectedPayload);
}

@test:Config {
    groups: ["list", "input"]
}
isolated function testNullableListTypeInputWithoutValue() returns error? {
    string document = string`query { concat }`;
    string url = "http://localhost:9091/list_inputs";
    json actualPayload = check getJsonPayloadFromService(url, document);
    json expectedPayload = {
        data: {
            concat: "Word list is empty"
        }
    };
    assertJsonValuesWithOrder(actualPayload, expectedPayload);
}

@test:Config {
    groups: ["list", "input"]
}
isolated function testNullableListTypeInputWithInvalidValue() returns error? {
    string document = string`query { concat(words: ["Hello!", 5, true, {}, "GraphQL"]) }`;
    string url = "http://localhost:9091/list_inputs";
    json actualPayload = check getJsonPayloadFromBadRequest(url, document);
    json expectedPayload = check getJsonContentFromFile("nullable_list_type_input_with_invalid_value.json");
    assertJsonValuesWithOrder(actualPayload, expectedPayload);
}

@test:Config {
    groups: ["list", "input"]
}
isolated function testListTypeInputsWithNestedList() returns error? {
    string document = string`query { getTotal(prices: [[2,3,4], [4, 5, 6, 7], [3,5,6,4,2,7]]) }`;
    string url = "http://localhost:9091/list_inputs";
    json actualPayload = check getJsonPayloadFromService(url, document);
    json expectedPayload = {
        data: {
            getTotal: [9.0, 22.0, 27.0]
        }
    };
    assertJsonValuesWithOrder(actualPayload, expectedPayload);
}

@test:Config {
    groups: ["list", "input"]
}
isolated function testNestedListInputWithInvalidValues1() returns error? {
    string document = string`query { getTotal(prices: [[2, 3, d], [4, 5, 6, "is"], [3, 5, 6, 4 , true, 7]]) }`;
    string url = "http://localhost:9091/list_inputs";
    json actualPayload = check getJsonPayloadFromBadRequest(url, document);
    json expectedPayload = check getJsonContentFromFile("nested_list_input_with_invalid_values1.json");
    assertJsonValuesWithOrder(actualPayload, expectedPayload);
}

@test:Config {
    groups: ["list", "input"]
}
isolated function testNestedListInputWithInvalidValues2() returns error? {
    string document = string`query { getTotal(prices: [ 2, 3, 4, 5, 6]) }`;
    string url = "http://localhost:9091/list_inputs";
    json actualPayload = check getJsonPayloadFromBadRequest(url, document);
    json expectedPayload = check getJsonContentFromFile("nested_list_input_with_invalid_values2.json");
    assertJsonValuesWithOrder(actualPayload, expectedPayload);
}

@test:Config {
    groups: ["list", "variables", "input"]
}
isolated function testListTypeInputWithVariable() returns error? {
    string document = string`query ($words:[String!]){ concat(words: $words) }`;
    string url = "http://localhost:9091/list_inputs";
    json variables = {
        words: ["Hello!", "This", "is", "Ballerina", "GraphQL"]
    };
    json actualPayload = check getJsonPayloadFromService(url, document, variables);
    json expectedPayload = {
        data: {
            concat: "Hello! This is Ballerina GraphQL"
        }
    };
    assertJsonValuesWithOrder(actualPayload, expectedPayload);
}

@test:Config {
    groups: ["list", "variables", "input"]
}
isolated function testListTypeInputWithInvalidVaraibles() returns error? {
    string document = string`query ($words: [String]){ concat(words: $words) }`;
    string url = "http://localhost:9091/list_inputs";
    json variables = {
        words: ["Hello!", true, "is", 4, "GraphQL"]
    };
    json actualPayload = check getJsonPayloadFromBadRequest(url, document, variables);
    json expectedPayload = check getJsonContentFromFile("list_type_input_with_invalid_variables.json");
    assertJsonValuesWithOrder(actualPayload, expectedPayload);
}

@test:Config {
    groups: ["list", "input_objects", "input"]
}
isolated function testListTypeWithInputObjects() returns error? {
    string document = string`query { getSuggestions(tvSeries: [{ name: "Breaking Bad", episodes: [{title:"ep1"}] }]) { movieName } }`;
    string url = "http://localhost:9091/list_inputs";
    json actualPayload = check getJsonPayloadFromService(url, document);
    json expectedPayload = {
        data: {
            getSuggestions: [
                {
                    movieName: "El Camino"
                }
            ]
        }
    };
    assertJsonValuesWithOrder(actualPayload, expectedPayload);
}

@test:Config {
    groups: ["list", "variables", "input_objects", "input"]
}
isolated function testListTypeWithInvalidInputObjectsValue() returns error? {
    string document = string`query { getSuggestions(tvSeries: [{ name: "Breaking Bad", episodes: [{title:"ep1"}]}, { name: "Breaking Bad", episodes:true }]) { movieName } }`;
    string url = "http://localhost:9091/list_inputs";
    json actualPayload = check getJsonPayloadFromBadRequest(url, document);
    json expectedPayload = {
        errors: [
            {
                message: "tvSeries: In element #1:[Episode!] cannot represent non [Episode!] value: true",
                locations: [
                    {
                        line: 1,
                        column: 120
                    }
                ]
            }
        ]
    };
    assertJsonValuesWithOrder(actualPayload, expectedPayload);
}

@test:Config {
    groups: ["list", "input_objects", "input"]
}
isolated function testListTypeWithNestedListInInputObject() returns error? {
    string document = string`query { getSuggestions(tvSeries: [{ name: "GOT", episodes: [{title:"ep1", newCharacters:["Sherlock", "Jessie"]}, {title:"ep2", newCharacters:["Michael", "Jessie"]}]}]) { movieName } }`;
    string url = "http://localhost:9091/list_inputs";
    json actualPayload = check getJsonPayloadFromService(url, document);
    json expectedPayload = {
        data: {
            getSuggestions: [
                {
                    movieName: "Escape Plan"
                },
                {
                    movieName: "Papillon"
                },
                {
                    movieName: "The Fugitive"
                }
            ]
        }
    };
    assertJsonValuesWithOrder(actualPayload, expectedPayload);
}

@test:Config {
    groups: ["list", "variables", "input_objects", "input"]
}
isolated function testVariablesInsideListValue() returns error? {
    string document = check getGraphQLDocumentFromFile("variables_inside_list_value.graphql");
    string url = "http://localhost:9091/list_inputs";
    json variables = {
        name2: "Jessie"
    };
    json actualPayload = check getJsonPayloadFromService(url, document, variables);
    json expectedPayload = {
        data: {
            getSuggestions: [
                {
                    movieName: "Escape Plan"
                },
                {
                    movieName: "Papillon"
                },
                {
                    movieName: "The Fugitive"
                }
            ]
        }
    };
    assertJsonValuesWithOrder(actualPayload, expectedPayload);
}

@test:Config {
    groups: ["list", "input_objects", "input"]
}
isolated function testListTypeWithInvalidNestedListInInputObject() returns error? {
    string document = string`query { getSuggestions(tvSeries: [{ name: "GOT", episodes: [{title:"ep1", newCharacters:["Sherlock", "Jessie"]}, {title:"ep2", newCharacters:[true, 4]}]}]) { movieName } }`;
    string url = "http://localhost:9091/list_inputs";
    json actualPayload = check getJsonPayloadFromBadRequest(url, document);
    json expectedPayload = check getJsonContentFromFile("list_type_with_invalid_nested_list_in_input_object.json");
    assertJsonValuesWithOrder(actualPayload, expectedPayload);
}

@test:Config {
    groups: ["list", "variables", "input_objects", "input"]
}
isolated function testListTypeVariablesWithInputObjects() returns error? {
    string document = string`query ($tvSeries: [TvSeries!]!){ getSuggestions(tvSeries: $tvSeries) { movieName } }`;
    string url = "http://localhost:9091/list_inputs";
    json variables = {
        tvSeries: [
            { 
                name: "Breaking Bad",
                episodes: [
                    {
                        title:"ep1"
                    }
                ] 
            }
        ]
    };
    json actualPayload = check getJsonPayloadFromService(url, document, variables);
    json expectedPayload = {
        data: {
            getSuggestions: [
                {
                    movieName: "El Camino"
                }
            ]
        }
    };
    assertJsonValuesWithOrder(actualPayload, expectedPayload);
}

@test:Config {
    groups: ["list", "variables", "input_objects", "input"]
}
isolated function testListTypeVariablesWithInvalidInputObjectsValue() returns error? {
    string document = string`query ($tvSeries: [TvSeries!]!){ getSuggestions(tvSeries: $tvSeries) { movieName } }`;
    string url = "http://localhost:9091/list_inputs";
    json variables = {
        tvSeries: [
            { 
                name: "Breaking Bad", 
                episodes: [
                    {
                        title:"ep1"
                    }
                ]
            },
            { 
                name: "Breaking Bad", 
                episodes:true 
            }
        ]
    };
    json actualPayload = check getJsonPayloadFromBadRequest(url, document, variables);
    json expectedPayload = {
        errors: [
            {
                message: "tvSeries: In element #1:[Episode!] cannot represent non [Episode!] value: true",
                locations: [
                    {
                        line: 1,
                        column: 60
                    }
                ]
            }
        ]
    };
    assertJsonValuesWithOrder(actualPayload, expectedPayload);
}

@test:Config {
    groups: ["list", "input_objects", "input"]
}
isolated function testListTypeVariablesWithNestedListInInputObject() returns error? {
    string document = string`query ($tvSeries: [TvSeries!]!){ getSuggestions(tvSeries: $tvSeries) { movieName } }`;
    string url = "http://localhost:9091/list_inputs";
    json variables = {
        tvSeries: [
            { 
                name: "GOT", 
                episodes: [
                    {
                        title:"ep1", 
                        newCharacters: ["Sherlock", "Jessie"]
                    },
                    {
                        title:"ep2", 
                        newCharacters: ["Michael", "Jessie"]
                    }
                ]
            }
        ]
    };
    json actualPayload = check getJsonPayloadFromService(url, document, variables);
    json expectedPayload = {
        data: {
            getSuggestions: [
                {
                    movieName: "Escape Plan"
                },
                {
                    movieName: "Papillon"
                },
                {
                    movieName: "The Fugitive"
                }
            ]
        }
    };
    assertJsonValuesWithOrder(actualPayload, expectedPayload);
}

@test:Config {
    groups: ["list", "input_objects", "input"]
}
isolated function testListTypeVariableWithInvalidNestedListInInputObject() returns error? {
    string document = string`query ($tvSeries: [TvSeries!]!) { getSuggestions(tvSeries: $tvSeries) { movieName } }`;
    string url = "http://localhost:9091/list_inputs";
    json variables = {
        tvSeries: [
            { 
                name: "GOT", 
                episodes: [
                    {
                        title:"ep1", 
                        newCharacters: ["Sherlock", "Jessie"]
                    },
                    {
                        title:"ep2", 
                        newCharacters: [true, 1]
                    }
                ]
            }
        ]
    };
    json actualPayload = check getJsonPayloadFromBadRequest(url, document, variables);
    json expectedPayload = check getJsonContentFromFile("list_type_variable_with_invalid_nested_list_in_input_object.json");
    assertJsonValuesWithOrder(actualPayload, expectedPayload);
}

@test:Config {
    groups: ["list", "input_objects", "input"]
}
isolated function testListTypeWithinInputObjects() returns error? {
    string document = string`query { getMovie(tvSeries: { name: "Breaking Bad", episodes: [{title:"Cancer Man"}] }) { movieName, director } }`;
    string url = "http://localhost:9091/list_inputs";
    json actualPayload = check getJsonPayloadFromService(url, document);
    json expectedPayload = {
        data: {
            getMovie: [
                {
                    movieName: "El Camino",
                    director: "Vince Gilligan"
                }
            ]
        }
    };
    assertJsonValuesWithOrder(actualPayload, expectedPayload);
}

@test:Config {
    groups: ["list", "input_objects", "input"]
}
isolated function testInvalidEmptyListTypeWithinInputObjects() returns error? {
    string document = string`query { getMovie(tvSeries: { name: "Breaking Bad", episodes: [{title:"Cancer Man", newCharacters:[]}] }) { movieName, director } }`;
    string url = "http://localhost:9091/list_inputs";
    json actualPayload = check getJsonPayloadFromBadRequest(url, document);
    json expectedPayload = {
        errors: [
            {
                message: "[String!] cannot represent non [String!] value: []",
                locations: [
                    {
                        line: 1,
                        column: 99
                    }
                ]
            }
        ]
    };
    assertJsonValuesWithOrder(actualPayload, expectedPayload);
}

@test:Config {
    groups: ["list", "input_objects", "input"]
}
isolated function testInvalidListTypeWithinInputObjects() returns error? {
    string document = string`query { getMovie(tvSeries: { name: "Breaking Bad", episodes: [{title:"Cancer Man", newCharacters:[true, graphql]}] }) { movieName, director } }`;
    string url = "http://localhost:9091/list_inputs";
    json actualPayload = check getJsonPayloadFromBadRequest(url, document);
    json expectedPayload = check getJsonContentFromFile("invalid_list_type_within_input_objects.json");
    assertJsonValuesWithOrder(actualPayload, expectedPayload);
}

@test:Config {
    groups: ["list", "input_objects", "input"]
}
isolated function testInvalidListTypeForInputObjects() returns error? {
    string document = string`query { getMovie(tvSeries: [{ name: "Breaking Bad", episodes: [{title:"Cancer Man", newCharacters:[true, graphql]}] }]) { movieName, director } }`;
    string url = "http://localhost:9091/list_inputs";
    json actualPayload = check getJsonPayloadFromBadRequest(url, document);
    json expectedPayload = {
        errors: [
            {
                message: "TvSeries! cannot represent non TvSeries! value.",
                locations: [
                    {
                        line: 1,
                        column: 18
                    }
                ]
            }
        ]
    };
    assertJsonValuesWithOrder(actualPayload, expectedPayload);
}

@test:Config {
    groups: ["list", "input_objects", "input"]
}
isolated function testInvalidValueWithNestedListInInputObjects() returns error? {
    string document = string`query { getMovie(tvSeries: { name: "Breaking Bad", episodes: {title:"Cancer Man", newCharacters:["paul"]}}) { movieName, director } }`;
    string url = "http://localhost:9091/list_inputs";
    json actualPayload = check getJsonPayloadFromBadRequest(url, document);
    json expectedPayload = {
        errors: [
            {
                message: "[Episode!] cannot represent non [Episode!] value.",
                locations: [
                    {
                        line: 1,
                        column: 52
                    }
                ]
            }
        ]
    };
    assertJsonValuesWithOrder(actualPayload, expectedPayload);
}

@test:Config {
    groups: ["list", "variables", "input_objects", "input"]
}
isolated function testListTypeWithinInputObjectsWithVariables() returns error? {
    string document = string`query ($tvSeries: TvSeries!){ getMovie(tvSeries: $tvSeries ) { movieName, director } }`;
    string url = "http://localhost:9091/list_inputs";
    json variables = {
        tvSeries:{ 
            name: "Braking Bad", 
            episodes: [
                {
                    title:"Cancer Man", 
                    newCharacters: ["Sherlock", "Jessie"]
                }
            ]
        }
    };
    json actualPayload = check getJsonPayloadFromService(url, document, variables);
    json expectedPayload = {
        data: {
            getMovie: [
                {
                    movieName: "Sherlock Holmes",
                    director: "Dexter Fletcher"
                }
            ]
        }
    };
    assertJsonValuesWithOrder(actualPayload, expectedPayload);
}

@test:Config {
    groups: ["list", "variables", "input_objects", "input"]
}
isolated function testInvalidEmptyListTypeWithinInputObjectsWithVariables() returns error? {
    string document = string`query ($tvSeries: TvSeries!) { getMovie(tvSeries: $tvSeries) { movieName, director } }`;
    string url = "http://localhost:9091/list_inputs";
    json varaibles = {
        tvSeries: {
            name: "Breaking Bad",
            episodes: [
                {
                    title:"Cancer Man",
                    newCharacters:[]
                }
            ]
        }
    };
    json actualPayload = check getJsonPayloadFromBadRequest(url, document, varaibles);
    json expectedPayload = {
        errors: [
            {
                message: "[String!] cannot represent non [String!] value: []",
                locations: [
                    {
                        line: 1,
                        column: 52
                    }
                ]
            }
        ]
    };
    assertJsonValuesWithOrder(actualPayload, expectedPayload);
}

@test:Config {
    groups: ["list", "variables", "input_objects", "input"]
}
isolated function testInvalidListTypeWithinInputObjectsWithVariables() returns error? {
    string document = string`query ($tvSeries: TvSeries!) { getMovie(tvSeries: $tvSeries) { movieName, director } }`;
    string url = "http://localhost:9091/list_inputs";
    json varaibles = {
        tvSeries: {
            name: "Breaking Bad",
            episodes: [
                {
                    title:"Cancer Man",
                    newCharacters: [true, 44]
                }
            ]
        }
    };
    json actualPayload = check getJsonPayloadFromBadRequest(url, document, varaibles);
    json expectedPayload = check getJsonContentFromFile("invalid_list_type_within_input_objects_with_variables.json");
    assertJsonValuesWithOrder(actualPayload, expectedPayload);
}

@test:Config {
    groups: ["list", "input"]
}
isolated function testListTypeWithEnumValues() returns error? {
    string document = string`query { isIncludeHoliday(days: [MONDAY, FRIDAY, TUESDAY, SATURDAY]) }`;
    string url = "http://localhost:9091/list_inputs";
    json actualPayload = check getJsonPayloadFromService(url, document);
    json expectedPayload = {
        data: {
            isIncludeHoliday: true
        }
    };
    assertJsonValuesWithOrder(actualPayload, expectedPayload);
}

@test:Config {
    groups: ["list", "input"]
}
isolated function testListTypeWithInvalidEnumValues() returns error? {
    string document = string`query { isIncludeHoliday(days: [MONDAY, FRIDAY, TUESDAY, SATURDAY, WEdnesday, 4]) }`;
    string url = "http://localhost:9091/list_inputs";
    json actualPayload = check getJsonPayloadFromBadRequest(url, document);
    json expectedPayload = check getJsonContentFromFile("list_type_with_invalid_enum_values.json");
    assertJsonValuesWithOrder(actualPayload, expectedPayload);
}

@test:Config {
    groups: ["list", "variables", "input"]
}
isolated function testListTypeWithVariableDefaultValues1() returns error? {
    string document = string`query ($words: [String] = ["Hello!", "This", "is", "Ballerina", "GraphQL"]){ concat(words: $words) }`;
    string url = "http://localhost:9091/list_inputs";
    json actualPayload = check getJsonPayloadFromService(url, document);
    json expectedPayload = {
        data: {
            concat: "Hello! This is Ballerina GraphQL"
        }
    };
    assertJsonValuesWithOrder(actualPayload, expectedPayload);
}

@test:Config {
    groups: ["list", "variables", "input"]
}
isolated function testListTypeWithVariableDefaultValues2() returns error? {
    string document = string`query ($words: [String] = []){ concat(words: $words) }`;
    string url = "http://localhost:9091/list_inputs";
    json actualPayload = check getJsonPayloadFromService(url, document);
    json expectedPayload = {
        data: {
            concat: "Word list is empty"
        }
    };
    assertJsonValuesWithOrder(actualPayload, expectedPayload);
}

@test:Config {
    groups: ["list", "variables", "input"]
}
isolated function testListTypeWithVariableDefaultValues3() returns error? {
    string document = string`query ($words: [String] = [null, null, "Hello", "GraphQL"]){ concat(words: $words) }`;
    string url = "http://localhost:9091/list_inputs";
    json actualPayload = check getJsonPayloadFromService(url, document);
    json expectedPayload = {
        data: {
            concat: "Hello GraphQL"
        }
    };
    assertJsonValuesWithOrder(actualPayload, expectedPayload);
}

@test:Config {
    groups: ["list", "variables", "input"]
}
isolated function testListTypeWithVariableDefaultValues4() returns error? {
    string document = string`query ($prices: [[Float!]!] = [[1, 2, 3], [34, 56, 65]]){ getTotal(prices: $prices) }`;
    string url = "http://localhost:9091/list_inputs";
    json actualPayload = check getJsonPayloadFromService(url, document);
    json expectedPayload = {
        data: {
            getTotal: [6.0, 155.0]
        }
    };
    assertJsonValuesWithOrder(actualPayload, expectedPayload);
}

@test:Config {
    groups: ["list", "variables", "input"]
}
isolated function testListTypeWithVariableDefaultValues5() returns error? {
    string document = string`query ($profileDetail: [ProfileDetail!] = [{name: "Jessie", age: 28}, {name: "Arthur", age: 5}]){ searchProfile(profileDetail: $profileDetail) { name, age} }`;
    string url = "http://localhost:9091/list_inputs";
    json actualPayload = check getJsonPayloadFromService(url, document);
    json expectedPayload = {
        data: {
            searchProfile: [
                {
                    name: "Jessie Pinkman",
                    age: 26
                },
                {
                    name: "Sherlock Holmes",
                    age: 40
                }
            ]
        }
    };
    assertJsonValuesWithOrder(actualPayload, expectedPayload);
}

@test:Config {
    groups: ["list", "variables", "input"]
}
isolated function testListTypeWithVariableDefaultValues6() returns error? {
    string document = string`query ($profileDetail: [ProfileDetail!] = [{name: "Jessie", age: 28}, {name: "Arthur", age: 5}]){ searchProfile(profileDetail: $profileDetail) { name, age} }`;
    string url = "http://localhost:9091/list_inputs";
    json actualPayload = check getJsonPayloadFromService(url, document);
    json expectedPayload = {
        data: {
            searchProfile: [
                {
                    name: "Jessie Pinkman",
                    age: 26
                },
                {
                    name: "Sherlock Holmes",
                    age: 40
                }
            ]
        }
    };
    assertJsonValuesWithOrder(actualPayload, expectedPayload);
}

@test:Config {
    groups: ["list", "variables", "input"]
}
isolated function testListTypeWithVariableDefaultValues7() returns error? {
    string document = check getGraphQLDocumentFromFile("list_type_with_variable_default_value_7.graphql");
    string url = "http://localhost:9091/list_inputs";
    json actualPayload = check getJsonPayloadFromService(url, document);
    json expectedPayload = check getJsonContentFromFile("list_type_with_variable_default_value_7.json");
    assertJsonValuesWithOrder(actualPayload, expectedPayload);
}

@test:Config {
    groups: ["list", "variables", "input_objects", "input"]
}
isolated function testListTypeWithVariableDefaultValues8() returns error? {
    string document = check getGraphQLDocumentFromFile("list_type_with_variable_default_value_8.graphql");
    string url = "http://localhost:9091/list_inputs";
    json actualPayload = check getJsonPayloadFromService(url, document);
    json expectedPayload = {
        data: {
            getMovie: [
                {
                    movieName: "Sherlock Holmes",
                    director: "Dexter Fletcher"
                }
            ]
        }
    };
    assertJsonValuesWithOrder(actualPayload, expectedPayload);
}

@test:Config {
    groups: ["list", "enum", "input"]
}
isolated function testListTypeWithVariableDefaultValues9() returns error? {
    string document = string`query ($days: [Weekday!] = [MONDAY, FRIDAY, TUESDAY, SATURDAY]){ isIncludeHoliday(days: $days) }`;
    string url = "http://localhost:9091/list_inputs";
    json actualPayload = check getJsonPayloadFromService(url, document);
    json expectedPayload = {
        data: {
            isIncludeHoliday: true
        }
    };
    assertJsonValuesWithOrder(actualPayload, expectedPayload);
}

@test:Config {
    groups: ["list", "enum", "input"]
}
isolated function testListTypeWithDefaultValue() returns error? {
    string document = string`query { isIncludeHoliday }`;
    string url = "http://localhost:9091/list_inputs";
    json actualPayload = check getJsonPayloadFromService(url, document);
    json expectedPayload = {
        data: {
            isIncludeHoliday: false
        }
    };
    assertJsonValuesWithOrder(actualPayload, expectedPayload);
}

@test:Config {
    groups: ["list", "variables", "input"]
}
isolated function testListTypeWithInvalidVariableDefaultValues1() returns error? {
    string document = string`query ($words: [String] = ["Hello!", "This", "is", Ballerina, true]){ concat(words: $words) }`;
    string url = "http://localhost:9091/list_inputs";
    json actualPayload = check getJsonPayloadFromBadRequest(url, document);
    json expectedPayload = check getJsonContentFromFile("list_type_with_invalid_variable_default_values_1.json");
    assertJsonValuesWithOrder(actualPayload, expectedPayload);
}

@test:Config {
    groups: ["list", "variables", "input"]
}
isolated function testListTypeWithInvalidVariableDefaultValues2() returns error? {
    string document = string`query ($words: [Int] = ["Hello!", "This", "is", "Ballerina", "GraphQL"]){ concat(words: $words) }`;
    string url = "http://localhost:9091/list_inputs";
    json actualPayload = check getJsonPayloadFromBadRequest(url, document);
    json expectedPayload = check getJsonContentFromFile("list_type_with_invalid_variable_default_values_2.json");
    assertJsonValuesWithOrder(actualPayload, expectedPayload);
}

@test:Config {
    groups: ["list", "variables", "input"]
}
isolated function testListTypeWithInvalidVariableDefaultValues3() returns error? {
    string document = string`query ($prices: [[Float!]!] = [[1, true, 3], false]){ getTotal(prices: $prices) }`;
    string url = "http://localhost:9091/list_inputs";
    json actualPayload = check getJsonPayloadFromBadRequest(url, document);
    json expectedPayload = check getJsonContentFromFile("list_type_with_invalid_variable_default_values_3.json");
    assertJsonValuesWithOrder(actualPayload, expectedPayload);
}

@test:Config {
    groups: ["list", "variables", "input"]
}
isolated function testListTypeWithInvalidVariableDefaultValues4() returns error? {
    string document = string`query ($prices: [[Float!]!] = [ 2, 3, 4, 5]){ getTotal(prices: $prices) }`;
    string url = "http://localhost:9091/list_inputs";
    json actualPayload = check getJsonPayloadFromBadRequest(url, document);
    json expectedPayload = check getJsonContentFromFile("list_type_with_invalid_variable_default_values_4.json");
    assertJsonValuesWithOrder(actualPayload, expectedPayload);
}

@test:Config {
    groups: ["list", "variables", "input"]
}
isolated function testListTypeWithInvalidVariableDefaultValues5() returns error? {
    string document = string`query ($prices: [[Float!]!] = [[], [4, 5], [null], null]){ getTotal(prices: $prices) }`;
    string url = "http://localhost:9091/list_inputs";
    json actualPayload = check getJsonPayloadFromBadRequest(url, document);
    json expectedPayload = check getJsonContentFromFile("list_type_with_invalid_variable_default_values_5.json");
    assertJsonValuesWithOrder(actualPayload, expectedPayload);
}

@test:Config {
    groups: ["list", "variables", "input"]
}
isolated function testListTypeWithInvalidVariableDefaultValues6() returns error? {
    string document = string`query ($prices: [[Float!]!] = null){ getTotal(prices: $prices) }`;
    string url = "http://localhost:9091/list_inputs";
    json actualPayload = check getJsonPayloadFromBadRequest(url, document);
    json expectedPayload = {
        errors: [
            {
                message: "[[Float!]!]! cannot represent non [[Float!]!]! value: null",
                locations: [
                    {
                        line: 1,
                        column: 31
                    }
                ]
            }
        ]
    };
    assertJsonValuesWithOrder(actualPayload, expectedPayload);
}

@test:Config {
    groups: ["list", "variables", "input"]
}
isolated function testListTypeWithInvalidVariableDefaultValues7() returns error? {
    string document = string`query ($profileDetail: [ProfileDetail] = [null, [], {name: "Arthur"}]){ searchProfile(profileDetail: $profileDetail) { name, age} }`;
    string url = "http://localhost:9091/list_inputs";
    json actualPayload = check getJsonPayloadFromBadRequest(url, document);
    json expectedPayload = check getJsonContentFromFile("list_type_with_invalid_variable_default_values_7.json");
    assertJsonValuesWithOrder(actualPayload, expectedPayload);
}

@test:Config {
    groups: ["list", "input"]
}
isolated function testListTypeWithInvalidVariableDefaultValue8() returns error? {
    string document = string`query ($days:[Weekday] = [MONDAY, FRIDAY, TUESDAY, SATURDAY]){ isIncludeHoliday(days: $days) }`;
    string url = "http://localhost:9091/list_inputs";
    json actualPayload = check getJsonPayloadFromBadRequest(url, document);
    json expectedPayload = {
        errors: [
            {
                message: "Variable \"days\" of type \"[Weekday]\" used in position expecting type \"[Weekday!]!\".",
                locations: [
                    {
                        line: 1,
                        column: 88
                    }
                ]
            }
        ]
    };
    assertJsonValuesWithOrder(actualPayload, expectedPayload);
}

@test:Config {
    groups: ["list", "input"]
}
isolated function testListTypeWithInvalidVariableDefaultValue9() returns error? {
    string document = string`query ($days:[Weekday!] = [MONDAY, FRIDAY, TUSDAY, SATURDAY]){ isIncludeHoliday(days: $days) }`;
    string url = "http://localhost:9091/list_inputs";
    json actualPayload = check getJsonPayloadFromBadRequest(url, document);
    json expectedPayload = {
        errors: [
            {
                message: "Value \"TUSDAY\" does not exist in \"days\" enum.",
                locations: [
                    {
                        line: 1,
                        column: 44
                    }
                ]
            }
        ]
    };
    assertJsonValuesWithOrder(actualPayload, expectedPayload);
}
