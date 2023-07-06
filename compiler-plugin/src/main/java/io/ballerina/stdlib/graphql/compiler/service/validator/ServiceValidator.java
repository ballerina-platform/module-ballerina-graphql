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

import io.ballerina.compiler.api.symbols.ArrayTypeSymbol;
import io.ballerina.compiler.api.symbols.ClassSymbol;
import io.ballerina.compiler.api.symbols.EnumSymbol;
import io.ballerina.compiler.api.symbols.FunctionTypeSymbol;
import io.ballerina.compiler.api.symbols.IntersectionTypeSymbol;
import io.ballerina.compiler.api.symbols.MapTypeSymbol;
import io.ballerina.compiler.api.symbols.MethodSymbol;
import io.ballerina.compiler.api.symbols.ObjectTypeSymbol;
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
import io.ballerina.compiler.syntax.tree.Node;
import io.ballerina.compiler.syntax.tree.NodeList;
import io.ballerina.compiler.syntax.tree.ObjectConstructorExpressionNode;
import io.ballerina.compiler.syntax.tree.ServiceDeclarationNode;
import io.ballerina.compiler.syntax.tree.SyntaxKind;
import io.ballerina.projects.plugins.SyntaxNodeAnalysisContext;
import io.ballerina.stdlib.graphql.commons.types.Schema;
import io.ballerina.stdlib.graphql.commons.types.TypeName;
import io.ballerina.stdlib.graphql.compiler.Utils;
import io.ballerina.stdlib.graphql.compiler.diagnostics.CompilationDiagnostic;
import io.ballerina.stdlib.graphql.compiler.service.InterfaceEntityFinder;
import io.ballerina.tools.diagnostics.Location;

import java.util.ArrayList;
import java.util.HashSet;
import java.util.List;
import java.util.Map;
import java.util.Set;
import java.util.stream.Collectors;

import static io.ballerina.stdlib.graphql.compiler.Utils.getAccessor;
import static io.ballerina.stdlib.graphql.compiler.Utils.getEffectiveType;
import static io.ballerina.stdlib.graphql.compiler.Utils.getEffectiveTypes;
import static io.ballerina.stdlib.graphql.compiler.Utils.hasLoaderAnnotation;
import static io.ballerina.stdlib.graphql.compiler.Utils.isDataLoaderMap;
import static io.ballerina.stdlib.graphql.compiler.Utils.isDistinctServiceClass;
import static io.ballerina.stdlib.graphql.compiler.Utils.isDistinctServiceReference;
import static io.ballerina.stdlib.graphql.compiler.Utils.isFileUploadParameter;
import static io.ballerina.stdlib.graphql.compiler.Utils.isPrimitiveTypeSymbol;
import static io.ballerina.stdlib.graphql.compiler.Utils.isRemoteMethod;
import static io.ballerina.stdlib.graphql.compiler.Utils.isResourceMethod;
import static io.ballerina.stdlib.graphql.compiler.Utils.isServiceClass;
import static io.ballerina.stdlib.graphql.compiler.Utils.isValidGraphqlParameter;
import static io.ballerina.stdlib.graphql.compiler.Utils.lowerCaseFirstChar;
import static io.ballerina.stdlib.graphql.compiler.service.validator.ValidatorUtils.RESOURCE_FUNCTION_GET;
import static io.ballerina.stdlib.graphql.compiler.service.validator.ValidatorUtils.RESOURCE_FUNCTION_SUBSCRIBE;
import static io.ballerina.stdlib.graphql.compiler.service.validator.ValidatorUtils.getLocation;
import static io.ballerina.stdlib.graphql.compiler.service.validator.ValidatorUtils.isInvalidFieldName;
import static io.ballerina.stdlib.graphql.compiler.service.validator.ValidatorUtils.isReservedFederatedResolverName;
import static io.ballerina.stdlib.graphql.compiler.service.validator.ValidatorUtils.isReservedFederatedTypeName;
import static io.ballerina.stdlib.graphql.compiler.service.validator.ValidatorUtils.updateContext;
import static java.util.Locale.ENGLISH;

/**
 * Validate functions in Ballerina GraphQL services.
 */
public class ServiceValidator {
    private final Set<Symbol> visitedClassesAndObjectTypeDefinitions = new HashSet<>();
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

