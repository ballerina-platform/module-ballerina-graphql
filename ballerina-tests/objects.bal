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

import ballerina/graphql;

public type Character distinct service object {
    isolated resource function get name() returns string;
};

public type Ship distinct service object {
    isolated resource function get id() returns string;
};

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

public isolated distinct service class Starship {
    *Ship;

    final string id;
    final string driver;

    public isolated function init(string id, string driver) {
        self.id = id;
        self.driver = driver;
    }

    isolated resource function get id() returns string {
        return self.id;
    }

    isolated resource function get driver(string name) returns string {
        return self.driver;
    }

    isolated resource function get enemyShips() returns Ship[] {
        return [new Starship("E3", "Han"), new Starship("E4", "Leia")];
    }
}

public enum Sex {
    MALE = "male",
    FEMALE = "female"
}

public type Animalia distinct service object {
    isolated resource function get id() returns int;
    isolated resource function get sex() returns Sex;
    isolated resource function get name() returns string;
    resource function get mother() returns Animalia;
    resource function get father() returns Animalia;
};

public type Equine distinct service object {
    *Animalia;
    resource function get mother() returns Equine;
    resource function get father() returns Equine;
};

public distinct service class Horse {
    *Equine;
    final int id;
    final string name;
    final Sex sex;

    function init(int id, Sex sex, string name) {
        self.id = id;
        self.sex = sex;
        self.name = name;
    }

    isolated resource function get name() returns string {
        return self.name;
    }

    isolated resource function get id() returns int {
        return self.id;
    }

    isolated resource function get sex() returns Sex {
        return self.sex;
    }

    resource function get mother() returns Horse {
        return <Horse>animals[0];
    }

    resource function get father() returns Horse {
        return <Horse>animals[1];
    }
}

public distinct service class Donkey {
    *Equine;
    final int id;
    final string name;
    final Sex sex;

    function init(int id, Sex sex, string name) {
        self.id = id;
        self.sex = sex;
        self.name = name;
    }

    isolated resource function get name() returns string {
        return self.name;
    }

    isolated resource function get id() returns int {
        return self.id;
    }

    isolated resource function get sex() returns Sex {
        return self.sex;
    }

    resource function get mother() returns Donkey {
        return <Donkey>animals[3];
    }

    resource function get father() returns Donkey {
        return <Donkey>animals[2];
    }
}

public distinct service class Mule {
    *Equine;
    final int id;
    final string name;
    final Sex sex;
    final boolean isAggressive;

    function init(int id, Sex sex, string name, boolean isAggressive = false) {
        self.id = id;
        self.sex = sex;
        self.name = name;
        self.isAggressive = isAggressive;
    }

    isolated resource function get name() returns string {
        return self.name;
    }

    isolated resource function get id() returns int {
        return self.id;
    }

    isolated resource function get sex() returns Sex {
        return self.sex;
    }

    resource function get mother() returns Horse {
        return <Horse>animals[5];
    }

    resource function get father() returns Donkey {
        return <Donkey>animals[4];
    }

    resource function get isAggressive() returns boolean {
        return self.isAggressive;
    }
}

public distinct service class Dog {
    *Animalia;
    final int id;
    final string name;
    final Sex sex;

    function init(int id, Sex sex, string name) {
        self.id = id;
        self.sex = sex;
        self.name = name;
    }

    isolated resource function get name() returns string {
        return self.name;
    }

    isolated resource function get id() returns int {
        return self.id;
    }

    isolated resource function get sex() returns Sex {
        return self.sex;
    }

    resource function get mother() returns Dog {
        return <Dog>animals[7];
    }

    resource function get father() returns Dog {
        return <Dog>animals[8];
    }
}

Animalia[] animals = [
    new Horse(1, FEMALE, "LUNA"),
    new Horse(2, MALE, "WALTER"),
    new Donkey(3, MALE, "MAX"),
    new Donkey(4, FEMALE, "WINNIE"),
    new Donkey(5, MALE, "RUDY"),
    new Horse(6, FEMALE, "SKYE"),
    new Horse(7, MALE, "COOPER"),
    new Dog(8, MALE, "REX"),
    new Dog(9, FEMALE, "COOKIE"),
    new Dog(10, FEMALE, "DAISY"),
    new Mule(11, FEMALE, "LARA")
];

public isolated service class ReviewData {
    isolated resource function get id() returns string => "123";
}

