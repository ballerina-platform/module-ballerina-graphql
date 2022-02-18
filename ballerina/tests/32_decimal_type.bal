// Copyright (c) 2022, WSO2 Inc. (http://www.wso2.org) All Rights Reserved.
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
import ballerina/lang.value;

@test:Config {
    groups: ["inputs", "decimal"]
}
isolated function testDecimalTypeInput() returns error? {
    string document = "{ convertDecimalToFloat(value: 1.33) }";
    string url = "http://localhost:9091/decimal_inputs";
    json actualPayload = check getJsonPayloadFromService(url, document);
    map<value:JsonFloat> payloadWithFloatValues = check actualPayload.cloneWithType();
    json expectedPayload = {
        data: {
            convertDecimalToFloat: 1.33
        }
    };
    assertJsonValuesWithOrder(payloadWithFloatValues, expectedPayload);
}

@test:Config {
    groups: ["inputs", "decimal"]
}
isolated function testDecimalTypeVariableInput() returns error? {
    string document = "($val:Decimal!){ convertDecimalToFloat(value:$val) }";
    json variables = {
        val: 2.3332414141451451411231341451
    };
    string url = "http://localhost:9091/decimal_inputs";
    json actualPayload = check getJsonPayloadFromService(url, document, variables);
    map<value:JsonFloat> payloadWithFloatValues = check actualPayload.cloneWithType();
    json expectedPayload = {
        data: {
            convertDecimalToFloat: 2.3332414141451451411231341451
        }
    };
    assertJsonValuesWithOrder(payloadWithFloatValues, expectedPayload);
}

@test:Config {
    groups: ["inputs", "decimal"]
}
isolated function testDecimalTypeDefaultValue() returns error? {
    string document = "($val:Decimal! = 2.3332414141451451411231341451){ convertDecimalToFloat(value:$val) }";
    string url = "http://localhost:9091/decimal_inputs";
    json actualPayload = check getJsonPayloadFromService(url, document);
    map<value:JsonFloat> payloadWithFloatValues = check actualPayload.cloneWithType();
    json expectedPayload = {
        data: {
            convertDecimalToFloat: 2.3332414141451451411231341451
        }
    };
    assertJsonValuesWithOrder(payloadWithFloatValues, expectedPayload);
}

@test:Config {
    groups: ["inputs", "input_coerce", "list", "decimal"]
}
isolated function testDecimalTypeListInput() returns error? {
    string document = "{ getTotalInDecimal(prices: [[1.33, 4.8], [5.6, 6], [5, 7, 8]]) }";
    string url = "http://localhost:9091/decimal_inputs";
    json actualPayload = check getJsonPayloadFromService(url, document);
    map<value:JsonDecimal> payloadWithDecimalValues = check actualPayload.cloneWithType();
    json expectedPayload = {
        data: {
            getTotalInDecimal: [6.13, 11.6, 20.0]
        }
    };
    assertJsonValuesWithOrder(payloadWithDecimalValues, expectedPayload);
}

@test:Config {
    groups: ["inputs", "input_coerce", "list", "variables", "decimal"]
}
isolated function testDecimalTypeListWithVariableInput() returns error? {
    string document = "($prices:[[Decimal!]!]!){ getTotalInDecimal(prices:$prices) }";
    string url = "http://localhost:9091/decimal_inputs";
    json variables = {
        prices: [[1.3323232, 4.856343], [5.63535, 6], [5, 7, 8]] 
    };
    json actualPayload = check getJsonPayloadFromService(url, document, variables);
    map<value:JsonDecimal> payloadWithDecimalValues = check actualPayload.cloneWithType();
    json expectedPayload = {
        data: {
            getTotalInDecimal: [6.1886662, 11.63535, 20.0]
        }
    };
    assertJsonValuesWithOrder(payloadWithDecimalValues, expectedPayload);
}

