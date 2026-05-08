/*
 * Copyright (c) 2026, WSO2 LLC. (http://www.wso2.com).
 *
 * WSO2 LLC. licenses this file to you under the Apache License,
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

package io.ballerina.stdlib.graphql.compiler.endpointyaml.generator;

import org.apache.commons.text.StringEscapeUtils;

import java.util.regex.Matcher;
import java.util.regex.Pattern;

public final class Utils {
    private static final String UNICODE_REGEX = "\\\\(\\\\*)u\\{([a-fA-F0-9]+)\\}";
    private static final Pattern UNICODE_PATTERN = Pattern.compile(UNICODE_REGEX);

    private Utils() {
    }

    public static String unescapeBallerina(String text) {
        return unescapeJava(unescapeUnicodeCodepoints(text));
    }

    public static String unescapeJava(String str) {
        return StringEscapeUtils.unescapeJava(str);
    }

    public static String unescapeUnicodeCodepoints(String identifier) {
        Matcher matcher = UNICODE_PATTERN.matcher(identifier);
        StringBuilder buffer = new StringBuilder(identifier.length());
        while (matcher.find()) {
            String leadingSlashes = matcher.group(1);
            if (isEscapedNumericEscape(leadingSlashes)) {
                continue;
            }

            int codePoint = Integer.parseInt(matcher.group(2), 16);
            char[] chars = Character.toChars(codePoint);
            String ch = String.valueOf(chars);

            if (ch.equals("\\")) {
                matcher.appendReplacement(buffer, Matcher.quoteReplacement(leadingSlashes + "\\u005C"));
            } else {
                matcher.appendReplacement(buffer, Matcher.quoteReplacement(leadingSlashes + ch));
            }
        }
        matcher.appendTail(buffer);
        return String.valueOf(buffer);
    }

    public static boolean isEscapedNumericEscape(String leadingSlashes) {
        return !isEven(leadingSlashes.length());
    }

    private static boolean isEven(int n) {
        return (n & 1) == 0;
    }
}
