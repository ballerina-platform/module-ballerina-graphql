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

package io.ballerina.stdlib.graphql.compiler.validator;

import io.ballerina.compiler.api.symbols.ArrayTypeSymbol;
import io.ballerina.compiler.api.symbols.ClassSymbol;
import io.ballerina.compiler.api.symbols.FunctionTypeSymbol;
import io.ballerina.compiler.api.symbols.IntersectionTypeSymbol;
import io.ballerina.compiler.api.symbols.MethodSymbol;
import io.ballerina.compiler.api.symbols.ParameterSymbol;
import io.ballerina.compiler.api.symbols.Qualifier;
import io.ballerina.compiler.api.symbols.RecordFieldSymbol;
import io.ballerina.compiler.api.symbols.RecordTypeSymbol;
import io.ballerina.compiler.api.symbols.ResourceMethodSymbol;
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
import io.ballerina.stdlib.graphql.compiler.validator.errors.CompilationError;
import io.ballerina.tools.diagnostics.Location;

import java.util.ArrayList;
import java.util.HashSet;
import java.util.List;
import java.util.Map;
import java.util.Set;

import static io.ballerina.stdlib.graphql.compiler.Utils.CONTEXT_IDENTIFIER;
import static io.ballerina.stdlib.graphql.compiler.Utils.FILE_UPLOAD_IDENTIFIER;
import static io.ballerina.stdlib.graphql.compiler.Utils.getEffectiveType;
import static io.ballerina.stdlib.graphql.compiler.Utils.getEffectiveTypes;
import static io.ballerina.stdlib.graphql.compiler.Utils.isDistinctServiceReference;
import static io.ballerina.stdlib.graphql.compiler.Utils.isGraphqlModuleSymbol;
import static io.ballerina.stdlib.graphql.compiler.Utils.isPrimitiveType;
import static io.ballerina.stdlib.graphql.compiler.Utils.isRemoteFunction;
import static io.ballerina.stdlib.graphql.compiler.validator.ValidatorUtils.RESOURCE_FUNCTION_GET;
import static io.ballerina.stdlib.graphql.compiler.validator.ValidatorUtils.getLocation;
import static io.ballerina.stdlib.graphql.compiler.validator.ValidatorUtils.isInvalidFieldName;
import static io.ballerina.stdlib.graphql.compiler.validator.ValidatorUtils.updateContext;

/**
 * Validate functions in Ballerina GraphQL services.
 */
public class ServiceValidator {
    private final Set<ClassSymbol> visitedClassSymbols = new HashSet<>();
    private final List<TypeSymbol> existingInputObjectTypes = new ArrayList<>();
    private final List<TypeSymbol> existingReturnTypes = new ArrayList<>();
    private SyntaxNodeAnalysisContext context;
    private int arrayDimension = 0;

    public void initialize(SyntaxNodeAnalysisContext context) {
        this.context = context;
    }

    public void validate() {
        ServiceDeclarationNode serviceDeclarationNode = (ServiceDeclarationNode) this.context.node();
        boolean resourceFunctionFound = false;
        for (Node node : serviceDeclarationNode.members()) {
            if (this.context.semanticModel().symbol(node).isEmpty()) {
                continue;
            }
            Symbol symbol = this.context.semanticModel().symbol(node).get();
            Location location = node.location();
            if (symbol.kind() == SymbolKind.METHOD) {
                MethodSymbol methodSymbol = (MethodSymbol) symbol;
                if (isRemoteFunction(methodSymbol)) {
                    validateMethod(methodSymbol, location, false);
                }
            } else if (symbol.kind() == SymbolKind.RESOURCE_METHOD) {
                ResourceMethodSymbol resourceMethodSymbol = (ResourceMethodSymbol) symbol;
                resourceFunctionFound = true;
                validateResourceMethod(resourceMethodSymbol, location);
            }
        }
        this.existingInputObjectTypes.clear();
        this.existingReturnTypes.clear();
        if (!resourceFunctionFound) {
            updateContext(this.context, CompilationError.MISSING_RESOURCE_FUNCTIONS, serviceDeclarationNode.location());
        }
    }

    private void validateResourceMethod(ResourceMethodSymbol methodSymbol, Location location) {
        validateResourceAccessorName(methodSymbol, location);
        validateResourcePath(methodSymbol, location);
        validateMethod(methodSymbol, location, true);
    }

    private void validateMethod(MethodSymbol methodSymbol, Location location, boolean isResourceMethod) {
        if (methodSymbol.typeDescriptor().returnTypeDescriptor().isPresent()) {
            TypeSymbol returnTypeSymbol = methodSymbol.typeDescriptor().returnTypeDescriptor().get();
            validateReturnType(returnTypeSymbol, location);
        }
        validateInputParameters(methodSymbol, location, isResourceMethod);
    }

