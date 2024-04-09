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

package io.ballerina.stdlib.graphql.compiler;

import io.ballerina.compiler.api.SemanticModel;
import io.ballerina.compiler.api.symbols.Annotatable;
import io.ballerina.compiler.api.symbols.AnnotationSymbol;
import io.ballerina.compiler.api.symbols.ClassSymbol;
import io.ballerina.compiler.api.symbols.IntersectionTypeSymbol;
import io.ballerina.compiler.api.symbols.MethodSymbol;
import io.ballerina.compiler.api.symbols.ModuleSymbol;
import io.ballerina.compiler.api.symbols.ObjectTypeSymbol;
import io.ballerina.compiler.api.symbols.ParameterSymbol;
import io.ballerina.compiler.api.symbols.Qualifier;
import io.ballerina.compiler.api.symbols.RecordTypeSymbol;
import io.ballerina.compiler.api.symbols.ResourceMethodSymbol;
import io.ballerina.compiler.api.symbols.ServiceDeclarationSymbol;
import io.ballerina.compiler.api.symbols.Symbol;
import io.ballerina.compiler.api.symbols.SymbolKind;
import io.ballerina.compiler.api.symbols.TypeDefinitionSymbol;
import io.ballerina.compiler.api.symbols.TypeDescKind;
import io.ballerina.compiler.api.symbols.TypeReferenceTypeSymbol;
import io.ballerina.compiler.api.symbols.TypeSymbol;
import io.ballerina.compiler.api.symbols.UnionTypeSymbol;
import io.ballerina.compiler.syntax.tree.AnnotationNode;
import io.ballerina.compiler.syntax.tree.BasicLiteralNode;
import io.ballerina.compiler.syntax.tree.DefaultableParameterNode;
import io.ballerina.compiler.syntax.tree.ExpressionNode;
import io.ballerina.compiler.syntax.tree.IdentifierToken;
import io.ballerina.compiler.syntax.tree.MappingConstructorExpressionNode;
import io.ballerina.compiler.syntax.tree.MappingFieldNode;
import io.ballerina.compiler.syntax.tree.ModuleVariableDeclarationNode;
import io.ballerina.compiler.syntax.tree.Node;
import io.ballerina.compiler.syntax.tree.ObjectConstructorExpressionNode;
import io.ballerina.compiler.syntax.tree.QualifiedNameReferenceNode;
import io.ballerina.compiler.syntax.tree.RecordFieldWithDefaultValueNode;
import io.ballerina.compiler.syntax.tree.SpecificFieldNode;
import io.ballerina.compiler.syntax.tree.SyntaxKind;
import io.ballerina.compiler.syntax.tree.TypeDefinitionNode;
import io.ballerina.projects.Project;
import io.ballerina.projects.plugins.SyntaxNodeAnalysisContext;
import io.ballerina.stdlib.graphql.commons.types.Schema;
import io.ballerina.stdlib.graphql.compiler.schema.generator.SchemaGenerator;
import io.ballerina.stdlib.graphql.compiler.service.InterfaceEntityFinder;
import io.ballerina.stdlib.graphql.compiler.service.validator.DefaultableParameterNodeFinder;
import io.ballerina.stdlib.graphql.compiler.service.validator.EntityAnnotationFinder;
import io.ballerina.stdlib.graphql.compiler.service.validator.RecordFieldWithDefaultValueVisitor;
import io.ballerina.stdlib.graphql.compiler.service.validator.RecordTypeDefinitionNodeFinder;
import io.ballerina.tools.diagnostics.Diagnostic;
import io.ballerina.tools.diagnostics.DiagnosticSeverity;

import java.util.ArrayList;
import java.util.List;
import java.util.stream.Collectors;

