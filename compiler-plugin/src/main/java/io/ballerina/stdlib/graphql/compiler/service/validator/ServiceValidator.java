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
import io.ballerina.compiler.api.symbols.MethodSymbol;
import io.ballerina.compiler.api.symbols.ParameterSymbol;
import io.ballerina.compiler.api.symbols.RecordFieldSymbol;
import io.ballerina.compiler.api.symbols.RecordTypeSymbol;
import io.ballerina.compiler.api.symbols.ResourceMethodSymbol;
import io.ballerina.compiler.api.symbols.ServiceDeclarationSymbol;
import io.ballerina.compiler.api.symbols.StreamTypeSymbol;
import io.ballerina.compiler.api.symbols.Symbol;
import io.ballerina.compiler.api.symbols.SymbolKind;
import io.ballerina.compiler.api.symbols.TypeDefinitionSymbol;
import io.ballerina.compiler.api.symbols.TypeDescKind;
import io.ballerina.compiler.api.symbols.TypeReferenceTypeSymbol;
import io.ballerina.compiler.api.symbols.TypeSymbol;
import io.ballerina.compiler.api.symbols.UnionTypeSymbol;
import io.ballerina.compiler.api.symbols.resourcepath.PathSegmentList;
import io.ballerina.compiler.api.symbols.resourcepath.ResourcePath;
import io.ballerina.compiler.api.symbols.resourcepath.util.PathSegment;
import io.ballerina.compiler.syntax.tree.Node;
import io.ballerina.compiler.syntax.tree.ServiceDeclarationNode;
import io.ballerina.projects.plugins.SyntaxNodeAnalysisContext;
import io.ballerina.stdlib.graphql.compiler.service.InterfaceFinder;
import io.ballerina.stdlib.graphql.compiler.service.errors.CompilationError;
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
import static io.ballerina.stdlib.graphql.compiler.Utils.isFileUploadParameter;
import static io.ballerina.stdlib.graphql.compiler.Utils.isPrimitiveType;
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
    private final Set<ClassSymbol> visitedClassSymbols = new HashSet<>();
    private final List<TypeSymbol> existingInputObjectTypes = new ArrayList<>();
    private final List<TypeSymbol> existingReturnTypes = new ArrayList<>();
    private final InterfaceFinder interfaceFinder;
    private final SyntaxNodeAnalysisContext context;
    private final ServiceDeclarationSymbol serviceDeclarationSymbol;
    private int arrayDimension = 0;
    private boolean errorOccurred;
    private boolean hasQueryType;

    public ServiceValidator(SyntaxNodeAnalysisContext context, ServiceDeclarationSymbol serviceDeclarationSymbol,
                            InterfaceFinder interfaceFinder) {
        this.context = context;
        this.serviceDeclarationSymbol = serviceDeclarationSymbol;
        this.interfaceFinder = interfaceFinder;
        this.errorOccurred = false;
        this.hasQueryType = false;
    }

    public void validate() {
        ServiceDeclarationNode node = (ServiceDeclarationNode) this.context.node();
        if (this.serviceDeclarationSymbol.listenerTypes().size() > 1) {
            addDiagnostic(CompilationError.INVALID_MULTIPLE_LISTENERS, node.location());
        }
        validateService();
    }

    public boolean isErrorOccurred() {
        return this.errorOccurred;
    }

    private void validateService() {
        ServiceDeclarationNode serviceDeclarationNode = (ServiceDeclarationNode) this.context.node();
        serviceDeclarationNode.metadata();
        for (Node node : serviceDeclarationNode.members()) {
            validateServiceMember(node);
        }
        if (!this.hasQueryType) {
            addDiagnostic(CompilationError.MISSING_RESOURCE_FUNCTIONS, serviceDeclarationNode.location());
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
                validateRemoteMethod(methodSymbol, location);
            }
        } else if (symbol.kind() == SymbolKind.RESOURCE_METHOD) {
            ResourceMethodSymbol resourceMethodSymbol = (ResourceMethodSymbol) symbol;
            validateRootServiceResourceMethod(resourceMethodSymbol, location);
        }
    }

    private void validateRootServiceResourceMethod(ResourceMethodSymbol methodSymbol, Location location) {
        String accessor = getAccessor(methodSymbol);
        if (RESOURCE_FUNCTION_SUBSCRIBE.equals(accessor)) {
            validateSubscribeResource(methodSymbol, location);
        } else if (RESOURCE_FUNCTION_GET.equals(accessor)) {
            this.hasQueryType = true;
            validateGetResource(methodSymbol, location);
        } else {
            Location accessorLocation = getLocation(methodSymbol, location);
            addDiagnostic(CompilationError.INVALID_ROOT_RESOURCE_ACCESSOR, accessorLocation);
        }
    }

    private void validateResourceMethod(ResourceMethodSymbol methodSymbol, Location location) {
        String accessor = getAccessor(methodSymbol);
        if (!RESOURCE_FUNCTION_GET.equals(accessor)) {
            Location accessorLocation = getLocation(methodSymbol, location);
            addDiagnostic(CompilationError.INVALID_RESOURCE_FUNCTION_ACCESSOR, accessorLocation);
        }
        validateGetResource(methodSymbol, location);
    }

    private void validateGetResource(ResourceMethodSymbol methodSymbol, Location location) {
        validateResourcePath(methodSymbol, location);
        validateMethod(methodSymbol, location);
    }

    private void validateSubscribeResource(ResourceMethodSymbol methodSymbol, Location location) {
        ResourcePath resourcePath = methodSymbol.resourcePath();
        if (resourcePath.kind() == ResourcePath.Kind.PATH_SEGMENT_LIST) {
            PathSegmentList pathSegmentList = (PathSegmentList) resourcePath;
            if (pathSegmentList.list().size() > 1) {
                addDiagnostic(CompilationError.INVALID_HIERARCHICAL_RESOURCE_PATH, location);
            } else {
                validateResourcePathSegment(location, pathSegmentList.list().get(0));
            }
        } else {
            addDiagnostic(CompilationError.INVALID_RESOURCE_PATH, location);
        }
        validateSubscriptionMethod(methodSymbol, location);
        validateInputParameters(methodSymbol, location);
    }

    private void validateSubscriptionMethod(MethodSymbol methodSymbol, Location location) {
        if (methodSymbol.typeDescriptor().returnTypeDescriptor().isEmpty()) {
            return;
        }
        TypeSymbol returnTypeSymbol = methodSymbol.typeDescriptor().returnTypeDescriptor().get();
        if (returnTypeSymbol.typeKind() == TypeDescKind.UNION) {
            List<TypeSymbol> effectiveTypes = getEffectiveTypes((UnionTypeSymbol) returnTypeSymbol);
            if (effectiveTypes.size() != 1) {
                addDiagnostic(CompilationError.INVALID_SUBSCRIBE_RESOURCE_RETURN_TYPE, location);
                return;
            } else {
                returnTypeSymbol = effectiveTypes.get(0);
            }
        }

        if (returnTypeSymbol.typeKind() != TypeDescKind.STREAM) {
            addDiagnostic(CompilationError.INVALID_SUBSCRIBE_RESOURCE_RETURN_TYPE, location);
        } else {
            StreamTypeSymbol typeSymbol = (StreamTypeSymbol) returnTypeSymbol;
            validateReturnType(typeSymbol.typeParameter(), location);
        }
    }

    private void validateRemoteMethod(MethodSymbol methodSymbol, Location location) {
        if (methodSymbol.getName().isEmpty()) {
            return;
        }
        if (isInvalidFieldName(methodSymbol.getName().get())) {
            addDiagnostic(CompilationError.INVALID_FIELD_NAME, location);
        }
        validateMethod(methodSymbol, location);
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
        if (resourcePath.kind() == ResourcePath.Kind.PATH_SEGMENT_LIST) {
            PathSegmentList pathSegmentList = (PathSegmentList) resourcePath;
            for (PathSegment pathSegment : pathSegmentList.list()) {
                validateResourcePathSegment(location, pathSegment);
            }
        } else {
            addDiagnostic(CompilationError.INVALID_RESOURCE_PATH, location);
        }
    }

    private void validateResourcePathSegment(Location location, PathSegment pathSegment) {
        if (pathSegment.pathSegmentKind() == PathSegment.Kind.NAMED_SEGMENT) {
            if (isInvalidFieldName(pathSegment.signature())) {
                addDiagnostic(CompilationError.INVALID_FIELD_NAME, location);
            }
        } else {
            addDiagnostic(CompilationError.INVALID_PATH_PARAMETERS, location);
        }
    }

    private void validateReturnType(TypeSymbol typeSymbol, Location location) {
        if (this.existingInputObjectTypes.contains(typeSymbol)) {
            addDiagnostic(CompilationError.INVALID_RETURN_TYPE_INPUT_OBJECT, location);
        } else if (typeSymbol.typeKind() == TypeDescKind.ANY || typeSymbol.typeKind() == TypeDescKind.ANYDATA) {
            addDiagnostic(CompilationError.INVALID_RETURN_TYPE_ANY, location);
        } else if (typeSymbol.typeKind() == TypeDescKind.UNION) {
            validateReturnTypeUnion((UnionTypeSymbol) typeSymbol, location);
        } else if (typeSymbol.typeKind() == TypeDescKind.ARRAY) {
            ArrayTypeSymbol arrayTypeSymbol = (ArrayTypeSymbol) typeSymbol;
            validateReturnType(arrayTypeSymbol.memberTypeDescriptor(), location);
        } else if (typeSymbol.typeKind() == TypeDescKind.TYPE_REFERENCE) {
            validateReturnTypeReference((TypeReferenceTypeSymbol) typeSymbol, location);
        } else if (typeSymbol.typeKind() == TypeDescKind.INTERSECTION) {
            TypeSymbol effectiveType = getEffectiveType((IntersectionTypeSymbol) typeSymbol);
            if (effectiveType == null) {
                addDiagnostic(CompilationError.INVALID_INTERSECTION_TYPE, location);
            } else {
                validateReturnType(effectiveType, location);
            }
        } else if (typeSymbol.typeKind() == TypeDescKind.NIL) {
            addDiagnostic(CompilationError.INVALID_RETURN_TYPE_NIL, location);
        } else if (typeSymbol.typeKind() == TypeDescKind.ERROR) {
            addDiagnostic(CompilationError.INVALID_RETURN_TYPE_ERROR, location);
        } else if (hasInvalidReturnType(typeSymbol)) {
            addDiagnostic(CompilationError.INVALID_RETURN_TYPE, location);
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

    private void validateReturnTypeClass(ClassSymbol classSymbol, Location location) {
        if (classSymbol.getName().isEmpty()) {
            return;
        }
        Location classSymbolLocation = getLocation(classSymbol, location);
        String className = classSymbol.getName().get();
        if (isServiceClass(classSymbol)) {
            if (this.interfaceFinder.isPossibleInterface(className)) {
                validateInterfaces(className, classSymbol, location);
            }
            validateServiceClassDefinition(classSymbol, classSymbolLocation);
        } else {
            addDiagnostic(CompilationError.INVALID_RETURN_TYPE, classSymbolLocation);
        }
    }

    private void validateInterfaces(String className, ClassSymbol classSymbol, Location location) {
        if (!isDistinctServiceClass(classSymbol)) {
            addDiagnostic(CompilationError.NON_DISTINCT_INTERFACE_CLASS, location, className);
            return;
        }
        for (ClassSymbol childClass : this.interfaceFinder.getImplementations(className)) {
            if (childClass.getName().isEmpty()) {
                continue;
            }
            String childClassName = childClass.getName().get();
            if (!isDistinctServiceClass(childClass)) {
                addDiagnostic(CompilationError.NON_DISTINCT_INTERFACE_IMPLEMENTATION, location, childClassName);
                return;
            }
            if (!this.interfaceFinder.isValidInterfaceImplementation(classSymbol, childClass)) {
                addDiagnostic(CompilationError.INTERFACE_IMPLEMENTATION_MISSING_RESOURCE, location, className,
                              childClassName);
            } else {
                this.interfaceFinder.addValidInterface(className);
                validateReturnTypeClass(childClass, location);
            }
        }
    }

    private void validateReturnTypeDefinition(TypeReferenceTypeSymbol typeReferenceTypeSymbol, Location location) {
        TypeDefinitionSymbol typeDefinitionSymbol = (TypeDefinitionSymbol) typeReferenceTypeSymbol.definition();
        if (typeReferenceTypeSymbol.typeDescriptor().typeKind() == TypeDescKind.RECORD) {
            if (this.existingInputObjectTypes.contains(typeReferenceTypeSymbol.typeDescriptor())) {
                addDiagnostic(CompilationError.INVALID_RETURN_TYPE_INPUT_OBJECT, location);
            } else {
                if (this.existingReturnTypes.contains(typeReferenceTypeSymbol.typeDescriptor())) {
                    return;
                }
                this.existingReturnTypes.add(typeReferenceTypeSymbol.typeDescriptor());
                validateRecordFields((RecordTypeSymbol) typeDefinitionSymbol.typeDescriptor(), location);
            }
        } else {
            validateReturnType(typeDefinitionSymbol.typeDescriptor(), location);
        }
    }

    private void validateInputParameters(MethodSymbol methodSymbol, Location location) {
        FunctionTypeSymbol functionTypeSymbol = methodSymbol.typeDescriptor();
        if (functionTypeSymbol.params().isPresent()) {
            int i = 0;
            for (ParameterSymbol parameterSymbol : functionTypeSymbol.params().get()) {
                Location inputLocation = getLocation(parameterSymbol, location);
                TypeSymbol parameterTypeSymbol = parameterSymbol.typeDescriptor();
                if (isContextParameter(parameterTypeSymbol)) {
                    if (i != 0) {
                        addDiagnostic(CompilationError.INVALID_LOCATION_FOR_CONTEXT_PARAMETER, inputLocation);
                    }
                } else {
                    validateInputParameterType(parameterSymbol.typeDescriptor(), inputLocation,
                                               isResourceMethod(methodSymbol));
                }
                i++;
            }
        }
    }

    private void validateInputParameterType(TypeSymbol typeSymbol, Location location, boolean isResourceMethod) {
        if (isFileUploadParameter(typeSymbol)) {
            if (this.arrayDimension > 1) {
                addDiagnostic(CompilationError.MULTI_DIMENSIONAL_UPLOAD_ARRAY, location);
            }
            if (isResourceMethod) {
                addDiagnostic(CompilationError.INVALID_FILE_UPLOAD_IN_RESOURCE_FUNCTION, location);
            }
        } else {
            validateInputType(typeSymbol, location, isResourceMethod);
        }
    }

    private void validateInputType(TypeSymbol typeSymbol, Location location, boolean isResourceMethod) {
        if (typeSymbol.typeKind() == TypeDescKind.UNION) {
            validateInputParameterType((UnionTypeSymbol) typeSymbol, location, isResourceMethod);
        } else if (typeSymbol.typeKind() == TypeDescKind.TYPE_REFERENCE) {
            validateInputParameterType((TypeReferenceTypeSymbol) typeSymbol, location, isResourceMethod);
        } else if (typeSymbol.typeKind() == TypeDescKind.ARRAY) {
            validateInputParameterType((ArrayTypeSymbol) typeSymbol, location, isResourceMethod);
        } else if (typeSymbol.typeKind() == TypeDescKind.INTERSECTION) {
            validateInputParameterType((IntersectionTypeSymbol) typeSymbol, location, isResourceMethod);
        } else if (typeSymbol.typeKind() == TypeDescKind.RECORD) {
            validateInputParameterType((RecordTypeSymbol) typeSymbol, location, isResourceMethod);
        } else if (typeSymbol.typeKind() == TypeDescKind.UNION) {
            validateInputParameterType((UnionTypeSymbol) typeSymbol, location, isResourceMethod);
        } else if (!isPrimitiveType(typeSymbol)) {
            addDiagnostic(CompilationError.INVALID_INPUT_PARAMETER_TYPE, location,
                          typeSymbol.getName().orElse(typeSymbol.typeKind().getName()));
        }
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
        validateInputParameterType(typeDescriptor, location, isResourceMethod);
    }

    private void validateInputParameterType(UnionTypeSymbol unionTypeSymbol, Location location,
                                            boolean isResourceMethod) {
        boolean foundDataType = false;
        int dataTypeCount = 0;
        for (TypeSymbol memberType : unionTypeSymbol.userSpecifiedMemberTypes()) {
            if (memberType.typeKind() != TypeDescKind.ERROR && memberType.typeKind() != TypeDescKind.NIL) {
                foundDataType = true;
                dataTypeCount++;
                if (memberType.typeKind() != TypeDescKind.SINGLETON) {
                    validateInputParameterType(memberType, location, isResourceMethod);
                }
            }
        }
        if (!foundDataType) {
            addDiagnostic(CompilationError.INVALID_INPUT_TYPE, location);
        } else if (dataTypeCount > 1) {
            addDiagnostic(CompilationError.INVALID_INPUT_TYPE_UNION, location);
        }
    }

    private void validateInputParameterType(IntersectionTypeSymbol intersectionTypeSymbol, Location location,
                                            boolean isResourceMethod) {
        TypeSymbol effectiveType = getEffectiveType(intersectionTypeSymbol);
        if (effectiveType == null) {
            addDiagnostic(CompilationError.INVALID_INTERSECTION_TYPE, location);
        } else {
            validateInputParameterType(effectiveType, location, isResourceMethod);
        }
    }

    private void validateInputParameterType(RecordTypeSymbol recordTypeSymbol, Location location,
                                            boolean isResourceMethod) {
        if (this.existingReturnTypes.contains(recordTypeSymbol)) {
            addDiagnostic(CompilationError.INVALID_RESOURCE_INPUT_OBJECT_PARAM, location);
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

    private boolean hasInvalidReturnType(TypeSymbol typeSymbol) {
        return typeSymbol.typeKind() == TypeDescKind.MAP || typeSymbol.typeKind() == TypeDescKind.JSON ||
                typeSymbol.typeKind() == TypeDescKind.BYTE || typeSymbol.typeKind() == TypeDescKind.OBJECT ||
                typeSymbol.typeKind() == TypeDescKind.STREAM;
    }

    private void validateServiceClassDefinition(ClassSymbol classSymbol, Location location) {
        if (this.visitedClassSymbols.contains(classSymbol)) {
            return;
        }
        this.visitedClassSymbols.add(classSymbol);
        boolean resourceMethodFound = false;
        for (MethodSymbol methodSymbol : classSymbol.methods().values()) {
            Location methodLocation = getLocation(methodSymbol, location);
            if (methodSymbol.kind() == SymbolKind.RESOURCE_METHOD) {
                resourceMethodFound = true;
                validateResourceMethod((ResourceMethodSymbol) methodSymbol, methodLocation);
            } else if (isRemoteMethod(methodSymbol)) {
                addDiagnostic(CompilationError.INVALID_FUNCTION, methodLocation);
            }
        }
        if (!resourceMethodFound) {
            addDiagnostic(CompilationError.MISSING_RESOURCE_FUNCTIONS, location);
        }
    }

    private void validateReturnTypeUnion(UnionTypeSymbol unionTypeSymbol, Location location) {
        List<TypeSymbol> effectiveTypes = getEffectiveTypes(unionTypeSymbol);
        if (effectiveTypes.isEmpty()) {
            addDiagnostic(CompilationError.INVALID_RETURN_TYPE_ERROR_OR_NIL, location);
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
            addDiagnostic(CompilationError.INVALID_UNION_MEMBER_TYPE, location);
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
            validateReturnType(recordField.typeDescriptor(), location);
            if (isInvalidFieldName(recordField.getName().get())) {
                addDiagnostic(CompilationError.INVALID_FIELD_NAME, location);
            }
        }
    }

    private void addDiagnostic(CompilationError compilationError, Location location) {
        this.errorOccurred = true;
        updateContext(this.context, compilationError, location);
    }

    private void addDiagnostic(CompilationError compilationError, Location location, Object... args) {
        this.errorOccurred = true;
        updateContext(this.context, compilationError, location, args);
    }
}
