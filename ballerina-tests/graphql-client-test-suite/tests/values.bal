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

final readonly & Student[] students = [s1, s2, s3];
final readonly & Person[] people = [p1, p2, p3];
