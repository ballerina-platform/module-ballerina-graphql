/*
 * Copyright (c) 2021, WSO2 Inc. (http://www.wso2.org) All Rights Reserved.
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

package io.ballerina.stdlib.graphql.compiler.schema.generator;

import io.ballerina.compiler.api.symbols.ModuleSymbol;
import io.ballerina.compiler.api.symbols.ServiceDeclarationSymbol;
import io.ballerina.compiler.api.symbols.Symbol;
import io.ballerina.compiler.api.symbols.TypeDescKind;
import io.ballerina.compiler.api.symbols.TypeSymbol;
import io.ballerina.compiler.api.symbols.UnionTypeSymbol;
import io.ballerina.compiler.syntax.tree.ServiceDeclarationNode;
import io.ballerina.compiler.syntax.tree.SyntaxKind;
import io.ballerina.projects.plugins.AnalysisTask;
import io.ballerina.projects.plugins.SyntaxNodeAnalysisContext;

import java.util.List;
import java.util.Optional;

import static io.ballerina.stdlib.graphql.compiler.Utils.isGraphqlModule;

/**
 * Performs compiler analysis task to generate the GraphQL schema from a Ballerina service.
 */
public class SchemaGeneratorTask implements AnalysisTask<SyntaxNodeAnalysisContext> {

    @Override
    public void perform(SyntaxNodeAnalysisContext syntaxNodeAnalysisContext) {
        ServiceDeclarationSymbol serviceDeclarationSymbol = getGraphqlServiceDeclarationNode(syntaxNodeAnalysisContext);
        if (serviceDeclarationSymbol != null) {
            FunctionAnalyzer functionAnalyzer = new FunctionAnalyzer();
            functionAnalyzer.generate();
        }
    }

    private static ServiceDeclarationSymbol getGraphqlServiceDeclarationNode(SyntaxNodeAnalysisContext context) {
        if (context.node().isMissing() || context.node().kind() != SyntaxKind.SERVICE_DECLARATION) {
            return null;
        }
        ServiceDeclarationNode serviceDeclarationNode = (ServiceDeclarationNode) context.node();
        Optional<Symbol> nodeSymbol = context.semanticModel().symbol(serviceDeclarationNode);
        if (nodeSymbol.isEmpty()) {
            return null;
        }
        ServiceDeclarationSymbol serviceDeclarationSymbol = (ServiceDeclarationSymbol) nodeSymbol.get();
        List<TypeSymbol> listeners = serviceDeclarationSymbol.listenerTypes();
        if (listeners.size() != 1) {
            return null;
        }
        if (listeners.get(0).typeKind() == TypeDescKind.UNION) {
            if (isValidListenerTypeUnion((UnionTypeSymbol) listeners.get(0))) {
                return serviceDeclarationSymbol;
            }
        } else {
            Optional<ModuleSymbol> moduleSymbol = listeners.get(0).getModule();
            if (isGraphqlModule(moduleSymbol)) {
                return serviceDeclarationSymbol;
            }
        }
        return null;
    }

    private static boolean isValidListenerTypeUnion(UnionTypeSymbol unionTypeSymbol) {
        List<TypeSymbol> memberTypes = unionTypeSymbol.memberTypeDescriptors();
        for (TypeSymbol typeSymbol : memberTypes) {
            Optional<ModuleSymbol> moduleSymbol = typeSymbol.getModule();
            if (moduleSymbol.isPresent()) {
                return isGraphqlModule(moduleSymbol);
            }
        }
        return false;
    }
}
