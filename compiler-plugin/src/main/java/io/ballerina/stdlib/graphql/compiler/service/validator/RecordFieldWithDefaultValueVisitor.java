/*
 * Copyright (c) 2023, WSO2 LLC. (http://www.wso2.com). All Rights Reserved.
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

package io.ballerina.stdlib.graphql.compiler.service.validator;

import io.ballerina.compiler.api.SemanticModel;
import io.ballerina.compiler.api.symbols.Symbol;
import io.ballerina.compiler.syntax.tree.NodeVisitor;
import io.ballerina.compiler.syntax.tree.RecordFieldWithDefaultValueNode;

import java.util.Optional;

/**
 * Obtains RecordFieldWithDefaultValueNode from the syntax tree.
 */
public class RecordFieldWithDefaultValueVisitor extends NodeVisitor {
    private final SemanticModel semanticModel;
    private final String fieldName;
    private RecordFieldWithDefaultValueNode recordFieldNode;

    public RecordFieldWithDefaultValueVisitor(SemanticModel semanticModel, String fieldName) {
        this.semanticModel = semanticModel;
        this.fieldName = fieldName;
    }

    @Override
    public void visit(RecordFieldWithDefaultValueNode recordFieldNode) {
        if (this.recordFieldNode != null) {
            return;
        }
        Optional<Symbol> symbol = this.semanticModel.symbol(recordFieldNode);
        if (symbol.isPresent() && this.fieldName.equals(symbol.get().getName().orElse(null))) {
            this.recordFieldNode = recordFieldNode;
        }
    }

    public Optional<RecordFieldWithDefaultValueNode> getRecordFieldNode() {
        return Optional.ofNullable(this.recordFieldNode);
    }
}
