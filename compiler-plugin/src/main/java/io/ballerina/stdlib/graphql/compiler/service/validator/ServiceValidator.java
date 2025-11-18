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

package io.ballerina.stdlib.graphql.compiler.service.validator;

import io.ballerina.compiler.api.SemanticModel;
import io.ballerina.compiler.api.symbols.AnnotationSymbol;
import io.ballerina.compiler.api.symbols.ArrayTypeSymbol;
import io.ballerina.compiler.api.symbols.ClassSymbol;
import io.ballerina.compiler.api.symbols.EnumSymbol;
import io.ballerina.compiler.api.symbols.FunctionSymbol;
import io.ballerina.compiler.api.symbols.FunctionTypeSymbol;
import io.ballerina.compiler.api.symbols.IntersectionTypeSymbol;
import io.ballerina.compiler.api.symbols.MapTypeSymbol;
import io.ballerina.compiler.api.symbols.MethodSymbol;
import io.ballerina.compiler.api.symbols.ObjectTypeSymbol;
import io.ballerina.compiler.api.symbols.ParameterKind;
import io.ballerina.compiler.api.symbols.ParameterSymbol;
import io.ballerina.compiler.api.symbols.Qualifier;
import io.ballerina.compiler.api.symbols.RecordFieldSymbol;
import io.ballerina.compiler.api.symbols.RecordTypeSymbol;
import io.ballerina.compiler.api.symbols.ResourceMethodSymbol;
import io.ballerina.compiler.api.symbols.ServiceDeclarationSymbol;
import io.ballerina.compiler.api.symbols.StreamTypeSymbol;
import io.ballerina.compiler.api.symbols.Symbol;
import io.ballerina.compiler.api.symbols.SymbolKind;
import io.ballerina.compiler.api.symbols.TableTypeSymbol;
import io.ballerina.compiler.api.symbols.TypeDefinitionSymbol;
import io.ballerina.compiler.api.symbols.TypeDescKind;
import io.ballerina.compiler.api.symbols.TypeReferenceTypeSymbol;
import io.ballerina.compiler.api.symbols.TypeSymbol;
import io.ballerina.compiler.api.symbols.UnionTypeSymbol;
import io.ballerina.compiler.api.symbols.resourcepath.PathSegmentList;
import io.ballerina.compiler.api.symbols.resourcepath.ResourcePath;
import io.ballerina.compiler.api.symbols.resourcepath.util.PathSegment;
import io.ballerina.compiler.syntax.tree.AnnotationNode;
import io.ballerina.compiler.syntax.tree.DefaultableParameterNode;
import io.ballerina.compiler.syntax.tree.ExpressionNode;
import io.ballerina.compiler.syntax.tree.IdentifierToken;
import io.ballerina.compiler.syntax.tree.ListConstructorExpressionNode;
import io.ballerina.compiler.syntax.tree.MappingConstructorExpressionNode;
import io.ballerina.compiler.syntax.tree.MappingFieldNode;
import io.ballerina.compiler.syntax.tree.MetadataNode;
import io.ballerina.compiler.syntax.tree.Node;
import io.ballerina.compiler.syntax.tree.NodeList;
import io.ballerina.compiler.syntax.tree.ObjectConstructorExpressionNode;
import io.ballerina.compiler.syntax.tree.RecordFieldWithDefaultValueNode;
import io.ballerina.compiler.syntax.tree.ServiceDeclarationNode;
import io.ballerina.compiler.syntax.tree.SimpleNameReferenceNode;
import io.ballerina.compiler.syntax.tree.SpecificFieldNode;
import io.ballerina.compiler.syntax.tree.SyntaxKind;
import io.ballerina.compiler.syntax.tree.TypeDefinitionNode;
import io.ballerina.projects.plugins.SyntaxNodeAnalysisContext;
import io.ballerina.stdlib.graphql.commons.types.Schema;
import io.ballerina.stdlib.graphql.commons.types.TypeName;
import io.ballerina.stdlib.graphql.commons.utils.TypeUtils;
import io.ballerina.stdlib.graphql.compiler.CacheConfigContext;
import io.ballerina.stdlib.graphql.compiler.FinderContext;
import io.ballerina.stdlib.graphql.compiler.Utils;
import io.ballerina.stdlib.graphql.compiler.diagnostics.CompilationDiagnostic;
import io.ballerina.stdlib.graphql.compiler.service.InterfaceEntityFinder;
import io.ballerina.tools.diagnostics.DiagnosticSeverity;
import io.ballerina.tools.diagnostics.Location;

import java.util.ArrayList;
import java.util.Collections;
import java.util.HashSet;
import java.util.List;
import java.util.Map;
import java.util.Optional;
import java.util.Set;
import java.util.stream.Collectors;

import static io.ballerina.compiler.syntax.tree.SyntaxKind.SPECIFIC_FIELD;
import static io.ballerina.compiler.syntax.tree.SyntaxKind.SPREAD_MEMBER;
import static io.ballerina.stdlib.graphql.commons.utils.Utils.getGraphqlModulePrefix;
import static io.ballerina.stdlib.graphql.compiler.Utils.getAccessor;
import static io.ballerina.stdlib.graphql.compiler.Utils.getBooleanValue;
import static io.ballerina.stdlib.graphql.compiler.Utils.getDefaultableParameterNode;
import static io.ballerina.stdlib.graphql.compiler.Utils.getEffectiveType;
import static io.ballerina.stdlib.graphql.compiler.Utils.getEffectiveTypes;
import static io.ballerina.stdlib.graphql.compiler.Utils.getEntityAnnotationNode;
import static io.ballerina.stdlib.graphql.compiler.Utils.getEntityAnnotationSymbol;
import static io.ballerina.stdlib.graphql.compiler.Utils.getMaxSize;
import static io.ballerina.stdlib.graphql.compiler.Utils.getRecordFieldWithDefaultValueNode;
import static io.ballerina.stdlib.graphql.compiler.Utils.getRecordTypeDefinitionNode;
import static io.ballerina.stdlib.graphql.compiler.Utils.getStringValue;
import static io.ballerina.stdlib.graphql.compiler.Utils.getTypeInclusions;
import static io.ballerina.stdlib.graphql.compiler.Utils.hasResourceConfigAnnotation;
import static io.ballerina.stdlib.graphql.compiler.Utils.isContextParameter;
import static io.ballerina.stdlib.graphql.compiler.Utils.isDistinctServiceClass;
import static io.ballerina.stdlib.graphql.compiler.Utils.isDistinctServiceReference;
import static io.ballerina.stdlib.graphql.compiler.Utils.isFileUploadParameter;
import static io.ballerina.stdlib.graphql.compiler.Utils.isGraphqlServiceConfig;
import static io.ballerina.stdlib.graphql.compiler.Utils.isPrimitiveTypeSymbol;
import static io.ballerina.stdlib.graphql.compiler.Utils.isRemoteMethod;
import static io.ballerina.stdlib.graphql.compiler.Utils.isResourceMethod;
import static io.ballerina.stdlib.graphql.compiler.Utils.isServiceClass;
import static io.ballerina.stdlib.graphql.compiler.Utils.isValidGraphqlParameter;
import static io.ballerina.stdlib.graphql.compiler.schema.generator.GeneratorUtils.FIELD_CACHE_CONFIG_FIELD;
import static io.ballerina.stdlib.graphql.compiler.schema.generator.GeneratorUtils.SCHEMA_STRING_FIELD;
import static io.ballerina.stdlib.graphql.compiler.service.validator.ValidatorUtils.RESOURCE_FUNCTION_GET;
import static io.ballerina.stdlib.graphql.compiler.service.validator.ValidatorUtils.RESOURCE_FUNCTION_SUBSCRIBE;
import static io.ballerina.stdlib.graphql.compiler.service.validator.ValidatorUtils.getLocation;
import static io.ballerina.stdlib.graphql.compiler.service.validator.ValidatorUtils.isInvalidFieldName;
import static io.ballerina.stdlib.graphql.compiler.service.validator.ValidatorUtils.isReservedFederatedResolverName;
import static io.ballerina.stdlib.graphql.compiler.service.validator.ValidatorUtils.isReservedFederatedTypeName;
import static io.ballerina.stdlib.graphql.compiler.service.validator.ValidatorUtils.updateContext;

/**
 * Validate functions in Ballerina GraphQL services.
 */
public class ServiceValidator {
    private final Set<Symbol> visitedClassesAndObjectTypeDefinitions = new HashSet<>();
    private final Set<String> validatedInputTypesHavingDefaultFields = new HashSet<>();
    private final List<TypeSymbol> existingInputObjectTypes = new ArrayList<>();
    private final List<TypeSymbol> existingReturnTypes = new ArrayList<>();
    private final InterfaceEntityFinder interfaceEntityFinder;
    private final SyntaxNodeAnalysisContext context;
    private final Node serviceNode;
    private int arrayDimension = 0;
    private boolean errorOccurred;
    private boolean hasQueryType;
    private final boolean isSubgraph;
    private TypeSymbol rootInputParameterTypeSymbol;
    private final List<String> currentFieldPath;
    private CacheConfigContext cacheConfigContext;

    private static final String FIELD_PATH_SEPARATOR = ".";
    private static final String PREFETCH_METHOD_PREFIX = "pre";
    private static final String PREFETCH_METHOD_NAME_CONFIG = "prefetchMethodName";
    private static final String KEY = "key";
    private static final String INPUT_OBJECT_FIELD = "input object field";
    private static final String PARAMETER = "parameter";
    private static final String CACHE_CONFIG = "cacheConfig";