import static io.ballerina.stdlib.graphql.commons.utils.Utils.PACKAGE_NAME;
import static io.ballerina.stdlib.graphql.commons.utils.Utils.hasGraphqlListener;
import static io.ballerina.stdlib.graphql.commons.utils.Utils.isGraphQLServiceObjectDeclaration;
import static io.ballerina.stdlib.graphql.commons.utils.Utils.isGraphqlModuleSymbol;
import static io.ballerina.stdlib.graphql.commons.utils.Utils.isSubgraphModuleSymbol;
import static io.ballerina.stdlib.graphql.compiler.ModuleLevelVariableDeclarationAnalysisTask.getDescription;
import static io.ballerina.stdlib.graphql.compiler.schema.generator.GeneratorUtils.getDescription;

/**
 * Util class for the compiler plugin.
 */
public final class Utils {

    // resource function constants
    public static final String LISTENER_IDENTIFIER = "Listener";
    public static final String CONTEXT_IDENTIFIER = "Context";
    public static final String FIELD_IDENTIFIER = "Field";
    public static final String FILE_UPLOAD_IDENTIFIER = "Upload";
    public static final String SERVICE_CONFIG_IDENTIFIER = "ServiceConfig";
    public static final String SUBGRAPH_ANNOTATION_NAME = "Subgraph";
    public static final String UUID_RECORD_NAME = "Uuid";
    private static final String ORG_NAME = "ballerina";
    private static final String UUID_MODULE_NAME = "uuid";
    private static final String RESOURCE_CONFIG_ANNOTATION = "ResourceConfig";
    private static final String ENTITY_ANNOTATION = "Entity";

    private static final String CACHE_CONFIG_ENABLE_FIELD = "enabled";
    private static final String CACHE_CONFIG_MAX_SIZE_FIELD = "maxSize";
    private static final int DEFAULT_MAX_SIZE = 120;

    // User data map keys
    public static final String IS_ANALYSIS_COMPLETED = "isAnalysisCompleted";
    public static final String MODIFIER_CONTEXT_MAP = "modifierContextMap";

    private Utils() {
    }

    public static boolean isValidUuidModule(ModuleSymbol module) {
        return module.id().orgName().equals(ORG_NAME) && module.id().moduleName().equals(UUID_MODULE_NAME);
    }

    public static boolean isRemoteMethod(MethodSymbol methodSymbol) {
        return methodSymbol.qualifiers().contains(Qualifier.REMOTE);
    }

    public static boolean isResourceMethod(MethodSymbol methodSymbol) {
        return methodSymbol.qualifiers().contains(Qualifier.RESOURCE);
    }

    public static boolean isGraphqlListener(Symbol listenerSymbol) {
        if (listenerSymbol.kind() != SymbolKind.TYPE) {
            return false;
        }
        TypeSymbol typeSymbol = ((TypeReferenceTypeSymbol) listenerSymbol).typeDescriptor();
        if (typeSymbol.typeKind() != TypeDescKind.OBJECT) {
            return false;
        }
        if (!isGraphqlModuleSymbol(typeSymbol)) {
            return false;
        }
        if (typeSymbol.getName().isEmpty()) {
            return false;
        }
        return LISTENER_IDENTIFIER.equals(typeSymbol.getName().get());
    }

    public static boolean isIgnoreType(TypeSymbol typeSymbol) {
        if (typeSymbol.typeKind() == TypeDescKind.NIL || typeSymbol.typeKind() == TypeDescKind.ERROR) {
            return true;
        }
        if (typeSymbol.typeKind() == TypeDescKind.TYPE_REFERENCE) {
            return isIgnoreType(((TypeReferenceTypeSymbol) typeSymbol).typeDescriptor());
        }
        return false;
    }

    public static List<TypeSymbol> getEffectiveTypes(UnionTypeSymbol unionTypeSymbol) {
        List<TypeSymbol> effectiveTypes = new ArrayList<>();
        for (TypeSymbol typeSymbol : unionTypeSymbol.userSpecifiedMemberTypes()) {
            if (typeSymbol.typeKind() == TypeDescKind.UNION) {
                effectiveTypes.addAll(getEffectiveTypes((UnionTypeSymbol) typeSymbol));
            } else if (!isIgnoreType(typeSymbol)) {
                effectiveTypes.add(typeSymbol);
            }
        }
        return effectiveTypes;
    }

