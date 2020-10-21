//// Copyright (c) 2020, WSO2 Inc. (http://www.wso2.org) All Rights Reserved.
////
//// WSO2 Inc. licenses this file to you under the Apache License,
//// Version 2.0 (the "License"); you may not use this file except
//// in compliance with the License.
//// You may obtain a copy of the License at
////
//// http://www.apache.org/licenses/LICENSE-2.0
////
//// Unless required by applicable law or agreed to in writing,
//// software distributed under the License is distributed on an
//// "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
//// KIND, either express or implied.  See the License for the
//// specific language governing permissions and limitations
//// under the License.
//
//public class Engine {
//    private Listener 'listener;
//    private string[] fields = [];
//
//    public isolated function init(Listener 'listener) {
//        self.'listener = 'listener;
//    }
//
//    isolated function addService(service s) {
//        self.fields = getFieldNames(s);
//    }
//
//    isolated function getListener() returns Listener {
//        return self.'listener;
//    }
//
//    isolated function getFields() returns string[] {
//        return self.fields;
//    }
//
//    isolated function validate(string documentString) returns Document|Error {
//        Document|Error parseResult = parse(documentString);
//        if (parseResult is Error) {
//            return parseResult;
//        }
//        Document document = <Document>parseResult;
//        var validationResult = validateDocument(self, document);
//        if (validationResult is ValidationError) {
//            return validationResult;
//        }
//        return document;
//    }
//
//    isolated function execute(Document document, string operationName) returns json {
//        map<json> data = {};
//        json[] errors = [];
//        int errorCount = 0;
//        map<Operation> operations = document.operations;
//        if (!operations.hasKey(operationName)) {
//            string message = "Unknown operation named \"" + operationName + "\".";
//            OperationNotFoundError err = OperationNotFoundError(message);
//            errors[errorCount] = getErrorJsonFromError(err);
//            return getResultJson(data, errors);
//        }
//        Operation operation = document.operations.get(operationName);
//        Token[] fields = operation.fields;
//        foreach Token token in fields {
//            string 'field = token.value;
//            var resourceValue = executeResource(self.'listener, 'field);
//            if (resourceValue is error) {
//                string message = resourceValue.message();
//                ErrorRecord errorRecord = getErrorRecordFromToken(token);
//                ExecutionError err = ExecutionError(message, errorRecord = errorRecord);
//                errors[errorCount] = getErrorJsonFromError(err);
//                errorCount += 1;
//            } else if (resourceValue is ()) {
//                data['field] = null;
//            } else {
//                data['field] = resourceValue;
//            }
//        }
//        return getResultJson(data, errors);
//    }
//}
