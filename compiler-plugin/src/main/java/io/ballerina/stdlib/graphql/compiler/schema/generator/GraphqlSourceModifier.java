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
import io.ballerina.compiler.syntax.tree.ImportDeclarationNode;
import io.ballerina.compiler.syntax.tree.ImportOrgNameNode;
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
import io.ballerina.compiler.syntax.tree.NonTerminalNode;
import io.ballerina.compiler.syntax.tree.ObjectConstructorExpressionNode;
import io.ballerina.compiler.syntax.tree.ObjectFieldNode;
import io.ballerina.compiler.syntax.tree.SeparatedNodeList;
import io.ballerina.compiler.syntax.tree.ServiceDeclarationNode;
import io.ballerina.compiler.syntax.tree.SimpleNameReferenceNode;
import io.ballerina.compiler.syntax.tree.SpecificFieldNode;
import io.ballerina.compiler.syntax.tree.SyntaxKind;
import io.ballerina.compiler.syntax.tree.SyntaxTree;
import io.ballerina.compiler.syntax.tree.Token;
import io.ballerina.compiler.syntax.tree.VariableDeclarationNode;
import io.ballerina.projects.DocumentId;
import io.ballerina.projects.Module;
import io.ballerina.projects.plugins.ModifierTask;
import io.ballerina.projects.plugins.SourceModifierContext;
import io.ballerina.stdlib.graphql.commons.types.Schema;
import io.ballerina.stdlib.graphql.commons.types.Type;
import io.ballerina.stdlib.graphql.compiler.CacheConfigContext;
import io.ballerina.stdlib.graphql.compiler.diagnostics.CompilationDiagnostic;
import io.ballerina.tools.diagnostics.Diagnostic;
import io.ballerina.tools.diagnostics.DiagnosticFactory;
import io.ballerina.tools.diagnostics.DiagnosticInfo;
import io.ballerina.tools.diagnostics.Location;
import io.ballerina.tools.text.TextDocument;
import io.ballerina.tools.text.TextRange;

import java.io.BufferedReader;
import java.io.ByteArrayOutputStream;
import java.io.IOException;
import java.io.InputStream;
import java.io.InputStreamReader;
import java.io.ObjectOutputStream;
import java.nio.charset.StandardCharsets;
import java.util.ArrayList;
import java.util.Base64;
import java.util.Comparator;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.Objects;
import java.util.stream.Collectors;

import static io.ballerina.stdlib.graphql.commons.utils.Utils.PACKAGE_NAME;
import static io.ballerina.stdlib.graphql.commons.utils.Utils.PACKAGE_ORG;
import static io.ballerina.stdlib.graphql.commons.utils.Utils.SUBGRAPH_SUB_MODULE_NAME;
import static io.ballerina.stdlib.graphql.compiler.Utils.SERVICE_CONFIG_IDENTIFIER;
import static io.ballerina.stdlib.graphql.compiler.Utils.isGraphqlServiceConfig;
import static io.ballerina.stdlib.graphql.compiler.schema.generator.GeneratorUtils.ENABLED_CACHE_FIELD;
import static io.ballerina.stdlib.graphql.compiler.schema.generator.GeneratorUtils.FIELD_CACHE_CONFIG_FIELD;
import static io.ballerina.stdlib.graphql.compiler.schema.generator.GeneratorUtils.MAX_SIZE_CACHE_FIELD;
import static io.ballerina.stdlib.graphql.compiler.schema.generator.GeneratorUtils.SCHEMA_STRING_FIELD;

/**
 * Modifies the GraphQL service to add an annotation to the service with the generated schema.
 */
