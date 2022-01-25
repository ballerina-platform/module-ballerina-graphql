// Copyright (c) 2021 WSO2 Inc. (http://www.wso2.org) All Rights Reserved.
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

import ballerina/graphql;

public type Person record {
    string name;
    int age;
};

public type Student record {
    string name;
    string subject;
};

public type Book readonly & record {
    string name;
    string author;
};

public type Movie readonly & record {
    string name;
    string director;
};

service /graphql on new graphql:Listener(4000) {

    isolated resource function get getName(Person & readonly person) returns string {
        return person.name;
    }

    isolated resource function get subject() returns Student & readonly {
        Student student = {name: "Jesse Pinkman", subject: "Arts and Crafts"};
        return student.cloneReadOnly();
    }

    isolated resource function get director() returns Movie {
        Movie movie = {name: "Pulp Fiction", director: "Quentin Tarantino"};
        return movie;
    }

    isolated resource function get author(Book book) returns string {
        return book.author;
    }
}
