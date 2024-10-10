// Copyright (c) 2023 WSO2 LLC. (http://www.wso2.com) All Rights Reserved.
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

isolated class ValueTreeBuilder {

    isolated function init() {
    }

    isolated function build(Context context, Data placeholderTree) returns Data {
        return <Data>self.buildValueTree(context, placeholderTree);
    }

    isolated function buildValueTree(Context context, anydata partialValue) returns anydata {
        if context.getUnresolvedPlaceholderNodeCount() == 0 {
            return partialValue;
        }
        while context.getUnresolvedPlaceholderCount() > 0 {
            context.resolvePlaceholders();
        }
        if partialValue is ErrorDetail {
            return partialValue;
        }
        if partialValue is PlaceholderNode {
            anydata value = context.getPlaceholderValue(partialValue.__uuid);
            context.decrementUnresolvedPlaceholderNodeCount();
            return self.buildValueTree(context, value);
        }
        if partialValue is map<anydata> && isMap(partialValue) {
            return self.buildValueTreeFromMap(context, partialValue);
        }
        if partialValue is record {} {
            return self.buildValueTreeFromRecord(context, partialValue);
        }
        if partialValue is anydata[] {
            return self.buildValueTreeFromArray(context, partialValue);
        }
        return partialValue;
    }

    isolated function buildValueTreeFromMap(Context context, map<anydata> partialValue) returns map<anydata> {
        map<anydata> data = {};
        foreach [string, anydata] [key, value] in partialValue.entries() {
            data[key] = self.buildValueTree(context, value);
        }
        return data;
    }

    isolated function buildValueTreeFromRecord(Context context, record {} partialValue) returns record {} {
        record {} data = {};
        foreach [string, anydata] [key, value] in partialValue.entries() {
            data[key] = self.buildValueTree(context, value);
        }
        return data;
    }

    isolated function buildValueTreeFromArray(Context context, anydata[] partialValue) returns anydata[] {
        anydata[] data = [];
        foreach anydata element in partialValue {
            anydata newVal = self.buildValueTree(context, element);
            data.push(newVal);
        }
        return data;
    }
}