public class GraphqlSourceModifier implements ModifierTask<SourceModifierContext> {
    private static final String ENTITY = "__Entity";
    public static final String MAP_DEFINITION_PLACEHOLDER = "mapDef";
    private static final String SUBGRAPH_MODULE_PLACEHOLDER = "subgraph";
    private final Map<DocumentId, GraphqlModifierContext> modifierContextMap;
    private final Map<Node, String> entityTypeNamesMap;
    private String subgraphModulePrefix;
    private SourceModifierContext context;
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
        this.context = sourceModifierContext;
        for (Map.Entry<DocumentId, GraphqlModifierContext> entry : this.modifierContextMap.entrySet()) {
            DocumentId documentId = entry.getKey();
            GraphqlModifierContext modifierContext = entry.getValue();
            Module module = sourceModifierContext.currentPackage().module(documentId.moduleId());
            ModulePartNode rootNode = module.document(documentId).syntaxTree().rootNode();
            ModulePartNode updatedRootNode = modifyDocument(sourceModifierContext, rootNode, modifierContext);
            updatedRootNode = addImportsIfMissing(updatedRootNode);
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
        this.subgraphModulePrefix = getSubgraphModulePrefix(rootNode);
        Map<NonTerminalNode, NonTerminalNode> modifiedNodes = new HashMap<>();
        Map<Node, Schema> nodeSchemaMap = modifierContext.getNodeSchemaMap();
        for (Map.Entry<Node, Schema> entry : nodeSchemaMap.entrySet()) {
            Schema schema = entry.getValue();
            this.isSubgraph = schema.isSubgraph();
            this.entities = schema.getEntities().stream().map(Type::getName).collect(Collectors.toList());
            String prefix = getGraphqlModulePrefix(rootNode);
            this.entityUnionTypeName = ENTITY + this.entityUnionSuffix;
            try {
                String schemaString = getSchemaAsEncodedString(schema);
                Node targetNode = entry.getKey();
                CacheConfigContext cacheConfigContext = modifierContext.getNodeCacheConfigMap().get(targetNode);
                if (targetNode.kind() == SyntaxKind.SERVICE_DECLARATION) {
                    ServiceDeclarationNode updatedNode = modifyServiceDeclarationNode(
                            (ServiceDeclarationNode) targetNode, schemaString, cacheConfigContext, prefix);
                    modifiedNodes.put((NonTerminalNode) targetNode, updatedNode);
                    this.entityTypeNamesMap.put(targetNode, this.entityUnionTypeName);
                    this.entityUnionSuffix++;
                } else if (targetNode.kind() == SyntaxKind.MODULE_VAR_DECL) {
                    ModuleVariableDeclarationNode graphqlServiceVariableDeclaration
                            = (ModuleVariableDeclarationNode) targetNode;
                    ModuleVariableDeclarationNode updatedNode = modifyModuleLevelServiceDeclarationNode(
                            schemaString, graphqlServiceVariableDeclaration, cacheConfigContext, prefix);
                    modifiedNodes.put((NonTerminalNode) targetNode, updatedNode);
                    this.entityTypeNamesMap.put(targetNode, this.entityUnionTypeName);
                    this.entityUnionSuffix++;
                } else if (targetNode.kind() == SyntaxKind.LOCAL_VAR_DECL) {
                    VariableDeclarationNode graphqlServiceVariableDeclaration = (VariableDeclarationNode) targetNode;
                    VariableDeclarationNode updatedNode = modifyVariableServiceDeclarationNode(
                            schemaString, graphqlServiceVariableDeclaration, cacheConfigContext, prefix);
                    modifiedNodes.put((NonTerminalNode) targetNode, updatedNode);
                    this.entityTypeNamesMap.put(targetNode, this.entityUnionTypeName);
                    this.entityUnionSuffix++;
                } else if (targetNode.kind() == SyntaxKind.OBJECT_FIELD) {
                    ObjectFieldNode graphqlServiceFieldDeclaration = (ObjectFieldNode) targetNode;
                    ObjectFieldNode updatedNode = modifyObjectFieldServiceDeclarationNode(
                            schemaString, graphqlServiceFieldDeclaration, cacheConfigContext, prefix);
                    modifiedNodes.put((NonTerminalNode) targetNode, updatedNode);
                    this.entityTypeNamesMap.put(targetNode, this.entityUnionTypeName);
                    this.entityUnionSuffix++;
                }
            } catch (IOException e) {
                updateContext(context, entry.getKey().location(), CompilationDiagnostic.SCHEMA_GENERATION_FAILED,
                              e.getMessage());
            }
        }

        ArrayList<NonTerminalNode> nodesToBeModified = new ArrayList<>(modifiedNodes.keySet());
        nodesToBeModified.sort(Comparator.comparingInt(n -> n.textRange().startOffset()));
        List<ModuleMemberDeclarationNode> entities = getEntityTypeDefinitions(nodeSchemaMap, nodesToBeModified);
        ModulePartNode modifiedRootNode = addServiceDeclarationAnnotations(rootNode, nodesToBeModified, modifiedNodes);
        NodeList<ModuleMemberDeclarationNode> modifiedMembers = modifiedRootNode.members().addAll(entities);
        return modifiedRootNode.modify(modifiedRootNode.imports(), modifiedMembers, modifiedRootNode.eofToken());
    }

