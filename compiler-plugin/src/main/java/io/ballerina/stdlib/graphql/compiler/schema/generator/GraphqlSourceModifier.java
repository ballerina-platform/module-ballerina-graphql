/*
 * Copyright (c) 2022, WSO2 Inc. (http://www.wso2.org) All Rights Reserved.
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

import io.ballerina.compiler.syntax.tree.AnnotationNode;
import io.ballerina.compiler.syntax.tree.ExpressionNode;
import io.ballerina.compiler.syntax.tree.IdentifierToken;
import io.ballerina.compiler.syntax.tree.MappingConstructorExpressionNode;
import io.ballerina.compiler.syntax.tree.MappingFieldNode;
import io.ballerina.compiler.syntax.tree.MetadataNode;
import io.ballerina.compiler.syntax.tree.ModuleMemberDeclarationNode;
import io.ballerina.compiler.syntax.tree.ModulePartNode;
import io.ballerina.compiler.syntax.tree.Node;
import io.ballerina.compiler.syntax.tree.NodeFactory;
import io.ballerina.compiler.syntax.tree.NodeList;
import io.ballerina.compiler.syntax.tree.NodeParser;
import io.ballerina.compiler.syntax.tree.QualifiedNameReferenceNode;
import io.ballerina.compiler.syntax.tree.SeparatedNodeList;
import io.ballerina.compiler.syntax.tree.ServiceDeclarationNode;
import io.ballerina.compiler.syntax.tree.SimpleNameReferenceNode;
import io.ballerina.compiler.syntax.tree.SpecificFieldNode;
import io.ballerina.compiler.syntax.tree.SyntaxKind;
import io.ballerina.compiler.syntax.tree.SyntaxTree;
import io.ballerina.compiler.syntax.tree.Token;
import io.ballerina.projects.DocumentId;
import io.ballerina.projects.Module;
import io.ballerina.projects.plugins.ModifierTask;
import io.ballerina.projects.plugins.SourceModifierContext;
import io.ballerina.stdlib.graphql.compiler.schema.types.Schema;
import io.ballerina.stdlib.graphql.compiler.service.errors.CompilationError;
import io.ballerina.tools.diagnostics.Diagnostic;
import io.ballerina.tools.diagnostics.DiagnosticFactory;
import io.ballerina.tools.diagnostics.DiagnosticInfo;
import io.ballerina.tools.diagnostics.Location;
import io.ballerina.tools.text.TextDocument;

import java.io.ByteArrayOutputStream;
import java.io.IOException;
import java.io.ObjectOutputStream;
import java.nio.charset.StandardCharsets;
import java.util.ArrayList;
import java.util.Base64;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

import static io.ballerina.stdlib.graphql.compiler.Utils.PACKAGE_NAME;
import static io.ballerina.stdlib.graphql.compiler.Utils.SERVICE_CONFIG_IDENTIFIER;
import static io.ballerina.stdlib.graphql.compiler.schema.generator.GeneratorUtils.SCHEMA_STRING_FIELD;

/**
 * Modifies the GraphQL service to add an annotation to the service with the generated schema.
 */
public class GraphqlSourceModifier implements ModifierTask<SourceModifierContext> {
    private final Map<DocumentId, GraphqlModifierContext> modifierContextMap;

    public GraphqlSourceModifier(Map<DocumentId, GraphqlModifierContext> modifierContextMap) {
        this.modifierContextMap = modifierContextMap;
    }

    @Override
    public void modify(SourceModifierContext sourceModifierContext) {
        for (Map.Entry<DocumentId, GraphqlModifierContext> entry : this.modifierContextMap.entrySet()) {
            DocumentId documentId = entry.getKey();
            GraphqlModifierContext modifierContext = entry.getValue();
            Module module = sourceModifierContext.currentPackage().module(documentId.moduleId());
            ModulePartNode rootNode = module.document(documentId).syntaxTree().rootNode();
            ModulePartNode updatedRootNode = modifyDocument(sourceModifierContext, rootNode, modifierContext);
            SyntaxTree syntaxTree = module.document(documentId).syntaxTree().modifyWith(updatedRootNode);
            TextDocument textDocument = syntaxTree.textDocument();
            if (module.documentIds().contains(documentId)) {
                sourceModifierContext.modifySourceFile(textDocument, documentId);
            } else {
                sourceModifierContext.modifyTestSourceFile(textDocument, documentId);
            }
        }
    }

