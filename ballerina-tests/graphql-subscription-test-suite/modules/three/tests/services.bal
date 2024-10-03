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

    isolated resource function subscribe messages() returns stream<int, error?> {
        int[] intArray = [1, 2, 3, 4, 5];
        return intArray.toStream();
    }

    isolated resource function subscribe students() returns stream<StudentService, error?> {
        StudentService[] students = [new StudentService(1, "Eren Yeager"), new StudentService(2, "Mikasa Ackerman")];
        return students.toStream();
    }

    isolated resource function subscribe values() returns stream<int>|error {
        int[] array = [];
        int _ = check trap array.remove(0);
        return array.toStream();
    }

    isolated resource function subscribe evenNumber() returns stream<int, error?> {
        EvenNumberGenerator evenNumberGenerator = new;
        return new (evenNumberGenerator);
    }
}

service /reviews on wrappedListener {
    resource function get greet() returns string {
        return "Welcome!";
    }

    resource function subscribe live() returns stream<Review> {
        return reviews.toArray().toStream();
    }

    resource function subscribe accountUpdates() returns stream<AccountRecords> {
        map<AccountDetails> details = {acc1: new AccountDetails("James", 2022), acc2: new AccountDetails("Paul", 2015)};
        map<AccountDetails> updatedDetails = {...details};
        updatedDetails["acc1"] = new AccountDetails("James Deen", 2022);
        return [{details}, {details: updatedDetails}].toStream();
    }
}