    private String getSubgraphModulePrefix(ModulePartNode rootNode) {
        List<ImportDeclarationNode> imports = rootNode.imports().stream().collect(Collectors.toList());
        if (imports.isEmpty()) {
            return null;
        }
        for (ImportDeclarationNode importDeclarationNode : imports) {
            if (importDeclarationNode.prefix().isPresent()) {
                if (importDeclarationNode.moduleName().stream().map(Token::text).collect(Collectors.joining("."))
                        .equals(SUBGRAPH_SUB_MODULE_NAME)) {
                    return importDeclarationNode.prefix().get().prefix().text();
                }
            }
        }
        return null;
    }

    private NodeList<ModuleMemberDeclarationNode> addEntityTypeDefinition(
            NodeList<ModuleMemberDeclarationNode> moduleMembers) {
        if (!this.isSubgraph) {
            return moduleMembers;
        }
        ModuleMemberDeclarationNode typeDefinition = getEntityTypeDefinition();
        return moduleMembers.add(typeDefinition);
    }

    private ModulePartNode addServiceDeclarationAnnotations(ModulePartNode rootNode,
                                                            ArrayList<NonTerminalNode> nodesToBeModified,
                                                            Map<NonTerminalNode, NonTerminalNode> modifiedNodes) {
        int prevModifiedNodeLength = 0;
        int prevOriginalNodeLength = 0;
        for (NonTerminalNode originalNode : nodesToBeModified) {
            int originalNodeStartOffset = originalNode.textRangeWithMinutiae().startOffset()
                    + prevModifiedNodeLength - prevOriginalNodeLength;
            int originalNodeLength = originalNode.textRangeWithMinutiae().length();
            NonTerminalNode replacingNode = rootNode.findNode(
                    TextRange.from(originalNodeStartOffset, originalNodeLength),
                    true);
            rootNode = rootNode.replace(replacingNode, modifiedNodes.get(originalNode));
            prevModifiedNodeLength += modifiedNodes.get(originalNode).textRangeWithMinutiae().length();
            prevOriginalNodeLength += originalNode.textRangeWithMinutiae().length();
        }
        return rootNode;
    }

    private List<ModuleMemberDeclarationNode> getEntityTypeDefinitions(Map<Node, Schema> nodeSchemaMap,
                                                                       ArrayList<NonTerminalNode> serviceNodes) {
        NodeList<ModuleMemberDeclarationNode> entities = NodeFactory.createNodeList();
        for (NonTerminalNode serviceNode : serviceNodes) {
            this.entityUnionTypeName = this.entityTypeNamesMap.get(serviceNode);
            Schema schema = nodeSchemaMap.get(serviceNode);
            isSubgraph = schema.isSubgraph();
            if (schema.getEntities().size() > 0) {
                this.entities = schema.getEntities().stream().map(Type::getName).collect(Collectors.toList());
                entities = addEntityTypeDefinition(entities);
            }
        }
        return entities.stream().toList();
    }

