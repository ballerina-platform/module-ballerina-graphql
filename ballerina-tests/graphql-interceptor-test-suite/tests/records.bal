// Copyright (c) 2024 WSO2 LLC. (http://www.wso2.com).
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

type Employee readonly & record {|
    readonly int id;
    string name;
    decimal salary;
|};

public type Person readonly & record {
    string name;
    int age?;
    Address address;
};

public type Address readonly & record {
    string number;
    string street;
    string city;
};

public type Book readonly & record {
    string name;
    string author;
};

public type Contact readonly & record {
    string number;
};

public type Languages record {|
    map<string> name;
|};

type EmployeeTable table<Employee> key(id);

public enum Weekday {
    SUNDAY,
    MONDAY,
    TUESDAY,
    WEDNESDAY,
    THURSDAY,
    FRIDAY,
    SATURDAY
}
