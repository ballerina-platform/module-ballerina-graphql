// Copyright (c) 2024 WSO2 LLC. (http://www.wso2.com).
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

isolated int dispatchCountOfBookLoader = 0;
isolated int dispatchCountOfAuthorLoader = 0;
isolated int dispatchCountOfUpdateAuthorLoader = 0;

isolated function resetDispatchCounters() {
    lock {
        dispatchCountOfAuthorLoader = 0;
    }
    lock {
        dispatchCountOfBookLoader = 0;
    }
    lock {
        dispatchCountOfUpdateAuthorLoader = 0;
    }
}

isolated function assertDispatchCountForBookLoader(int expectedCount) {
    lock {
        test:assertEquals(dispatchCountOfBookLoader, expectedCount);
    }
}

isolated function assertDispatchCountForUpdateAuthorLoader(int expectedCount) {
    lock {
        test:assertEquals(dispatchCountOfUpdateAuthorLoader, expectedCount);
    }
}

isolated function assertDispatchCountForAuthorLoader(int expectedCount) {
    lock {
        test:assertEquals(dispatchCountOfAuthorLoader, expectedCount);
    }
}