    private ModuleMemberDeclarationNode getEntityTypeDefinition() {
        String unionOfEntities = String.join("|", this.entities);
        return NodeParser.parseModuleMemberDeclaration(
                "type " + this.entityUnionTypeName + " " + unionOfEntities + ";");
    }

    private ModuleVariableDeclarationNode modifyModuleLevelServiceDeclarationNode(String schemaString,
                                                                                  ModuleVariableDeclarationNode node,
                                                                                  CacheConfigContext cacheConfigContext,
                                                                                  String prefix) {
        // noinspection OptionalGetWithoutIsPresent
        ObjectConstructorExpressionNode graphqlServiceObject
                = (ObjectConstructorExpressionNode) node.initializer().get();
        ObjectConstructorExpressionNode updatedGraphqlServiceObject = modifyServiceObjectNode(graphqlServiceObject,
                schemaString, cacheConfigContext, prefix);
        return node.modify().withInitializer(updatedGraphqlServiceObject).apply();
    }

    private VariableDeclarationNode modifyVariableServiceDeclarationNode(String schemaString,
                                                                         VariableDeclarationNode node,
                                                                         CacheConfigContext cacheConfigContext,
                                                                         String prefix) {
        ObjectConstructorExpressionNode graphqlServiceObject
                = (ObjectConstructorExpressionNode) node.initializer().get();
        ObjectConstructorExpressionNode updatedGraphqlServiceObject = modifyServiceObjectNode(
                graphqlServiceObject, schemaString, cacheConfigContext, prefix);
        return node.modify().withInitializer(updatedGraphqlServiceObject).apply();
    }

    private ObjectFieldNode modifyObjectFieldServiceDeclarationNode(String schemaString,
                                                                    ObjectFieldNode node,
                                                                    CacheConfigContext cacheConfigContext,
                                                                    String prefix) {
        ObjectConstructorExpressionNode graphqlServiceObject
                = (ObjectConstructorExpressionNode) node.expression().get();
        ObjectConstructorExpressionNode updatedGraphqlServiceObject = modifyServiceObjectNode(
                graphqlServiceObject, schemaString, cacheConfigContext, prefix);
        return node.modify().withExpression(updatedGraphqlServiceObject).apply();
    }

    private ObjectConstructorExpressionNode modifyServiceObjectNode(ObjectConstructorExpressionNode node,
                                                                    String schemaString,
                                                                    CacheConfigContext cacheConfigContext,
                                                                    String prefix) {
        NodeList<AnnotationNode> annotations = NodeFactory.createNodeList();
        if (node.annotations().isEmpty()) {
            AnnotationNode annotationNode = getServiceAnnotation(schemaString, cacheConfigContext, prefix);
            annotations = annotations.add(annotationNode);
        } else {
            for (AnnotationNode annotationNode : node.annotations()) {
                annotationNode = updateAnnotationNode(annotationNode, schemaString, cacheConfigContext, prefix);
                annotations = annotations.add(annotationNode);
            }
        }
        ObjectConstructorExpressionNode.ObjectConstructorExpressionNodeModifier modifier = node.modify();
        modifier = modifier.withAnnotations(annotations);
        NodeList<Node> members = node.members();
        if (this.isSubgraph) {
            members = addServiceResourceResolverToMembers(members, node.location());
            if (this.entities.size() > 0) {
                members = addEntityResourceResolverToMembers(members, node.location());
            }
        }
        modifier = modifier.withMembers(members);
        return modifier.apply();
    }

    private ServiceDeclarationNode modifyServiceDeclarationNode(ServiceDeclarationNode node, String schemaString,
                                                                CacheConfigContext cacheConfigContext, String prefix) {
        MetadataNode metadataNode = getMetadataNode(node, schemaString, cacheConfigContext, prefix);
        ServiceDeclarationNode.ServiceDeclarationNodeModifier modifier = node.modify();
        modifier = modifier.withMetadata(metadataNode);
        NodeList<Node> members = node.members();
        if (this.isSubgraph) {
            members = addServiceResourceResolverToMembers(members, node.location());
            if (this.entities.size() > 0) {
                members = addEntityResourceResolverToMembers(members, node.location());
            }
        }
        modifier = modifier.withMembers(members);
        return modifier.apply();
    }

