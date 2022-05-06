// Copyright (c) 2022, WSO2 Inc. (http://www.wso2.org) All Rights Reserved.
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

public isolated distinct service class Character {
    final string name;

    public isolated function init(string name) {
        self.name = name;
    }

    isolated resource function get name() returns string {
        return self.name;
    }
}

public isolated distinct service class Human {
    *Character;

    final string name;
    final int id;

    public isolated function init(string name, int id) {
        self.name = name;
        self.id = id;
    }

    isolated resource function get name() returns string {
        return self.name;
    }

    isolated resource function get id() returns int {
        return self.id;
    }
}

public isolated distinct service class Droid {
    *Character;

    final string name;
    final int year;

    public isolated function init(string name, int year) {
        self.name = name;
        self.year = year;
    }

    isolated resource function get name() returns string {
        return self.name;
    }

    isolated resource function get year() returns int {
        return self.year;
    }
}
