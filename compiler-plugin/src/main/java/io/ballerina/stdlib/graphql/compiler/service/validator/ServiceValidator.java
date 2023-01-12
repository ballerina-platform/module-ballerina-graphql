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
import io.ballerina.compiler.api.symbols.FunctionTypeSymbol;
import io.ballerina.compiler.api.symbols.IntersectionTypeSymbol;
import io.ballerina.compiler.api.symbols.MapTypeSymbol;
import io.ballerina.compiler.api.symbols.MethodSymbol;
import io.ballerina.compiler.api.symbols.ObjectTypeSymbol;
import io.ballerina.compiler.api.symbols.ParameterSymbol;
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
import io.ballerina.compiler.syntax.tree.ObjectConstructorExpressionNode;
import io.ballerina.compiler.syntax.tree.ServiceDeclarationNode;
import io.ballerina.compiler.syntax.tree.SyntaxKind;
import io.ballerina.projects.plugins.SyntaxNodeAnalysisContext;
import io.ballerina.stdlib.graphql.commons.types.TypeName;
import io.ballerina.stdlib.graphql.compiler.diagnostics.CompilationDiagnostic;
import io.ballerina.stdlib.graphql.compiler.service.InterfaceFinder;
import io.ballerina.tools.diagnostics.Location;

import java.util.ArrayList;
import java.util.HashSet;
import java.util.List;
import java.util.Map;
import java.util.Set;

import static io.ballerina.stdlib.graphql.compiler.Utils.getAccessor;
import static io.ballerina.stdlib.graphql.compiler.Utils.getEffectiveType;
import static io.ballerina.stdlib.graphql.compiler.Utils.getEffectiveTypes;
import static io.ballerina.stdlib.graphql.compiler.Utils.isContextParameter;
import static io.ballerina.stdlib.graphql.compiler.Utils.isDistinctServiceClass;
import static io.ballerina.stdlib.graphql.compiler.Utils.isDistinctServiceReference;
import static io.ballerina.stdlib.graphql.compiler.Utils.isFieldParameter;
import static io.ballerina.stdlib.graphql.compiler.Utils.isFileUploadParameter;
import static io.ballerina.stdlib.graphql.compiler.Utils.isRemoteMethod;
import static io.ballerina.stdlib.graphql.compiler.Utils.isResourceMethod;
import static io.ballerina.stdlib.graphql.compiler.Utils.isServiceClass;
import static io.ballerina.stdlib.graphql.compiler.service.validator.ValidatorUtils.RESOURCE_FUNCTION_GET;
import static io.ballerina.stdlib.graphql.compiler.service.validator.ValidatorUtils.RESOURCE_FUNCTION_SUBSCRIBE;
import static io.ballerina.stdlib.graphql.compiler.service.validator.ValidatorUtils.getLocation;
import static io.ballerina.stdlib.graphql.compiler.service.validator.ValidatorUtils.isInvalidFieldName;
import static io.ballerina.stdlib.graphql.compiler.service.validator.ValidatorUtils.updateContext;

/**
 * Validate functions in Ballerina GraphQL services.
 */
public class ServiceValidator {
    private static final String FIELD_PATH_SEPARATOR = ".";
    private final Set<Symbol> visitedClassesAndObjectTypeDefinitions = new HashSet<>();
    private final List<TypeSymbol> existingInputObjectTypes = new ArrayList<>();
    private final List<TypeSymbol> existingReturnTypes = new ArrayList<>();
    private final InterfaceFinder interfaceFinder;
    private final SyntaxNodeAnalysisContext context;
    private final Node serviceNode;
    private int arrayDimension = 0;
    private boolean errorOccurred;
    private boolean hasQueryType;
    private TypeSymbol rootInputParameterTypeSymbol;

    private final List<String> currentFieldPath;