    public ServiceValidator(SyntaxNodeAnalysisContext context, Node serviceNode,
                            InterfaceEntityFinder interfaceEntityFinder, boolean isSubgraph,
                            CacheConfigContext cacheConfigContext) {
        this.context = context;
        this.serviceNode = serviceNode;
        this.interfaceEntityFinder = interfaceEntityFinder;
        this.errorOccurred = false;
        this.hasQueryType = false;
        this.currentFieldPath = new ArrayList<>();
        this.isSubgraph = isSubgraph;
        this.cacheConfigContext = cacheConfigContext;
    }

    public void validate() {
        String modulePrefix = getGraphqlModulePrefix(this.context.node().syntaxTree().rootNode());
        if (serviceNode.kind() == SyntaxKind.SERVICE_DECLARATION) {
            validateServiceDeclaration(modulePrefix);
        } else if (serviceNode.kind() == SyntaxKind.OBJECT_CONSTRUCTOR) {
            validateServiceObject(modulePrefix);
        }
        validateEntities();
    }

    private void validateEntities() {
        for (Map.Entry<String, Symbol> entry : this.interfaceEntityFinder.getEntities().entrySet()) {
            AnnotationSymbol entityAnnotationSymbol = getEntityAnnotationSymbol(entry.getValue());
            if (entityAnnotationSymbol == null) {
                continue;
            }
            FinderContext finderContext = new FinderContext(this.context);
            AnnotationNode annotationNode = getEntityAnnotationNode(entityAnnotationSymbol, entry.getKey(),
                                                                    finderContext);
            if (annotationNode == null) {
                continue;
            }
            validateEntityAnnotation(annotationNode);
        }
    }

    private void validateEntityAnnotation(AnnotationNode entityAnnotation) {
        if (entityAnnotation.annotValue().isEmpty()) {
            return;
        }
        List<String> keyFields = new ArrayList<>();
        for (MappingFieldNode fieldNode : entityAnnotation.annotValue().get().fields()) {
            if (fieldNode.kind() != SPECIFIC_FIELD) {
                addDiagnostic(CompilationDiagnostic.PROVIDE_KEY_VALUE_PAIR_FOR_ENTITY_ANNOTATION, fieldNode.location());
                continue;
            }
            SpecificFieldNode specificFieldNode = (SpecificFieldNode) fieldNode;
            Node fieldNameNode = specificFieldNode.fieldName();
            if (fieldNameNode.kind() != SyntaxKind.IDENTIFIER_TOKEN) {
                continue;
            }
            IdentifierToken fieldNameToken = (IdentifierToken) fieldNameNode;
            String fieldName = fieldNameToken.text().trim();
            if (KEY.equals(fieldName)) {
                validateKeyField(specificFieldNode);
                keyFields = extractKeyFields(specificFieldNode);

            }

            validateFieldsAgainstKeys(keyFields, entityAnnotation.location());

        }
    }

    private void validateFieldsAgainstKeys(List<String> keyFields, Location location) {

        if (keyFields == null || keyFields.isEmpty()) {
            return;

        }

        Set<String> keyFieldSet = new HashSet<>(keyFields);
        List<RecordFieldSymbol> recordFields = getRecordFields();

        boolean hasExtraFields = false;

        for (RecordFieldSymbol recordField : recordFields) {
            String fieldName = recordField.getName().orElse(null);

            if (fieldName == null) {
                continue;
            }

            if (!keyFieldSet.contains(fieldName)) {
                hasExtraFields = true;
                addDiagnostic(CompilationDiagnostic.INVALID_ENTITY_FIELD,
                        recordField.location(), fieldName);
            }
        }
        Symbol currentEntity = getCurrentEntitySymbol();
        if (hasExtraFields && !hasResolveReferenceFunctionForEntity(currentEntity)) {
            addDiagnostic(CompilationDiagnostic.INVALID_ENTITY_FIELD, location);
        }
    }

    private Symbol getCurrentEntitySymbol() {

        for (Map.Entry<String, Symbol> entry : this.interfaceEntityFinder.getEntities().entrySet()) {
            AnnotationSymbol entityAnnotation = getEntityAnnotationSymbol(entry.getValue());
            if (entityAnnotation != null) {
                return entry.getValue();
            }
        }
        return null;
    }

    private boolean hasResolveReferenceFunctionForEntity(Symbol entitySymbol) {
        if (entitySymbol == null || context == null) {
            return false;
        }

        String entityName = entitySymbol.getName().orElse(null);
        if (entityName == null) {
            return false;
        }

        // Get semantic model from context
        SemanticModel semanticModel = context.semanticModel();

        // Get module symbols and search for resolveReference function
        List<Symbol> moduleSymbols = new ArrayList<>();
        semanticModel.moduleSymbols().forEach(moduleSymbols::add);

        for (Symbol symbol : moduleSymbols) {
            if (symbol.kind() != SymbolKind.FUNCTION) {
                continue;
            }

            FunctionSymbol functionSymbol = (FunctionSymbol) symbol;
            if (!"resolveReference".equals(functionSymbol.getName().orElse(""))) {
                continue;
            }

            Optional<List<ParameterSymbol>> paramsOpt = functionSymbol.typeDescriptor().params();
            if (paramsOpt.isEmpty() || paramsOpt.get().isEmpty()) {
                continue;
            }

            ParameterSymbol firstParam = paramsOpt.get().get(0);
            TypeSymbol paramType = firstParam.typeDescriptor();


            // Check if the parameter type matches the entity
            if (paramType != null) {
                // Try matching by name
                if (entityName.equals(paramType.getName().orElse(null))) {
                    return true;
                }

                // For type reference types, also check the original type
                if (paramType.typeKind() == TypeDescKind.TYPE_REFERENCE) {
                    TypeReferenceTypeSymbol typeRef = (TypeReferenceTypeSymbol) paramType;
                    if (entityName.equals(typeRef.getName().orElse(null))) {
                        return true;
                    }
                }
            }
        }

        return false;
    }
    private List<String> extractKeyFields(SpecificFieldNode specificFieldNode) {

        List<String> keyFields = new ArrayList<>();
        if (specificFieldNode.valueExpr().isEmpty()) {
            return keyFields;

        }

        ExpressionNode valueNode = specificFieldNode.valueExpr().get();

        if (valueNode.kind() == SyntaxKind.STRING_LITERAL) {
            keyFields.add(valueNode.toString().replace("\"", "").trim());
        } else if (valueNode.kind() == SyntaxKind.LIST_CONSTRUCTOR) {
            for (Node keyNode : ((ListConstructorExpressionNode) valueNode).expressions()) {
                if (keyNode.kind() == SyntaxKind.STRING_LITERAL) {
                    keyFields.add(keyNode.toString().replace("\"", "").trim());
                }
            }
        } else {
            addDiagnostic(CompilationDiagnostic.PROVIDE_A_STRING_LITERAL_OR_AN_ARRAY_OF_STRING_LITERALS_FOR_KEY_FIELD,
                    valueNode.location());

        }

        return keyFields;

    }

    private List<RecordFieldSymbol> getRecordFields() {

        for (Map.Entry<String, Symbol> entry : this.interfaceEntityFinder.getEntities().entrySet()) {
            AnnotationSymbol entityAnnotation = getEntityAnnotationSymbol(entry.getValue());
            if (entityAnnotation != null) {
                Symbol entitySymbol = entry.getValue();

                if (entitySymbol instanceof TypeDefinitionSymbol) {
                    TypeDefinitionSymbol typeDefSymbol = (TypeDefinitionSymbol) entitySymbol;
                    TypeSymbol typeDescriptor = typeDefSymbol.typeDescriptor();

                    if (typeDescriptor instanceof RecordTypeSymbol) {
                        RecordTypeSymbol recordType = (RecordTypeSymbol) typeDescriptor;
                        return new ArrayList<>(recordType.fieldDescriptors().values());
                    }
                }
            }
        }
        return Collections.emptyList();
    }

    private void validateKeyField(SpecificFieldNode specificFieldNode) {
        if (specificFieldNode.valueExpr().isEmpty()) {
            addDiagnostic(CompilationDiagnostic.PROVIDE_A_STRING_LITERAL_OR_AN_ARRAY_OF_STRING_LITERALS_FOR_KEY_FIELD,
                          specificFieldNode.location(), KEY);
            return;
        }
        ExpressionNode keyFieldExpression = specificFieldNode.valueExpr().get();
        if (keyFieldExpression.kind() == SyntaxKind.LIST_CONSTRUCTOR) {
            for (Node expression : ((ListConstructorExpressionNode) keyFieldExpression).expressions()) {
                validateKeyFieldValue(expression);
            }
            return;
        }
        validateKeyFieldValue(keyFieldExpression);
    }

    public void validateKeyFieldValue(Node expression) {
        if (expression.kind() != SyntaxKind.STRING_LITERAL) {
            addDiagnostic(CompilationDiagnostic.PROVIDE_A_STRING_LITERAL_OR_AN_ARRAY_OF_STRING_LITERALS_FOR_KEY_FIELD,
                          expression.location(), KEY);
        }
    }

    private void validateServiceObject(String modulePrefix) {
        ObjectConstructorExpressionNode objectConstructorExpNode = (ObjectConstructorExpressionNode) serviceNode;
        List<Node> serviceMethodNodes = getServiceMethodNodes(objectConstructorExpNode.members());
        if (!objectConstructorExpNode.annotations().isEmpty()) {
            validateAnnotation(objectConstructorExpNode, modulePrefix);
        }
        validateRootServiceMethods(serviceMethodNodes, objectConstructorExpNode.location());
        if (!this.hasQueryType) {
            addDiagnostic(CompilationDiagnostic.MISSING_RESOURCE_FUNCTIONS, objectConstructorExpNode.location());
        }
        validateEntitiesResolverReturnTypes();
    }

