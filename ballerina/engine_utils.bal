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

import graphql.parser;

import ballerina/cache;
import ballerina/crypto;
import ballerina/jballerina.java;
import ballerina/lang.regexp;

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

isolated function validateInterceptorReturnValue(readonly & __Type 'type, any|error value, string interceptorName)
    returns anydata|error {
    if value is error|ErrorDetail {
        return value;
    } else if value is anydata && isValidReturnType('type, value) {
        return value;
    }
    string interceptorError = string `Invalid return type in Interceptor "${interceptorName}". ` +
                            string `Expected type ${getTypeNameFromType('type)}`;
    return error(interceptorError);
}

isolated function isValidReturnType(readonly & __Type 'type, anydata value) returns boolean {
    if 'type.kind is NON_NULL {
        if value == () {
            return false;
        }
        return isValidReturnType(unwrapNonNullType('type), value);
    } else if value == () {
        return true;
    } else if 'type.kind is ENUM && value is string {
        return true;
    } else if 'type.kind is LIST && (value is anydata[] || value is table<anydata>) {
        return true;
    } else if 'type.kind is OBJECT && value is map<anydata> {
        return true;
    } else if 'type.kind is SCALAR && value is Scalar {
        if getOfTypeName('type) == getTypeNameFromScalarValue(value) {
            return true;
        }
        return false;
    } else if 'type.kind is UNION|INTERFACE {
        readonly & __Type[] possibleTypes = <readonly & __Type[]>'type.possibleTypes;
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

isolated function getFieldObject(parser:FieldNode fieldNode, parser:RootOperationType operationType,
        readonly & __Schema schema, Engine engine, any|error fieldValue = ()) returns Field {
    readonly & (string|int)[] path = [fieldNode.getAlias()];
    string operationTypeName = getOperationTypeNameFromOperationType(operationType);
    readonly & __Type parentType = <readonly & __Type>getTypeFromTypeArray(schema.types, operationTypeName);
    readonly & __Type fieldType = getFieldTypeFromParentType(parentType, schema.types, fieldNode);
    string parentArgHashes = generateArgHash(fieldNode.getArguments());
    return new (fieldNode, fieldType, parentType, engine.getService(), path, operationType, fieldValue = fieldValue,
        cacheConfig = engine.getCacheConfig(), parentArgHashes = [parentArgHashes]
    );
}

isolated function createSchema(string schemaString) returns readonly & __Schema|Error = @java:Method {
    'class: "io.ballerina.stdlib.graphql.runtime.engine.Engine"
} external;

isolated function isMap(map<any> value) returns boolean = @java:Method {
    'class: "io.ballerina.stdlib.graphql.runtime.engine.EngineUtils"
} external;

isolated function getTypeNameFromValue(any value) returns string = @java:Method {
    'class: "io.ballerina.stdlib.graphql.runtime.engine.EngineUtils"
} external;

# Obtains the schema representation of a federated subgraph, expressed in the SDL format.
# + encodedSchemaString - Compile time auto generated schema
# + return - Subgraph schema in SDL format as a string on success, or an error otherwise
public isolated function getSdlString(string encodedSchemaString)
returns string|error = @java:Method {
    'class: "io.ballerina.stdlib.graphql.runtime.engine.EngineUtils"
} external;

isolated function getDefaultPrefetchMethodName(string fieldName) returns string {
    return re `^[a-z]`.replace(fieldName, isolated function(regexp:Groups groups) returns string {
        return string `${DEFAULT_PREFETCH_METHOD_NAME_PREFIX}${groups[0].substring().toUpperAscii()}`;
    });
}

isolated function initCacheTable(ServerCacheConfig? operationCacheConfig, ServerCacheConfig? fieldCacheConfig)
returns cache:Cache? {
    if operationCacheConfig is ServerCacheConfig && operationCacheConfig.enabled {
        return new ({capacity: operationCacheConfig.maxSize, evictionFactor: 0.2, defaultMaxAge: operationCacheConfig.maxAge});
    } else if fieldCacheConfig is ServerCacheConfig && fieldCacheConfig.enabled {
        return new ({capacity: fieldCacheConfig.maxSize, evictionFactor: 0.2, defaultMaxAge: fieldCacheConfig.maxAge});
    }
    return;
}

isolated function initDocumentCacheTable(DocumentCacheConfig? documentCacheConfig) returns cache:Cache? {
    if documentCacheConfig is DocumentCacheConfig && documentCacheConfig.enabled {
        return new ({capacity: documentCacheConfig.maxSize, evictionFactor: 0.2, defaultMaxAge: -1});
    }
    return;
}

isolated function generateDocumentCacheKey(string document) returns string {
    string standardizeDocument = getStandardizeDocument(document);
    byte[] hash = crypto:hashMd5(standardizeDocument.toBytes());
    return hash.toBase64();
}

isolated function getStandardizeDocument(string document) returns string {
    // Find all string & block string values and replace them with placeholder `-STRING-`
    string:RegExp pattern = re `"""([\s\S]*?)"""|"((?:[^"\\]|\\["\\/bfnrt]|\\u[0-9A-Fa-f]{4})*)"`;
    regexp:Span[] strings = pattern.findAll(document);
    string formattedDocument = pattern.replaceAll(document.trim(), STRING_PLACEHOLDER);
    // Remove all comments
    pattern = re `#.*`;
    formattedDocument = pattern.replaceAll(formattedDocument, "");
    // Replace multiple spaces and new lines between fields and args with a single comma
    pattern = re `[a-zA-Z0-9_"}\-\]]([\s]+)[_a-zA-Z]`;
    formattedDocument = pattern.replaceAll(formattedDocument, replaceFunction);
    // Remove remaining spaces and new lines
    pattern = re `[\s]+`;
    formattedDocument = pattern.replaceAll(formattedDocument, "");
    // Replace placeholder `-STRING-` with original string values
    foreach regexp:Span span in strings {
        pattern = re `-STRING-`;
        formattedDocument = pattern.replace(formattedDocument, span.substring());
    }
    return formattedDocument;
}

isolated function replaceFunction(regexp:Groups groups) returns string => re `\s+`.replaceAll(groups[0].substring(), ",");

isolated function hasRecordReturnType(service object {} serviceObject, string[] path)
    returns boolean = @java:Method {
    'class: "io.ballerina.stdlib.graphql.runtime.engine.Engine"
} external;

isolated function isRecordWithNoOptionalFields(any|error value) returns boolean = @java:Method {
    'class: "io.ballerina.stdlib.graphql.runtime.engine.EngineUtils"
} external;