    public static TypeSymbol getEffectiveType(IntersectionTypeSymbol intersectionTypeSymbol) {
        List<TypeSymbol> effectiveTypes = new ArrayList<>();
        for (TypeSymbol typeSymbol : intersectionTypeSymbol.memberTypeDescriptors()) {
            if (typeSymbol.typeKind() == TypeDescKind.READONLY) {
                continue;
            }
            effectiveTypes.add(typeSymbol);
        }
        if (effectiveTypes.size() == 1) {
            return effectiveTypes.get(0);
        }
        return intersectionTypeSymbol;
    }

    public static ObjectTypeSymbol getObjectTypeSymbol(Symbol serviceObjectTypeOrClass) {
        if (serviceObjectTypeOrClass.kind() == SymbolKind.TYPE_DEFINITION) {
            TypeDefinitionSymbol serviceObjectTypeSymbol = (TypeDefinitionSymbol) serviceObjectTypeOrClass;
            TypeSymbol typeSymbol = serviceObjectTypeSymbol.typeDescriptor();
            if (typeSymbol.typeKind() == TypeDescKind.OBJECT) {
                return (ObjectTypeSymbol) typeSymbol;
            }
        } else if (serviceObjectTypeOrClass.kind() == SymbolKind.CLASS) {
            return (ObjectTypeSymbol) serviceObjectTypeOrClass;
        }
        String symbolName = "Provided symbol";
        if (serviceObjectTypeOrClass.getName().isPresent()) {
            symbolName = serviceObjectTypeOrClass.getName().get();
        }
        throw new UnsupportedOperationException(
                symbolName + " is not ClassSymbol or TypeDefinitionSymbol of an object");
    }

    public static boolean isDistinctServiceReference(TypeSymbol typeSymbol) {
        if (typeSymbol.typeKind() != TypeDescKind.TYPE_REFERENCE) {
            return false;
        }
        Symbol typeDescriptor = ((TypeReferenceTypeSymbol) typeSymbol).typeDescriptor();
        return isDistinctServiceClass(typeDescriptor);
    }

    public static boolean isDistinctServiceClass(Symbol symbol) {
        if (!isServiceClass(symbol)) {
            return false;
        }
        return ((ClassSymbol) symbol).qualifiers().contains(Qualifier.DISTINCT);
    }

    public static boolean isServiceClass(Symbol symbol) {
        if (symbol.kind() != SymbolKind.CLASS) {
            return false;
        }
        return ((ClassSymbol) symbol).qualifiers().contains(Qualifier.SERVICE);
    }

    public static boolean isServiceObjectDefinition(Symbol symbol) {
        if (symbol.kind() != SymbolKind.TYPE_DEFINITION) {
            return false;
        }
        TypeSymbol typeDescriptor = ((TypeDefinitionSymbol) symbol).typeDescriptor();
        return isServiceObjectType(typeDescriptor);
    }

    public static boolean isServiceObjectReference(TypeSymbol typeSymbol) {
        if (typeSymbol.typeKind() != TypeDescKind.TYPE_REFERENCE) {
            return false;
        }
        TypeSymbol typeDescriptor = ((TypeReferenceTypeSymbol) typeSymbol).typeDescriptor();
        return isServiceObjectType(typeDescriptor);
    }

    private static boolean isServiceObjectType(TypeSymbol typeSymbol) {
        if (typeSymbol.typeKind() != TypeDescKind.OBJECT || typeSymbol.kind() != SymbolKind.TYPE) {
            return false;
        }
        return ((ObjectTypeSymbol) typeSymbol).qualifiers().contains(Qualifier.SERVICE);
    }

    public static boolean hasCompilationErrors(SyntaxNodeAnalysisContext context) {
        for (Diagnostic diagnostic : context.semanticModel().diagnostics()) {
            if (diagnostic.diagnosticInfo().severity() == DiagnosticSeverity.ERROR) {
                return true;
            }
        }
        return false;
    }

    public static boolean isFileUploadParameter(TypeSymbol typeSymbol) {
        if (typeSymbol.getName().isEmpty()) {
            return false;
        }
        if (!isGraphqlModuleSymbol(typeSymbol)) {
            return false;
        }
        return FILE_UPLOAD_IDENTIFIER.equals(typeSymbol.getName().get());
    }

