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

public class CharReader {
    private CharIterator iterator;
    private string:Char?[] buffer;

    public isolated function init(string document) {
        self.iterator = document.iterator();
        self.buffer = [];
    }

    public isolated function peek(int into = 0) returns string:Char? {
        if self.buffer.length() > into {
            return self.buffer[into];
        }
        int startIndex = self.buffer.length();
        foreach int i in startIndex ... into {
            string:Char? char = self.next();
            self.buffer.push(char);
        }
        return self.buffer[into];
    }

    public isolated function read() returns string:Char? {
        if self.buffer.length() > 0 {
            return self.buffer.shift();
        }
        return self.next();
    }

    isolated function next() returns string:Char? {
        CharIteratorNode? next = self.iterator.next();
        if next is () {
            return;
        }
        return next.value;
    }
}
