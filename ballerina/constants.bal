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

const CONTENT_TYPE_JSON = "application/json";
const CONTENT_TYPE_GQL = "application/graphql";
const CONTENT_TYPE_MULTIPART_FORM_DATA = "multipart/form-data";
const CONTENT_TYPE_TEXT_HTML = "text/html";
const HTTP_HOST_HEADER = "Host";

const PARAM_QUERY = "query";
const PARAM_OPERATION_NAME = "operationName";
const PARAM_VARIABLES = "variables";

const MULTIPART_OPERATIONS = "operations";
const MULITPART_MAP = "map";
const UPLOAD = "Upload";
const CONTENT_ENCODING = "Content-Encoding";

const SCHEMA_FIELD = "__schema";
const TYPE_NAME_FIELD = "__typename";
const TYPE_FIELD = "__type";

const SCHEMA_TYPE_NAME = "__Schema";
const TYPE_TYPE_NAME = "__Type";
const QUERY_TYPE_NAME = "Query";
const MUTATION_TYPE_NAME = "Mutation";
const SUBSCRIPTION_TYPE_NAME = "Subscription";

const NAME_ARGUMENT = "name";
const KEY_ARGUMENT = "key";
const DATA_FIELD = "data";
const ERRORS_FIELD = "errors";
const SUBSCRIPTION_FIELD = "subscriptionType";
const IS_DEPRECATED_FIELD = "isDeprecated";
const INCLUDE_DEPRECATED_ARGUMENT = "includeDeprecated";

// Scalar type names used in GraphQL
const INT = "Int";
const STRING = "String";
const FLOAT = "Float";
const BOOLEAN = "Boolean";
const DECIMAL = "Decimal";

// Default directive names used in GraphQL
const SKIP = "skip";
const INCLUDE = "include";

// Message types related to graphql-transport-ws subscription protocol
const WS_INIT = "connection_init";
const WS_ACK = "connection_ack";
const WS_PING = "ping";
const WS_PONG = "pong";
const WS_SUBSCRIBE = "subscribe";
const WS_NEXT = "next";
const WS_ERROR = "error";
const WS_COMPLETE = "complete";

// Subprotocol constants used in headers
const GRAPHQL_TRANSPORT_WS = "graphql-transport-ws";
const WS_SUB_PROTOCOL = "Sec-WebSocket-Protocol";

const decimal PING_MESSAGE_SCHEDULE_INTERVAL = 15;
const decimal PONG_MESSAGE_HANDLER_SCHEDULE_INTERVAL = 15;

// Constants used in the executor visitor
const OPERATION_TYPE = "operationType";
const PATH = "path";

// Constants related to the DataLoader
const DEFAULT_PREFETCH_METHOD_NAME_PREFIX = "pre";

// Localhost
const LOCALHOST = "localhost";

// Observability Metrics
const GRAPHQL_OPERATION_NAME = "graphql_service_operation_name";
const GRAPHQL_OPERATION_TYPE = "graphql_service_operation_type";
const GRAPHQL_ERRORS = "graphql_service_errors";
const GRAPHQL_FIELD_NAME = "graphql_service_field_name";

const GRAPHQL_PARSING_ERROR = "graphql_service_parsing_error";
const GRAPHQL_VALIDATION_ERROR = "graphql_service_validation_error";
const GRAPHQL_EXECUTION_ERROR = "graphql_service_execution_error";
const GRPAHQL_ANONYMOUS_OPERATION = "anonymous";