    private void validateServiceDeclaration(String modulePrefix) {
        ServiceDeclarationNode node = (ServiceDeclarationNode) serviceNode;
        // No need to check isEmpty(), already validated in ServiceDeclarationAnalysisTask
        // noinspection OptionalGetWithoutIsPresent
        ServiceDeclarationSymbol serviceDeclarationSymbol = (ServiceDeclarationSymbol) context.semanticModel()
                .symbol(node).get();
        if (serviceDeclarationSymbol.listenerTypes().size() > 1) {
            addDiagnostic(CompilationDiagnostic.INVALID_MULTIPLE_LISTENERS, node.location());
        }
        validateService(modulePrefix);
    }

    public boolean isErrorOccurred() {
        return this.errorOccurred;
    }

    public CacheConfigContext getCacheConfigContext() {
        return this.cacheConfigContext;
    }

    private void validateService(String modulePrefix) {
        ServiceDeclarationNode serviceDeclarationNode = (ServiceDeclarationNode) this.context.node();
        List<Node> serviceMethodNodes = getServiceMethodNodes(serviceDeclarationNode.members());
        if (serviceDeclarationNode.metadata().isPresent()) {
            validateAnnotation(serviceDeclarationNode.metadata().get(), modulePrefix);
        }
        validateRootServiceMethods(serviceMethodNodes, serviceDeclarationNode.location());
        if (!this.hasQueryType) {
            addDiagnostic(CompilationDiagnostic.MISSING_RESOURCE_FUNCTIONS, serviceDeclarationNode.location());
        }
        validateEntitiesResolverReturnTypes();
    }

    private void validateAnnotation(MetadataNode metadataNode, String modulePrefix) {
        for (AnnotationNode annotationNode : metadataNode.annotations()) {
            if (isGraphqlServiceConfig(annotationNode, modulePrefix)) {
                validateServiceAnnotation(annotationNode);
            }
        }
    }

    private void validateAnnotation(ObjectConstructorExpressionNode node, String modulePrefix) {
        for (AnnotationNode annotationNode : node.annotations()) {
            if (isGraphqlServiceConfig(annotationNode, modulePrefix)) {
                validateServiceAnnotation(annotationNode);
            }
        }
    }

    private void validateServiceAnnotation(AnnotationNode annotationNode) {
        if (annotationNode.annotValue().isPresent()) {
            for (MappingFieldNode field : annotationNode.annotValue().get().fields()) {
                validateServiceAnnotationField(field);
            }
        }
    }

    private void validateServiceAnnotationField(MappingFieldNode field) {
        if (field.kind() == SPECIFIC_FIELD) {
            SpecificFieldNode specificFieldNode = (SpecificFieldNode) field;
            Node fieldName = specificFieldNode.fieldName();
            if (fieldName.kind() == SyntaxKind.IDENTIFIER_TOKEN) {
                IdentifierToken identifierToken = (IdentifierToken) fieldName;
                String identifierName = identifierToken.text();
                if (SCHEMA_STRING_FIELD.equals(identifierName) || FIELD_CACHE_CONFIG_FIELD.equals(identifierName)) {
                    addDiagnostic(CompilationDiagnostic.INVALID_MODIFICATION_OF_SERVICE_CONFIG_FIELD,
                            serviceNode.location(), identifierName);
                }
            }
        }
    }

    private List<Node> getServiceMethodNodes(NodeList<Node> serviceMembers) {
        return serviceMembers.stream().filter(this::isServiceMethod).collect(Collectors.toList());
    }

    private boolean isServiceMethod(Node node) {
        if (this.context.semanticModel().symbol(node).isEmpty()) {
            return false;
        }
        Symbol symbol = this.context.semanticModel().symbol(node).get();
        return symbol.kind() == SymbolKind.RESOURCE_METHOD || symbol.kind() == SymbolKind.METHOD;
    }

    private void validateRootServiceMethods(List<Node> serviceMethods, Location location) {
        List<MethodSymbol> methodSymbols = getMethodSymbols(serviceMethods);
        for (Node methodNode : serviceMethods) {
            // No need to check fo isEmpty(), already validated in getRemoteOrResourceMethodSymbols
            // noinspection OptionalGetWithoutIsPresent
            MethodSymbol methodSymbol = (MethodSymbol) this.context.semanticModel().symbol(methodNode).get();
            Location methodLocation = methodNode.location();

            if (isRemoteMethod(methodSymbol)) {
                this.currentFieldPath.add(TypeName.MUTATION.getName());
                validateRemoteMethod(methodSymbol, methodLocation);
                this.currentFieldPath.remove(TypeName.MUTATION.getName());
                validatePrefetchMethodMapping(methodSymbol, methodSymbols, location);
            } else if (isResourceMethod(methodSymbol)) {
                validateRootServiceResourceMethod((ResourceMethodSymbol) methodSymbol, methodLocation);
                validatePrefetchMethodMapping(methodSymbol, methodSymbols, location);
            }
        }
    }

    private void validatePrefetchMethodMapping(MethodSymbol methodSymbol, List<MethodSymbol> serviceMethods,
                                               Location location) {
        String graphqlFieldName = getGraphqlFieldName(methodSymbol);
        String prefetchMethodName = getDefaultPrefetchMethodName(graphqlFieldName);
        Location methodLocation = getLocation(methodSymbol, location);
        boolean hasPrefetchMethodConfig = false;

        if (hasResourceConfigAnnotation(methodSymbol)) {
            FinderContext finderContext = new FinderContext(this.context);
            ResourceConfigAnnotationFinder resourceConfigAnnotationFinder = new ResourceConfigAnnotationFinder(
                    finderContext, methodSymbol);
            Optional<AnnotationNode> annotation = resourceConfigAnnotationFinder.find();
            hasPrefetchMethodConfig = annotation.isPresent() && hasPrefetchMethodNameConfig(annotation.get());
            if (hasPrefetchMethodConfig) {
                prefetchMethodName = getPrefetchMethodName(annotation.get());
                if (prefetchMethodName == null) {
                    addDiagnostic(CompilationDiagnostic.UNABLE_TO_VALIDATE_PREFETCH_METHOD, annotation.get().location(),
                                  PREFETCH_METHOD_NAME_CONFIG, graphqlFieldName);
                    return;
                }
                if (isSubscription(methodSymbol)) {
                    addDiagnostic(CompilationDiagnostic.INVALID_USAGE_OF_PREFETCH_METHOD_NAME_CONFIG,
                                  annotation.get().location(), PREFETCH_METHOD_NAME_CONFIG, graphqlFieldName);
                    return;
                }
            }
        }
        if (isSubscription(methodSymbol)) {
            return;
        }
        MethodSymbol prefetchMethod = findPrefetchMethod(prefetchMethodName, serviceMethods);
        if (prefetchMethod == null) {
            if (hasPrefetchMethodConfig) {
                addDiagnostic(CompilationDiagnostic.UNABLE_TO_FIND_PREFETCH_METHOD, methodLocation, prefetchMethodName,
                              graphqlFieldName);
            }
            return;
        }
        validatePrefetchMethodSignature(prefetchMethod, methodSymbol, location);
    }

    private boolean isSubscription(MethodSymbol methodSymbol) {
        return isResourceMethod(methodSymbol) && RESOURCE_FUNCTION_SUBSCRIBE.equals(
                getAccessor((ResourceMethodSymbol) methodSymbol));
    }

    private String getGraphqlFieldName(MethodSymbol methodSymbol) {
        return isResourceMethod(methodSymbol) ? getFieldPath((ResourceMethodSymbol) methodSymbol) :
                methodSymbol.getName().orElse("");
    }

    private String getPrefetchMethodName(AnnotationNode annotation) {
        // noinspection OptionalGetWithoutIsPresent
        MappingConstructorExpressionNode mappingConstructorExpressionNode = annotation.annotValue().get();
        for (MappingFieldNode field : mappingConstructorExpressionNode.fields()) {
            if (field.kind() == SPECIFIC_FIELD) {
                SpecificFieldNode specificFieldNode = (SpecificFieldNode) field;
                Node fieldName = specificFieldNode.fieldName();
                if (fieldName.kind() == SyntaxKind.IDENTIFIER_TOKEN) {
                    IdentifierToken identifierToken = (IdentifierToken) fieldName;
                    String identifierName = identifierToken.text();
                    if (PREFETCH_METHOD_NAME_CONFIG.equals(identifierName)) {
                        return getStringValue(specificFieldNode);
                    }
                }
            }
        }
        return null;
    }

    private void updateCacheConfigContextFromAnnot(AnnotationNode annotation) {
        // noinspection OptionalGetWithoutIsPresent
        MappingConstructorExpressionNode mappingConstructorExpressionNode = annotation.annotValue().get();
        for (MappingFieldNode field : mappingConstructorExpressionNode.fields()) {
            if (field.kind() == SPECIFIC_FIELD) {
                SpecificFieldNode specificFieldNode = (SpecificFieldNode) field;
                Node fieldName = specificFieldNode.fieldName();
                if (fieldName.kind() == SyntaxKind.IDENTIFIER_TOKEN) {
                    IdentifierToken identifierToken = (IdentifierToken) fieldName;
                    String identifierName = identifierToken.text();
                    if (CACHE_CONFIG.equals(identifierName) && specificFieldNode.valueExpr().isPresent()) {
                        boolean enabled =
                                getBooleanValue((MappingConstructorExpressionNode) specificFieldNode.valueExpr().get());
                        if (enabled) {
                            int maxSize =
                                    getMaxSize((MappingConstructorExpressionNode) specificFieldNode.valueExpr().get());
                            this.cacheConfigContext.setEnabled(enabled);
                            this.cacheConfigContext.setMaxSize(maxSize);
                        }
                    }
                }
            }
        }
    }