    private static final String EMPTY_STRING = "";
    private static final String FIELD_PATH_SEPARATOR = ".";
    private static final String LOAD_METHOD_PREFIX = "load";
    private static final String REMOTE_KEY_WORD = "remote";

    public ServiceValidator(SyntaxNodeAnalysisContext context, Node serviceNode,
                            InterfaceEntityFinder interfaceEntityFinder, boolean isSubgraph) {
        this.context = context;
        this.serviceNode = serviceNode;
        this.interfaceEntityFinder = interfaceEntityFinder;
        this.errorOccurred = false;
        this.hasQueryType = false;
        this.currentFieldPath = new ArrayList<>();
        this.isSubgraph = isSubgraph;
    }

    public void validate() {
        if (serviceNode.kind() == SyntaxKind.SERVICE_DECLARATION) {
            validateServiceDeclaration();
        } else if (serviceNode.kind() == SyntaxKind.OBJECT_CONSTRUCTOR) {
            validateServiceObject();
        }
    }

    private void validateServiceObject() {
        ObjectConstructorExpressionNode objectConstructorExpNode = (ObjectConstructorExpressionNode) serviceNode;
        List<Node> remoteOrResourceMethodNodes = getRemoteOrResourceMethodNodes(objectConstructorExpNode.members());
        validateRootServiceRemoteOrResourceMethods(remoteOrResourceMethodNodes);
        if (!this.hasQueryType) {
            addDiagnostic(CompilationDiagnostic.MISSING_RESOURCE_FUNCTIONS, objectConstructorExpNode.location());
        }
        validateEntitiesResolverReturnTypes();
    }

    private void validateServiceDeclaration() {
        ServiceDeclarationNode node = (ServiceDeclarationNode) serviceNode;
        // No need to check isEmpty(), already validated in ServiceDeclarationAnalysisTask
        // noinspection OptionalGetWithoutIsPresent
        ServiceDeclarationSymbol serviceDeclarationSymbol = (ServiceDeclarationSymbol) context.semanticModel()
                .symbol(node).get();
        if (serviceDeclarationSymbol.listenerTypes().size() > 1) {
            addDiagnostic(CompilationDiagnostic.INVALID_MULTIPLE_LISTENERS, node.location());
        }
        validateService();
    }

    public boolean isErrorOccurred() {
        return this.errorOccurred;
    }

    private void validateService() {
        ServiceDeclarationNode serviceDeclarationNode = (ServiceDeclarationNode) this.context.node();
        List<Node> remoteOrResourceMethodNodes = getRemoteOrResourceMethodNodes(serviceDeclarationNode.members());
        validateRootServiceRemoteOrResourceMethods(remoteOrResourceMethodNodes);
        if (!this.hasQueryType) {
            addDiagnostic(CompilationDiagnostic.MISSING_RESOURCE_FUNCTIONS, serviceDeclarationNode.location());
        }
        validateEntitiesResolverReturnTypes();
    }

    private List<Node> getRemoteOrResourceMethodNodes(NodeList<Node> serviceMembers) {
        return serviceMembers.stream().filter(this::isServiceRemoteOrResourceMethod).collect(Collectors.toList());
    }

    private boolean isServiceRemoteOrResourceMethod(Node node) {
        if (this.context.semanticModel().symbol(node).isEmpty()) {
            return false;
        }
        Symbol symbol = this.context.semanticModel().symbol(node).get();
        return symbol.kind() == SymbolKind.RESOURCE_METHOD || symbol.kind() == SymbolKind.METHOD
                && isRemoteMethod((MethodSymbol) symbol);
    }