    private NodeList<Node> addEntityResourceResolverToMembers(NodeList<Node> serviceMembers, Location location) {
        FunctionDefinitionNode entityResolver = getEntityResolver(location);
        return serviceMembers.add(entityResolver);
    }

    private NodeList<Node> addServiceResourceResolverToMembers(NodeList<Node> serviceMembers, Location location) {
        FunctionDefinitionNode serviceResolver = getServiceResolver(location);
        return serviceMembers.add(serviceResolver);
    }

    private FunctionDefinitionNode getEntityResolver(Location location) {
        try {
            String mapDef = getEntityTypedescMapInitializer();
            Class<GraphqlSourceModifier> currentClass = GraphqlSourceModifier.class;
            InputStream inputStream = currentClass.getResourceAsStream("/entity_resolver.bal.partial");
            String entityResolver = readFromInputStream(inputStream);
            Objects.requireNonNull(inputStream).close();
            entityResolver = entityResolver.replaceAll(ENTITY, this.entityUnionTypeName);
            entityResolver = entityResolver.replaceAll(MAP_DEFINITION_PLACEHOLDER, mapDef);
            if (this.subgraphModulePrefix != null) {
                entityResolver = entityResolver.replaceAll(SUBGRAPH_MODULE_PLACEHOLDER, this.subgraphModulePrefix);
            }
            return (FunctionDefinitionNode) NodeParser.parseObjectMember(entityResolver);
        } catch (IOException | NullPointerException e) {
            updateContext(this.context, location, CompilationDiagnostic.FAILED_TO_ADD_ENTITY_RESOLVER, e.getMessage());
            return null;
        }
    }

    private String readFromInputStream(InputStream inputStream) throws IOException {
        StringBuilder resultStringBuilder = new StringBuilder();
        InputStreamReader streamReader = new InputStreamReader(inputStream, StandardCharsets.UTF_8);
        try (BufferedReader bufferedReader = new BufferedReader(streamReader)) {
            String line;
            while ((line = bufferedReader.readLine()) != null) {
                resultStringBuilder.append(line).append("\n");
            }
        }
        return resultStringBuilder.toString();
    }

    private FunctionDefinitionNode getServiceResolver(Location location) {
        try {
            String mapDef = getEntityTypedescMapInitializer();
            Class<GraphqlSourceModifier> currentClass = GraphqlSourceModifier.class;
            InputStream inputStream = currentClass.getResourceAsStream("/service_resolver.bal.partial");
            String serviceResolver = readFromInputStream(inputStream);
            Objects.requireNonNull(inputStream).close();
            serviceResolver = serviceResolver.replaceAll(MAP_DEFINITION_PLACEHOLDER, mapDef);
            if (this.subgraphModulePrefix != null) {
                serviceResolver = serviceResolver.replaceAll(SUBGRAPH_MODULE_PLACEHOLDER, this.subgraphModulePrefix);
            }
            return (FunctionDefinitionNode) NodeParser.parseObjectMember(serviceResolver);
        } catch (IOException | NullPointerException e) {
            updateContext(this.context, location, CompilationDiagnostic.FAILED_TO_ADD_SERVICE_RESOLVER, e.getMessage());
            return null;
        }
    }

    private String getEntityTypedescMapInitializer() {
        List<String> mapFields = this.entities.stream().map(entity -> "\"" + entity + "\"" + ":" + entity)
                .collect(Collectors.toList());
        return "{" + String.join(", ", mapFields) + "}";
    }

    private MetadataNode getMetadataNode(ServiceDeclarationNode node, String schemaString,
                                         CacheConfigContext cacheConfigContext,
                                         String prefix) {
        if (node.metadata().isPresent()) {
            return getMetadataNodeFromExistingMetadata(node.metadata().get(), schemaString, cacheConfigContext, prefix);
        } else {
            return getNewMetadataNode(schemaString, cacheConfigContext, prefix);
        }
    }