    private void validateResourceAccessorName(MethodSymbol methodSymbol, Location location) {
        if (methodSymbol.kind() == SymbolKind.RESOURCE_METHOD) {
            ResourceMethodSymbol resourceMethodSymbol = (ResourceMethodSymbol) methodSymbol;
            if (resourceMethodSymbol.getName().isPresent()) {
                if (!resourceMethodSymbol.getName().get().equals(RESOURCE_FUNCTION_GET)) {
                    Location accessorLocation = getLocation(resourceMethodSymbol, location);
                    updateContext(this.context, CompilationError.INVALID_RESOURCE_FUNCTION_ACCESSOR, accessorLocation);
                }
            } else {
                Location accessorLocation = getLocation(resourceMethodSymbol, location);
                updateContext(this.context, CompilationError.INVALID_RESOURCE_FUNCTION_ACCESSOR, accessorLocation);
            }
        }
    }

    private void validateResourcePath(ResourceMethodSymbol resourceMethodSymbol, Location location) {
        ResourcePath resourcePath = resourceMethodSymbol.resourcePath();
        if (resourcePath.kind() == ResourcePath.Kind.PATH_SEGMENT_LIST) {
            PathSegmentList pathSegmentList = (PathSegmentList) resourcePath;
            for (PathSegment pathSegment : pathSegmentList.list()) {
                validateResourcePathSegment(location, pathSegment);
            }
        } else {
            updateContext(this.context, CompilationError.MISSING_RESOURCE_NAME, location);
        }
    }

    private void validateResourcePathSegment(Location location, PathSegment pathSegment) {
        if (pathSegment.pathSegmentKind() == PathSegment.Kind.NAMED_SEGMENT) {
            if (isInvalidFieldName(pathSegment.signature())) {
                updateContext(this.context, CompilationError.INVALID_FIELD_NAME, location);
            }
        } else {
            updateContext(this.context, CompilationError.INVALID_PATH_PARAMETERS, location);
        }
    }

    private void validateReturnType(TypeSymbol typeSymbol, Location location) {
        if (this.existingInputObjectTypes.contains(typeSymbol)) {
            updateContext(this.context, CompilationError.INVALID_RETURN_TYPE_INPUT_OBJECT, location);
        } else if (typeSymbol.typeKind() == TypeDescKind.ANY || typeSymbol.typeKind() == TypeDescKind.ANYDATA) {
            updateContext(this.context, CompilationError.INVALID_RETURN_TYPE_ANY, location);
        } else if (typeSymbol.typeKind() == TypeDescKind.UNION) {
            validateReturnTypeUnion((UnionTypeSymbol) typeSymbol, location);
        } else if (typeSymbol.typeKind() == TypeDescKind.ARRAY) {
            ArrayTypeSymbol arrayTypeSymbol = (ArrayTypeSymbol) typeSymbol;
            validateReturnType(arrayTypeSymbol.memberTypeDescriptor(), location);
        } else if (typeSymbol.typeKind() == TypeDescKind.TYPE_REFERENCE) {
            validateReturnTypeDefinitions((TypeReferenceTypeSymbol) typeSymbol, location);
        } else if (typeSymbol.typeKind() == TypeDescKind.INTERSECTION) {
            TypeSymbol effectiveType = getEffectiveType((IntersectionTypeSymbol) typeSymbol, location);
            if (effectiveType == null) {
                updateContext(this.context, CompilationError.INVALID_INTERSECTION_Type, location);
            } else {
                validateReturnType(effectiveType, location);
            }
        } else if (typeSymbol.typeKind() == TypeDescKind.NIL) {
            updateContext(this.context, CompilationError.INVALID_RETURN_TYPE_NIL, location);
        } else if (typeSymbol.typeKind() == TypeDescKind.ERROR) {
            updateContext(this.context, CompilationError.INVALID_RETURN_TYPE_ERROR, location);
        } else if (hasInvalidReturnType(typeSymbol)) {
            updateContext(this.context, CompilationError.INVALID_RETURN_TYPE, location);
        }
    }

