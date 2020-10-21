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

//import ballerina/stringutils;

isolated function getLexicalTokens(string document) returns Token[]|InvalidTokenError {
    CharToken[] tokens = check tokenizeCharacters(document);
    return getWordTokens(tokens);
}

isolated function tokenizeCharacters(string document) returns CharToken[]|InvalidTokenError {
    CharToken[] charTokens = [];
    Location currentLocation = {
        line: 1,
        column: 1
    };

    Iterator iterator = document.iterator();
    while (true) {
        IteratorNode? next = iterator.next();
        if (next is ()) {
            break;
        }
        IteratorNode nextNode = <IteratorNode>next;
        string nextChar = nextNode.value;
        CharToken token = check getCharToken(nextChar, currentLocation);
        updateLocation(nextChar, currentLocation);
        charTokens.push(token);
    }
    CharToken eofToken = {
        'type: EOF,
        value: EOF,
        location: currentLocation
    };
    charTokens.push(eofToken);
    return charTokens;
}

isolated function getCharToken(string value, Location location) returns CharToken|InvalidTokenError {
    Location localLocation = location.clone();
    if (value is SpecialCharacter) {
        return {
            'type: value,
            value: value,
            location: localLocation
        };
    }
    return {
        'type: CHAR,
        value: value,
        location: localLocation
    };
}

isolated function getWordTokens(CharToken[] charTokens) returns Token[]|InvalidTokenError {
    Token[] wordTokens = [];
    string word = "";
    Location location = {
        line: 1,
        column: 1
    };
    foreach CharToken charToken in charTokens {
        CharTokenType tokenType = charToken.'type;
        string value = charToken.value;
        if (word == "") {
            location = charToken.location.clone();
        }
        if (tokenType == CHAR) {
            word += value;
        } else if (tokenType is SpecialCharacter) {
            addWord(word, location, wordTokens);
            wordTokens.push({
                'type: tokenType,
                value: charToken.value,
                location: charToken.location
            });
            word = "";
        }
    }
    return wordTokens;
}

isolated function addWord(string value, Location location, Token[] tokens) {
    if (value != "") {
        Token token = {
            'type: WORD,
            value: value,
            location: location
        };
        tokens.push(token);
    }
}

isolated function updateLocation(string char, Location location) {
    if (char is LineTerminator) {
        location.column = 1;
        location.line += 1;
    } else {
        location.column += 1;
    }
}