    private ModulePartNode modifyDocument(SourceModifierContext context, ModulePartNode rootNode,
                                          GraphqlModifierContext modifierContext) {
        Map<ServiceDeclarationNode, ServiceDeclarationNode> nodeMap = new HashMap<>();
        Map<ServiceDeclarationNode, Schema> nodeSchemaMap = modifierContext.getNodeSchemaMap();
        for (Map.Entry<ServiceDeclarationNode, Schema> entry : nodeSchemaMap.entrySet()) {
            Schema schema = entry.getValue();
            try {
                String schemaString = getSchemaAsEncodedString(schema);
                ServiceDeclarationNode updatedNode = modifyServiceNode(entry.getKey(), schemaString);
                nodeMap.put(entry.getKey(), updatedNode);
            } catch (IOException e) {
                updateContext(context, entry.getKey().location());
            }
        }
        NodeList<ModuleMemberDeclarationNode> members = NodeFactory.createNodeList();
        for (ModuleMemberDeclarationNode member : rootNode.members()) {
            if (member.kind() == SyntaxKind.SERVICE_DECLARATION) {
                if (nodeMap.containsKey((ServiceDeclarationNode) member)) {
                    members = members.add(nodeMap.get(member));
                    continue;
                }
            }
            members = members.add(member);
        }
        return rootNode.modify(rootNode.imports(), members, rootNode.eofToken());
    }

    private ServiceDeclarationNode modifyServiceNode(ServiceDeclarationNode node, String schemaString) {
        MetadataNode metadataNode = getMetadataNode(node, schemaString);
        return node.modify().withMetadata(metadataNode).apply();
    }

    private MetadataNode getMetadataNode(ServiceDeclarationNode node, String schemaString) {
        if (node.metadata().isPresent()) {
            return getMetadataNodeFromExistingMetadata(node.metadata().get(), schemaString);
        } else {
            return getNewMetadataNode(schemaString);
        }
    }

    private MetadataNode getMetadataNodeFromExistingMetadata(MetadataNode metadataNode, String schemaString) {
        NodeList<AnnotationNode> annotationNodes = NodeFactory.createNodeList();
        if (metadataNode.annotations().isEmpty()) {
            AnnotationNode annotationNode = getSchemaStringAnnotation(schemaString);
            annotationNodes = annotationNodes.add(annotationNode);
        } else {
            boolean isAnnotationFound = false;
            for (AnnotationNode annotationNode : metadataNode.annotations()) {
                if (isGraphqlServiceConfig(annotationNode)) {
                    isAnnotationFound = true;
                    annotationNode = updateAnnotationNode(annotationNode, schemaString);
                }
                annotationNodes = annotationNodes.add(annotationNode);
            }
            if (!isAnnotationFound) {
                AnnotationNode annotationNode = getSchemaStringAnnotation(schemaString);
                annotationNodes = annotationNodes.add(annotationNode);
            }
        }
        return NodeFactory.createMetadataNode(metadataNode.documentationString().orElse(null), annotationNodes);
    }

    private AnnotationNode updateAnnotationNode(AnnotationNode annotationNode, String schemaString) {
        if (annotationNode.annotValue().isPresent()) {
            SeparatedNodeList<MappingFieldNode> updatedFields =
                    getUpdatedFields(annotationNode.annotValue().get(), schemaString);
            MappingConstructorExpressionNode node =
                    NodeFactory.createMappingConstructorExpressionNode(
                            NodeFactory.createToken(SyntaxKind.OPEN_BRACE_TOKEN), updatedFields,
                            NodeFactory.createToken(SyntaxKind.CLOSE_BRACE_TOKEN));
            return annotationNode.modify().withAnnotValue(node).apply();
        }
        return getSchemaStringAnnotation(schemaString);
    }

