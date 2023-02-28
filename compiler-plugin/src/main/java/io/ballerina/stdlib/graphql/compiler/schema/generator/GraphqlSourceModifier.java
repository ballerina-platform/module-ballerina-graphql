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
import io.ballerina.compiler.syntax.tree.FunctionDefinitionNode;
import io.ballerina.compiler.syntax.tree.IdentifierToken;
import io.ballerina.compiler.syntax.tree.MappingConstructorExpressionNode;
import io.ballerina.compiler.syntax.tree.MappingFieldNode;
import io.ballerina.compiler.syntax.tree.MetadataNode;
import io.ballerina.compiler.syntax.tree.ModuleMemberDeclarationNode;
import io.ballerina.compiler.syntax.tree.ModulePartNode;
import io.ballerina.compiler.syntax.tree.ModuleVariableDeclarationNode;
import io.ballerina.compiler.syntax.tree.Node;
import io.ballerina.compiler.syntax.tree.NodeFactory;
import io.ballerina.compiler.syntax.tree.NodeList;
import io.ballerina.compiler.syntax.tree.NodeParser;
import io.ballerina.compiler.syntax.tree.ObjectConstructorExpressionNode;
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
import io.ballerina.stdlib.graphql.commons.types.Schema;
import io.ballerina.stdlib.graphql.commons.types.Type;
import io.ballerina.stdlib.graphql.compiler.diagnostics.CompilationDiagnostic;
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
import java.util.stream.Collectors;

import static io.ballerina.stdlib.graphql.commons.utils.Utils.PACKAGE_NAME;
import static io.ballerina.stdlib.graphql.compiler.Utils.SERVICE_CONFIG_IDENTIFIER;
import static io.ballerina.stdlib.graphql.compiler.schema.generator.GeneratorUtils.SCHEMA_STRING_FIELD;

/**
 * Modifies the GraphQL service to add an annotation to the service with the generated schema.
 */
public class GraphqlSourceModifier implements ModifierTask<SourceModifierContext> {
    private final Map<DocumentId, GraphqlModifierContext> modifierContextMap;
    private final Map<Node, String> entityTypeNamesMap;
    private static final String ENTITY = "__Entity";
    private int entityUnionSuffix = 0;
    private String entityUnionTypeName;
    private List<String> entities;
    private boolean isSubgraph = false;

    public GraphqlSourceModifier(Map<DocumentId, GraphqlModifierContext> modifierContextMap) {
        this.modifierContextMap = modifierContextMap;
        this.entityTypeNamesMap = new HashMap<>();
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
        Map<Node, Node> nodeMap = new HashMap<>();
        Map<Node, Schema> nodeSchemaMap = modifierContext.getNodeSchemaMap();
        for (Map.Entry<Node, Schema> entry : nodeSchemaMap.entrySet()) {
            Schema schema = entry.getValue();
            this.isSubgraph = schema.isSubgraph();
            this.entities = schema.getEntities().stream().map(Type::getName).collect(Collectors.toList());
            this.entityUnionTypeName = ENTITY + this.entityUnionSuffix;
            try {
                String schemaString = getSchemaAsEncodedString(schema);
                Node targetNode = entry.getKey();
                if (targetNode.kind() == SyntaxKind.SERVICE_DECLARATION) {
                    ServiceDeclarationNode updatedNode = modifyServiceDeclarationNode(
                            (ServiceDeclarationNode) targetNode, schemaString);
                    nodeMap.put(targetNode, updatedNode);
                    this.entityTypeNamesMap.put(targetNode, this.entityUnionTypeName);
                    this.entityUnionSuffix++;
                } else if (targetNode.kind() == SyntaxKind.MODULE_VAR_DECL) {
                    ModuleVariableDeclarationNode graphqlServiceVariableDeclaration
                            = (ModuleVariableDeclarationNode) targetNode;
                    ModuleVariableDeclarationNode updatedNode = modifyServiceVariableDeclarationNode(
                            schemaString, graphqlServiceVariableDeclaration);
                    nodeMap.put(targetNode, updatedNode);
                    this.entityTypeNamesMap.put(targetNode, this.entityUnionTypeName);
                    this.entityUnionSuffix++;
                }
            } catch (IOException e) {
                updateContext(context, entry.getKey().location(), CompilationDiagnostic.SCHEMA_GENERATION_FAILED,
                              e.getMessage());
            }
        }
        NodeList<ModuleMemberDeclarationNode> members = NodeFactory.createNodeList();
        for (ModuleMemberDeclarationNode member : rootNode.members()) {
            if (member.kind() == SyntaxKind.SERVICE_DECLARATION || member.kind() == SyntaxKind.MODULE_VAR_DECL) {
                if (nodeMap.containsKey(member)) {
                    this.entityUnionTypeName = this.entityTypeNamesMap.get(member);
                    Schema schema = nodeSchemaMap.get(member);
                    isSubgraph = schema.isSubgraph();
                    if (schema.getEntities().size() > 0) {
                        this.entities = schema.getEntities().stream().map(Type::getName).collect(Collectors.toList());
                        members = addEntityTypeDefinition(members);
                    }
                    members = members.add((ModuleMemberDeclarationNode) nodeMap.get(member));
                    continue;
                }
            }
            members = members.add(member);
        }
        return rootNode.modify(rootNode.imports(), members, rootNode.eofToken());
    }

