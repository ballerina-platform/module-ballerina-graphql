// Copyright (c) 2024, WSO2 LLC. (http://www.wso2.org) All Rights Reserved.
//
// WSO2 LLC. licenses this file to you under the Apache License,
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

package io.ballerina.stdlib.graphql.compiler;

import io.ballerina.compiler.api.SemanticModel;
import io.ballerina.compiler.api.symbols.ModuleSymbol;
import io.ballerina.compiler.api.symbols.Symbol;
import io.ballerina.compiler.api.symbols.TypeReferenceTypeSymbol;
import io.ballerina.compiler.syntax.tree.ObjectConstructorExpressionNode;
import io.ballerina.compiler.syntax.tree.QualifiedNameReferenceNode;
import io.ballerina.compiler.syntax.tree.SyntaxKind;
import io.ballerina.compiler.syntax.tree.TypeDescriptorNode;
import io.ballerina.compiler.syntax.tree.TypedBindingPatternNode;
import io.ballerina.compiler.syntax.tree.VariableDeclarationNode;
import io.ballerina.projects.DocumentId;
import io.ballerina.projects.plugins.SyntaxNodeAnalysisContext;
import io.ballerina.stdlib.graphql.commons.types.Schema;
import io.ballerina.stdlib.graphql.compiler.schema.generator.GraphqlModifierContext;
import io.ballerina.stdlib.graphql.compiler.service.InterfaceEntityFinder;
import io.ballerina.stdlib.graphql.compiler.service.validator.ServiceValidator;

import java.util.Map;
import java.util.Optional;

import static io.ballerina.stdlib.graphql.compiler.Utils.hasCompilationErrors;

public class LocalLevelServiceObjectAnalysisTask extends ServiceAnalysisTask {

    public LocalLevelServiceObjectAnalysisTask(Map<DocumentId, GraphqlModifierContext> nodeMap) {
        super(nodeMap);
    }

    private static final String PACKAGE_NAME = "graphql";
    private static final String SERVICE_NAME = "Service";

    @Override
    public void perform(SyntaxNodeAnalysisContext context) {
        if (hasCompilationErrors(context)) {
            return;
        }
        ObjectConstructorExpressionNode node = (ObjectConstructorExpressionNode) context.node();
        if (node.parent().kind() != SyntaxKind.LOCAL_VAR_DECL) {
            return;
        }
        VariableDeclarationNode parentNode = (VariableDeclarationNode) node.parent();
        if (!isGraphQLServiceObjectDeclaration(context.semanticModel(), parentNode.typedBindingPattern())) {
            return;
        }
        InterfaceEntityFinder interfaceEntityFinder = getInterfaceEntityFinder(context.semanticModel());
        ServiceValidator serviceValidator = getServiceValidator(context, node, interfaceEntityFinder);
        if (serviceValidator.isErrorOccurred()) {
            return;
        }
        Schema schema = generateSchema(context, interfaceEntityFinder, node, null);
        DocumentId documentId = context.documentId();
        addToModifierContextMap(documentId, node, schema);
    }

    public boolean isGraphQLServiceObjectDeclaration(SemanticModel semanticModel,
                                                     TypedBindingPatternNode typedBindingPatternNode) {
        TypeDescriptorNode typeDescriptorNode = typedBindingPatternNode.typeDescriptor();
        if (typeDescriptorNode.kind() != SyntaxKind.QUALIFIED_NAME_REFERENCE) {
            return false;
        }
        return isGraphqlServiceQualifiedNameReference(semanticModel, (QualifiedNameReferenceNode) typeDescriptorNode);
    }

    private boolean isGraphqlServiceQualifiedNameReference(SemanticModel semanticModel,
                                                           QualifiedNameReferenceNode nameReferenceNode) {
        Optional<Symbol> symbol = semanticModel.symbol(nameReferenceNode);
        if (symbol.isEmpty()) {
            return false;
        }
        TypeReferenceTypeSymbol typeSymbol = (TypeReferenceTypeSymbol) symbol.get();
        Optional<ModuleSymbol> moduleSymbol = typeSymbol.getModule();
        if (moduleSymbol.isEmpty()) {
            return false;
        }
        if (!isPresentAndEquals(moduleSymbol.get().getName(), PACKAGE_NAME)) {
            return false;
        }
        return isPresentAndEquals(typeSymbol.getName(), SERVICE_NAME);
    }

    private boolean isPresentAndEquals(Optional<String> actualValue, String expectedValue) {
        return actualValue.isPresent() && expectedValue.equals(actualValue.get());
    }
}
