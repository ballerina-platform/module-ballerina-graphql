/*
 * Copyright (c) 2020, WSO2 Inc. (http://www.wso2.org) All Rights Reserved.
 *
 * WSO2 Inc. licenses this file to you under the Apache License,
 * Version 2.0 (the "License"); you may not use this file except
 * in compliance with the License.
 * You may obtain a copy of the License at
 *
 *    http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing,
 * software distributed under the License is distributed on an
 * "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
 * KIND, either express or implied. See the License for the
 * specific language governing permissions and limitations
 * under the License.
 */

package io.ballerina.stdlib.graphql.runtime.parser;

import io.ballerina.runtime.api.values.BString;

/**
 * This class is used to implement utility functions for the Ballerina GraphQL parser.
 */
public class ParserUtils {

    /**
     * Validates whether a given character is a valid first character for a GraphQL identifier. The input is a BString,
     * but it should only contain a single character.
     *
     * @param character - The {@code BString} value of the character to be validated
     * @return {@code true} if the character is a valid first character for a GraphQL identifier, otherwise {@code
     * false}
     */
    public static boolean isValidFirstChar(BString character) {
        int c = character.getValue().charAt(0);
        return isIdentifierInitialChar(c);
    }

    /**
     * Validates whether a given character is a valid non-first character for a GraphQL identifier. The input is a
     * BString, but it should only contain a single character.
     *
     * @param character - The {@code BString} value of the character to be validated
     * @return {@code true} if the character is a valid non-first character for a GraphQL identifier, otherwise {@code
     * false}
     */
    public static boolean isValidChar(BString character) {
        int c = character.getValue().charAt(0);
        return isIdentifierInitialChar(c) || isDigit(c);
    }

    private static boolean isIdentifierInitialChar(int c) {
        if ('A' <= c && 'Z' >= c) {
            return true;
        }

        if ('a' <= c && 'z' >= c) {
            return true;
        }

        return c == '_';
    }

    private static boolean isDigit(int c) {
        return ('0' <= c && '9' >= c);
    }
}