    public static boolean isValidGraphqlParameter(TypeSymbol typeSymbol) {
        if (typeSymbol.getName().isEmpty()) {
            return false;
        }
        if (!isGraphqlModuleSymbol(typeSymbol)) {
            return false;
        }
        if (isContextParameter(typeSymbol)) {
            return true;
        }
        return FIELD_IDENTIFIER.equals(typeSymbol.getName().get());
    }

    public static boolean isContextParameter(TypeSymbol typeSymbol) {
        if (typeSymbol.getName().isEmpty()) {
            return false;
        }
        return isGraphqlModuleSymbol(typeSymbol) && CONTEXT_IDENTIFIER.equals(typeSymbol.getName().get());
    }

    public static String getAccessor(ResourceMethodSymbol resourceMethodSymbol) {
        return resourceMethodSymbol.getName().orElse(null);
    }

    public static boolean isFunctionDefinition(Node node) {
        return node.kind() == SyntaxKind.RESOURCE_ACCESSOR_DEFINITION
                || node.kind() == SyntaxKind.OBJECT_METHOD_DEFINITION;
    }

    public static boolean isRecordTypeDefinition(Symbol symbol) {
        if (symbol.kind() != SymbolKind.TYPE_DEFINITION) {
            return false;
        }
        TypeDefinitionSymbol typeDefinitionSymbol = (TypeDefinitionSymbol) symbol;
        return typeDefinitionSymbol.typeDescriptor().typeKind() == TypeDescKind.RECORD;
    }

    public static boolean hasSubgraphAnnotation(List<AnnotationSymbol> annotations) {
        for (AnnotationSymbol annotation : annotations) {
            if (annotation.getName().isEmpty() || !isSubgraphModuleSymbol(annotation)) {
                continue;
            }
            String annotationName = annotation.getName().get();
            if (annotationName.equals(SUBGRAPH_ANNOTATION_NAME)) {
                return true;
            }
        }
        return false;
    }

    // The function used by the LS extension to get the Schema object
    public static Schema getSchemaObject(Node node, SemanticModel semanticModel, Project project) {
        String description;
        Node serviceNode;
        boolean isSubgraph;
        if (node.kind() == SyntaxKind.SERVICE_DECLARATION) {
            if (semanticModel.symbol(node).isEmpty()) {
                return null;
            }
            ServiceDeclarationSymbol symbol = (ServiceDeclarationSymbol) semanticModel.symbol(node).get();
            if (!hasGraphqlListener(symbol)) {
                return null;
            }
            isSubgraph = hasSubgraphAnnotation(symbol.annotations());
            description = getDescription(symbol);
            serviceNode = node;
        } else if (node.kind() == SyntaxKind.MODULE_VAR_DECL) {
            ModuleVariableDeclarationNode moduleVarDclNode = (ModuleVariableDeclarationNode) node;
            if (!isGraphQLServiceObjectDeclaration(moduleVarDclNode)) {
                return null;
            }
            if (moduleVarDclNode.initializer().isEmpty()) {
                return null;
            }
            ExpressionNode expressionNode = moduleVarDclNode.initializer().get();
            if (expressionNode.kind() != SyntaxKind.OBJECT_CONSTRUCTOR) {
                return null;
            }
            ObjectConstructorExpressionNode objectNode = (ObjectConstructorExpressionNode) expressionNode;
            // noinspection OptionalGetWithoutIsPresent
            var annotations = objectNode.annotations().stream()
                    .map(annotationNode -> (AnnotationSymbol) semanticModel.symbol(annotationNode).get())
                    .collect(Collectors.toList());
            isSubgraph = hasSubgraphAnnotation(annotations);
            serviceNode = expressionNode;
            description = getDescription(semanticModel, moduleVarDclNode);
        } else {
            return null;
        }

        InterfaceEntityFinder interfaceFinder = new InterfaceEntityFinder();
        interfaceFinder.populateInterfacesAndEntities(semanticModel);
        FinderContext finderContext = new FinderContext(semanticModel, project,
                                                        project.currentPackage().getDefaultModule().moduleId());
        SchemaGenerator schemaGenerator = new SchemaGenerator(serviceNode, interfaceFinder, finderContext, description,
                                                              isSubgraph);
        return schemaGenerator.generate();
    }
    