    private boolean hasPrefetchMethodNameConfig(AnnotationNode annotation) {
        if (annotation.annotValue().isEmpty()) {
            return false;
        }
        MappingConstructorExpressionNode mappingConstructorExpressionNode = annotation.annotValue().get();
        for (MappingFieldNode field : mappingConstructorExpressionNode.fields()) {
            if (field.kind() == SPECIFIC_FIELD) {
                SpecificFieldNode specificFieldNode = (SpecificFieldNode) field;
                Node fieldName = specificFieldNode.fieldName();
                if (fieldName.kind() == SyntaxKind.IDENTIFIER_TOKEN) {
                    IdentifierToken identifierToken = (IdentifierToken) fieldName;
                    String identifierName = identifierToken.text();
                    return PREFETCH_METHOD_NAME_CONFIG.equals(identifierName);
                }
            }
        }
        return false;
    }

    private boolean hasCacheConfig(AnnotationNode annotation) {
        if (annotation.annotValue().isEmpty()) {
            return false;
        }
        MappingConstructorExpressionNode mappingConstructorExpressionNode = annotation.annotValue().get();
        for (MappingFieldNode field : mappingConstructorExpressionNode.fields()) {
            if (field.kind() == SPECIFIC_FIELD) {
                SpecificFieldNode specificFieldNode = (SpecificFieldNode) field;
                Node fieldName = specificFieldNode.fieldName();
                if (fieldName.kind() == SyntaxKind.IDENTIFIER_TOKEN) {
                    IdentifierToken identifierToken = (IdentifierToken) fieldName;
                    String identifierName = identifierToken.text();
                    if (CACHE_CONFIG.equals(identifierName)) {
                        return true;
                    }
                }
            }
        }
        return false;
    }

    private MethodSymbol findPrefetchMethod(String prefetchMethodName, List<MethodSymbol> serviceMethods) {
        return serviceMethods.stream()
                .filter(method -> method.kind() == SymbolKind.METHOD && !isRemoteMethod(method) && method.getName()
                        .orElse("").equals(prefetchMethodName)).findFirst().orElse(null);
    }

    private void validateEntitiesResolverReturnTypes() {
        if (!this.isSubgraph) {
            return;
        }
        this.currentFieldPath.add(TypeName.QUERY.getName());
        this.currentFieldPath.add(Schema.ENTITIES_RESOLVER_NAME);
        for (Symbol symbol : interfaceEntityFinder.getEntities().values()) {
            if (this.existingReturnTypes.contains(symbol)) {
                continue;
            }
            // noinspection OptionalGetWithoutIsPresent
            Location location = symbol.getLocation().get();
            if (symbol.kind() == SymbolKind.CLASS) {
                validateReturnTypeClass((ClassSymbol) symbol, location);
            } else if (symbol.kind() == SymbolKind.TYPE_DEFINITION) {
                RecordTypeSymbol recordTypeSymbol = (RecordTypeSymbol) ((TypeDefinitionSymbol) symbol).typeDescriptor();
                String recordName = symbol.getName().orElse(recordTypeSymbol.signature());
                validateReturnType(recordTypeSymbol, recordTypeSymbol, location, recordName);
            }
        }
        this.currentFieldPath.remove(Schema.ENTITIES_RESOLVER_NAME);
        this.currentFieldPath.remove(TypeName.QUERY.getName());
    }

    private void validateRootServiceResourceMethod(ResourceMethodSymbol methodSymbol, Location location) {
        String resourceMethodName = getFieldPath(methodSymbol);
        Location accessorLocation = getLocation(methodSymbol, location);
        if (isReservedFederatedResolverName(resourceMethodName)) {
            addDiagnostic(CompilationDiagnostic.INVALID_USE_OF_RESERVED_RESOURCE_PATH, accessorLocation,
                          resourceMethodName);
        }
        String accessor = getAccessor(methodSymbol);
        if (RESOURCE_FUNCTION_SUBSCRIBE.equals(accessor)) {
            this.currentFieldPath.add(TypeName.SUBSCRIPTION.getName());
            validateSubscribeResource(methodSymbol, location);
            this.currentFieldPath.remove(TypeName.SUBSCRIPTION.getName());
        } else if (RESOURCE_FUNCTION_GET.equals(accessor)) {
            this.currentFieldPath.add(TypeName.QUERY.getName());
            this.hasQueryType = true;
            validateGetResource(methodSymbol, location);
            this.currentFieldPath.remove(TypeName.QUERY.getName());
        } else {
            addDiagnostic(CompilationDiagnostic.INVALID_ROOT_RESOURCE_ACCESSOR, accessorLocation, accessor,
                          resourceMethodName);
        }
    }

    private List<MethodSymbol> getMethodSymbols(List<Node> serviceMembers) {
        return serviceMembers.stream().filter(this::isServiceMethod)
                .map(methodNode -> (MethodSymbol) this.context.semanticModel().symbol(methodNode).get())
                .collect(Collectors.toList());
    }

    private void validateResourceMethod(ResourceMethodSymbol methodSymbol, Location location) {
        String accessor = getAccessor(methodSymbol);
        if (!RESOURCE_FUNCTION_GET.equals(accessor)) {
            Location accessorLocation = getLocation(methodSymbol, location);
            addDiagnostic(CompilationDiagnostic.INVALID_RESOURCE_FUNCTION_ACCESSOR, accessorLocation, accessor,
                          getFieldPath(methodSymbol));
        }
        validateGetResource(methodSymbol, getLocation(methodSymbol, location));
    }

    private void validateGetResource(ResourceMethodSymbol methodSymbol, Location location) {
        String path = getFieldPath(methodSymbol);
        this.currentFieldPath.add(path);
        validateResourcePath(methodSymbol, location);
        validateMethod(methodSymbol, location);
        updateCacheConfigContext(methodSymbol);
        this.currentFieldPath.remove(path);
    }

    private void updateCacheConfigContext(MethodSymbol methodSymbol) {
        if (hasResourceConfigAnnotation(methodSymbol)) {
            FinderContext finderContext = new FinderContext(this.context);
            ResourceConfigAnnotationFinder resourceConfigAnnotationFinder = new ResourceConfigAnnotationFinder(
                    finderContext, methodSymbol);
            Optional<AnnotationNode> annotation = resourceConfigAnnotationFinder.find();
            if (annotation.isPresent() && hasCacheConfig(annotation.get())) {
                updateCacheConfigContextFromAnnot(annotation.get());
            }
        }
    }

    private void validateSubscribeResource(ResourceMethodSymbol methodSymbol, Location location) {
        ResourcePath resourcePath = methodSymbol.resourcePath();
        String resourcePathSignature = resourcePath.signature();
        if (resourcePath.kind() == ResourcePath.Kind.PATH_SEGMENT_LIST) {
            PathSegmentList pathSegmentList = (PathSegmentList) resourcePath;
            if (pathSegmentList.list().size() > 1) {
                addDiagnostic(CompilationDiagnostic.INVALID_HIERARCHICAL_RESOURCE_PATH, location,
                              resourcePathSignature);
            } else {
                validateResourcePathSegment(location, pathSegmentList.list().get(0));
            }
        } else if (resourcePath.kind() == ResourcePath.Kind.PATH_REST_PARAM) {
            addDiagnostic(CompilationDiagnostic.INVALID_PATH_PARAMETERS, location, resourcePathSignature);
        } else {
            addDiagnostic(CompilationDiagnostic.INVALID_RESOURCE_PATH, location, resourcePathSignature);
        }
        validateSubscriptionMethod(methodSymbol, location);
        validateInputParameters(methodSymbol, location);
    }

    private void validatePrefetchMethodSignature(MethodSymbol prefetchMethod, MethodSymbol resolverMethod,
                                                 Location location) {
        Location prefetchMethodLocation = getLocation(prefetchMethod, location);
        validatePrefetchMethodParams(prefetchMethod, prefetchMethodLocation, resolverMethod);
        validatePrefetchMethodReturnType(prefetchMethod, prefetchMethodLocation);
    }

    private void validatePrefetchMethodParams(MethodSymbol prefetchMethod, Location prefetchMethodLocation,
                                              MethodSymbol resolverMethod) {
        String prefetchMethodName = prefetchMethod.getName().orElse("");
        Set<String> fieldMethodParamSignatures = resolverMethod.typeDescriptor().params().isPresent() ?
                resolverMethod.typeDescriptor().params().get().stream().map(ParameterSymbol::signature)
                        .map(String::trim).collect(Collectors.toSet()) : new HashSet<>();
        List<ParameterSymbol> parameterSymbols = prefetchMethod.typeDescriptor().params().isPresent() ?
                prefetchMethod.typeDescriptor().params().get() : new ArrayList<>();
        boolean hasContextParam = false;
        for (ParameterSymbol symbol : parameterSymbols) {
            if (isContextParameter(symbol.typeDescriptor())) {
                hasContextParam = true;
            } else if (!fieldMethodParamSignatures.contains(symbol.signature().trim())) {
                addDiagnostic(CompilationDiagnostic.INVALID_PARAMETER_IN_PREFETCH_METHOD, prefetchMethodLocation,
                              symbol.signature(), prefetchMethodName,
                              isResourceMethod(resolverMethod) ? getFieldPath((ResourceMethodSymbol) resolverMethod) :
                                      resolverMethod.getName().orElse(resolverMethod.signature()));
            }
        }
        if (!hasContextParam) {
            addDiagnostic(CompilationDiagnostic.MISSING_GRAPHQL_CONTEXT_PARAMETER, prefetchMethodLocation,
                          prefetchMethod.getName().orElse(prefetchMethod.signature()));
        }
    }

    private void validatePrefetchMethodReturnType(MethodSymbol prefetchMethod, Location prefetchMethodLocation) {
        if (prefetchMethod.typeDescriptor().returnTypeDescriptor().isPresent()) {
            TypeSymbol returnType = prefetchMethod.typeDescriptor().returnTypeDescriptor().get();
            if (returnType.typeKind() == TypeDescKind.NIL) {
                return;
            }
            addDiagnostic(CompilationDiagnostic.INVALID_RETURN_TYPE_IN_PREFETCH_METHOD,
                          getLocation(returnType, prefetchMethodLocation), returnType.signature(),
                          prefetchMethod.getName().orElse(""));
        }
    }