    private MetadataNode getMetadataNodeFromExistingMetadata(MetadataNode metadataNode, String schemaString,
                                                             CacheConfigContext cacheConfigContext, String prefix) {
        NodeList<AnnotationNode> annotationNodes = NodeFactory.createNodeList();
        if (metadataNode.annotations().isEmpty()) {
            AnnotationNode annotationNode = getServiceAnnotation(schemaString, cacheConfigContext, prefix);
            annotationNodes = annotationNodes.add(annotationNode);
        } else {
            boolean isAnnotationFound = false;
            for (AnnotationNode annotationNode : metadataNode.annotations()) {
                if (isGraphqlServiceConfig(annotationNode)) {
                    isAnnotationFound = true;
                    annotationNode = updateAnnotationNode(annotationNode, schemaString, cacheConfigContext, prefix);
                }
                annotationNodes = annotationNodes.add(annotationNode);
            }
            if (!isAnnotationFound) {
                AnnotationNode annotationNode = getServiceAnnotation(schemaString, cacheConfigContext, prefix);
                annotationNodes = annotationNodes.add(annotationNode);
            }
        }
        return NodeFactory.createMetadataNode(metadataNode.documentationString().orElse(null), annotationNodes);
    }

    private AnnotationNode updateAnnotationNode(AnnotationNode annotationNode, String schemaString,
                                                CacheConfigContext cacheConfigContext, String prefix) {
        if (annotationNode.annotValue().isPresent()) {
            SeparatedNodeList<MappingFieldNode> updatedFields =
                    getUpdatedFields(annotationNode.annotValue().get(), schemaString, cacheConfigContext);
            MappingConstructorExpressionNode node =
                    annotationNode.annotValue().get().modify().withFields(updatedFields).apply();
            return annotationNode.modify().withAnnotValue(node).apply();
        }
        return getServiceAnnotation(schemaString, cacheConfigContext, prefix);
    }

    private SeparatedNodeList<MappingFieldNode> getUpdatedFields(MappingConstructorExpressionNode annotationValue,
                                                                 String schemaString,
                                                                 CacheConfigContext cacheConfigContext) {
        List<Node> fields = new ArrayList<>();
        SeparatedNodeList<MappingFieldNode> existingFields = annotationValue.fields();
        Token separator = NodeFactory.createToken(SyntaxKind.COMMA_TOKEN);
        int fieldCount = existingFields.size();
        for (int i = 0; i < fieldCount; i++) {
            fields.add(existingFields.get(i));
            if (fieldCount > 1 && i < fieldCount - 1) {
                fields.add(existingFields.getSeparator(i));
            }
        }
        if (fieldCount > 0) {
            fields.add(separator);
        }
        fields.add(getSchemaStringFieldNode(schemaString));
        fields.add(separator);
        fields.add(getFieldCacheConfigNode(cacheConfigContext));
        return NodeFactory.createSeparatedNodeList(fields);
    }

    private MetadataNode getNewMetadataNode(String schemaString, CacheConfigContext cacheConfigContext, String prefix) {
        NodeList<AnnotationNode> annotationNodes =
                NodeFactory.createNodeList(getServiceAnnotation(schemaString, cacheConfigContext, prefix));
        return NodeFactory.createMetadataNode(null, annotationNodes);
    }

    private AnnotationNode getServiceAnnotation(String schemaString, CacheConfigContext cacheConfigContext,
                                                String prefix) {
        String configIdentifierString = prefix + SyntaxKind.COLON_TOKEN.stringValue() + SERVICE_CONFIG_IDENTIFIER;
        IdentifierToken identifierToken = NodeFactory.createIdentifierToken(configIdentifierString);
        Token atToken = NodeFactory.createToken(SyntaxKind.AT_TOKEN);
        SimpleNameReferenceNode nameReferenceNode = NodeFactory.createSimpleNameReferenceNode(identifierToken);
        MappingConstructorExpressionNode annotValue = getAnnotationExpression(schemaString, cacheConfigContext);
        return NodeFactory.createAnnotationNode(atToken, nameReferenceNode, annotValue);
    }

