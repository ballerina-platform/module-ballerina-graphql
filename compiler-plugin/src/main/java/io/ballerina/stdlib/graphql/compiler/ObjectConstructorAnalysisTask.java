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
import io.ballerina.compiler.api.symbols.Symbol;
import io.ballerina.compiler.syntax.tree.ModuleVariableDeclarationNode;
import io.ballerina.compiler.syntax.tree.Node;
import io.ballerina.compiler.syntax.tree.NonTerminalNode;
import io.ballerina.compiler.syntax.tree.ObjectConstructorExpressionNode;
import io.ballerina.compiler.syntax.tree.ObjectFieldNode;
import io.ballerina.compiler.syntax.tree.SyntaxKind;
import io.ballerina.compiler.syntax.tree.VariableDeclarationNode;
import io.ballerina.projects.DocumentId;
import io.ballerina.projects.plugins.SyntaxNodeAnalysisContext;
import io.ballerina.stdlib.graphql.commons.types.Schema;
import io.ballerina.stdlib.graphql.compiler.service.InterfaceEntityFinder;
import io.ballerina.stdlib.graphql.compiler.service.validator.ServiceValidator;

import java.util.Map;
import java.util.Optional;

import static io.ballerina.stdlib.graphql.commons.utils.Utils.isGraphqlModuleSymbol;
import static io.ballerina.stdlib.graphql.compiler.Utils.hasCompilationErrors;

public class ObjectConstructorAnalysisTask extends ServiceAnalysisTask {

    public ObjectConstructorAnalysisTask(Map<String, Object> nodeMap) {
        super(nodeMap);
    }

    @Override
    public void perform(SyntaxNodeAnalysisContext context) {
        if (hasCompilationErrors(context)) {
            return;
        }
        ObjectConstructorExpressionNode node = (ObjectConstructorExpressionNode) context.node();
        if (!isGraphQLServiceObjectDeclaration(context.semanticModel(), (NonTerminalNode) context.node())) {
            return;
        }

        InterfaceEntityFinder interfaceEntityFinder = getInterfaceEntityFinder(context.semanticModel());
        ServiceValidator serviceValidator = getServiceValidator(context, node, interfaceEntityFinder,
                                                    new CacheConfigContext(false));
        if (serviceValidator.isErrorOccurred()) {
            return;
        }
        Schema schema = generateSchema(context, interfaceEntityFinder, node, null);
        DocumentId documentId = context.documentId();
        addToModifierContextMap(documentId, node.parent(), schema);
        addToModifierContextMap(documentId, node.parent(), serviceValidator.getCacheConfigContext());
    }

    public boolean isGraphQLServiceObjectDeclaration(SemanticModel semanticModel,
                                                     NonTerminalNode node) {
        Node typeReferenceNode;
        if (node.parent().kind() == SyntaxKind.LOCAL_VAR_DECL) {
            typeReferenceNode = ((VariableDeclarationNode) node.parent()).typedBindingPattern()
                                                                         .typeDescriptor();
        } else if (node.parent().kind() == SyntaxKind.MODULE_VAR_DECL) {
            typeReferenceNode = ((ModuleVariableDeclarationNode) node.parent()).typedBindingPattern()
                                                                               .typeDescriptor();
        } else if (node.parent().kind() == SyntaxKind.OBJECT_FIELD) {
            typeReferenceNode = ((ObjectFieldNode) node.parent()).typeName();
        } else {
            return false;
        }
        Optional<Symbol> typeReferenceSymbol = semanticModel.symbol(typeReferenceNode);
        return typeReferenceSymbol.isPresent() && isGraphqlModuleSymbol(typeReferenceSymbol.get());
    }

}
