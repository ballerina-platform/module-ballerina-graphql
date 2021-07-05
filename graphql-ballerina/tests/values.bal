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

const string quote1 = "I am a high-functioning sociapath!";
const string quote2 = "I am the one who knocks!";
const string quote3 = "I can make them hurt if I want to!";

Address a1 = {
    number: "221/B",
    street: "Baker Street",
    city: "London"
};

Address a2 = {
    number: "308",
    street: "Negra Arroyo Lane",
    city: "Albuquerque"
};

Address a3 = {
    number: "Uknown",
    street: "Unknown",
    city: "Hogwarts"
};

Address a4 = {
    number: "9809",
    street: "Margo Street",
    city: "Albuquerque"
};

Person p1 = {
    name: "Sherlock Holmes",
    age: 40,
    address: a1
};

Person p2 = {
    name: "Walter White",
    age: 50,
    address: a2
};

Person p3 = {
    name: "Tom Marvolo Riddle",
    age: 100,
    address: a3
};

Person p4 = {
    name: "Jesse Pinkman",
    age: 25,
    address: a4
};

Person[] people = [p1, p2, p3];

Book b1 = {
    name: "The Art of Electronics",
    author: "Paul Horowitz"
};

Book b2 = {
    name: "Practical Electronics",
    author: "Paul Scherz"
};

Book b3 = {
    name: "Algorithms to Live By",
    author: "Brian Christian"
};

Book b4 = {
    name: "Code: The Hidden Language",
    author: "Charles Petzold"
};

Book b5 = {
    name: "Calculus Made Easy",
    author: "Silvanus P. Thompson"
};

Book b6 = {
    name: "Calculus",
    author: "Michael Spivak"
};

Course c1 = {
    name: "Electronics",
    code: 106,
    books: [b1, b2]
};

Course c2 = {
    name: "Computer Science",
    code: 107,
    books: [b3, b4]
};

Course c3 = {
    name: "Mathematics",
    code: 105,
    books: [b5, b6]
};

Student s1 = {
    name: "John Doe",
    courses: [c1, c2]
};

Student s2 = {
    name: "Jane Doe",
    courses: [c2, c3]
};

Student s3 = {
    name: "Jonny Doe",
    courses: [c1, c2, c3]
};

Student[] students = [s1, s2, s3];

EmployeeTable employees = table[
    { id: 1, name: "John Doe", salary: 1000.00 },
    { id: 2, name: "Jane Doe", salary: 2000.00 },
    { id: 3, name: "Johnny Roe", salary: 500.00 }
];

public final readonly & table<LiftRecord> key(id) liftTable = table [
    { id: "astra-express", name: "Astra Express", status: OPEN, capacity: 10, night: false, elevationgain: 20},
    { id: "jazz-cat", name: "Jazz Cat", status: CLOSED, capacity: 5, night: true, elevationgain: 30},
    { id: "jolly-roger", name: "Jolly Roger", status: CLOSED, capacity: 8, night: true, elevationgain: 10}
];

public final readonly & table<TrailRecord> key(id) trailTable = table [
    {id: "blue-bird", name: "Blue Bird", status: OPEN, difficulty: "intermediate", groomed: true, trees: false, night: false},
    {id: "blackhawk", name: "Blackhawk", status: OPEN, difficulty: "intermediate", groomed: true, trees: false, night: false},
    {id: "ducks-revenge", name: "Duck's Revenge", status: CLOSED, difficulty: "expert", groomed: true, trees: false, night: false}
];

public final readonly & table<EdgeRecord> key(liftId, trailId) edgeTable = table [
    {liftId: "astra-express", trailId: "blue-bird"},
    {liftId: "astra-express", trailId: "ducks-revenge"},
    {liftId: "jazz-cat", trailId: "blue-bird"},
    {liftId: "jolly-roger", trailId: "blackhawk"},
    {liftId: "jolly-roger", trailId: "ducks-revenge"}
];

Contact contact1 = {
    number: "+94112233445"
};

Contact contact2 = {
    number: "+94717171717"
};

Contact contact3 = {
    number: "+94771234567"
};

Worker w1 = {
    id: "id1",
    name: "John Doe",
    contacts: { home: contact1 }
};

Worker w2 = {
    id: "id2",
    name: "Jane Doe",
    contacts: { home: contact2 }
};

Worker w3 = {
    id: "id3",
    name: "Jonny Doe",
    contacts: { home: contact3 }
};

map<Worker> workers = { id1: w1, id2: w2, id3: w3 };
map<Contact> contacts = { home1: contact1, home2: contact2, home3: contact3 };

Company company = {
    workers: workers,
    contacts: contacts
};