    private MappingConstructorExpressionNode getAnnotationExpression(String schemaString,
                                                                     CacheConfigContext cacheConfigContext) {
        Token openBraceToken = NodeFactory.createToken(SyntaxKind.OPEN_BRACE_TOKEN);
        Token closeBraceToken = NodeFactory.createToken(SyntaxKind.CLOSE_BRACE_TOKEN);
        List<Node> fields = new ArrayList<>();
        SpecificFieldNode schemaFieldNode = getSchemaStringFieldNode(schemaString);
        Token separator = NodeFactory.createToken(SyntaxKind.COMMA_TOKEN);
        fields.add(schemaFieldNode);
        fields.add(separator);
        SpecificFieldNode cacheFieldNode = getFieldCacheConfigNode(cacheConfigContext);
        fields.add(cacheFieldNode);
        SeparatedNodeList<MappingFieldNode> separatedNodeList = NodeFactory.createSeparatedNodeList(fields);
        return NodeFactory.createMappingConstructorExpressionNode(openBraceToken, separatedNodeList, closeBraceToken);
    }

    private SpecificFieldNode getSchemaStringFieldNode(String schemaString) {
        Node fieldName = NodeFactory.createIdentifierToken(SCHEMA_STRING_FIELD);
        Token colon = NodeFactory.createToken(SyntaxKind.COLON_TOKEN);
        String expression = "\"" + schemaString + "\"";
        ExpressionNode fieldValue = NodeParser.parseExpression(expression);
        return NodeFactory.createSpecificFieldNode(null, fieldName, colon, fieldValue);
    }

    private SpecificFieldNode getFieldCacheConfigNode(CacheConfigContext cacheConfigContext) {
        Node fieldName = NodeFactory.createIdentifierToken(FIELD_CACHE_CONFIG_FIELD);
        Token colon = NodeFactory.createToken(SyntaxKind.COLON_TOKEN);
        MappingConstructorExpressionNode fieldCacheValue = getFieldCacheConfigValueNode(cacheConfigContext);
        return NodeFactory.createSpecificFieldNode(null, fieldName, colon, fieldCacheValue);
    }

    private MappingConstructorExpressionNode getFieldCacheConfigValueNode(CacheConfigContext cacheConfigContext) {
        Token openBraceToken = NodeFactory.createToken(SyntaxKind.OPEN_BRACE_TOKEN);
        Token closeBraceToken = NodeFactory.createToken(SyntaxKind.CLOSE_BRACE_TOKEN);
        List<Node> fields = new ArrayList<>();
        Token separator = NodeFactory.createToken(SyntaxKind.COMMA_TOKEN);
        SpecificFieldNode cacheEnabledFieldNode = getEnabledFieldNode(cacheConfigContext.getEnabled());
        fields.add(cacheEnabledFieldNode);
        fields.add(separator);
        SpecificFieldNode cacheMaxSizeFieldNode = getMaxSizeFieldNode(cacheConfigContext.getMaxSize());
        fields.add(cacheMaxSizeFieldNode);
        SeparatedNodeList<MappingFieldNode> separatedNodeList = NodeFactory.createSeparatedNodeList(fields);
        return NodeFactory.createMappingConstructorExpressionNode(openBraceToken, separatedNodeList, closeBraceToken);
    }

    private SpecificFieldNode getEnabledFieldNode(boolean enabledFieldCache) {
        Node fieldName = NodeFactory.createIdentifierToken(ENABLED_CACHE_FIELD);
        Token colon = NodeFactory.createToken(SyntaxKind.COLON_TOKEN);
        ExpressionNode fieldValue = NodeParser.parseExpression(String.valueOf(enabledFieldCache));
        return NodeFactory.createSpecificFieldNode(null, fieldName, colon, fieldValue);
    }

