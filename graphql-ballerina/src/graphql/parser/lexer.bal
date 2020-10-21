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

import ballerina/stringutils;

isolated function getLexicalTokens(string document) returns Token[]|InvalidTokenError? {
    CharToken[] tokens = check tokenizeCharacters(document);
    //return getTokensForWords(tokens);
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
        'type: EOF_TOKEN,
        value: EOF,
        location: currentLocation
    };
    charTokens.push(eofToken);
    return charTokens;
}

isolated function getCharToken(string value, Location location) returns CharToken|InvalidTokenError {
    Location localLocation = location.clone();
    if (stringutils:matches(value, VALID_CHAR_REGEX)) {
        return {
            'type: CHAR,
            value: value,
            location: localLocation
        };
    } else if (value is WhiteSpace) {
        return {
            'type: WHITE_SPACE,
            value: value,
            location: localLocation
        };
    } else if (value is LineTerminator) {
        return {
            'type: LINE_TERMINATOR,
            value: value,
            location: localLocation
        };
    }
    string message = "Syntax Error: Cannot parse the unexpected character \"" + value + "\".";
    ErrorRecord errorRecord = {
        locations: [localLocation]
    };
    return InvalidTokenError(message, errorRecord = errorRecord);
}

//isolated function getTokensForWords(CharToken[] tokens) returns Token[]|InvalidTokenError {
//    check validateCharTokens(tokens);
//    Token[] wordTokens = [];
//    string word = "";
//    Location location = {
//        line: 1,
//        column: 1
//    };
//    foreach CharToken charToken in tokens {
//        CharTokenType tokenType = charToken.'type;
//        string value = charToken.value;
//        if (word == "") {
//            location = charToken.location.clone();
//        }
//        if (tokenType == CHAR) {
//            word += value;
//        } else if (tokenType == LINE_TERMINATOR || tokenType == WHITE_SPACE) {
//             addWord(word, location, wordTokens);
//             word = "";
//        } else if (tokenType is EOF_TOKEN) {
//            wordTokens.push({
//                value: charToken.value,
//                location: charToken.location
//            });
//            word = "";
//        }
//    }
//    return wordTokens;
//}

//isolated function addWord(string value, Location location, Token[] tokens) {
//    if (value != "") {
//        Token token = {
//            'type: WORD,
//            value: value,
//            location: location
//        };
//        tokens.push(token);
//    }
//}

//isolated function checkForComments(Token token, int currentLine, boolean isComment) returns [int, boolean] {
//    int nextLine = token.location.line;
//    boolean comment = isComment;
//    if (nextLine > currentLine) {
//        nextLine = nextLine;
//        comment = false;
//    }
//    if (token.value == COMMENT) {
//        comment = true;
//    }
//    return [nextLine, comment];
//}

isolated function updateLocation(string char, Location location) {
    if (char is LineTerminator) {
        location.column = 1;
        location.line += 1;
    } else {
        location.column += 1;
    }
}

isolated function validateCharTokens(CharToken[] tokens) returns InvalidTokenError? {
    if (tokens.length() == 1) {
        string message = "Syntax Error: Unexpected <EOF>.";
        ErrorRecord errorRecord = getErrorRecordFromToken({
            value: tokens[0].value,
            location: tokens[0].location
        });
        return InvalidTokenError(message, errorRecord = errorRecord);
    }
}