    private SeparatedNodeList<MappingFieldNode> getUpdatedFields(MappingConstructorExpressionNode annotationValue,
                                                                 String schemaString) {
        List<Node> fields = new ArrayList<>();
        SeparatedNodeList<MappingFieldNode> existingFields = annotationValue.fields();
        Token separator = NodeFactory.createToken(SyntaxKind.COMMA_TOKEN);
        for (MappingFieldNode field : existingFields) {
            fields.add(field);
            fields.add(separator);
        }
        fields.add(getSchemaStringFieldNode(schemaString));
        return NodeFactory.createSeparatedNodeList(fields);
    }

    private MetadataNode getNewMetadataNode(String schemaString) {
        NodeList<AnnotationNode> annotationNodes = NodeFactory.createNodeList(getSchemaStringAnnotation(schemaString));
        return NodeFactory.createMetadataNode(null, annotationNodes);
    }

    private AnnotationNode getSchemaStringAnnotation(String schemaString) {
        String configIdentifierString = PACKAGE_NAME + SyntaxKind.COLON_TOKEN.stringValue() + SERVICE_CONFIG_IDENTIFIER;
        IdentifierToken identifierToken = NodeFactory.createIdentifierToken(configIdentifierString);
        Token atToken = NodeFactory.createToken(SyntaxKind.AT_TOKEN);
        SimpleNameReferenceNode nameReferenceNode = NodeFactory.createSimpleNameReferenceNode(identifierToken);
        MappingConstructorExpressionNode annotValue = getAnnotationExpression(schemaString);
        return NodeFactory.createAnnotationNode(atToken, nameReferenceNode, annotValue);
    }

    private MappingConstructorExpressionNode getAnnotationExpression(String schemaString) {
        Token openBraceToken = NodeFactory.createToken(SyntaxKind.OPEN_BRACE_TOKEN);
        Token closeBraceToken = NodeFactory.createToken(SyntaxKind.CLOSE_BRACE_TOKEN);
        SpecificFieldNode specificFieldNode = getSchemaStringFieldNode(schemaString);
        SeparatedNodeList<MappingFieldNode> separatedNodeList = NodeFactory.createSeparatedNodeList(specificFieldNode);
        return NodeFactory.createMappingConstructorExpressionNode(openBraceToken, separatedNodeList, closeBraceToken);
    }

    private SpecificFieldNode getSchemaStringFieldNode(String schemaString) {
        Node fieldName = NodeFactory.createIdentifierToken(SCHEMA_STRING_FIELD);
        Token colon = NodeFactory.createToken(SyntaxKind.COLON_TOKEN);
        String expression = "\"" + schemaString + "\"";
        ExpressionNode fieldValue = NodeParser.parseExpression(expression);
        return NodeFactory.createSpecificFieldNode(null, fieldName, colon, fieldValue);
    }

    private String getSchemaAsEncodedString(Schema schema) throws IOException {
        ByteArrayOutputStream outputStream = new ByteArrayOutputStream();
        ObjectOutputStream objectOutputStream = new ObjectOutputStream(outputStream);
        objectOutputStream.writeObject(schema);
        objectOutputStream.flush();
        objectOutputStream.close();
        return new String(Base64.getEncoder().encode(outputStream.toByteArray()), StandardCharsets.UTF_8);
    }

    private boolean isGraphqlServiceConfig(AnnotationNode annotationNode) {
        if (annotationNode.annotReference().kind() != SyntaxKind.QUALIFIED_NAME_REFERENCE) {
            return false;
        }
        QualifiedNameReferenceNode referenceNode = ((QualifiedNameReferenceNode) annotationNode.annotReference());
        if (!PACKAGE_NAME.equals(referenceNode.modulePrefix().text())) {
            return false;
        }
        return SERVICE_CONFIG_IDENTIFIER.equals(referenceNode.identifier().text());
    }

    private void updateContext(SourceModifierContext context, Location location) {
        CompilationError error = CompilationError.SCHEMA_GENERATION_FAILED;
        DiagnosticInfo diagnosticInfo = new DiagnosticInfo(error.getErrorCode(), error.getError(),
                                                           error.getDiagnosticSeverity());
        Diagnostic diagnostic = DiagnosticFactory.createDiagnostic(diagnosticInfo, location);
        context.reportDiagnostic(diagnostic);
    }
}
