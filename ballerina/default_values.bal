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

__InputValue inputValue = {
        name: "if",
        'type: {
            kind: NON_NULL, 
            ofType: {
                name: BOOLEAN,
                kind: SCALAR
            }
        }
    };

__Directive defaultDirectiveSkip = {
    name: SKIP,
    description: "Directs the executor to skip this field or fragment when the `if` argument is true.",
    locations: [FIELD, FRAGMENT_SPREAD, INLINE_FRAGMENT],
    args: [inputValue]
};

__Directive defaultDirectiveInclude = {
    name: INCLUDE,
    description: "Directs the executor to include this field or fragment only when the `if` argument is true.",
    locations: [FIELD, FRAGMENT_SPREAD, INLINE_FRAGMENT],
    args: [inputValue]
};

final readonly & __Directive[] defaultDirectives = [defaultDirectiveSkip.cloneReadOnly(), defaultDirectiveInclude.cloneReadOnly()];