    private NodeList<ModuleMemberDeclarationNode> addEntityTypeDefinition(
            NodeList<ModuleMemberDeclarationNode> moduleMembers) {
        if (!this.isSubgraph) {
            return moduleMembers;
        }
        ModuleMemberDeclarationNode typeDefinition = getEntityTypeDefinition();
        return moduleMembers.add(typeDefinition);
    }

    private ModuleMemberDeclarationNode getEntityTypeDefinition() {
        String unionOfEntities = String.join("|", this.entities);
        return NodeParser.parseModuleMemberDeclaration(
                "type " + this.entityUnionTypeName + " " + unionOfEntities + ";");
    }

    private ModuleVariableDeclarationNode modifyServiceVariableDeclarationNode(String schemaString,
                                                                               ModuleVariableDeclarationNode node) {
        // noinspection OptionalGetWithoutIsPresent
        ObjectConstructorExpressionNode graphqlServiceObject
                = (ObjectConstructorExpressionNode) node.initializer().get();
        ObjectConstructorExpressionNode updatedGraphqlServiceObject = modifyServiceObjectNode(graphqlServiceObject,
                                                                                              schemaString);
        return node.modify().withInitializer(updatedGraphqlServiceObject).apply();
    }

    private ObjectConstructorExpressionNode modifyServiceObjectNode(ObjectConstructorExpressionNode node,
                                                                    String schemaString) {
        NodeList<AnnotationNode> annotations = NodeFactory.createNodeList();
        if (node.annotations().isEmpty()) {
            AnnotationNode annotationNode = getSchemaStringAnnotation(schemaString);
            annotations = annotations.add(annotationNode);
        } else {
            for (AnnotationNode annotationNode : node.annotations()) {
                annotationNode = updateAnnotationNode(annotationNode, schemaString);
                annotations = annotations.add(annotationNode);
            }
        }
        ObjectConstructorExpressionNode.ObjectConstructorExpressionNodeModifier modifier = node.modify();
        modifier = modifier.withAnnotations(annotations);
        NodeList<Node> members = node.members();
        if (this.isSubgraph) {
            members = addServiceResourceResolverToMembers(members);
            if (this.entities.size() > 0) {
                members = addEntityResourceResolverToMembers(members);
            }
        }
        modifier = modifier.withMembers(members);
        return modifier.apply();
    }

    private ServiceDeclarationNode modifyServiceDeclarationNode(ServiceDeclarationNode node, String schemaString) {
        MetadataNode metadataNode = getMetadataNode(node, schemaString);
        ServiceDeclarationNode.ServiceDeclarationNodeModifier modifier = node.modify();
        modifier = modifier.withMetadata(metadataNode);
        NodeList<Node> members = node.members();
        if (this.isSubgraph) {
            members = addServiceResourceResolverToMembers(members);
            if (this.entities.size() > 0) {
                members = addEntityResourceResolverToMembers(members);
            }
        }
        modifier = modifier.withMembers(members);
        return modifier.apply();
    }

    private NodeList<Node> addEntityResourceResolverToMembers(NodeList<Node> serviceMembers) {
        FunctionDefinitionNode entityResolver = getEntityResolver();
        return serviceMembers.add(entityResolver);
    }

    private NodeList<Node> addServiceResourceResolverToMembers(NodeList<Node> serviceMembers) {
        FunctionDefinitionNode serviceResolver = getServiceResolver();
        return serviceMembers.add(serviceResolver);
    }

