// Copyright (c) 2025, WSO2 Inc. (http://www.wso2.org) All Rights Reserved.
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

final int DIGIT_TAG = 1;
final int EXP_TAG = 2;
final int WHITE_SPACE_TAG = 3;
final int LINE_TERMINATOR_TAG = 4;
final int COMMA_TAG = 5;
final int SPECIAL_CHARACTER_TAG = 6;

public final map<int> & readonly symbolTable = {
    "0": DIGIT_TAG,
    "1": DIGIT_TAG,
    "2": DIGIT_TAG,
    "3": DIGIT_TAG,
    "4": DIGIT_TAG,
    "5": DIGIT_TAG,
    "6": DIGIT_TAG,
    "7": DIGIT_TAG,
    "8": DIGIT_TAG,
    "9": DIGIT_TAG,
    "!": SPECIAL_CHARACTER_TAG,
    "$": SPECIAL_CHARACTER_TAG,
    "(": SPECIAL_CHARACTER_TAG,
    ")": SPECIAL_CHARACTER_TAG,
    "...": SPECIAL_CHARACTER_TAG,
    ":": SPECIAL_CHARACTER_TAG,
    "=": SPECIAL_CHARACTER_TAG,
    "@": SPECIAL_CHARACTER_TAG,
    "[": SPECIAL_CHARACTER_TAG,
    "]": SPECIAL_CHARACTER_TAG,
    "{": SPECIAL_CHARACTER_TAG,
    "|": SPECIAL_CHARACTER_TAG,
    "}": SPECIAL_CHARACTER_TAG,
    "\"": SPECIAL_CHARACTER_TAG,
    " ": WHITE_SPACE_TAG,
    "\t": WHITE_SPACE_TAG,
    "\n": LINE_TERMINATOR_TAG,
    "\r": LINE_TERMINATOR_TAG,
    "": LINE_TERMINATOR_TAG,
    ",": COMMA_TAG,
    "e": EXP_TAG,
    "E": EXP_TAG
};