    public static boolean isPrimitiveTypeSymbol(TypeSymbol typeSymbol) {
        switch (typeSymbol.typeKind()) {
            case INT:
            case INT_SIGNED8:
            case INT_UNSIGNED8:
            case INT_SIGNED16:
            case INT_UNSIGNED16:
            case INT_SIGNED32:
            case INT_UNSIGNED32:
            case STRING:
            case STRING_CHAR:
            case BOOLEAN:
            case DECIMAL:
            case FLOAT:
                return true;
        }
        return false;
    }

    public static boolean hasResourceConfigAnnotation(MethodSymbol resourceMethodSymbol) {
        return resourceMethodSymbol.annotations().stream().anyMatch(
                annotationSymbol -> isGraphqlModuleSymbol(annotationSymbol) && annotationSymbol.getName().isPresent()
                        && annotationSymbol.getName().get().equals(RESOURCE_CONFIG_ANNOTATION));
    }

    public static AnnotationSymbol getEntityAnnotationSymbol(Symbol symbol) {
        Annotatable annotatable;
        if (symbol.kind() == SymbolKind.TYPE_DEFINITION) {
            annotatable = (TypeDefinitionSymbol) symbol;
        } else if (symbol.kind() == SymbolKind.CLASS) {
            annotatable = (ClassSymbol) symbol;
        } else {
            return null;
        }
        return annotatable.annotations().stream()
                .filter(annotationSymbol -> annotationSymbol.getName().orElse("").equals(ENTITY_ANNOTATION)).findFirst()
                .orElse(null);
    }

    public static String getStringValue(SpecificFieldNode specificFieldNode) {
        if (specificFieldNode.valueExpr().isEmpty()) {
            return null;
        }
        ExpressionNode valueExpression = specificFieldNode.valueExpr().get();
        if (valueExpression.kind() == SyntaxKind.STRING_LITERAL) {
            BasicLiteralNode stringLiteralNode = (BasicLiteralNode) valueExpression;
            String stringLiteral = stringLiteralNode.toSourceCode().trim();
            return stringLiteral.substring(1, stringLiteral.length() - 1);
        }
        return null;
    }

    public static boolean getBooleanValue(MappingConstructorExpressionNode mappingConstructorNode) {
        if (mappingConstructorNode.fields().isEmpty()) {
            return true;
        }
        for (MappingFieldNode field: mappingConstructorNode.fields()) {
            if (field.kind() == SyntaxKind.SPECIFIC_FIELD) {
                SpecificFieldNode specificFieldNode = (SpecificFieldNode) field;
                Node fieldName = specificFieldNode.fieldName();
                if (fieldName.kind() == SyntaxKind.IDENTIFIER_TOKEN) {
                    IdentifierToken identifierToken = (IdentifierToken) fieldName;
                    String identifierName = identifierToken.text();
                    if (CACHE_CONFIG_ENABLE_FIELD.equals(identifierName) && specificFieldNode.valueExpr().isPresent()) {
                        ExpressionNode valueExpression = specificFieldNode.valueExpr().get();
                        if (valueExpression.kind() == SyntaxKind.BOOLEAN_LITERAL) {
                            BasicLiteralNode stringLiteralNode = (BasicLiteralNode) valueExpression;
                            return Boolean.parseBoolean(stringLiteralNode.toSourceCode().trim());
                        }
                    }
                }
            }
        }
        return true;
    }

