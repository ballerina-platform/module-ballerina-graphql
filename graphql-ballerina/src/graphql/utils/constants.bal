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

const OPERATION_QUERY = "query";

const OPEN_BRACE = "{";
const CLOSE_BRACE = "}";

const CONTENT_TYPE_JSON = "application/json";
const CONTENT_TYPE_GQL = "application/graphql";

const VALIDATION_TYPE_NAME = "Name";

const RESULT_FIELD_ERRORS = "errors";
const RESULT_FIELD_DATA = "data";

const FIELD_ERROR_RECORD = "errorRecord";

// Parser
const COMMENT_BLOCK = "#";
const EOF = "<EOF>";
const WORD_VALIDATOR = "^[a-zA-Z_][a-zA-Z0-9_]*$";