    private void validateRootServiceRemoteOrResourceMethods(List<Node> remoteOrResourceMethods) {
        List<MethodSymbol> resourceOrRemoteMethodSymbols = getRemoteOrResourceMethodSymbols(remoteOrResourceMethods);
        for (Node methodNode : remoteOrResourceMethods) {
            // No need to check fo isEmpty(), already validated in getRemoteOrResourceMethodSymbols
            MethodSymbol methodSymbol = (MethodSymbol) this.context.semanticModel().symbol(methodNode).get();
            Location location = methodNode.location();
            if (hasLoaderAnnotation(methodSymbol)) {
                validateLoadMethod(methodSymbol, location, resourceOrRemoteMethodSymbols);
            } else if (isRemoteMethod(methodSymbol)) {
                this.currentFieldPath.add(TypeName.MUTATION.getName());
                validateRemoteMethod(methodSymbol, location, resourceOrRemoteMethodSymbols);
                this.currentFieldPath.remove(TypeName.MUTATION.getName());
            } else if (isResourceMethod(methodSymbol)) {
                validateRootServiceResourceMethod((ResourceMethodSymbol) methodSymbol, location,
                                                  resourceOrRemoteMethodSymbols);
            }
        }
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

    private void validateRootServiceResourceMethod(ResourceMethodSymbol methodSymbol, Location location,
                                                   List<MethodSymbol> resourceOrRemoteMethodSymbols) {
        String resourceMethodName = getFieldPath(methodSymbol);
        Location accessorLocation = getLocation(methodSymbol, location);
        if (isReservedFederatedResolverName(resourceMethodName)) {
            addDiagnostic(CompilationDiagnostic.INVALID_USE_OF_RESERVED_RESOURCE_PATH, accessorLocation,
                          resourceMethodName);
        }
        String accessor = getAccessor(methodSymbol);
        if (RESOURCE_FUNCTION_SUBSCRIBE.equals(accessor)) {
            this.currentFieldPath.add(TypeName.SUBSCRIPTION.getName());
            validateSubscribeResource(methodSymbol, location, resourceOrRemoteMethodSymbols);
            this.currentFieldPath.remove(TypeName.SUBSCRIPTION.getName());
        } else if (RESOURCE_FUNCTION_GET.equals(accessor)) {
            this.currentFieldPath.add(TypeName.QUERY.getName());
            this.hasQueryType = true;
            validateGetResource(methodSymbol, location, resourceOrRemoteMethodSymbols);
            this.currentFieldPath.remove(TypeName.QUERY.getName());
        } else {
            addDiagnostic(CompilationDiagnostic.INVALID_ROOT_RESOURCE_ACCESSOR, accessorLocation, accessor,
                          resourceMethodName);
        }
    }

    private List<MethodSymbol> getRemoteOrResourceMethodSymbols(List<Node> serviceMembers) {
        return serviceMembers.stream().filter(this::isServiceRemoteOrResourceMethod)
                .map(methodNode -> (MethodSymbol) this.context.semanticModel().symbol(methodNode).get())
                .collect(Collectors.toList());
    }

    private void validateResourceMethod(ResourceMethodSymbol methodSymbol, Location location,
                                        List<MethodSymbol> resourceOrRemoteMethodSymbols) {
        String accessor = getAccessor(methodSymbol);
        if (!RESOURCE_FUNCTION_GET.equals(accessor)) {
            Location accessorLocation = getLocation(methodSymbol, location);
            addDiagnostic(CompilationDiagnostic.INVALID_RESOURCE_FUNCTION_ACCESSOR, accessorLocation, accessor,
                          getFieldPath(methodSymbol));
        }
        validateGetResource(methodSymbol, getLocation(methodSymbol, location), resourceOrRemoteMethodSymbols);
    }

    private void validateGetResource(ResourceMethodSymbol methodSymbol, Location location,
                                     List<MethodSymbol> remoteOrResourceMethodSymbols) {
        String path = getFieldPath(methodSymbol);
        this.currentFieldPath.add(path);
        validateResourcePath(methodSymbol, location);
        validateMethod(methodSymbol, location, remoteOrResourceMethodSymbols);
        this.currentFieldPath.remove(path);
    }

    private void validateSubscribeResource(ResourceMethodSymbol methodSymbol, Location location,
                                           List<MethodSymbol> resourceOrRemoteMethodSymbols) {
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
        validateInputParameters(methodSymbol, location, resourceOrRemoteMethodSymbols);
    }

    private void validateLoadMethod(MethodSymbol loadMethodSymbol, Location location,
                                    List<MethodSymbol> serviceMethods) {
        String loadMethodName = getMethodName(loadMethodSymbol);
        Location loadMethodLocation = getLocation(loadMethodSymbol, location);
        if (isResourceMethod(loadMethodSymbol) && RESOURCE_FUNCTION_SUBSCRIBE.equals(
                getAccessor((ResourceMethodSymbol) loadMethodSymbol))) {
            addDiagnostic(CompilationDiagnostic.INVALID_USAGE_OF_LOADER_ANNOTATION_IN_SUBSCRIBE_RESOURCE,
                          loadMethodLocation, loadMethodName);
            return;
        }

        if (!loadMethodName.startsWith(LOAD_METHOD_PREFIX)) {
            addDiagnostic(CompilationDiagnostic.INVALID_RESOURCE_FUNCTION_NAME_FOR_DATA_LOADER, loadMethodLocation,
                          loadMethodName, LOAD_METHOD_PREFIX, loadMethodName);
            return;
        }

        MethodSymbol correspondingGraphqlFieldMethod = findCorrespondingMethodMappingForLoadMethod(loadMethodSymbol,
                                                                                                   loadMethodLocation,
                                                                                                   serviceMethods);
        if (correspondingGraphqlFieldMethod == null) {
            return;
        }
        validateLoadMethodParams(loadMethodSymbol, loadMethodLocation, correspondingGraphqlFieldMethod);
        validateLoadMethodReturnType(loadMethodSymbol, loadMethodLocation);
    }

    private MethodSymbol findCorrespondingMethodMappingForLoadMethod(MethodSymbol loadMethodSymbol,
                                                                     Location loadMethodLocation,
                                                                     List<MethodSymbol> serviceMethods) {
        String loadMethodName = getMethodName(loadMethodSymbol);
        // field name starting with a capital letter
        String expectedFieldName = loadMethodName.substring(LOAD_METHOD_PREFIX.length());
        MethodSymbol field = findRemoteOrGetResourceMethodSymbolExceptLoadMethods(serviceMethods, expectedFieldName);
        if (field == null) {
            // field name starting with a simple letter
            expectedFieldName = lowerCaseFirstChar(expectedFieldName);
            field = findRemoteOrGetResourceMethodSymbolExceptLoadMethods(serviceMethods, expectedFieldName);
        }
        if (isRemoteMethod(loadMethodSymbol) && (field == null || !isRemoteMethod(field))) {
            addDiagnostic(CompilationDiagnostic.NO_MATCHING_REMOTE_METHOD_FOUND_FOR_LOAD_METHOD,
                          loadMethodLocation, expectedFieldName, loadMethodName);
            return null;
        }
        if (isResourceMethod(loadMethodSymbol) && (field == null || !isResourceMethod(field))) {
            addDiagnostic(CompilationDiagnostic.NO_MATCHING_RESOURCE_METHOD_FOUND_FOR_LOAD_METHOD,
                          loadMethodLocation, expectedFieldName, loadMethodName);
            return null;
        }
        return field;
    }

    private String getMethodName(MethodSymbol methodSymbol) {
        return isResourceMethod(methodSymbol) ? getFieldPath((ResourceMethodSymbol) methodSymbol) :
                methodSymbol.getName().orElse(EMPTY_STRING);
    }

    private void validateLoadMethodParams(MethodSymbol loadMethodSymbol, Location loadMethodLocation,
                                          MethodSymbol correspondingGraphqlFieldMethod) {
        String loadMethodName = getMethodName(loadMethodSymbol);
        Set<String> fieldMethodParamSignatures = correspondingGraphqlFieldMethod.typeDescriptor().params().isPresent() ?
                correspondingGraphqlFieldMethod.typeDescriptor().params().get().stream().map(ParameterSymbol::signature)
                        .collect(Collectors.toSet()) : new HashSet<>();
        List<ParameterSymbol> parameterSymbols = loadMethodSymbol.typeDescriptor().params().isPresent() ?
                loadMethodSymbol.typeDescriptor().params().get() : new ArrayList<>();
        boolean hasDataLoaderMapParameter = false;
        for (ParameterSymbol symbol : parameterSymbols) {
            if (isDataLoaderMap(symbol.typeDescriptor())) {
                hasDataLoaderMapParameter = true;
            } else if (!fieldMethodParamSignatures.contains(symbol.signature())) {
                addDiagnostic(CompilationDiagnostic.INVALID_PARAMETER_IN_LOAD_METHOD, loadMethodLocation,
                              symbol.signature(), loadMethodName, getMethodName(correspondingGraphqlFieldMethod));
            }
        }
        if (!hasDataLoaderMapParameter) {
            addDiagnostic(CompilationDiagnostic.MISSING_DATA_LOADER_PARAMETER, loadMethodLocation, loadMethodName);
        }
    }

    private void validateLoadMethodReturnType(MethodSymbol loadMethodSymbol, Location loadMethodLocation) {
        if (loadMethodSymbol.typeDescriptor().returnTypeDescriptor().isEmpty()) {
            return;
        }
        TypeSymbol returnType = loadMethodSymbol.typeDescriptor().returnTypeDescriptor().get();
        if (returnType.typeKind() == TypeDescKind.NIL) {
            return;
        }
        addDiagnostic(CompilationDiagnostic.INVALID_RETURN_TYPE_IN_LOADER_METHOD,
                      getLocation(returnType, loadMethodLocation), returnType.signature(),
                      getMethodName(loadMethodSymbol));
    }

    private MethodSymbol findRemoteOrGetResourceMethodSymbolExceptLoadMethods(List<MethodSymbol> serviceMethods,
                                                                              String expectedFieldName) {
        return serviceMethods.stream()
                .filter(method -> !hasLoaderAnnotation(method)
                        && hasExpectedRemoteOrGetResourceMethodName(method, expectedFieldName))
                .findFirst().orElse(null);
    }

    private boolean hasExpectedRemoteOrGetResourceMethodName(MethodSymbol methodSymbol, String expectedMethodName) {
        return isResourceMethod(methodSymbol) && RESOURCE_FUNCTION_GET.equals(
                getAccessor((ResourceMethodSymbol) methodSymbol)) && getFieldPath(
                (ResourceMethodSymbol) methodSymbol).equals(expectedMethodName) || (isRemoteMethod(methodSymbol)
                && methodSymbol.getName().orElse(EMPTY_STRING).equals(expectedMethodName));
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

    private void validateRemoteMethod(MethodSymbol methodSymbol, Location location,
                                      List<MethodSymbol> serviceRemoteOrResourceMethods) {
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
        validateMethod(methodSymbol, location, serviceRemoteOrResourceMethods);
        this.currentFieldPath.remove(fieldName);
    }

    private void validateMethod(MethodSymbol methodSymbol, Location location,
                                List<MethodSymbol> remoteOrResourceMethods) {
        if (methodSymbol.typeDescriptor().returnTypeDescriptor().isPresent()) {
            TypeSymbol returnTypeSymbol = methodSymbol.typeDescriptor().returnTypeDescriptor().get();
            validateReturnType(returnTypeSymbol, location);
        }
        validateInputParameters(methodSymbol, location, remoteOrResourceMethods);
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
            if (hasLoaderAnnotation(methodSymbol)) {
                validateLoadMethod(methodSymbol, location, methodSymbols);
            } else if (methodSymbol.kind() == SymbolKind.RESOURCE_METHOD) {
                resourceMethodFound = true;
                validateResourceMethod((ResourceMethodSymbol) methodSymbol, location, methodSymbols);
            } else if (isRemoteMethod(methodSymbol)) {
                // noinspection OptionalGetWithoutIsPresent
                String interfaceName = typeDefinitionSymbol.getName().get();
                String remoteMethodName = methodSymbol.getName().orElse(methodSymbol.signature());
                addDiagnostic(CompilationDiagnostic.INVALID_FUNCTION, getLocation(methodSymbol, location),
                              interfaceName, remoteMethodName);
            }
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
        if (isReservedFederatedTypeName(recordTypeName)) {
            addDiagnostic(CompilationDiagnostic.INVALID_USE_OF_RESERVED_TYPE_AS_OUTPUT_TYPE, location,
                          getCurrentFieldPath(), recordTypeName);
        } else if (this.existingInputObjectTypes.contains(descriptor)) {
            addDiagnostic(CompilationDiagnostic.INVALID_RETURN_TYPE_INPUT_OBJECT, location, getCurrentFieldPath(),
                          recordTypeName);
        } else {
            if (this.existingReturnTypes.contains(descriptor)) {
                return;
            }
            this.existingReturnTypes.add(descriptor);
            validateRecordFields(recordTypeSymbol, location);
        }
    }

    private void validateInputParameters(MethodSymbol methodSymbol, Location location,
                                         List<MethodSymbol> remoteOrResourceMethods) {
        FunctionTypeSymbol functionTypeSymbol = methodSymbol.typeDescriptor();
        if (functionTypeSymbol.params().isPresent()) {
            List<ParameterSymbol> parameterSymbols = functionTypeSymbol.params().get();
            boolean hasDataLoaderAnnotation = hasLoaderAnnotation(methodSymbol);
            for (ParameterSymbol parameter : parameterSymbols) {
                Location inputLocation = getLocation(parameter, location);
                if (isDataLoaderMap(parameter.typeDescriptor()) && !hasDataLoaderAnnotation) {
                    if (RESOURCE_FUNCTION_SUBSCRIBE.equals(methodSymbol.getName().orElse(EMPTY_STRING))) {
                        addDiagnostic(CompilationDiagnostic.INVALID_DATA_LOADER_USAGE_IN_SUBSCRIPTION, inputLocation,
                                      getFieldPath((ResourceMethodSymbol) methodSymbol));
                        continue;
                    }
                    checkForCorrespondingLoadMethod(methodSymbol, remoteOrResourceMethods, location);
                    continue;
                }
                if (isValidGraphqlParameter(parameter.typeDescriptor())) {
                    continue;
                }
                if (parameter.annotations().isEmpty()) {
                    validateInputParameterType(parameter.typeDescriptor(), inputLocation,
                                               isResourceMethod(methodSymbol));
                }
            }
        }
    }

    private void checkForCorrespondingLoadMethod(MethodSymbol methodSymbol, List<MethodSymbol> remoteOrResourceMethods,
                                                 Location location) {
        String methodName = getMethodName(methodSymbol);
        String expectedLoadMethodName = getLoadMethodName(methodName);
        boolean hasMatchingLoadMethod = remoteOrResourceMethods.stream().anyMatch(method -> isResourceMethod(method) ?
                expectedLoadMethodName.equals(getFieldPath((ResourceMethodSymbol) method))
                        && RESOURCE_FUNCTION_GET.equals(getAccessor((ResourceMethodSymbol) method)) :
                expectedLoadMethodName.equals(method.getName().orElse(EMPTY_STRING)));
        if (!hasMatchingLoadMethod) {
            addDiagnostic(CompilationDiagnostic.NO_MATCHING_LOAD_FUNCTION_FOUND, getLocation(methodSymbol, location),
                          isResourceMethod(methodSymbol) ? RESOURCE_FUNCTION_GET : REMOTE_KEY_WORD,
                          expectedLoadMethodName, methodName);
        }
    }

    private String getLoadMethodName(String methodName) {
        return LOAD_METHOD_PREFIX + methodName.substring(0, 1).toUpperCase(ENGLISH) + methodName.substring(1);
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
            if (this.existingInputObjectTypes.contains(recordTypeSymbol)) {
                return;
            }
            this.existingInputObjectTypes.add(recordTypeSymbol);
            if (isReservedFederatedTypeName(recordTypeName)) {
                addDiagnostic(CompilationDiagnostic.INVALID_USE_OF_RESERVED_TYPE_AS_INPUT_TYPE, location,
                              recordTypeName);
            }
            for (RecordFieldSymbol recordFieldSymbol : recordTypeSymbol.fieldDescriptors().values()) {
                validateInputType(recordFieldSymbol.typeDescriptor(), location, isResourceMethod);
            }
        }
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
            if (hasLoaderAnnotation(methodSymbol)) {
                validateLoadMethod(methodSymbol, location, methodSymbols);
            } else if (methodSymbol.kind() == SymbolKind.RESOURCE_METHOD) {
                resourceMethodFound = true;
                validateResourceMethod((ResourceMethodSymbol) methodSymbol, location, methodSymbols);
            } else if (isRemoteMethod(methodSymbol)) {
                // noinspection OptionalGetWithoutIsPresent
                addDiagnostic(CompilationDiagnostic.INVALID_FUNCTION, getLocation(methodSymbol, location), className,
                              methodSymbol.getName().get());
            }
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
        this.errorOccurred = true;
        updateContext(this.context, compilationDiagnostic, location);
    }

    private void addDiagnostic(CompilationDiagnostic compilationDiagnostic, Location location, Object... args) {
        this.errorOccurred = true;
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
        return String.join(FIELD_PATH_SEPARATOR, this.currentFieldPath);
    }
}