    public static int getMaxSize(MappingConstructorExpressionNode mappingConstructorNode) {
        if (mappingConstructorNode.fields().isEmpty()) {
            return DEFAULT_MAX_SIZE;
        }
        for (MappingFieldNode field: mappingConstructorNode.fields()) {
            if (field.kind() == SyntaxKind.SPECIFIC_FIELD) {
                SpecificFieldNode specificFieldNode = (SpecificFieldNode) field;
                Node fieldName = specificFieldNode.fieldName();
                if (fieldName.kind() == SyntaxKind.IDENTIFIER_TOKEN) {
                    IdentifierToken identifierToken = (IdentifierToken) fieldName;
                    String identifierName = identifierToken.text();
                    if (CACHE_CONFIG_MAX_SIZE_FIELD.equals(identifierName) &&
                            specificFieldNode.valueExpr().isPresent()) {
                        ExpressionNode valueExpression = specificFieldNode.valueExpr().get();
                        if (valueExpression.kind() == SyntaxKind.NUMERIC_LITERAL) {
                            BasicLiteralNode integerLiteralNode = (BasicLiteralNode) valueExpression;
                            return Integer.parseInt(integerLiteralNode.toSourceCode().trim());
                        }
                    }
                }
            }
        }
        return DEFAULT_MAX_SIZE;
    }

    public static String getStringValue(BasicLiteralNode expression) {
        String literalToken = expression.literalToken().text().trim();
        return literalToken.substring(1, literalToken.length() - 1);
    }

    public static DefaultableParameterNode getDefaultableParameterNode(MethodSymbol methodSymbol,
                                                                       ParameterSymbol parameterSymbol,
                                                                       FinderContext context) {
        DefaultableParameterNodeFinder finder = new DefaultableParameterNodeFinder(context, methodSymbol,
                                                                                   parameterSymbol);
        return finder.getDeflatableParameterNode().orElse(null);
    }

    public static TypeDefinitionNode getRecordTypeDefinitionNode(RecordTypeSymbol recordTypeSymbol,
                                                                 String recordTypeName, FinderContext context) {
        RecordTypeDefinitionNodeFinder recordTypeDefFinder = new RecordTypeDefinitionNodeFinder(context,
                                                                                                recordTypeSymbol,
                                                                                                recordTypeName);
        return recordTypeDefFinder.find().orElse(null);
    }

    public static AnnotationNode getEntityAnnotationNode(AnnotationSymbol annotationSymbol, String entityName,
                                                         FinderContext context) {
        EntityAnnotationFinder entityAnnotationFinder = new EntityAnnotationFinder(context, annotationSymbol,
                                                                                   entityName);
        return entityAnnotationFinder.find().orElse(null);
    }

    public static RecordFieldWithDefaultValueNode getRecordFieldWithDefaultValueNode(String recordFieldName,
                                                                                     TypeDefinitionNode typeDefNode,
                                                                                     SemanticModel semanticModel) {
        RecordFieldWithDefaultValueVisitor visitor = new RecordFieldWithDefaultValueVisitor(semanticModel,
                                                                                            recordFieldName);
        typeDefNode.accept(visitor);
        return visitor.getRecordFieldNode().orElse(null);
    }

    public static List<TypeSymbol> getTypeInclusions(TypeSymbol typeSymbol) {
        if (typeSymbol.typeKind() == TypeDescKind.TYPE_REFERENCE) {
            TypeSymbol typeDescriptor = ((TypeReferenceTypeSymbol) typeSymbol).typeDescriptor();
            if (typeDescriptor.typeKind() == TypeDescKind.RECORD) {
                return ((RecordTypeSymbol) typeDescriptor).typeInclusions();
            }
        }
        if (typeSymbol.typeKind() == TypeDescKind.RECORD) {
            return ((RecordTypeSymbol) typeSymbol).typeInclusions();
        }
        return new ArrayList<>();
    }

    public static boolean isGraphqlServiceConfig(AnnotationNode annotationNode) {
        if (annotationNode.annotReference().kind() != SyntaxKind.QUALIFIED_NAME_REFERENCE) {
            return false;
        }
        QualifiedNameReferenceNode referenceNode = ((QualifiedNameReferenceNode) annotationNode.annotReference());
        if (!PACKAGE_NAME.equals(referenceNode.modulePrefix().text())) {
            return false;
        }
        return SERVICE_CONFIG_IDENTIFIER.equals(referenceNode.identifier().text());
    }
}