    public ServiceValidator(SyntaxNodeAnalysisContext context, Node serviceNode, InterfaceFinder interfaceFinder) {
        this.context = context;
        this.serviceNode = serviceNode;
        this.interfaceFinder = interfaceFinder;
        this.errorOccurred = false;
        this.hasQueryType = false;
        this.currentFieldPath = new ArrayList<>();
    }

    public void validate() {
        if (serviceNode.kind() == SyntaxKind.SERVICE_DECLARATION) {
            validateServiceDeclaration();
        } else if (serviceNode.kind() == SyntaxKind.OBJECT_CONSTRUCTOR) {
            validateServiceObject();
        }
    }

    private void validateServiceObject() {
        ObjectConstructorExpressionNode objectConstructorExpressionNode = (ObjectConstructorExpressionNode) serviceNode;
        for (Node node : objectConstructorExpressionNode.members()) {
            validateServiceMember(node);
        }
        if (!this.hasQueryType) {
            addDiagnostic(CompilationDiagnostic.MISSING_RESOURCE_FUNCTIONS, objectConstructorExpressionNode.location());
        }
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
        for (Node node : serviceDeclarationNode.members()) {
            validateServiceMember(node);
        }
        if (!this.hasQueryType) {
            addDiagnostic(CompilationDiagnostic.MISSING_RESOURCE_FUNCTIONS, serviceDeclarationNode.location());
        }
    }

    private void validateServiceMember(Node node) {
        if (this.context.semanticModel().symbol(node).isEmpty()) {
            return;
        }
        Symbol symbol = this.context.semanticModel().symbol(node).get();
        Location location = node.location();
        if (symbol.kind() == SymbolKind.METHOD) {
            MethodSymbol methodSymbol = (MethodSymbol) symbol;
            if (isRemoteMethod(methodSymbol)) {
                this.currentFieldPath.add(TypeName.MUTATION.getName());
                validateRemoteMethod(methodSymbol, location);
                this.currentFieldPath.remove(TypeName.MUTATION.getName());
            }
        } else if (symbol.kind() == SymbolKind.RESOURCE_METHOD) {
            ResourceMethodSymbol resourceMethodSymbol = (ResourceMethodSymbol) symbol;
            validateRootServiceResourceMethod(resourceMethodSymbol, location);
        }
    }