    private FunctionDefinitionNode getEntityResolver() {
        String mapDef = getEntityTypedescMapInitializer();
        String entityResolver = "\t resource function get _entities(subgraph:Representation[] representations) "
                + "\t returns (" + this.entityUnionTypeName + "|error?)[] {\n"
                + "\t map<typedesc<" + this.entityUnionTypeName + ">> typedescs = " + mapDef + ";\n"
                + "\t (" + this.entityUnionTypeName + "|error?)[] entities = [];\n"
                + "\t foreach subgraph:Representation rep in representations {\n"
                + "\t if !typedescs.hasKey(rep.__typename) {\n"
                + "\t     entities.push(error(string `No entities found for {__typename: '${rep.__typename}'}`));\n"
                + "\t     continue;\n"
                + "\t }\n"
                + "\t typedesc<" + this.entityUnionTypeName + "> entityTypedesc = typedescs.get(rep.__typename);\n"
                + "\t subgraph:FederatedEntity? federatedEntity = entityTypedesc.@subgraph:Entity;\n"
                + "\t if federatedEntity is () {\n"
                + "\t     entities.push(error(string `No entities found for {__typename: '${rep.__typename}'}`));\n"
                + "\t     continue;\n"
                + "\t }\n"
                + "\t subgraph:ReferenceResolver? resolve = federatedEntity.resolveReference;\n"
                + "\t if resolve is () {\n"
                + "\t     entities.push(error(string `No resolvers defined for '${rep.__typename}' entity`));\n"
                + "\t     continue;\n"
                + "\t }\n"
                + "\t record {}|service object {}|error? entity = resolve(rep);\n"
                + "\t if entity is error? {\n"
                + "\t      entities.push(entity);\n"
                + "\t      continue;\n"
                + "\t }\n"
                + "\t " + this.entityUnionTypeName + "|error entityWithType = entity.ensureType(entityTypedesc);\n"
                + "\t if entityWithType is error {\n"
                + "\t      entities.push(error(string `Incorrect return type specified for the "
                + "'${rep.__typename}' entity reference resolver.`));\n"
                + "\t      continue;\n"
                + "\t }\n"
                + "\t entities.push(entityWithType);\n"
                + "\t }\n"
                + "\treturn entities;\n"
                + "\t}";
        return (FunctionDefinitionNode) NodeParser.parseObjectMember(entityResolver);
    }

    private FunctionDefinitionNode getServiceResolver() {
        String mapDef = getEntityTypedescMapInitializer();
        String entityResolver = "\t resource function get _service() returns record { string sdl; }|error {\n"
                + "\t map<typedesc> typedescs = " + mapDef + ";\n"
                + "\t map<subgraph:FederatedEntity> keyDirectives = {};\n"
                + "\t foreach var [entity, entityTypedesc] in typedescs.entries() {\n"
                + "\t   subgraph:FederatedEntity keyDirective = check entityTypedesc.@subgraph:Entity.ensureType();\n"
                + "\t   keyDirectives[entity] = keyDirective;\n"
                + "\t }\n"
                + "\t graphql:GraphqlServiceConfig config = check (typeof self).@graphql:ServiceConfig.ensureType();\n"
                + "\t string sdl = check graphql:getSdlString(config.schemaString, keyDirectives);\n"
                + "\t return {sdl};\n"
                + "\t}\n";
        return (FunctionDefinitionNode) NodeParser.parseObjectMember(entityResolver);
    }

    private String getEntityTypedescMapInitializer() {
        List<String> mapFields = this.entities.stream().map(entity -> "\"" + entity + "\"" + ":" + entity)
                .collect(Collectors.toList());
        return "{" + String.join(", ", mapFields) + "}";
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

    private void updateContext(SourceModifierContext context, Location location,
                               CompilationDiagnostic compilerDiagnostic, String errorMessage) {
        DiagnosticInfo diagnosticInfo = new DiagnosticInfo(compilerDiagnostic.getDiagnosticCode(),
                        compilerDiagnostic.getDiagnostic(), compilerDiagnostic.getDiagnosticSeverity());
        Diagnostic diagnostic = DiagnosticFactory.createDiagnostic(diagnosticInfo, location, errorMessage);
        context.reportDiagnostic(diagnostic);
    }
}
