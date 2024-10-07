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

service /subscriptions on subscriptionListener {
    isolated resource function get name() returns string {
        return "Walter White";
    }

    resource function subscribe name() returns stream<string, error?> {
        return namesArray.toStream();
    }

    isolated resource function subscribe messages() returns stream<int, error?> {
        int[] intArray = [1, 2, 3, 4, 5];
        return intArray.toStream();
    }

    isolated resource function subscribe stringMessages() returns stream<string?, error?> {
        string?[] stringArray = [(), "1", "2", "3", "4", "5"];
        return stringArray.toStream();
    }

    isolated resource function subscribe books() returns stream<Book, error?> {
        Book[] books = [
            {name: "Crime and Punishment", author: "Fyodor Dostoevsky"},
            {name: "A Game of Thrones", author: "George R.R. Martin"}
        ];
        return books.toStream();
    }

    isolated resource function subscribe students() returns stream<StudentService, error?> {
        StudentService[] students = [new StudentService(1, "Eren Yeager"), new StudentService(2, "Mikasa Ackerman")];
        return students.toStream();
    }

    isolated resource function subscribe filterValues(int value) returns stream<int, error?> {
        int[] intArray = [1, 2, 3, 4, 5];
        int[] filteredArray = [];
        foreach int i in intArray {
            if i < value {
                filteredArray.push(i);
            }
        }
        return filteredArray.toStream();
    }

    isolated resource function subscribe multipleValues() returns stream<(PeopleService)>|error {
        StudentService s = new StudentService(1, "Jesse Pinkman");
        TeacherService t = new TeacherService(0, "Walter White", "Chemistry");
        return [s, t].toStream();
    }
}