@test:Config {
    groups: ["inputs", "input_coerce", "list", "decimal"]
}
isolated function testDecimalTypeListWithDefaultInput() returns error? {
    string document = check getGraphQLDocumentFromFile("decimal_types.graphql");
    string url = "http://localhost:9091/decimal_inputs";
    json actualPayload = check getJsonPayloadFromService(url, document, operationName = "getTotalInDecimal");
    map<value:JsonDecimal> payloadWithDecimalValues = check actualPayload.cloneWithType();
    json expectedPayload = {
        data: {
            getTotalInDecimal: [6.1886662, 11.63535, 20.0]
        }
    };
    assertJsonValuesWithOrder(payloadWithDecimalValues, expectedPayload);
}

@test:Config {
    groups: ["inputs", "input_coerce", "input_object", "decimal"]
}
isolated function testDecimalTypeWithInputObject() returns error? {
    string document = check getGraphQLDocumentFromFile("decimal_types.graphql");
    string url = "http://localhost:9091/decimal_inputs";
    json actualPayload = check getJsonPayloadFromService(url, document, operationName = "getSubTotal");
    map<value:JsonDecimal> payloadWithDecimalValues = check actualPayload.cloneWithType();
    json expectedPayload = {
        data: {
            getSubTotal: 218.5555332
        }
    };
    assertJsonValuesWithOrder(payloadWithDecimalValues, expectedPayload);
}

@test:Config {
    groups: ["inputs", "input_coerce", "input_object", "decimal"]
}
isolated function testDecimalTypeWithInputObjectVariable() returns error? {
    string document = "($items:[Item!]!){ getSubTotal(items: $items) }";
    string url = "http://localhost:9091/decimal_inputs";
    json variables = {
        items: [
            {name: "soap", price: 64.5555332 },
            { name: "sugar", price: 154 }
        ]
    };
    json actualPayload = check getJsonPayloadFromService(url, document, variables);
    map<value:JsonDecimal> payloadWithDecimalValues = check actualPayload.cloneWithType();
    json expectedPayload = {
        data: {
            getSubTotal: 218.5555332
        }
    };
    assertJsonValuesWithOrder(payloadWithDecimalValues, expectedPayload);
}

@test:Config {
    groups: ["inputs", "input_coerce", "input_object", "decimal"]
}
isolated function testDecimalTypeWithInputObjectDefaultValue() returns error? {
    string document = check getGraphQLDocumentFromFile("decimal_types.graphql");
    string url = "http://localhost:9091/decimal_inputs";
    json actualPayload = check getJsonPayloadFromService(url, document, operationName = "getSubTotalWithDefaultValue");
    map<value:JsonDecimal> payloadWithDecimalValues = check actualPayload.cloneWithType();
    json expectedPayload = {
        data: {
            getSubTotal: 218.5555332
        }
    };
    assertJsonValuesWithOrder(payloadWithDecimalValues, expectedPayload);
}

@test:Config {
    groups: ["inputs", "input_coerce", "decimal"]
}
isolated function testCoerceIntToDecimal() returns error? {
    string document = "{ convertDecimalToFloat(value: 1) }";
    string url = "http://localhost:9091/decimal_inputs";
    json actualPayload = check getJsonPayloadFromService(url, document);
    map<value:JsonFloat> payloadWithFloatValues = check actualPayload.cloneWithType();
    json expectedPayload = {
        data: {
            convertDecimalToFloat: 1.0
        }
    };
    assertJsonValuesWithOrder(payloadWithFloatValues, expectedPayload);
}

@test:Config {
    groups: ["inputs", "input_coerce", "decimal"]
}
isolated function testCoerceIntToDecimalWithVariableInput() returns error? {
    string document = "($val:Decimal!){ convertDecimalToFloat(value:$val) }";
    json variables = {
        val: 2
    };
    string url = "http://localhost:9091/decimal_inputs";
    json actualPayload = check getJsonPayloadFromService(url, document, variables);
    map<value:JsonFloat> payloadWithFloatValues = check actualPayload.cloneWithType();
    json expectedPayload = {
        data: {
            convertDecimalToFloat: 2.0
        }
    };
    assertJsonValuesWithOrder(payloadWithFloatValues, expectedPayload);
}

