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
import io.ballerina.compiler.api.symbols.RecordTypeSymbol;
import io.ballerina.compiler.api.symbols.Symbol;
import io.ballerina.compiler.api.symbols.TypeDefinitionSymbol;
import io.ballerina.compiler.syntax.tree.NodeVisitor;
import io.ballerina.compiler.syntax.tree.TypeDefinitionNode;

import java.util.Optional;

/**
 * Obtains record definition node from the syntax tree.
 */
public class RecordTypeDefinitionNodeVisitor extends NodeVisitor {
    private final RecordTypeSymbol recordTypeSymbol;
    private final SemanticModel semanticModel;
    private final String recordTypeName;
    private TypeDefinitionNode typeDefinitionNode;

    public RecordTypeDefinitionNodeVisitor(SemanticModel semanticModel, RecordTypeSymbol recordTypeSymbol,
                                           String recordTypeName) {
        this.semanticModel = semanticModel;
        this.recordTypeSymbol = recordTypeSymbol;
        this.recordTypeName = recordTypeName;
    }

    @Override
    public void visit(TypeDefinitionNode typeDefinitionNode) {
        if (this.typeDefinitionNode != null) {
            return;
        }
        Optional<Symbol> recordTypeDefSymbol = this.semanticModel.symbol(typeDefinitionNode);
        if (recordTypeDefSymbol.isEmpty()) {
            return;
        }
        TypeDefinitionSymbol recordTypeDef = (TypeDefinitionSymbol) recordTypeDefSymbol.get();
        if (recordTypeDef.getName().isEmpty() || !this.recordTypeName.equals(recordTypeDef.getName().get())) {
            return;
        }
        if (recordTypeDef.typeDescriptor().equals(this.recordTypeSymbol)) {
            this.typeDefinitionNode = typeDefinitionNode;
        }
    }

    public Optional<TypeDefinitionNode> getRecordTypeDefinitionNode() {
        return Optional.ofNullable(this.typeDefinitionNode);
    }
}
