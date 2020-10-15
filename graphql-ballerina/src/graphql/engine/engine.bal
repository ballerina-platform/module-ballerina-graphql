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

public class Engine {
    private Listener 'listener;

    public isolated function init(Listener 'listener) {
        self.'listener = 'listener;
    }

    isolated function getOutputForDocument(string documentString) returns json {
        map<json> data = {};
        json[] errors = [];
        int errorCount = 0;
        Document|ParsingError parseResult = parse(documentString);
        if (parseResult is ParsingError) {
            errors[errorCount] = getErrorJsonFromError(parseResult);
            return getResultJson(data, errors);
        }
        Document document = <Document>parseResult;
        if (document.operations.length() > 1) {
            NotImplementedError err = NotImplementedError("Ballerina GraphQL does not support multiple operations yet.");
            errors[errorCount] = getErrorJsonFromError(err);
            return getResultJson(data, errors);
        } else if (document.operations.length() == 0) {
            InvalidDocumentError err = InvalidDocumentError("Document does not contains any operation.");
            errors[errorCount] = getErrorJsonFromError(err);
            return getResultJson(data, errors);
        }
        Operation operation = document.operations[0];
        OperationType 'type = operation.'type;
        if ('type == OPERATION_QUERY) {
            Token[] fields = operation.fields;
            foreach Token token in fields {
                string 'field = token.value;
                var resourceValue = getStoredResource(self.'listener, 'field);
                if (resourceValue is error) {
                    string message = resourceValue.message();
                    ErrorRecord errorRecord = getErrorRecordFromToken(token);
                    ExecutionError err = ExecutionError(message, errorRecord = errorRecord);
                    errors[errorCount] = getErrorJsonFromError(err);
                    errorCount += 1;
                } else if (resourceValue is ()) {
                    data['field] = null;
                } else {
                    data['field] = resourceValue;
                }
            }
        } else {
            NotImplementedError err =
            NotImplementedError("Ballerina GraphQL does not support " + 'type.toString() + " operation yet.");
            errors[errorCount] = getErrorJsonFromError(err);
            return getResultJson(data, errors);
        }
        return getResultJson(data, errors);
    }

    isolated function validate(Document document) returns ValidationError? {
        Operation[] operations = document.operations;
        if (operations.length() > 1) {
            return NotImplementedError("Ballerina GraphQL does not support multiple operations yet.");
        }
    }

    isolated function process(string documentString) {
        //Document|Error parseResult = parse(documentString);
        //if (parseResult is Error) {
        //    errors[errorCount] = getErrorJsonFromError(parseResult);
        //    return getResultJson(data, errors);
        //}
        //Document document = <Document>parseResult;
    }
}