public type Device distinct service object {

    @graphql:ResourceConfig {
        complexity: 1
    }
    isolated resource function get id() returns @graphql:ID int;

    isolated resource function get brand() returns string;

    isolated resource function get model() returns string;

    @graphql:ResourceConfig {
        complexity: 4
    }
    isolated resource function get price() returns float;
};

public isolated distinct service class Phone {
    *Device;

    private final int id;
    private final string brand;
    private final string model;
    private final float price;
    private final OS os;
    private final Device[] connectedDevices;

    isolated function init(int id, string brand, string model, float price, OS os) {
        self.id = id;
        self.brand = brand;
        self.model = model;
        self.price = price;
        self.os = os;
    }

    isolated resource function get id() returns @graphql:ID int => self.id;

    isolated resource function get brand() returns string => self.brand;

    isolated resource function get model() returns string => self.model;

    isolated resource function get price() returns float => self.price;

    isolated resource function get os() returns OS => self.os;
}

public isolated distinct service class Laptop {
    *Device;

    private final int id;
    private final string brand;
    private final string model;
    private final float price;
    private final string processor;
    private final int ram;

    isolated function init(int id, string brand, string model, float price, string processor, int ram) {
        self.id = id;
        self.brand = brand;
        self.model = model;
        self.price = price;
        self.processor = processor;
        self.ram = ram;
    }

    isolated resource function get id() returns @graphql:ID int => self.id;

    isolated resource function get brand() returns string => self.brand;

    isolated resource function get model() returns string => self.model;

    isolated resource function get price() returns float => self.price;

    isolated resource function get processor() returns string => self.processor;

    isolated resource function get ram() returns int => self.ram;
}

public isolated distinct service class Tablet {
    *Device;

    private final int id;
    private final string brand;
    private final string model;
    private final float price;
    private final boolean hasCellular;

    isolated function init(int id, string brand, string model, float price, boolean hasCellular) {
        self.id = id;
        self.brand = brand;
        self.model = model;
        self.price = price;
        self.hasCellular = hasCellular;
    }

    isolated resource function get id() returns @graphql:ID int => self.id;

    isolated resource function get brand() returns string => self.brand;

    isolated resource function get model() returns string => self.model;

    isolated resource function get price() returns float => self.price;

    isolated resource function get hasCellular() returns boolean => self.hasCellular;
}

enum OS {
    iOS,
    Android,
    Windows
}

type Mobile Phone|Tablet;

type RatingInput readonly & record {|
    string title;
    int stars;
    string description;
    int authorId;
|};

type RatingData readonly & record {|
    readonly int id;
    string title;
    int stars;
    string description;
    int authorId;
|};

service class Rating {
    private final RatingData data;

    isolated function init(RatingData data) {
        self.data = data;
    }

    isolated resource function get id() returns @graphql:ID int => self.data.id;

    @graphql:ResourceConfig {
        complexity: 1
    }
    isolated resource function get title() returns string => self.data.title;

    @graphql:ResourceConfig {
        complexity: 1
    }
    isolated resource function get stars() returns int => self.data.stars;

    isolated resource function get description() returns string => self.data.description;

    @graphql:ResourceConfig {
        complexity: 10
    }
    isolated resource function get author() returns DeviceUserProfile|error {
        lock {
            if profileTable.hasKey(self.data.authorId) {
                return new DeviceUserProfile(profileTable.get(self.data.authorId));
            }
        }
        return error("Author not found");
    }
}

type DeviceUserProfileData readonly & record {|
    readonly int id;
    string name;
    int age;
|};

service class DeviceUserProfile {
    private final DeviceUserProfileData data;

    isolated function init(DeviceUserProfileData data) {
        self.data = data;
    }

    isolated resource function get id() returns @graphql:ID int => self.data.id;

    isolated resource function get name() returns string => self.data.name;

    isolated resource function get age() returns int => self.data.age;
}

isolated table<RatingData> key(id) ratingTable = table [
    {id: 1, title: "Good", stars: 4, description: "Good product", authorId: 1},
    {id: 2, title: "Bad", stars: 2, description: "Bad product", authorId: 2},
    {id: 3, title: "Excellent", stars: 5, description: "Excellent product", authorId: 3},
    {id: 4, title: "Poor", stars: 1, description: "Poor product", authorId: 4}
];

isolated table<DeviceUserProfileData> key(id) profileTable = table [
    {id: 1, name: "Alice", age: 25},
    {id: 2, name: "Bob", age: 30},
    {id: 3, name: "Charlie", age: 35},
    {id: 4, name: "David", age: 40}
];