    private void validateSubscriptionMethod(ResourceMethodSymbol methodSymbol, Location location) {
        if (methodSymbol.typeDescriptor().returnTypeDescriptor().isEmpty()) {
            return;
        }
        TypeSymbol returnTypeSymbol = methodSymbol.typeDescriptor().returnTypeDescriptor().get();
        String returnTypeName = returnTypeSymbol.getName().orElse(returnTypeSymbol.signature());
        String resourceMethodName = getFieldPath(methodSymbol);
        if (returnTypeSymbol.typeKind() == TypeDescKind.UNION) {
            List<TypeSymbol> effectiveTypes = getEffectiveTypes((UnionTypeSymbol) returnTypeSymbol);
            if (effectiveTypes.size() != 1) {
                addDiagnostic(CompilationDiagnostic.INVALID_SUBSCRIBE_RESOURCE_RETURN_TYPE, location, returnTypeName,
                              resourceMethodName);
                return;
            } else {
                returnTypeSymbol = effectiveTypes.get(0);
            }
        }

        if (returnTypeSymbol.typeKind() != TypeDescKind.STREAM) {
            addDiagnostic(CompilationDiagnostic.INVALID_SUBSCRIBE_RESOURCE_RETURN_TYPE, location, returnTypeName,
                          resourceMethodName);
        } else {
            String path = getFieldPath(methodSymbol);
            this.currentFieldPath.add(path);
            StreamTypeSymbol typeSymbol = (StreamTypeSymbol) returnTypeSymbol;
            validateReturnType(typeSymbol.typeParameter(), location);
            this.currentFieldPath.remove(path);
        }
    }

    private void validateRemoteMethod(MethodSymbol methodSymbol, Location location) {
        if (methodSymbol.getName().isEmpty()) {
            return;
        }
        String fieldName = methodSymbol.getName().get();
        this.currentFieldPath.add(fieldName);
        if (isInvalidFieldName(fieldName)) {
            addDiagnostic(CompilationDiagnostic.INVALID_FIELD_NAME, location, getCurrentFieldPath(), fieldName);
        } else if (isReservedFederatedResolverName(fieldName)) {
            Location methodLocation = getLocation(methodSymbol, location);
            addDiagnostic(CompilationDiagnostic.INVALID_USE_OF_RESERVED_REMOTE_METHOD_NAME, methodLocation, fieldName);
        }
        validateMethod(methodSymbol, location);
        this.currentFieldPath.remove(fieldName);
    }

    private void validateMethod(MethodSymbol methodSymbol, Location location) {
        if (methodSymbol.typeDescriptor().returnTypeDescriptor().isPresent()) {
            TypeSymbol returnTypeSymbol = methodSymbol.typeDescriptor().returnTypeDescriptor().get();
            validateReturnType(returnTypeSymbol, location);
        }
        validateInputParameters(methodSymbol, location);
    }

    private void validateResourcePath(ResourceMethodSymbol resourceMethodSymbol, Location location) {
        ResourcePath resourcePath = resourceMethodSymbol.resourcePath();
        String resourcePathSignature = resourcePath.signature();
        if (resourcePath.kind() == ResourcePath.Kind.PATH_SEGMENT_LIST) {
            PathSegmentList pathSegmentList = (PathSegmentList) resourcePath;
            for (PathSegment pathSegment : pathSegmentList.list()) {
                validateResourcePathSegment(location, pathSegment);
            }
        } else if (resourcePath.kind() == ResourcePath.Kind.PATH_REST_PARAM) {
            addDiagnostic(CompilationDiagnostic.INVALID_PATH_PARAMETERS, location, resourcePathSignature);
        } else {
            addDiagnostic(CompilationDiagnostic.INVALID_RESOURCE_PATH, location, resourcePathSignature);
        }
    }

    private void validateResourcePathSegment(Location location, PathSegment pathSegment) {
        if (pathSegment.pathSegmentKind() == PathSegment.Kind.NAMED_SEGMENT) {
            String fieldName = pathSegment.signature();
            if (isInvalidFieldName(fieldName)) {
                addDiagnostic(CompilationDiagnostic.INVALID_FIELD_NAME, location, getCurrentFieldPath(), fieldName);
            }
        } else {
            String pathWithParameters = pathSegment.signature();
            addDiagnostic(CompilationDiagnostic.INVALID_PATH_PARAMETERS, location, pathWithParameters);
        }
    }

