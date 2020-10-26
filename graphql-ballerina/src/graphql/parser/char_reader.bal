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

class CharReader {
    private CharIterator iterator;
    private boolean isEof;
    private Location currentLocation;

    public isolated function init(string document) {
        self.iterator = document.iterator();
        self.isEof = false;
        self.currentLocation = {
            line: 1,
            column: 1
        };
    }

    isolated function getNext() returns CharToken|InvalidTokenError? {
        if (self.isEof) {
            return;
        }
        CharIteratorNode? next = self.iterator.next();
        if (next is ()) {
            CharToken eofToken = {
                value: EOF,
                location: self.currentLocation
            };
            self.isEof = true;
            return eofToken;
        }
        CharIteratorNode nextNode = <CharIteratorNode>next;
        string nextChar = nextNode.value;
        CharToken token = getCharToken(nextChar, self.currentLocation);
        updateLocation(nextChar, self.currentLocation);
        return token;
    }
}

type CharIteratorNode record {
    string value;
};

type CharIterator object {
    public isolated function next() returns CharIteratorNode?;
};

isolated function updateLocation(string char, Location location) {
    if (char is LineTerminator) {
        location.column = 1;
        location.line += 1;
    } else {
        location.column += 1;
    }
}

isolated function getCharToken(string value, Location location) returns CharToken {
    Location localLocation = location.clone();
    return {
        value: value,
        location: localLocation
    };
}
