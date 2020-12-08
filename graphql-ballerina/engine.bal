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
import graphql.commons;

public class Engine {
    private Listener 'listener;
    private Schema? schema;

    public isolated function init(Listener 'listener) {
        self.'listener = 'listener;
        self.schema = ();
    }

    isolated function registerService(Service s) {
        self.schema = createSchema(s);
        commons:println(self.schema.toString());
    }

    isolated function parse(string documentString) returns parser:DocumentNode|Error {
        parser:Parser parser = new (documentString);
        parser:DocumentNode|parser:Error parseResult = parser.parse();
        if (parseResult is parser:Error) {
            parser:Location l = <parser:Location>parseResult.detail()["location"];
            return ParsingError(parseResult.message(), line = l.line, column = l.column);
        }
        return <parser:DocumentNode>parseResult;
    }

    isolated function validate(parser:DocumentNode document) returns json[]? {
        var validationResult = self.validateDocument(document);
        if (validationResult is ErrorDetail[]) {
            json[] errors = [];

            foreach ErrorDetail err in validationResult {
                var errorDetailJson = err.cloneWithType(json);
                if (errorDetailJson is map<json>) {
                    errors.push(errorDetailJson);
                }
            }
            return errors;
        }
    }

    isolated function validateDocument(parser:DocumentNode document) returns ErrorDetail[]? {
        ValidatorVisitor validator = new;
        validator.validate(document);
        ErrorDetail[] errors = validator.getErrors();
        if (errors.length() > 0) {
            return errors;
        }
    }

    isolated function execute(parser:DocumentNode document, string operationName) returns map<json> {
        return {};
        //map<json> data = {};
        //json[] errors = [];
        //int errorCount = 0;
        //Operation[] operations = document.operations;
        //Operation? operationToExecute = ();
        //foreach Operation operation in operations {
        //    if (operationName == operation.name) {
        //        operationToExecute = operation;
        //        break;
        //    }
        //}
        //if (operationToExecute is ()) {
        //    string message = "Unknown operation named \"" + operationName + "\".";
        //    OperationNotFoundError err = OperationNotFoundError(message);
        //    errors[errorCount] = getErrorJsonFromError(err);
        //    return getResultJson(data, errors);
        //}
        //
        //Operation operation = <Operation>operationToExecute;
        //Field[] fields = operation.fields;
        //foreach Field 'field in fields {
        //    var resourceValue = executeResource(self.'listener, 'field);
        //    if (resourceValue is error) {
        //        string message = resourceValue.message();
        //        ErrorRecord errorRecord = getErrorRecordFromField('field);
        //        ExecutionError err = ExecutionError(message, errorRecord = errorRecord);
        //        errors[errorCount] = getErrorJsonFromError(err);
        //        errorCount += 1;
        //    } else if (resourceValue is ()) {
        //        data['field.name] = null;
        //    } else {
        //        data['field.name] = resourceValue;
        //    }
        //}
        //return getResultJson(data, errors);
    }
}