    private void validateReturnType(TypeSymbol typeSymbol, Location location) {
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
                break;
            case ANY:
            case ANYDATA:
                addDiagnostic(CompilationDiagnostic.INVALID_RETURN_TYPE_ANY, location, getCurrentFieldPath());
                break;
            case UNION:
                validateReturnTypeUnion((UnionTypeSymbol) typeSymbol, location);
                break;
            case ARRAY:
                validateReturnType(((ArrayTypeSymbol) typeSymbol).memberTypeDescriptor(), location);
                break;
            case TYPE_REFERENCE:
                validateReturnTypeReference((TypeReferenceTypeSymbol) typeSymbol, location);
                break;
            case TABLE:
                validateReturnType(((TableTypeSymbol) typeSymbol).rowTypeParameter(), location);
                break;
            case INTERSECTION:
                validateReturnType((IntersectionTypeSymbol) typeSymbol, location);
                break;
            case NIL:
                addDiagnostic(CompilationDiagnostic.INVALID_RETURN_TYPE_NIL, location, getCurrentFieldPath());
                break;
            case ERROR:
                addDiagnostic(CompilationDiagnostic.INVALID_RETURN_TYPE_ERROR, location, getCurrentFieldPath());
                break;
            case RECORD:
                addDiagnostic(CompilationDiagnostic.INVALID_ANONYMOUS_FIELD_TYPE, location, typeSymbol.signature(),
                              getCurrentFieldPath());
                break;
            case OBJECT:
                addDiagnostic(CompilationDiagnostic.INVALID_RETURN_TYPE, location, typeSymbol.signature(),
                              getCurrentFieldPath());
                break;
            default:
                addDiagnostic(CompilationDiagnostic.INVALID_RETURN_TYPE, location,
                              typeSymbol.getName().orElse(typeSymbol.typeKind().getName()), getCurrentFieldPath());
        }
    }

    private void validateReturnTypeReference(TypeReferenceTypeSymbol typeReferenceTypeSymbol, Location location) {
        SymbolKind symbolKind = typeReferenceTypeSymbol.definition().kind();
        if (symbolKind == SymbolKind.TYPE_DEFINITION) {
            validateReturnTypeDefinition(typeReferenceTypeSymbol, location);
        } else if (symbolKind == SymbolKind.CLASS) {
            ClassSymbol classSymbol = (ClassSymbol) typeReferenceTypeSymbol.definition();
            validateReturnTypeClass(classSymbol, location);
        } else if (symbolKind == SymbolKind.ENUM) {
            validateEnumReturnType((EnumSymbol) typeReferenceTypeSymbol.definition(), location);
        }
    }

    private void validateEnumReturnType(EnumSymbol enumSymbol, Location location) {
        // noinspection OptionalGetWithoutIsPresent
        String enumName = enumSymbol.getName().get();
        Location enumLocation = getLocation(enumSymbol, location);
        if (isReservedFederatedTypeName(enumName)) {
            addDiagnostic(CompilationDiagnostic.INVALID_USE_OF_RESERVED_TYPE_AS_OUTPUT_TYPE, enumLocation,
                          getCurrentFieldPath(), enumName);
        }
    }

    private void validateReturnType(IntersectionTypeSymbol typeSymbol, Location location) {
        TypeSymbol effectiveType = getEffectiveType(typeSymbol);
        if (effectiveType.typeKind() == TypeDescKind.RECORD) {
            validateRecordFields((RecordTypeSymbol) effectiveType, location);
        } else {
            validateReturnType(effectiveType, location);
        }
    }

    private void validateReturnTypeClass(ClassSymbol classSymbol, Location location) {
        if (classSymbol.getName().isEmpty()) {
            return;
        }
        Location classSymbolLocation = getLocation(classSymbol, location);
        if (isServiceClass(classSymbol)) {
            validateServiceClassDefinition(classSymbol, classSymbolLocation);
        } else {
            addDiagnostic(CompilationDiagnostic.INVALID_RETURN_TYPE_CLASS, classSymbolLocation,
                          classSymbol.getName().get(), getCurrentFieldPath());
        }
    }

    private void validateReturnTypeDefinition(TypeReferenceTypeSymbol typeReferenceTypeSymbol, Location location) {
        TypeDefinitionSymbol typeDefinitionSymbol = (TypeDefinitionSymbol) typeReferenceTypeSymbol.definition();
        if (typeReferenceTypeSymbol.typeDescriptor().typeKind() == TypeDescKind.RECORD) {
            RecordTypeSymbol recordTypeSymbol = (RecordTypeSymbol) typeDefinitionSymbol.typeDescriptor();
            String recordName = typeDefinitionSymbol.getName().orElse(recordTypeSymbol.signature());
            validateReturnType(recordTypeSymbol, typeReferenceTypeSymbol.typeDescriptor(), location, recordName);
        } else if (typeReferenceTypeSymbol.typeDescriptor().typeKind() == TypeDescKind.OBJECT) {
            validateReturnTypeObject(typeDefinitionSymbol, location);
        } else if (typeReferenceTypeSymbol.typeDescriptor().typeKind() == TypeDescKind.TYPE_REFERENCE) {
            addDiagnostic(CompilationDiagnostic.UNSUPPORTED_TYPE_ALIAS,
                    getLocation(typeReferenceTypeSymbol, location), typeReferenceTypeSymbol.getName().get(),
                    typeReferenceTypeSymbol.typeDescriptor().getName().get());
        } else if (isPrimitiveTypeSymbol(typeReferenceTypeSymbol.typeDescriptor())) {
            // noinspection OptionalGetWithoutIsPresent
            addDiagnostic(CompilationDiagnostic.UNSUPPORTED_TYPE_ALIAS,
                          getLocation(typeReferenceTypeSymbol, location), typeReferenceTypeSymbol.getName().get(),
                                      typeReferenceTypeSymbol.typeDescriptor().typeKind().getName());
        } else if (typeDefinitionSymbol.getModule().isPresent()
                && Utils.isValidUuidModule(typeDefinitionSymbol.getModule().get())
                && typeDefinitionSymbol.getName().isPresent()
                && typeDefinitionSymbol.getName().get().equals(Utils.UUID_RECORD_NAME)) {
            return;
        } else {
            validateReturnType(typeReferenceTypeSymbol.typeDescriptor(), location);
        }
    }

    private void validateReturnTypeObject(TypeDefinitionSymbol typeDefinitionSymbol, Location location) {
        if (typeDefinitionSymbol.getName().isEmpty()) {
            ObjectTypeSymbol objectTypeSymbol = (ObjectTypeSymbol) typeDefinitionSymbol.typeDescriptor();
            addDiagnostic(CompilationDiagnostic.INVALID_RETURN_TYPE, location, objectTypeSymbol.signature(),
                          getCurrentFieldPath());
            return;
        }

        String objectTypeName = typeDefinitionSymbol.getName().get();
        if (isReservedFederatedTypeName(objectTypeName)) {
            addDiagnostic(CompilationDiagnostic.INVALID_USE_OF_RESERVED_TYPE_AS_OUTPUT_TYPE, location,
                          getCurrentFieldPath(), objectTypeName);
        }
        if (!this.interfaceEntityFinder.isPossibleInterface(objectTypeName)) {
            addDiagnostic(CompilationDiagnostic.INVALID_RETURN_TYPE, location, objectTypeName, getCurrentFieldPath());
            return;
        }
        validateInterfaceObjectTypeDefinition(typeDefinitionSymbol, location);
        validateInterfaceImplementation(objectTypeName, location);
    }

    private void validateInterfaceObjectTypeDefinition(TypeDefinitionSymbol typeDefinitionSymbol, Location location) {
        if (this.visitedClassesAndObjectTypeDefinitions.contains(typeDefinitionSymbol)) {
            return;
        }
        this.visitedClassesAndObjectTypeDefinitions.add(typeDefinitionSymbol);
        boolean resourceMethodFound = false;
        ObjectTypeSymbol objectTypeSymbol = (ObjectTypeSymbol) typeDefinitionSymbol.typeDescriptor();
        if (!objectTypeSymbol.qualifiers().contains(Qualifier.DISTINCT)) {
            String typeName = typeDefinitionSymbol.getName().orElse("$anonymous");
            addDiagnostic(CompilationDiagnostic.NON_DISTINCT_INTERFACE, location, typeName);
        }
        List<MethodSymbol> methodSymbols = new ArrayList<>(objectTypeSymbol.methods().values());
        for (MethodSymbol methodSymbol : methodSymbols) {
            if (methodSymbol.kind() == SymbolKind.RESOURCE_METHOD) {
                resourceMethodFound = true;
                validateResourceMethod((ResourceMethodSymbol) methodSymbol, location);
            } else if (isRemoteMethod(methodSymbol)) {
                // noinspection OptionalGetWithoutIsPresent
                String interfaceName = typeDefinitionSymbol.getName().get();
                String remoteMethodName = methodSymbol.getName().orElse(methodSymbol.signature());
                addDiagnostic(CompilationDiagnostic.INVALID_FUNCTION, getLocation(methodSymbol, location),
                              interfaceName, remoteMethodName);
            }
            validatePrefetchMethodMapping(methodSymbol, methodSymbols, location);
        }
        if (!resourceMethodFound) {
            addDiagnostic(CompilationDiagnostic.MISSING_RESOURCE_FUNCTIONS, location);
        }
    }

    private void validateInterfaceImplementation(String interfaceName, Location location) {
        for (Symbol implementation : this.interfaceEntityFinder.getImplementations(interfaceName)) {
            if (implementation.getName().isEmpty()) {
                continue;
            }
            if (implementation.kind() == SymbolKind.CLASS) {
                if (!isDistinctServiceClass(implementation)) {
                    String implementationName = implementation.getName().get();
                    Location implementationLocation = getLocation(implementation, location);
                    addDiagnostic(CompilationDiagnostic.NON_DISTINCT_INTERFACE_IMPLEMENTATION, implementationLocation,
                                  implementationName);
                    continue;
                }
                validateReturnTypeClass((ClassSymbol) implementation, location);
            } else if (implementation.kind() == SymbolKind.TYPE_DEFINITION) {
                validateReturnTypeObject((TypeDefinitionSymbol) implementation, location);
            }
        }
    }

    private void validateReturnType(RecordTypeSymbol recordTypeSymbol, TypeSymbol descriptor, Location location,
                                    String recordTypeName) {
        if (this.existingReturnTypes.contains(descriptor)) {
            return;
        }
        if (isReservedFederatedTypeName(recordTypeName)) {
            addDiagnostic(CompilationDiagnostic.INVALID_USE_OF_RESERVED_TYPE_AS_OUTPUT_TYPE, location,
                          getCurrentFieldPath(), recordTypeName);
            return;
        }
        if (this.existingInputObjectTypes.contains(descriptor)) {
            addDiagnostic(CompilationDiagnostic.INVALID_RETURN_TYPE_INPUT_OBJECT, location, getCurrentFieldPath(),
                          recordTypeName);
            return;
        }
        if (recordTypeSymbol.fieldDescriptors().isEmpty()) {
            addDiagnostic(CompilationDiagnostic.INVALID_EMPTY_RECORD_OBJECT_TYPE, location, recordTypeName,
                          getCurrentFieldPath());
            return;
        }
        this.existingReturnTypes.add(descriptor);
        validateRecordFields(recordTypeSymbol, location);
    }

    private void validateInputParameters(MethodSymbol methodSymbol, Location location) {
        FunctionTypeSymbol functionTypeSymbol = methodSymbol.typeDescriptor();
        if (functionTypeSymbol.params().isPresent()) {
            List<ParameterSymbol> parameterSymbols = functionTypeSymbol.params().get();
            for (ParameterSymbol parameter : parameterSymbols) {
                Location inputLocation = getLocation(parameter, location);
                if (isValidGraphqlParameter(parameter.typeDescriptor())) {
                    continue;
                }
                if (parameter.annotations().isEmpty()) {
                    validateInputParameterType(parameter.typeDescriptor(), inputLocation,
                                               isResourceMethod(methodSymbol));
                }
                if (parameter.paramKind() == ParameterKind.DEFAULTABLE) {
                    validateDefaultParameter(parameter, methodSymbol, inputLocation);
                }
            }
        }
    }

    private void validateDefaultParameter(ParameterSymbol parameter, MethodSymbol methodSymbol,
                                          Location parameterLocation) {
        // noinspection OptionalGetWithoutIsPresent
        String parameterName = parameter.getName().get();
        FinderContext finderContext = new FinderContext(this.context);
        DefaultableParameterNode parameterNode = getDefaultableParameterNode(methodSymbol, parameter, finderContext);
        if (parameterNode == null) {
            addDiagnostic(CompilationDiagnostic.UNABLE_TO_INFER_DEFAULT_VALUE_AT_COMPILE_TIME, parameterLocation,
                          getFieldOrParamString(false), parameterName);
            return;
        }
        validateDefaultValueExpression(parameterNode.expression(), parameterName, false);
    }

    private String getFieldOrParamString(boolean isObjectField) {
        return isObjectField ? INPUT_OBJECT_FIELD : PARAMETER;
    }

    private void validateDefaultValueExpression(Node valueExpression, String fieldOrParamName, boolean isObjectField) {
        switch (valueExpression.kind()) {
            case NIL_LITERAL:
            case NUMERIC_LITERAL:
            case STRING_LITERAL:
            case BOOLEAN_LITERAL:
                return;
            case SIMPLE_NAME_REFERENCE: {
                validateDefaultValueExpression((SimpleNameReferenceNode) valueExpression, fieldOrParamName,
                                               isObjectField);
                return;
            }

            case MAPPING_CONSTRUCTOR: {
                validateDefaultValueExpression((MappingConstructorExpressionNode) valueExpression, fieldOrParamName,
                                               isObjectField);
                return;
            }
            case LIST_CONSTRUCTOR: {
                validateDefaultValueExpression((ListConstructorExpressionNode) valueExpression, fieldOrParamName,
                                               isObjectField);
                return;
            }
            default:
                addDiagnostic(CompilationDiagnostic.PROVIDE_LITERAL_OR_CONSTRUCTOR_EXPRESSION_FOR_DEFAULT_PARAM,
                              valueExpression.location(), getFieldOrParamString(isObjectField), fieldOrParamName);
        }
    }

    private void validateDefaultValueExpression(SimpleNameReferenceNode nameReferenceNode, String parameterOrFieldName,
                                                boolean isObjectField) {
        Optional<Symbol> symbol = this.context.semanticModel().symbol(nameReferenceNode);
        if (symbol.isEmpty()) {
            addDiagnostic(CompilationDiagnostic.UNABLE_TO_INFER_DEFAULT_VALUE_AT_COMPILE_TIME,
                          nameReferenceNode.location(), getFieldOrParamString(isObjectField), parameterOrFieldName);
            return;
        }
        if (symbol.get().kind() != SymbolKind.CONSTANT && symbol.get().kind() != SymbolKind.ENUM_MEMBER) {
            addDiagnostic(CompilationDiagnostic.PROVIDE_LITERAL_OR_CONSTRUCTOR_EXPRESSION_FOR_DEFAULT_PARAM,
                          nameReferenceNode.location(), getFieldOrParamString(isObjectField), parameterOrFieldName);
        }
    }

    private void validateDefaultValueExpression(MappingConstructorExpressionNode mappingConstructor,
                                                String parameterOrFieldName, boolean isObjectField) {
        for (MappingFieldNode field : mappingConstructor.fields()) {
            if (field.kind() != SyntaxKind.SPECIFIC_FIELD) {
                addDiagnostic(CompilationDiagnostic.UNABLE_TO_INFER_DEFAULT_VALUE_PROVIDE_KEY_VALUE_PAIR,
                              field.location(), getFieldOrParamString(isObjectField), parameterOrFieldName);
                continue;
            }
            SpecificFieldNode specificFieldNode = (SpecificFieldNode) field;
            if (specificFieldNode.valueExpr().isPresent()) {
                validateDefaultValueExpression(specificFieldNode.valueExpr().get(), parameterOrFieldName,
                                               isObjectField);
            } else {
                addDiagnostic(CompilationDiagnostic.UNABLE_TO_INFER_DEFAULT_VALUE_PROVIDE_KEY_VALUE_PAIR,
                              field.location(), getFieldOrParamString(isObjectField), parameterOrFieldName);
            }
        }
    }

    private void validateDefaultValueExpression(ListConstructorExpressionNode listConstructor,
                                                String parameterOrFieldName, boolean isObjectField) {
        for (Node member : listConstructor.expressions()) {
            if (member.kind() == SPREAD_MEMBER) {
                addDiagnostic(CompilationDiagnostic.UNABLE_TO_INFER_DEFAULT_VALUE_AVOID_USING_SPREAD_OPERATION,
                              member.location(), getFieldOrParamString(isObjectField), parameterOrFieldName);
                continue;
            }
            validateDefaultValueExpression(member, parameterOrFieldName, isObjectField);
        }
    }

    private String getDefaultPrefetchMethodName(String graphqlFieldName) {
        return PREFETCH_METHOD_PREFIX + uppercaseFirstChar(graphqlFieldName);
    }

    private String uppercaseFirstChar(String string) {
        if (string == null || string.length() == 0) {
            return string;
        }
        char[] chars = string.toCharArray();
        chars[0] = Character.toUpperCase(chars[0]);
        return new String(chars);
    }

    private void validateInputParameterType(TypeSymbol typeSymbol, Location location, boolean isResourceMethod) {
        if (isFileUploadParameter(typeSymbol)) {
            String methodName = currentFieldPath.get(currentFieldPath.size() - 1);
            if (this.arrayDimension > 1) {
                addDiagnostic(CompilationDiagnostic.MULTI_DIMENSIONAL_UPLOAD_ARRAY, location, methodName);
            }
            if (isResourceMethod) {
                addDiagnostic(CompilationDiagnostic.INVALID_FILE_UPLOAD_IN_RESOURCE_FUNCTION, location, methodName);
            }
        } else {
            validateInputType(typeSymbol, location, isResourceMethod);
        }
    }

    private void validateInputType(TypeSymbol typeSymbol, Location location, boolean isResourceMethod) {
        setRootInputParameterTypeSymbol(typeSymbol);
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
                break;
            case TYPE_REFERENCE:
                validateInputParameterType((TypeReferenceTypeSymbol) typeSymbol, location, isResourceMethod);
                break;
            case UNION:
                validateInputParameterType((UnionTypeSymbol) typeSymbol, location, isResourceMethod);
                break;
            case ARRAY:
                validateInputParameterType((ArrayTypeSymbol) typeSymbol, location, isResourceMethod);
                break;
            case INTERSECTION:
                validateInputParameterType((IntersectionTypeSymbol) typeSymbol, location, isResourceMethod);
                break;
            case RECORD:
                addDiagnostic(CompilationDiagnostic.INVALID_ANONYMOUS_INPUT_TYPE, location, typeSymbol.signature(),
                              getCurrentFieldPath());
                break;
            default:
                addDiagnostic(CompilationDiagnostic.INVALID_INPUT_PARAMETER_TYPE, location,
                              rootInputParameterTypeSymbol.signature(), getCurrentFieldPath());
        }
        if (isRootInputParameterTypeSymbol(typeSymbol)) {
            resetRootInputParameterTypeSymbol();
        }
    }

    private void setRootInputParameterTypeSymbol(TypeSymbol typeSymbol) {
        if (rootInputParameterTypeSymbol == null) {
            rootInputParameterTypeSymbol = typeSymbol;
        }
    }

    private void resetRootInputParameterTypeSymbol() {
        rootInputParameterTypeSymbol = null;
    }

    private boolean isRootInputParameterTypeSymbol(TypeSymbol typeSymbol) {
        return rootInputParameterTypeSymbol == typeSymbol;
    }

    private void validateInputParameterType(ArrayTypeSymbol arrayTypeSymbol, Location location,
                                            boolean isResourceMethod) {
        this.arrayDimension++;
        TypeSymbol memberTypeSymbol = arrayTypeSymbol.memberTypeDescriptor();
        validateInputParameterType(memberTypeSymbol, location, isResourceMethod);
        this.arrayDimension--;
    }

    private void validateInputParameterType(TypeReferenceTypeSymbol typeSymbol, Location location,
                                            boolean isResourceMethod) {
        TypeSymbol typeDescriptor = typeSymbol.typeDescriptor();
        Symbol typeDefinition = typeSymbol.definition();
        // noinspection OptionalGetWithoutIsPresent
        String typeName = typeDefinition.getName().get();
        if (typeDefinition.kind() == SymbolKind.ENUM) {
            if (isReservedFederatedTypeName(typeName)) {
                addDiagnostic(CompilationDiagnostic.INVALID_USE_OF_RESERVED_TYPE_AS_INPUT_TYPE, location, typeName);
            }
        } else if (typeDefinition.kind() == SymbolKind.TYPE_DEFINITION &&
                typeDescriptor.typeKind() == TypeDescKind.RECORD) {
            validateInputParameterType((RecordTypeSymbol) typeDescriptor, location, typeName, isResourceMethod);
        } else if (typeDescriptor.typeKind() == TypeDescKind.TYPE_REFERENCE) {
            addDiagnostic(CompilationDiagnostic.UNSUPPORTED_TYPE_ALIAS, getLocation(typeSymbol, location),
                    typeSymbol.getName().get(), typeDescriptor.getName().get());
        } else if (isPrimitiveTypeSymbol(typeDescriptor)) {
            // noinspection OptionalGetWithoutIsPresent
            addDiagnostic(CompilationDiagnostic.UNSUPPORTED_TYPE_ALIAS, getLocation(typeSymbol, location),
                          typeSymbol.getName().get(), typeDescriptor.typeKind().getName());
        } else {
            validateInputParameterType(typeDescriptor, location, isResourceMethod);
        }
    }

    private void validateInputParameterType(UnionTypeSymbol unionTypeSymbol, Location location,
                                            boolean isResourceMethod) {
        boolean foundDataType = false;
        int dataTypeCount = 0;
        for (TypeSymbol memberType : unionTypeSymbol.userSpecifiedMemberTypes()) {
            if (memberType.typeKind() == TypeDescKind.ERROR) {
                addDiagnostic(CompilationDiagnostic.INVALID_INPUT_PARAMETER_TYPE, location,
                              TypeDescKind.ERROR.getName(), this.getCurrentFieldPath());
            } else if (memberType.typeKind() != TypeDescKind.NIL) {
                foundDataType = true;
                dataTypeCount++;
                if (memberType.typeKind() != TypeDescKind.SINGLETON) {
                    validateInputParameterType(memberType, location, isResourceMethod);
                }
            }
        }
        if (!foundDataType) {
            addDiagnostic(CompilationDiagnostic.INVALID_INPUT_TYPE, location);
        } else if (dataTypeCount > 1) {
            addDiagnostic(CompilationDiagnostic.INVALID_INPUT_TYPE_UNION, location);
        }
    }

    private void validateInputParameterType(IntersectionTypeSymbol intersectionTypeSymbol, Location location,
                                            boolean isResourceMethod) {
        TypeSymbol effectiveType = getEffectiveType(intersectionTypeSymbol);
        if (effectiveType.typeKind() == TypeDescKind.RECORD) {
            String typeName = effectiveType.getName().orElse(effectiveType.signature());
            validateInputParameterType((RecordTypeSymbol) effectiveType, location, typeName, isResourceMethod);
        } else {
            validateInputParameterType(effectiveType, location, isResourceMethod);
        }
    }

    private void validateInputParameterType(RecordTypeSymbol recordTypeSymbol, Location location, String recordTypeName,
                                            boolean isResourceMethod) {
        if (this.existingReturnTypes.contains(recordTypeSymbol)) {
            addDiagnostic(CompilationDiagnostic.INVALID_RESOURCE_INPUT_OBJECT_PARAM, location, getCurrentFieldPath(),
                          recordTypeName);
        } else {
            if (recordTypeSymbol.fieldDescriptors().isEmpty()) {
                addDiagnostic(CompilationDiagnostic.INVALID_EMPTY_RECORD_INPUT_TYPE, location, recordTypeName,
                        getCurrentFieldPath());
            }
            if (this.existingInputObjectTypes.contains(recordTypeSymbol)) {
                return;
            }
            this.existingInputObjectTypes.add(recordTypeSymbol);
            if (isReservedFederatedTypeName(recordTypeName)) {
                addDiagnostic(CompilationDiagnostic.INVALID_USE_OF_RESERVED_TYPE_AS_INPUT_TYPE, location,
                              recordTypeName);
            }
            for (RecordFieldSymbol recordFieldSymbol : recordTypeSymbol.fieldDescriptors().values()) {
                boolean isDeprecated = recordFieldSymbol.deprecated();
                if (isDeprecated) {
                    addDiagnostic(CompilationDiagnostic.UNSUPPORTED_INPUT_FIELD_DEPRECATION,
                            getLocation(recordFieldSymbol, location), recordTypeName);
                }
                validateInputType(recordFieldSymbol.typeDescriptor(), location, isResourceMethod);
            }
            if (hasDefaultValues(recordTypeSymbol)) {
                validateInputObjectDefaultValues(recordTypeSymbol, recordTypeName, location);
            }
        }
    }

    private boolean hasDefaultValues(RecordTypeSymbol recordTypeSymbol) {
        return recordTypeSymbol.fieldDescriptors().values().stream().anyMatch(RecordFieldSymbol::hasDefaultValue);
    }

    private void validateInputObjectDefaultValues(RecordTypeSymbol recordTypeSymbol, String inputObjectTypeName,
                                                  Location location) {
        if (this.validatedInputTypesHavingDefaultFields.contains(inputObjectTypeName)) {
            return;
        }
        FinderContext finderContext = new FinderContext(this.context);
        TypeDefinitionNode typeDefinitionNode = getRecordTypeDefinitionNode(recordTypeSymbol, inputObjectTypeName,
                                                                            finderContext);
        if (typeDefinitionNode == null) {
            addDiagnostic(CompilationDiagnostic.UNABLE_TO_VALIDATE_DEFAULT_VALUES_OF_INPUT_OBJECT_AT_COMPILE_TIME,
                    location, inputObjectTypeName);
            return;
        }
        for (RecordFieldSymbol recordFieldSymbol : recordTypeSymbol.fieldDescriptors().values()) {
            if (recordFieldSymbol.hasDefaultValue()) {
                validateInputObjectDefaultFields(typeDefinitionNode, recordTypeSymbol, recordFieldSymbol,
                                                 getLocation(recordFieldSymbol, location), inputObjectTypeName);
            }
        }
        this.validatedInputTypesHavingDefaultFields.add(inputObjectTypeName);
    }

    private void validateInputObjectDefaultFields(TypeDefinitionNode typeDefNode, RecordTypeSymbol recordTypeSymbol,
                                                  RecordFieldSymbol recordFieldSymbol, Location location,
                                                  String inputObjectName) {
        if (recordFieldSymbol.getName().isEmpty()) {
            return;
        }
        RecordFieldWithDefaultValueNode defaultField = getRecordFieldWithDefaultValueNode(
                recordFieldSymbol.getName().get(), typeDefNode, this.context.semanticModel());
        if (defaultField == null) {
            ArrayList<TypeSymbol> typeInclusions = new ArrayList<>(getTypeInclusions(recordTypeSymbol));
            while (!typeInclusions.isEmpty()) {
                TypeSymbol includedTypeSymbol = typeInclusions.remove(0);
                defaultField = getRecordFieldFromIncludedRecordType(recordFieldSymbol, includedTypeSymbol);
                if (defaultField != null) {
                    break;
                }
                typeInclusions.addAll(getTypeInclusions(includedTypeSymbol));
            }
        }
        if (defaultField == null) {
            addDiagnostic(CompilationDiagnostic.UNABLE_TO_VALIDATE_DEFAULT_VALUES_OF_INPUT_FIELD_AT_COMPILE_TIME,
                          getLocation(recordFieldSymbol, location), recordFieldSymbol.getName().get(), inputObjectName);
            return;
        }
        validateDefaultValueExpression(defaultField.expression(), defaultField.fieldName().text(), true);
    }

    private RecordFieldWithDefaultValueNode getRecordFieldFromIncludedRecordType(RecordFieldSymbol recordFieldSymbol,
                                                                                 TypeSymbol includedTypeSymbol) {
        if (recordFieldSymbol.getName().isEmpty() || includedTypeSymbol.getName().isEmpty()) {
            return null;
        }
        if (includedTypeSymbol.typeKind() == TypeDescKind.TYPE_REFERENCE) {
            TypeSymbol typeDescriptor = ((TypeReferenceTypeSymbol) includedTypeSymbol).typeDescriptor();
            if (typeDescriptor.typeKind() == TypeDescKind.RECORD) {
                FinderContext finderContext = new FinderContext(this.context);
                TypeDefinitionNode recordTypeDefNode = getRecordTypeDefinitionNode((RecordTypeSymbol) typeDescriptor,
                                                                                   includedTypeSymbol.getName().get(),
                                                                                   finderContext);
                if (recordTypeDefNode == null) {
                    return null;
                }
                return getRecordFieldWithDefaultValueNode(recordFieldSymbol.getName().get(), recordTypeDefNode,
                                                          this.context.semanticModel());
            }
        }
        return null;
    }

    private void validateServiceClassDefinition(ClassSymbol classSymbol, Location location) {
        if (this.visitedClassesAndObjectTypeDefinitions.contains(classSymbol)) {
            return;
        }
        this.visitedClassesAndObjectTypeDefinitions.add(classSymbol);
        // noinspection OptionalGetWithoutIsPresent
        String className = classSymbol.getName().get();
        if (isReservedFederatedTypeName(className)) {
            addDiagnostic(CompilationDiagnostic.INVALID_USE_OF_RESERVED_TYPE_AS_OUTPUT_TYPE, location,
                          getCurrentFieldPath(), className);
        }
        boolean resourceMethodFound = false;
        List<MethodSymbol> methodSymbols = new ArrayList<>(classSymbol.methods().values());
        for (MethodSymbol methodSymbol : methodSymbols) {
            if (methodSymbol.kind() == SymbolKind.RESOURCE_METHOD) {
                resourceMethodFound = true;
                validateResourceMethod((ResourceMethodSymbol) methodSymbol, location);
            } else if (isRemoteMethod(methodSymbol)) {
                // noinspection OptionalGetWithoutIsPresent
                addDiagnostic(CompilationDiagnostic.INVALID_FUNCTION, getLocation(methodSymbol, location), className,
                              methodSymbol.getName().get());
            }
            validatePrefetchMethodMapping(methodSymbol, methodSymbols, location);
        }
        if (!resourceMethodFound) {
            addDiagnostic(CompilationDiagnostic.MISSING_RESOURCE_FUNCTIONS, location);
        }
    }

    private void validateReturnTypeUnion(UnionTypeSymbol unionTypeSymbol, Location location) {
        List<TypeSymbol> effectiveTypes = getEffectiveTypes(unionTypeSymbol);
        if (effectiveTypes.isEmpty()) {
            addDiagnostic(CompilationDiagnostic.INVALID_RETURN_TYPE_ERROR_OR_NIL, location, getCurrentFieldPath());
        } else if (effectiveTypes.size() == 1) {
            validateReturnType(effectiveTypes.get(0), location);
        } else {
            for (TypeSymbol typeSymbol : effectiveTypes) {
                validateUnionTypeMember(typeSymbol, location);
            }
        }
    }

    private void validateUnionTypeMember(TypeSymbol memberType, Location location) {
        if (!isDistinctServiceReference(memberType)) {
            String memberTypeName = memberType.getName().orElse(memberType.signature());
            addDiagnostic(CompilationDiagnostic.INVALID_UNION_MEMBER_TYPE, location, memberTypeName);
        } else {
            validateReturnType(memberType, location);
        }
    }

    private void validateRecordFields(RecordTypeSymbol recordTypeSymbol, Location location) {
        Map<String, RecordFieldSymbol> recordFieldSymbolMap = recordTypeSymbol.fieldDescriptors();
        for (RecordFieldSymbol recordField : recordFieldSymbolMap.values()) {
            if (recordField.getName().isEmpty()) {
                continue;
            }
            String fieldName = recordField.getName().get();
            this.currentFieldPath.add(fieldName);
            if (recordField.typeDescriptor().typeKind() == TypeDescKind.MAP) {
                MapTypeSymbol mapTypeSymbol = (MapTypeSymbol) recordField.typeDescriptor();
                validateReturnType(mapTypeSymbol.typeParam(), location);
            } else {
                validateReturnType(recordField.typeDescriptor(), location);
            }
            if (isInvalidFieldName(fieldName)) {
                addDiagnostic(CompilationDiagnostic.INVALID_FIELD_NAME, location, getCurrentFieldPath(), fieldName);
            }
            this.currentFieldPath.remove(fieldName);
        }
    }

    private void addDiagnostic(CompilationDiagnostic compilationDiagnostic, Location location) {
        this.errorOccurred =
                compilationDiagnostic.getDiagnosticSeverity() == DiagnosticSeverity.ERROR || this.errorOccurred;
        updateContext(this.context, compilationDiagnostic, location);
    }

    private void addDiagnostic(CompilationDiagnostic compilationDiagnostic, Location location, Object... args) {
        this.errorOccurred =
                compilationDiagnostic.getDiagnosticSeverity() == DiagnosticSeverity.ERROR || this.errorOccurred;
        updateContext(this.context, compilationDiagnostic, location, args);
    }

    private String getFieldPath(ResourceMethodSymbol methodSymbol) {
        List<String> pathNames = new ArrayList<>();
        if (methodSymbol.resourcePath().kind() == ResourcePath.Kind.PATH_SEGMENT_LIST) {
            PathSegmentList pathSegmentList = (PathSegmentList) methodSymbol.resourcePath();
            for (PathSegment pathSegment : pathSegmentList.list()) {
                pathNames.add(pathSegment.signature());
            }
        }
        return String.join(FIELD_PATH_SEPARATOR, pathNames);
    }

    private String getCurrentFieldPath() {
        return String.join(FIELD_PATH_SEPARATOR,
                this.currentFieldPath.stream().map(TypeUtils::removeEscapeCharacter).toList());
    }
}