    private void validateRootServiceResourceMethod(ResourceMethodSymbol methodSymbol, Location location) {
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
            Location accessorLocation = getLocation(methodSymbol, location);
            String resourceMethodName = getFieldPath(methodSymbol);
            addDiagnostic(CompilationDiagnostic.INVALID_ROOT_RESOURCE_ACCESSOR, accessorLocation, accessor,
                          resourceMethodName);
        }
    }

    private void validateResourceMethod(ResourceMethodSymbol methodSymbol, Location location) {
        String accessor = getAccessor(methodSymbol);
        if (!RESOURCE_FUNCTION_GET.equals(accessor)) {
            Location accessorLocation = getLocation(methodSymbol, location);
            addDiagnostic(CompilationDiagnostic.INVALID_RESOURCE_FUNCTION_ACCESSOR, accessorLocation, accessor,
                          getFieldPath(methodSymbol));
        }
        validateGetResource(methodSymbol, location);
    }

    private void validateGetResource(ResourceMethodSymbol methodSymbol, Location location) {
        String path = getFieldPath(methodSymbol);
        this.currentFieldPath.add(path);
        validateResourcePath(methodSymbol, location);
        validateMethod(methodSymbol, location);
        this.currentFieldPath.remove(path);
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
        if (typeReferenceTypeSymbol.definition().kind() == SymbolKind.TYPE_DEFINITION) {
            validateReturnTypeDefinition(typeReferenceTypeSymbol, location);
        } else if (typeReferenceTypeSymbol.definition().kind() == SymbolKind.CLASS) {
            ClassSymbol classSymbol = (ClassSymbol) typeReferenceTypeSymbol.definition();
            validateReturnTypeClass(classSymbol, location);
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
        } else {
            validateReturnType(typeDefinitionSymbol.typeDescriptor(), location);
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
        if (!this.interfaceFinder.isPossibleInterface(objectTypeName)) {
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
        // TODO: Check for distinct keyword and add diagnostic
        // https://github.com/ballerina-platform/ballerina-standard-library/issues/3337
        boolean resourceMethodFound = false;
        ObjectTypeSymbol objectTypeSymbol = (ObjectTypeSymbol) typeDefinitionSymbol.typeDescriptor();
        for (MethodSymbol methodSymbol : objectTypeSymbol.methods().values()) {
            Location methodLocation = getLocation(methodSymbol, location);
            if (methodSymbol.kind() == SymbolKind.RESOURCE_METHOD) {
                resourceMethodFound = true;
                validateResourceMethod((ResourceMethodSymbol) methodSymbol, methodLocation);
            } else if (isRemoteMethod(methodSymbol)) {
                // noinspection OptionalGetWithoutIsPresent
                String interfaceName = typeDefinitionSymbol.getName().get();
                String remoteMethodName = methodSymbol.getName().orElse(methodSymbol.signature());
                addDiagnostic(CompilationDiagnostic.INVALID_FUNCTION, methodLocation, interfaceName, remoteMethodName);
            }
        }
        if (!resourceMethodFound) {
            addDiagnostic(CompilationDiagnostic.MISSING_RESOURCE_FUNCTIONS, location);
        }
    }

    private void validateInterfaceImplementation(String interfaceName, Location location) {
        for (Symbol implementation : this.interfaceFinder.getImplementations(interfaceName)) {
            if (implementation.getName().isEmpty()) {
                continue;
            }
            if (implementation.kind() == SymbolKind.CLASS) {
                if (!isDistinctServiceClass(implementation)) {
                    String implementationName = implementation.getName().get();
                    addDiagnostic(CompilationDiagnostic.NON_DISTINCT_INTERFACE_IMPLEMENTATION, location,
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
        if (this.existingInputObjectTypes.contains(descriptor)) {
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

    private void validateInputParameters(MethodSymbol methodSymbol, Location location) {
        FunctionTypeSymbol functionTypeSymbol = methodSymbol.typeDescriptor();
        if (functionTypeSymbol.params().isPresent()) {
            List<ParameterSymbol> parameterSymbols = functionTypeSymbol.params().get();
            for (ParameterSymbol parameter : parameterSymbols) {
                Location inputLocation = getLocation(parameter, location);
                if (isContextParameter(parameter.typeDescriptor()) || isFieldParameter(parameter.typeDescriptor())) {
                    continue;
                }
                validateInputParameterType(parameter.typeDescriptor(), inputLocation, isResourceMethod(methodSymbol));
            }
        }
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
        if (typeDefinition.kind() == SymbolKind.ENUM) {
            return;
        }
        if (typeDefinition.kind() == SymbolKind.TYPE_DEFINITION && typeDescriptor.typeKind() == TypeDescKind.RECORD) {
            // noinspection OptionalGetWithoutIsPresent
            String typeName = typeDefinition.getName().get();
            validateInputParameterType((RecordTypeSymbol) typeDescriptor, location, typeName, isResourceMethod);
            return;
        }
        validateInputParameterType(typeDescriptor, location, isResourceMethod);
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
        boolean resourceMethodFound = false;
        for (MethodSymbol methodSymbol : classSymbol.methods().values()) {
            Location methodLocation = getLocation(methodSymbol, location);
            if (methodSymbol.kind() == SymbolKind.RESOURCE_METHOD) {
                resourceMethodFound = true;
                validateResourceMethod((ResourceMethodSymbol) methodSymbol, methodLocation);
            } else if (isRemoteMethod(methodSymbol)) {
                // noinspection OptionalGetWithoutIsPresent
                addDiagnostic(CompilationDiagnostic.INVALID_FUNCTION, methodLocation, classSymbol.getName().get(),
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