    private void validateReturnTypeDefinitions(TypeReferenceTypeSymbol typeReferenceTypeSymbol, Location location) {
        if (typeReferenceTypeSymbol.definition().kind() == SymbolKind.TYPE_DEFINITION) {
            TypeDefinitionSymbol typeDefinitionSymbol = (TypeDefinitionSymbol) typeReferenceTypeSymbol.definition();
            if (typeReferenceTypeSymbol.typeDescriptor().typeKind() == TypeDescKind.RECORD) {
                if (this.existingInputObjectTypes.contains(typeReferenceTypeSymbol.typeDescriptor())) {
                    updateContext(this.context, CompilationError.INVALID_RETURN_TYPE_INPUT_OBJECT, location);
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
        } else if (typeReferenceTypeSymbol.definition().kind() == SymbolKind.CLASS) {
            ClassSymbol classSymbol = (ClassSymbol) typeReferenceTypeSymbol.definition();
            Location classSymbolLocation = getLocation(classSymbol, location);
            if (!classSymbol.qualifiers().contains(Qualifier.SERVICE)) {
                updateContext(this.context, CompilationError.INVALID_RETURN_TYPE, classSymbolLocation);
            } else {
                validateServiceClassDefinition(classSymbol, classSymbolLocation);
            }
        }
    }

    private void validateInputParameters(MethodSymbol methodSymbol, Location location, boolean isResourceMethod) {
        FunctionTypeSymbol functionTypeSymbol = methodSymbol.typeDescriptor();
        if (functionTypeSymbol.params().isPresent()) {
            int i = 0;
            for (ParameterSymbol parameterSymbol : functionTypeSymbol.params().get()) {
                Location inputLocation = getLocation(parameterSymbol, location);
                TypeSymbol parameterTypeSymbol = parameterSymbol.typeDescriptor();
                if (isContextParameter(parameterTypeSymbol)) {
                    if (i != 0) {
                        updateContext(this.context, CompilationError.INVALID_LOCATION_FOR_CONTEXT_PARAMETER,
                                      inputLocation);
                    }
                } else {
                    validateInputParameterType(parameterSymbol.typeDescriptor(), inputLocation, isResourceMethod);
                }
                i++;
            }
        }
    }

    private void validateInputParameterType(TypeSymbol typeSymbol, Location location, boolean isResourceMethod) {
        if (isFileUploadParameter(typeSymbol)) {
            if (this.arrayDimension > 1) {
                updateContext(this.context, CompilationError.MULTI_DIMENSIONAL_UPLOAD_ARRAY, location);
            }
            if (isResourceMethod) {
                updateContext(this.context, CompilationError.INVALID_FILE_UPLOAD_IN_RESOURCE_FUNCTION, location);
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
            updateContext(this.context, CompilationError.INVALID_INPUT_PARAMETER_TYPE, location,
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
            updateContext(this.context, CompilationError.INVALID_INPUT_TYPE, location);
        } else if (dataTypeCount > 1) {
            updateContext(this.context, CompilationError.INVALID_INPUT_TYPE_UNION, location);
        }
    }

    private void validateInputParameterType(IntersectionTypeSymbol intersectionTypeSymbol, Location location,
                                            boolean isResourceMethod) {
        TypeSymbol effectiveType = getEffectiveType(intersectionTypeSymbol, location);
        if (effectiveType == null) {
            updateContext(this.context, CompilationError.INVALID_INTERSECTION_Type, location);
        } else {
            validateInputParameterType(effectiveType, location, isResourceMethod);
        }
    }

    private void validateInputParameterType(RecordTypeSymbol recordTypeSymbol, Location location,
                                            boolean isResourceMethod) {
        if (this.existingReturnTypes.contains(recordTypeSymbol)) {
            updateContext(this.context, CompilationError.INVALID_RESOURCE_INPUT_OBJECT_PARAM, location);
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
        if (!this.visitedClassSymbols.contains(classSymbol)) {
            this.visitedClassSymbols.add(classSymbol);
            boolean resourceMethodFound = false;
            Map<String, MethodSymbol> methods = classSymbol.methods();
            for (MethodSymbol methodSymbol : methods.values()) {
                Location methodLocation = getLocation(methodSymbol, location);
                if (methodSymbol.kind() == SymbolKind.RESOURCE_METHOD) {
                    resourceMethodFound = true;
                    validateResourceMethod((ResourceMethodSymbol) methodSymbol, methodLocation);
                } else if (isRemoteFunction(methodSymbol)) {
                    updateContext(this.context, CompilationError.INVALID_FUNCTION, methodLocation);
                }
            }
            if (!resourceMethodFound) {
                updateContext(this.context, CompilationError.MISSING_RESOURCE_FUNCTIONS, location);
            }
        }
    }

    private void validateReturnTypeUnion(UnionTypeSymbol unionTypeSymbol, Location location) {
        List<TypeSymbol> effectiveTypes = getEffectiveTypes(unionTypeSymbol);
        if (effectiveTypes.isEmpty()) {
            updateContext(this.context, CompilationError.INVALID_RETURN_TYPE_ERROR_OR_NIL, location);
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
            updateContext(this.context, CompilationError.INVALID_UNION_MEMBER_TYPE, location);
        } else {
            validateReturnType(memberType, location);
        }
    }

    private void validateRecordFields(RecordTypeSymbol recordTypeSymbol, Location location) {
        Map<String, RecordFieldSymbol> recordFieldSymbolMap = recordTypeSymbol.fieldDescriptors();
        for (RecordFieldSymbol recordField : recordFieldSymbolMap.values()) {
            validateReturnType(recordField.typeDescriptor(), location);
            if (isInvalidFieldName(recordField.getName().orElse(""))) {
                updateContext(this.context, CompilationError.INVALID_FIELD_NAME, location);
            }
        }
    }

    private boolean isContextParameter(TypeSymbol typeSymbol) {
        if (typeSymbol.getName().isEmpty()) {
            return false;
        }
        if (!isGraphqlModuleSymbol(typeSymbol)) {
            return false;
        }
        return CONTEXT_IDENTIFIER.equals(typeSymbol.getName().get());
    }

    private boolean isFileUploadParameter(TypeSymbol typeSymbol) {
        if (typeSymbol.getName().isEmpty()) {
            return false;
        }
        if (!isGraphqlModuleSymbol(typeSymbol)) {
            return false;
        }
        return FILE_UPLOAD_IDENTIFIER.equals(typeSymbol.getName().get());
    }
}
