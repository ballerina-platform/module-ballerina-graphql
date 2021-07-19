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
    private boolean eof;
    private string[] buffer;

    public isolated function init(string document) {
        self.iterator = document.iterator();
        self.eof = false;
        self.buffer = [];
    }

    public isolated function isEof() returns boolean {
        return self.eof;
    }

    public isolated function peek() returns string {
        if (self.buffer.length() > 0) {
            return self.buffer[0];
        }
        string char = self.read();
        self.buffer.push(char);
        return char;
    }

    public isolated function read() returns string {
        if (self.buffer.length() > 0) {
            return self.buffer.shift();
        }
        CharIteratorNode? next = self.iterator.next();
        if (next is ()) {
            self.eof = true;
            return EOF;
        }
        CharIteratorNode nextNode = <CharIteratorNode>next;
        return nextNode.value;
    }
}
