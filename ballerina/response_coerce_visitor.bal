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

import ballerina/lang.array;
import graphql.parser;

class ResponseCoerceVisitor {
    *parser:Visitor;

    private final readonly & __Schema schema;
    private OutputObject outputObject;
    private OutputObject coercedOutputObject;

    isolated function init(readonly & __Schema schema, OutputObject outputObject) {
        self.schema = schema;
        self.outputObject = outputObject;
        self.coercedOutputObject = {};
    }

    isolated function getCoercedOutputObject(parser:OperationNode operationNode) returns OutputObject {
        ErrorDetail[]? errors = self.outputObject?.errors;
        if errors != () {
            self.coerceErrors(errors);
        }
        self.visitOperation(operationNode);
        return self.coercedOutputObject;
    }

    isolated function coerceErrors(ErrorDetail[] errors) {
        ErrorDetail[] sortedErrors = array:sort(errors, array:ASCENDING, sortErrorDetail);
        self.coercedOutputObject["errors"] = sortedErrors;
    }

    public isolated function visitDocument(parser:DocumentNode documentNode, anydata data = ()) {
        // Do nothing
    }

    public isolated function visitOperation(parser:OperationNode operationNode, anydata data = ()) {
        Data coerced = {};
        OutputData? outputData = getOutputDataRecord(self.outputObject, coerced);
        if outputData is OutputData {
            foreach parser:Selection selection in operationNode.getSelections() {
                self.visitSelection(selection, outputData);
            }
            self.coercedOutputObject.data = coerced;
        }
    }

    public isolated function visitSelection(parser:Selection selection, anydata data = ()) {
        OutputData outputData = <OutputData>data;
        if selection.isFragment {
            self.visitFragment(<parser:FragmentNode>selection?.node, data);
        } else {
            self.visitField(<parser:FieldNode>selection?.node, data);
        }
    }

    public isolated function visitField(parser:FieldNode fieldNode, anydata data = ()) {
        OutputData outputData = <OutputData>data;
        Data original = outputData.original;
        Data coerced = outputData.coerced;

        anydata|anydata[] subOriginal = original[fieldNode.getAlias()];
        if subOriginal is anydata[] {
            anydata[] subCoercedArray = [];
            foreach anydata element in subOriginal {
                if element is Data {
                    subCoercedArray.push(self.orderData(element, fieldNode));
                } else {
                    subCoercedArray.push(element);
                }
            }
            coerced[fieldNode.getAlias()] = subCoercedArray;
        } else if subOriginal is Data {
            coerced[fieldNode.getAlias()] = self.orderData(subOriginal, fieldNode);
        } else {
            if original.hasKey(fieldNode.getAlias()) {
                coerced[fieldNode.getAlias()] = subOriginal;
            }
        }
    }

    public isolated function visitArgument(parser:ArgumentNode argumentNode, anydata data = ()) {
        // Do nothing
    }

    public isolated function visitFragment(parser:FragmentNode fragmentNode, anydata data = ()) {
        OutputData outputData = <OutputData>data;
        foreach parser:Selection selection in fragmentNode.getSelections() {
            self.visitSelection(selection, data);
        }
    }

    isolated function orderData(Data original, parser:FieldNode fieldNode) returns Data {
        Data coerced = {};
        OutputData outputData = { original: original, coerced: coerced };
        foreach parser:Selection selection in fieldNode.getSelections() {
            self.visitSelection(selection, outputData);
        }
        return coerced;
    }
}

isolated function sortErrorDetail(ErrorDetail errorDetail) returns int {
    Location[]? locations = errorDetail?.locations;
    if (locations == ()) {
        return 0;
    } else {
        return locations[0].line;
    }
}

isolated function getOutputDataRecord(OutputObject outputObject, Data coerced) returns OutputData? {
    Data? original = outputObject?.data;
    if original == () {
        return;
    }
    return { original: <Data>original, coerced: coerced };
}

type OutputData record {
    Data original;
    Data coerced;
};
