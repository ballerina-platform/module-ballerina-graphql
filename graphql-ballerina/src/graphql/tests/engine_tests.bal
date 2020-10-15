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

listener Listener 'listener = new(9090);

@test:Config {}
function testInvokeResource() {
    string document = getShorthandNotationDocument();
    var attachResult = 'listener.__attach(invokeResourceTestService);
    if (attachResult is error) {
        test:assertFail("Attaching the service resulted in an error." + attachResult.toString());
    }
    Engine engine = new('listener);
    var result = engine.getOutputForDocument(document);
}


service invokeResourceTestService = service {
    isolated resource function name() returns string {
        return "John Doe";
    }

    isolated resource function id() returns int {
        return 1;
    }

    isolated resource function birthdate() returns string {
        return "01-01-1980";
    }
};