@test:Config {
    groups: ["inputs", "input_coerce", "decimal"]
}
isolated function testCoerceIntToDecimalWithDefaultValue() returns error? {
    string document = "($val:Decimal! = 5){ convertDecimalToFloat(value:$val) }";
    string url = "http://localhost:9091/decimal_inputs";
    json actualPayload = check getJsonPayloadFromService(url, document);
    map<value:JsonFloat> payloadWithFloatValues = check actualPayload.cloneWithType();
    json expectedPayload = {
        data: {
            convertDecimalToFloat: 5.0
        }
    };
    assertJsonValuesWithOrder(payloadWithFloatValues, expectedPayload);
}

@test:Config {
    groups: ["inputs", "input_coerce", "decimal"]
}
isolated function testCoerceDecimalToFloat() returns error? {
    string document = "($weight:Float!){ weightInPounds(weightInKg:$weight) }";
    string url = "http://localhost:9091/inputs";
    json variables = {
        weight: 56.4d 
    };
    json actualPayload = check getJsonPayloadFromService(url, document, variables);
    map<value:JsonFloat> payloadWithFloatValues = check actualPayload.cloneWithType();
    json expectedPayload = {
        data: {
            weightInPounds: 124.362
        }
    };
    assertJsonValuesWithOrder(payloadWithFloatValues, expectedPayload);
}

@test:Config {
    groups: ["inputs", "input_coerce", "decimal"]
}
isolated function testDecimalWithNegativeZero() returns error? {
    string document = "($val:Decimal!){ convertDecimalToFloat(value:$val) }";
    string url = "http://localhost:9091/decimal_inputs";
    json variables = {
        val: -0 
    };
    json actualPayload = check getJsonPayloadFromService(url, document, variables);
    map<value:JsonFloat> payloadWithFloatValues = check actualPayload.cloneWithType();
    json expectedPayload = {
        data: {
            convertDecimalToFloat: 0.0
        }
    };
    assertJsonValuesWithOrder(payloadWithFloatValues, expectedPayload);
}

@test:Config {
    groups: ["inputs", "input_coerce", "decimal"]
}
isolated function testDecimalWithMarginalValue() returns error? {
    string document = "($val:Decimal!){ convertDecimalToFloat(value:$val) }";
    string url = "http://localhost:9091/decimal_inputs";
    json variables = {
        val: 1.797693134862314E+308 
    };
    json actualPayload = check getJsonPayloadFromService(url, document, variables);
    map<value:JsonFloat> payloadWithFloatValues = check actualPayload.cloneWithType();
    json expectedPayload = {
        data: {
            convertDecimalToFloat: 1.797693134862314E308
        }
    };
    assertJsonValuesWithOrder(payloadWithFloatValues, expectedPayload);
}

@test:Config {
    groups: ["inputs", "input_coerce", "decimal"]
}
isolated function testDecimalWithPositiveInfinity() returns error? {
    string document = "{ convertDecimalToFloat(value: 1.7E309) }";
    string url = "http://localhost:9091/decimal_inputs";
    json actualPayload = check getJsonPayloadFromBadRequest(url, document);
    json expectedPayload = check getJsonContentFromFile("decimal_with_positive_infinity.json");
    assertJsonValuesWithOrder(actualPayload, expectedPayload);
}

@test:Config {
    groups: ["inputs", "input_coerce", "decimal"]
}
isolated function testDecimalWithNegativeInfinity() returns error? {
    string document = "{ convertDecimalToFloat(value: -1.7E309) }";
    string url = "http://localhost:9091/decimal_inputs";
    json actualPayload = check getJsonPayloadFromBadRequest(url, document);
    json expectedPayload = check getJsonContentFromFile("decimal_with_negative_infinity.json");
    assertJsonValuesWithOrder(actualPayload, expectedPayload);
}
