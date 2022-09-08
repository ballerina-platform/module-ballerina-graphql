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
    FEMAELE = "female"
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
    new Horse(1, FEMAELE, "LUNA"),
    new Horse(2, MALE, "WALTER"),
    new Donkey(3, MALE, "MAX"),
    new Donkey(4, FEMAELE, "WINNIE"),
    new Donkey(5, MALE, "RUDY"),
    new Horse(6, FEMAELE, "SKYE"),
    new Horse(7, MALE, "COOPER"),
    new Dog(8, MALE, "REX"),
    new Dog(9, FEMAELE, "COOKIE"),
    new Dog(10, FEMAELE, "DAISY"),
    new Mule(11, FEMAELE, "LARA")
];
