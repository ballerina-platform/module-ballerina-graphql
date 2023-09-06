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
import io.ballerina.compiler.api.symbols.MethodSymbol;
import io.ballerina.compiler.api.symbols.ParameterSymbol;
import io.ballerina.compiler.api.symbols.Symbol;
import io.ballerina.compiler.api.symbols.SymbolKind;
import io.ballerina.compiler.syntax.tree.FunctionDefinitionNode;
import io.ballerina.compiler.syntax.tree.NodeVisitor;
import io.ballerina.compiler.syntax.tree.ParameterNode;

import java.util.Optional;

/**
 * Used to obtain ParameterNode from the syntax tree.
 */
public class MethodDefinitionNodeVisitor extends NodeVisitor {
    private final SemanticModel semanticModel;
    private final MethodSymbol methodSymbol;
    private final ParameterSymbol parameterSymbol;
    private ParameterNode parameterNode;

    public MethodDefinitionNodeVisitor(SemanticModel semanticModel, MethodSymbol methodSymbol,
                                       ParameterSymbol parameterSymbol) {
        this.semanticModel = semanticModel;
        this.methodSymbol = methodSymbol;
        this.parameterSymbol = parameterSymbol;
    }

    @Override
    public void visit(FunctionDefinitionNode functionDefinitionNode) {
        if (this.parameterNode != null) {
            return;
        }
        Optional<Symbol> functionSymbol = this.semanticModel.symbol(functionDefinitionNode);
        if (functionSymbol.isEmpty() || !functionSymbol.get().equals(this.methodSymbol)) {
            return;
        }
        for (ParameterNode paramNode : functionDefinitionNode.functionSignature().parameters()) {
            if (this.semanticModel.symbol(paramNode).isEmpty()) {
                continue;
            }
            Symbol symbol = this.semanticModel.symbol(paramNode).get();
            if (symbol.kind() == SymbolKind.PARAMETER && symbol.equals(this.parameterSymbol)) {
                this.parameterNode = paramNode;
            }
        }
    }

    public Optional<ParameterNode> getParameterNode() {
        return Optional.ofNullable(this.parameterNode);
    }
}
