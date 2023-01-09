/*
 * Copyright (c) 2022, WSO2 LLC. (http://www.wso2.org). All Rights Reserved.
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

package io.ballerina.stdlib.graphql.commons.types;

import java.io.Serializable;

/**
 * Represents the {@code position} in GraphQL schema.
 */
public class Position implements Serializable {
    private static final long serialVersionUID = 1L;
    private final String filePath;
    private final LinePosition starLine;
    private final LinePosition endLine;

    public Position(String filePath, LinePosition starLine, LinePosition endLine) {
        this.filePath = filePath;
        this.starLine = starLine;
        this.endLine = endLine;
    }

    public String getFilePath() {
        return filePath;
    }

    public LinePosition getStarLine() {
        return starLine;
    }

    public LinePosition getEndLine() {
        return endLine;
    }
}
