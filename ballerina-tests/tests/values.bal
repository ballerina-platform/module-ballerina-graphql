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

final readonly & Address a1 = {
    number: "221/B",
    street: "Baker Street",
    city: "London"
};

final readonly & Address a2 = {
    number: "308",
    street: "Negra Arroyo Lane",
    city: "Albuquerque"
};

final readonly & Address a3 = {
    number: "Uknown",
    street: "Unknown",
    city: "Hogwarts"
};

final readonly & Address a4 = {
    number: "9809",
    street: "Margo Street",
    city: "Albuquerque"
};

final readonly & Person p1 = {
    name: "Sherlock Holmes",
    age: 40,
    address: a1
};

final readonly & Person p2 = {
    name: "Walter White",
    age: 50,
    address: a2
};

final readonly & Person p3 = {
    name: "Tom Marvolo Riddle",
    age: 100,
    address: a3
};

final readonly & Person p4 = {
    name: "Jesse Pinkman",
    age: 25,
    address: a4
};

final readonly & Person[] people = [p1, p2, p3];

final readonly & Book b1 = {
    name: "The Art of Electronics",
    author: "Paul Horowitz"
};

final readonly & Book b2 = {
    name: "Practical Electronics",
    author: "Paul Scherz"
};

final readonly & Book b3 = {
    name: "Algorithms to Live By",
    author: "Brian Christian"
};

final readonly & Book b4 = {
    name: "Code: The Hidden Language",
    author: "Charles Petzold"
};

final readonly & Book b5 = {
    name: "Calculus Made Easy",
    author: "Silvanus P. Thompson"
};

final readonly & Book b6 = {
    name: "Calculus",
    author: "Michael Spivak"
};

final readonly & Book b7 = {
    name: "The Sign of Four",
    author: "Athur Conan Doyle"
};

final readonly & Book b8 = {
    name: "The Valley of Fear",
    author: "Athur Conan Doyle"
};

final readonly & Book b9 = {
    name: "Harry Potter and the Sorcerer's Stone",
    author: "J.K Rowling"
};

final readonly & Book b10 = {
    name: "Harry Potter and the Chamber of Secrets",
    author: "J.K Rowling"
};

final readonly & Movie m1 =  {
    movieName: "Harry Potter and the Sorcerer's Stone",
    director: "Chris Columbus"
};

final readonly & Movie m2 =  {
    movieName: "Sherlock Holmes",
    director: "Dexter Fletcher"
};

final readonly & Movie m3 = {
    movieName: "El Camino",
    director: "Vince Gilligan"
};

final readonly & Movie m4 = {
    movieName: "Escape Plan",
    director: "Mikael Hafstrom"
};

final readonly & Movie m5 = {
    movieName: "Papillon",
    director: "Franklin Schaffner"
};

final readonly & Movie m6 = {
    movieName: "The Fugitive",
    director: "Andrew Davis"
};

final readonly & Course c1 = {
    name: "Electronics",
    code: 106,
    books: [b1, b2]
};

final readonly & Course c2 = {
    name: "Computer Science",
    code: 107,
    books: [b3, b4]
};

final readonly & Course c3 = {
    name: "Mathematics",
    code: 105,
    books: [b5, b6]
};

final readonly & Student s1 = {
    name: "John Doe",
    courses: [c1, c2]
};

final readonly & Student s2 = {
    name: "Jane Doe",
    courses: [c2, c3]
};

final readonly & Student s3 = {
    name: "Jonny Doe",
    courses: [c1, c2, c3]
};

final readonly & Student[] students = [s1, s2, s3];

final readonly & EmployeeTable employees = table[
    { id: 1, name: "John Doe", salary: 1000.00 },
    { id: 2, name: "Jane Doe", salary: 2000.00 },
    { id: 3, name: "Johnny Roe", salary: 500.00 }
];

final readonly & EmployeeTable oldEmployees = table[
    { id: 4, name: "John", salary: 5000.00 },
    { id: 5, name: "Jane", salary: 7000.00 },
    { id: 6, name: "Johnny", salary: 1000.00 }
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

final readonly & Contact contact1 = {
    number: "+94112233445"
};

final readonly & Contact contact2 = {
    number: "+94717171717"
};

final readonly & Contact contact3 = {
    number: "+94771234567"
};

final readonly & Worker w1 = {
    id: "id1",
    name: "John Doe",
    contacts: { home: contact1 }
};

final readonly & Worker w2 = {
    id: "id2",
    name: "Jane Doe",
    contacts: { home: contact2 }
};

final readonly & Worker w3 = {
    id: "id3",
    name: "Jonny Doe",
    contacts: { home: contact3 }
};

final readonly & map<Worker & readonly> workers = { id1: w1, id2: w2, id3: w3 };
final readonly & map<Contact & readonly> contacts = { home1: contact1, home2: contact2, home3: contact3 };

final readonly & Company company = {
    workers: workers.cloneReadOnly(),
    contacts: contacts.cloneReadOnly()
};

final readonly & TaskTable tasks = table[
    {sprint: 77, subTasks: ["GraphQL-task1", error("Undefined task!"), "HTTP-task2"]}
];

// WebSocket Message types
const WS_INIT = "connection_init";
const WS_ACK = "connection_ack";
const WS_PING = "ping";
const WS_PONG = "pong";
const WS_SUBSCRIBE = "subscribe";
const WS_NEXT = "next";
const WS_ERROR = "error";
const WS_COMPLETE = "complete";

// WebSocket Sub Protocols
const GRAPHQL_TRANSPORT_WS = "graphql-transport-ws";
const WS_SUB_PROTOCOL = "Sec-WebSocket-Protocol";

final isolated table<AuthorRow> key(id) authorTable = table [
    {id: 1, name: "Author 1"},
    {id: 2, name: "Author 2"},
    {id: 3, name: "Author 3"},
    {id: 4, name: "Author 4"},
    {id: 5, name: "Author 5"}
];

final isolated table<BookRow> key(id) bookTable = table [
    {id: 1, title: "Book 1", author: 1},
    {id: 2, title: "Book 2", author: 1},
    {id: 3, title: "Book 3", author: 1},
    {id: 4, title: "Book 4", author: 2},
    {id: 5, title: "Book 5", author: 2},
    {id: 6, title: "Book 6", author: 3},
    {id: 7, title: "Book 7", author: 3},
    {id: 8, title: "Book 8", author: 4},
    {id: 9, title: "Book 9", author: 5}
];

isolated int dispatchCountOfBookLoader = 0;
isolated int dispatchCountOfAuthorLoader = 0;
isolated int dispatchCountOfUpdateAuthorLoader = 0;

const int DEFAULT_INT_VALUE = 20;
