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

public type Address record {
    string number;
    string street;
    string city;
};

public type Person record {
    string name;
    int age;
    Address address;
};

type Book record {
    string name;
    string author;
};

type Course record {
    string name;
    int code;
    Book[] books;
};

type Student record {
    string name;
    Course[] courses;
};

type Employee record {|
    readonly int id;
    string name;
    decimal salary;
|};

public type Contact record {
    string number;
};

public type Worker record {|
    string id;
    string name;
    map<Contact> contacts;
|};

public type Company record {|
    map<Worker> workers;
    map<Contact> contacts;
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

type Time record {|
    Weekday weekday;
    string time;
|};

public enum Status {
    OPEN,
    CLOSED,
    HOLD
}

public type LiftRecord readonly & record {|
    readonly string id;
    string name;
    Status status;
    int capacity;
    boolean night;
    int elevationgain;
|};

public type TrailRecord readonly & record {|
    readonly string id;
    string name;
    Status status;
    string difficulty;
    boolean groomed;
    boolean trees;
    boolean night;
|};

public type EdgeRecord readonly & record {|
    readonly string liftId;
    readonly string trailId;
|};

public type Movie record {
    string movieName;
    string director?;
};

public type ProfileDetail record {
    string name;
    int age?;
};

public type Info record {
    string bookName;
    int edition;
    ProfileDetail author;
    Movie movie?;
};

public type Date record {
    Weekday day;
};

public type Weight record {
    float weightInKg;
};

public type WeightInKg record {
    int weight;
};
