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

import ballerina/graphql;

public type _Any record {
    string data = "data";
};

public type FieldSet record {|
    string data;
|};

enum link__Purpose {
    A,
    B
}

public type link__Import record {
    string data = "data";
};

service class _Service {
    resource function get data() returns string {
        return "data";
    }
}

service on new graphql:Listener(4000) {
    resource function get 'any() returns _Any {
        return {};
    }

    remote function services() returns _Service {
        return new;
    }

    resource function get fieldSet(FieldSet input) returns string {
        return "data";
    }

    resource function get linkImport() returns link__Import {
        return {};
    }

    resource function get linkPurpose() returns link__Purpose {
        return A;
    }

    resource function get enumInput(link__Purpose input) returns string {
        return "data";
    }
}
