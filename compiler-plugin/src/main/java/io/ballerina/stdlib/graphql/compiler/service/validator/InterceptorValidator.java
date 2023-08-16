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

import io.ballerina.compiler.api.symbols.MethodSymbol;
import io.ballerina.compiler.api.symbols.ResourceMethodSymbol;
import io.ballerina.compiler.api.symbols.Symbol;
import io.ballerina.compiler.api.symbols.SymbolKind;
import io.ballerina.compiler.api.symbols.TypeReferenceTypeSymbol;
import io.ballerina.compiler.syntax.tree.ClassDefinitionNode;
import io.ballerina.compiler.syntax.tree.Node;
import io.ballerina.compiler.syntax.tree.NodeList;
import io.ballerina.compiler.syntax.tree.SyntaxKind;
import io.ballerina.projects.plugins.SyntaxNodeAnalysisContext;
import io.ballerina.stdlib.graphql.compiler.diagnostics.CompilationDiagnostic;
import io.ballerina.tools.diagnostics.Location;

import static io.ballerina.stdlib.graphql.commons.utils.Utils.isGraphqlModuleSymbol;
import static io.ballerina.stdlib.graphql.compiler.Utils.isRemoteMethod;
import static io.ballerina.stdlib.graphql.compiler.service.validator.ValidatorUtils.GRAPHQL_INTERCEPTOR;
import static io.ballerina.stdlib.graphql.compiler.service.validator.ValidatorUtils.INTERCEPTOR_EXECUTE;
import static io.ballerina.stdlib.graphql.compiler.service.validator.ValidatorUtils.updateContext;

/**
 * Validate Interceptors in Ballerina GraphQL services.
 */
public class InterceptorValidator {

    private final ClassDefinitionNode classDefinitionNode;
    private final SyntaxNodeAnalysisContext context;
    private boolean errorOccurred;

    public InterceptorValidator(SyntaxNodeAnalysisContext context, ClassDefinitionNode classDefinitionNode) {
        this.context = context;
        this.classDefinitionNode = classDefinitionNode;
        this.errorOccurred = false;
    }

    public void validate() {
        NodeList<Node> members = this.classDefinitionNode.members();
        for (Node member : members) {
            if (member.kind() == SyntaxKind.TYPE_REFERENCE) {
                if (isInterceptor(member)) {
                    validateInterceptorService(members);
                    break;
                }
            }
        }
    }

    public boolean isErrorOccurred() {
        return this.errorOccurred;
    }

    private void validateInterceptorService(NodeList<Node> members) {
        for (Node node : members) {
            validateInterceptorServiceMember(node);
        }
    }

    private void validateInterceptorServiceMember(Node node) {
        if (this.context.semanticModel().symbol(node).isEmpty()) {
            return;
        }
        Symbol symbol = this.context.semanticModel().symbol(node).get();
        Location location = node.location();
        if (symbol.kind() == SymbolKind.METHOD) {
            MethodSymbol methodSymbol = (MethodSymbol) symbol;
            if (isRemoteMethod(methodSymbol)) {
                validateRemoteMethod(methodSymbol, location);
            }
        } else if (symbol.kind() == SymbolKind.RESOURCE_METHOD) {
            ResourceMethodSymbol resourceMethodSymbol = (ResourceMethodSymbol) symbol;
            String resourceMethodSignature = resourceMethodSymbol.signature();
            addDiagnostic(CompilationDiagnostic.RESOURCE_METHOD_INSIDE_INTERCEPTOR, location, resourceMethodSignature);
        }
    }

    private void validateRemoteMethod(MethodSymbol methodSymbol, Location location) {
        if (methodSymbol.getName().isEmpty()) {
            return;
        }
        if (!methodSymbol.getName().get().equals(INTERCEPTOR_EXECUTE)) {
            addDiagnostic(CompilationDiagnostic.INVALID_REMOTE_METHOD_INSIDE_INTERCEPTOR, location,
                          methodSymbol.signature());
        }
    }

    public boolean isInterceptor(Node member) {
        if (this.context.semanticModel().symbol(member).isEmpty()) {
            return false;
        }
        Symbol symbol = this.context.semanticModel().symbol(member).get();
        TypeReferenceTypeSymbol typeReferenceTypeSymbol = (TypeReferenceTypeSymbol) symbol;
        if (typeReferenceTypeSymbol.getName().isEmpty()) {
            return false;
        }
        if (!isGraphqlModuleSymbol(typeReferenceTypeSymbol)) {
            return false;
        }
        return GRAPHQL_INTERCEPTOR.equals(typeReferenceTypeSymbol.getName().get());
    }

    private void addDiagnostic(CompilationDiagnostic compilationDiagnostic, Location location, Object ...args) {
        this.errorOccurred = true;
        updateContext(this.context, compilationDiagnostic, location, args);
    }
}