    private SpecificFieldNode getMaxSizeFieldNode(int maxSize) {
        Node fieldName = NodeFactory.createIdentifierToken(MAX_SIZE_CACHE_FIELD);
        Token colon = NodeFactory.createToken(SyntaxKind.COLON_TOKEN);
        ExpressionNode fieldValue = NodeParser.parseExpression(String.valueOf(maxSize));
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

    private void updateContext(SourceModifierContext context, Location location,
                               CompilationDiagnostic compilerDiagnostic, String errorMessage) {
        DiagnosticInfo diagnosticInfo = new DiagnosticInfo(compilerDiagnostic.getDiagnosticCode(),
                                                           compilerDiagnostic.getDiagnostic(),
                                                           compilerDiagnostic.getDiagnosticSeverity());
        Diagnostic diagnostic = DiagnosticFactory.createDiagnostic(diagnosticInfo, location, errorMessage);
        context.reportDiagnostic(diagnostic);
    }

    private String getGraphqlModulePrefix(ModulePartNode rootNode) {
        for (ImportDeclarationNode importDeclarationNode : rootNode.imports()) {
            if (!isGraphqlImportNode(importDeclarationNode)) {
                continue;
            }
            if (importDeclarationNode.prefix().isPresent()) {
                return importDeclarationNode.prefix().get().prefix().text();
            }
        }
        return PACKAGE_NAME;
    }

    private ModulePartNode addImportsIfMissing(ModulePartNode rootNode) {
        if (rootNode.imports().isEmpty()) {
            ImportDeclarationNode importDeclarationNode = getGraphqlImportNode();
            NodeList<ImportDeclarationNode> importNodes = NodeFactory.createNodeList(importDeclarationNode);
            return rootNode.modify().withImports(importNodes).apply();
        }

        boolean foundGraphqlImport = false;

        for (ImportDeclarationNode importNode : rootNode.imports()) {
            if (!isGraphqlImportNode(importNode)) {
                continue;
            }
            foundGraphqlImport = true;
            break;
        }
        if (!foundGraphqlImport) {
            ImportDeclarationNode importDeclarationNode = getGraphqlImportNode();
            NodeList<ImportDeclarationNode> importNodes = rootNode.imports().add(importDeclarationNode);
            return rootNode.modify().withImports(importNodes).apply();
        }
        return rootNode;
    }

    private ImportDeclarationNode getGraphqlImportNode() {
        Token importKeyword = NodeFactory.createToken(SyntaxKind.IMPORT_KEYWORD,
                                                      NodeFactory.createEmptyMinutiaeList(),
                                                      NodeFactory.createMinutiaeList(
                                                              NodeFactory.createWhitespaceMinutiae(" ")));

        Token orgNameToken = NodeFactory.createIdentifierToken(PACKAGE_ORG);
        Token slashToken = NodeFactory.createToken(SyntaxKind.SLASH_TOKEN);
        ImportOrgNameNode importOrgNameToken = NodeFactory.createImportOrgNameNode(orgNameToken, slashToken);

        IdentifierToken moduleNameNode = NodeFactory.createIdentifierToken(PACKAGE_NAME);
        SeparatedNodeList<IdentifierToken> moduleName = NodeFactory.createSeparatedNodeList(moduleNameNode);
        Token semicolonToken = NodeFactory.createToken(SyntaxKind.SEMICOLON_TOKEN);
        return NodeFactory.createImportDeclarationNode(importKeyword, importOrgNameToken, moduleName, null,
                                                       semicolonToken);
    }

    private static boolean isGraphqlImportNode(ImportDeclarationNode importNode) {
        if (importNode.orgName().isEmpty()) {
            return false;
        }
        if (!PACKAGE_ORG.equals(importNode.orgName().get().orgName().text())) {
            return false;
        }
        if (importNode.moduleName().size() != 1) {
            return false;
        }
        return PACKAGE_NAME.equals(importNode.moduleName().get(0).text());
    }
}
