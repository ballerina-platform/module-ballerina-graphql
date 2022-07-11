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

import ballerina/jballerina.java;
import graphql.parser;

isolated function getOutputObjectFromErrorDetail(ErrorDetail|ErrorDetail[] errorDetail) returns OutputObject {
    if errorDetail is ErrorDetail {
        return {
            errors: [errorDetail]
        };
    }
    return {errors: errorDetail};
}

isolated function getErrorDetailFromError(parser:Error err) returns ErrorDetail {
    int line = err.detail()["line"];
    int column = err.detail()["column"];
    Location location = {line: line, column: column};
    return {
        message: err.message(),
        locations: [location]
    };
}

isolated function isValidReturnType(__Type 'type, anydata value) returns boolean {
    if 'type.kind is NON_NULL {
        return isValidReturnType(getOfType('type), value);
    }
    if 'type.kind is LIST && value is anydata[] {
        return true;
    }
    if 'type.kind is OBJECT && value is map<anydata> {
        return true;
    }
    if 'type.kind is SCALAR|ENUM && value is Scalar {
        if getOfTypeName('type) == getTypeNameFromValue(value) {
            return true;
        }
    }
    if 'type.kind is UNION|INTERFACE {
        __Type[] possibleTypes = <__Type[]>'type.possibleTypes;
        boolean isValidType = false;
        foreach __Type possibleType in possibleTypes {
            isValidType = isValidReturnType(possibleType, value);
            if isValidType {
                break;
            }
        }
        return isValidType;
    }
    return false;
}

isolated function validateInterceptorReturnValue(Field 'field, any|error value, string interceptorName) returns error? {
    if value is error {
        return value;
    }
    if value is anydata && isValidReturnType('field.getGetSchemaField(), value) {
        return;
    }
    return error(string `Invalid return type in Intecetor ${interceptorName}`);
}

isolated function createSchema(string schemaString) returns readonly & __Schema|Error = @java:Method {
    'class: "io.ballerina.stdlib.graphql.runtime.engine.Engine"
} external;

isolated function executeSubscription(ExecutorVisitor visitor, parser:FieldNode fieldNode, any result) = @java:Method {
    'class: "io.ballerina.stdlib.graphql.runtime.engine.Engine"
} external;

isolated function attachFieldToEngine(Field fieldNode, Engine engine) = @java:Method {
    'class: "io.ballerina.stdlib.graphql.runtime.engine.Engine"
} external;

isolated function getFieldFromEngine(Engine engine) returns Field = @java:Method {
    'class: "io.ballerina.stdlib.graphql.runtime.engine.EngineUtils"
} external;

isolated function getSubscriptionResult(ExecutorVisitor visitor,
                                        parser:FieldNode node) returns any|error = @java:Method {
    'class: "io.ballerina.stdlib.graphql.runtime.engine.Engine"
} external;

isolated function isMap(map<anydata> value) returns boolean = @java:Method {
    'class: "io.ballerina.stdlib.graphql.runtime.engine.EngineUtils"
} external;

isolated function getTypeNameFromValue(any value) returns string = @java:Method {
    'class: "io.ballerina.stdlib.graphql.runtime.engine.EngineUtils"
} external;

isolated function executeResource(service object {} serviceObject, parser:FieldNode fieldNode, Context context)
returns any|error = @java:Method {
    'class: "io.ballerina.stdlib.graphql.runtime.engine.Engine"
} external;

isolated function executeInterceptor(readonly & Interceptor interceptor, Field fieldNode, Context context)
returns any|error = @java:Method {
    'class: "io.ballerina.stdlib.graphql.runtime.engine.Engine"
} external;

isolated function getInterceptorName(readonly & Interceptor interceptor) returns string = @java:Method {
    'class: "io.ballerina.stdlib.graphql.runtime.engine.Engine"
} external;
