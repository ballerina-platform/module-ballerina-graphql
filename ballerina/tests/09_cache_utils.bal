// Copyright (c) 2024, WSO2 LLC. (http://www.wso2.org) All Rights Reserved.
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

import graphql.parser;

import ballerina/test;

@test:Config {
    groups: ["server_cache"]
}
function testCacheUtils() returns error? {
    parser:FieldNode[] fields = check getFieldNodesFromDocumentFile("cache_utils");
    test:assertTrue(fields.length() == 1);
    Field 'field = getField(fields[0], Person, ["person"], {maxAge: 10});
    test:assertTrue('field.isCacheEnabled());
    test:assertEquals('field.getCacheMaxAge(), 10d);
    test:assertEquals('field.getCacheKey(), "person.Jq9sXPlesvC6Q7cU5RPkZA==");
}

@test:Config {
    groups: ["server_cache"]
}
function testCacheConfigInferring() returns error? {
    parser:FieldNode[] fields = check getFieldNodesFromDocumentFile("cache_utils");
    test:assertTrue(fields.length() == 1);
    Field 'field = getField(fields[0], Person, ["person"], {maxAge: 10});
    test:assertTrue('field.getSubfields() is Field[]);
    Field[] subfields = <Field[]>'field.getSubfields();
    string[] expectedCacheKey = ["person.name.11FxOYiYfpMxmANj4kGJzg==", "person.address.nj4v+q6cUjv3W/MbZdNQXg=="];
    foreach int i in 0 ..< subfields.length() {
        test:assertTrue(subfields[i].isCacheEnabled());
        test:assertEquals(subfields[i].getCacheMaxAge(), 10d);
        test:assertEquals(subfields[i].getCacheKey(), expectedCacheKey[i]);
        if subfields[i].getName() == "address" {
            Field[]? subSubfields = subfields[i].getSubfields();
            test:assertTrue(subSubfields is Field[]);
            test:assertEquals((<Field[]>subSubfields).length(), 1);
            Field subSubfield = (<Field[]>subSubfields)[0];
            test:assertTrue(subSubfield.isCacheEnabled());
            test:assertEquals(subSubfield.getCacheMaxAge(), 10d);
            test:assertEquals(subSubfield.getCacheKey(), string `person.address.city.11FxOYiYfpMxmANj4kGJzg==`);
        }
    }
}
