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

import io.ballerina.compiler.api.symbols.ArrayTypeSymbol;
import io.ballerina.compiler.api.symbols.ClassSymbol;
import io.ballerina.compiler.api.symbols.ConstantSymbol;
import io.ballerina.compiler.api.symbols.EnumSymbol;
import io.ballerina.compiler.api.symbols.IntersectionTypeSymbol;
import io.ballerina.compiler.api.symbols.MethodSymbol;
import io.ballerina.compiler.api.symbols.ParameterSymbol;
import io.ballerina.compiler.api.symbols.RecordFieldSymbol;
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
import io.ballerina.compiler.api.symbols.resourcepath.PathSegmentList;
import io.ballerina.compiler.api.symbols.resourcepath.ResourcePath;
import io.ballerina.compiler.api.symbols.resourcepath.util.PathSegment;
import io.ballerina.compiler.syntax.tree.ServiceDeclarationNode;
import io.ballerina.projects.plugins.SyntaxNodeAnalysisContext;
import io.ballerina.stdlib.graphql.compiler.schema.types.EnumValue;
import io.ballerina.stdlib.graphql.compiler.schema.types.Type;
import io.ballerina.stdlib.graphql.compiler.schema.types.TypeKind;
import io.ballerina.stdlib.graphql.compiler.schema.types.defaults.DefaultType;
import io.ballerina.stdlib.graphql.compiler.schema.types.defaults.Description;
import io.ballerina.stdlib.graphql.compiler.service.InterfaceFinder;

import java.util.HashMap;
import java.util.List;
import java.util.Map;

import static io.ballerina.stdlib.graphql.compiler.Utils.getEffectiveType;
import static io.ballerina.stdlib.graphql.compiler.Utils.getEffectiveTypes;
import static io.ballerina.stdlib.graphql.compiler.Utils.isRemoteMethod;
import static io.ballerina.stdlib.graphql.compiler.Utils.isResourceMethod;
import static io.ballerina.stdlib.graphql.compiler.schema.generator.GeneratorUtils.getDeprecationReason;
import static io.ballerina.stdlib.graphql.compiler.schema.generator.GeneratorUtils.getDescription;
import static io.ballerina.stdlib.graphql.compiler.schema.generator.GeneratorUtils.getTypeName;

/**
 * Finds the GraphQL types associated with a Ballerina service.
 */
public class TypeFinder {
    private final Map<String, Type> typeMap;
    private final InterfaceFinder interfaceFinder;

    public TypeFinder(InterfaceFinder interfaceFinder) {
        this.typeMap = new HashMap<>();
        this.interfaceFinder = interfaceFinder;
    }

    public Map<String, Type> getTypeMap() {
        return this.typeMap;
    }

    public void findTypes(SyntaxNodeAnalysisContext context) {
        ServiceDeclarationNode node = (ServiceDeclarationNode) context.node();
        // Ignore calling `get` without `isPresent` as it is already checked in the previous validation.
        @SuppressWarnings("OptionalGetWithoutIsPresent")
        ServiceDeclarationSymbol symbol = (ServiceDeclarationSymbol) context.semanticModel().symbol(node).get();
        for (MethodSymbol methodSymbol : symbol.methods().values()) {
            if (isResourceMethod(methodSymbol)) {
                findTypes((ResourceMethodSymbol) methodSymbol);
            } else if (isRemoteMethod(methodSymbol)) {
                findTypes(methodSymbol);
            }
        }
    }

    private void findTypes(ResourceMethodSymbol methodSymbol) {
        ResourcePath resourcePath = methodSymbol.resourcePath();
        if (resourcePath.kind() == ResourcePath.Kind.PATH_SEGMENT_LIST) {
            findTypes((PathSegmentList) resourcePath);
        }
        findTypes((MethodSymbol) methodSymbol);
    }

    private void findTypes(MethodSymbol methodSymbol) {
        if (methodSymbol.typeDescriptor().returnTypeDescriptor().isPresent()) {
            findTypes(methodSymbol.typeDescriptor().returnTypeDescriptor().get());
        }
        if (methodSymbol.typeDescriptor().params().isPresent()) {
            for (ParameterSymbol parameterSymbol : methodSymbol.typeDescriptor().params().get()) {
                findInputTypes(parameterSymbol.typeDescriptor());
            }
        }
    }

    private void findTypes(PathSegmentList pathSegmentList) {
        if (pathSegmentList.list().size() > 1) {
            for (int i = 0; i < pathSegmentList.list().size() - 1; i++) {
                PathSegment pathSegment = pathSegmentList.list().get(i);
                String name = pathSegment.signature();
                addType(name, TypeKind.OBJECT, null, null);
            }
        }
    }

    private void findTypes(TypeSymbol typeSymbol) {
        String typeName = getTypeName(typeSymbol);
        if (this.typeMap.containsKey(typeName)) {
            return;
        }
        switch (typeSymbol.typeKind()) {
            case STRING:
            case STRING_CHAR:
                addDefaultType(DefaultType.STRING, typeSymbol);
                break;
            case INT:
                addDefaultType(DefaultType.INT, typeSymbol);
                break;
            case FLOAT:
                addDefaultType(DefaultType.FLOAT, typeSymbol);
                break;
            case BOOLEAN:
                addDefaultType(DefaultType.BOOLEAN, typeSymbol);
                break;
            case DECIMAL:
                addDefaultType(DefaultType.DECIMAL, typeSymbol);
                break;
            case TYPE_REFERENCE:
                findTypes((TypeReferenceTypeSymbol) typeSymbol, typeName);
                break;
            case ARRAY:
                findTypes((ArrayTypeSymbol) typeSymbol);
                break;
            case UNION:
                findTypes((UnionTypeSymbol) typeSymbol, typeName, null);
                break;
            case INTERSECTION:
                findTypes((IntersectionTypeSymbol) typeSymbol, null, null);
                break;
        }
    }

    private void findTypes(TypeReferenceTypeSymbol typeReferenceTypeSymbol, String typeName) {
        if (typeReferenceTypeSymbol.getName().isEmpty()) {
            return;
        }
        Symbol definitionSymbol = typeReferenceTypeSymbol.definition();
        if (definitionSymbol.kind() == SymbolKind.TYPE_DEFINITION) {
            findTypes((TypeDefinitionSymbol) definitionSymbol, typeName);
        } else if (definitionSymbol.kind() == SymbolKind.CLASS) {
            findTypes((ClassSymbol) definitionSymbol, typeName);
        } else if (definitionSymbol.kind() == SymbolKind.ENUM) {
            findTypes((EnumSymbol) definitionSymbol, typeName);
        }
    }

    private void findTypes(TypeDefinitionSymbol typeDefinitionSymbol, String typeName) {
        String description = getDescription(typeDefinitionSymbol);
        if (typeDefinitionSymbol.typeDescriptor().typeKind() == TypeDescKind.RECORD) {
            addType(typeName, TypeKind.OBJECT, description, typeDefinitionSymbol.typeDescriptor());
            findTypes((RecordTypeSymbol) typeDefinitionSymbol.typeDescriptor());
        } else if (typeDefinitionSymbol.typeDescriptor().typeKind() == TypeDescKind.UNION) {
            findTypes((UnionTypeSymbol) typeDefinitionSymbol.typeDescriptor(), typeName, description);
        } else if (typeDefinitionSymbol.typeDescriptor().typeKind() == TypeDescKind.INTERSECTION) {
            findTypes((IntersectionTypeSymbol) typeDefinitionSymbol.typeDescriptor(), typeName, description);
        }
    }

    private Type findTypes(ClassSymbol classSymbol, String typeName) {
        String description = getDescription(classSymbol);
        Type type;
        if (this.interfaceFinder.isValidInterface(typeName)) {
            type = addType(typeName, TypeKind.INTERFACE, description, classSymbol);
            findTypesFromInterface(typeName, type);
        } else {
            type = addType(typeName, TypeKind.OBJECT, description, classSymbol);
        }

        for (MethodSymbol methodSymbol : classSymbol.methods().values()) {
            if (isResourceMethod(methodSymbol)) {
                findTypes((ResourceMethodSymbol) methodSymbol);
            } else if (isRemoteMethod(methodSymbol)) {
                findTypes(methodSymbol);
            }
        }
        return type;
    }

    private void findTypesFromInterface(String typeName, Type interfaceType) {
        List<ClassSymbol> implementations = this.interfaceFinder.getImplementations(typeName);
        for (ClassSymbol implementation : implementations) {
            // When adding an implementation, the name is already checked. Therefore, no need to check isEmpty().
            //noinspection OptionalGetWithoutIsPresent
            Type implementedType = findTypes(implementation, implementation.getName().get());
            interfaceType.addPossibleType(implementedType);
            implementedType.addInterface(interfaceType);
        }
    }

    private void findTypes(EnumSymbol enumSymbol, String typeName) {
        String description = getDescription(enumSymbol);
        Type enumType = addType(typeName, TypeKind.ENUM, description, enumSymbol.typeDescriptor());
        for (ConstantSymbol enumMember : enumSymbol.members()) {
            addEnumValueToType(enumType, enumMember);
        }
    }

    private void addEnumValueToType(Type type, ConstantSymbol enumMember) {
        String memberDescription = getDescription(enumMember);
        String name = enumMember.resolvedValue().orElse("");
        boolean isDeprecated = enumMember.deprecated();
        String deprecationReason = getDeprecationReason(enumMember);
        EnumValue enumValue = new EnumValue(name, memberDescription, isDeprecated, deprecationReason);
        type.addEnumValue(enumValue);
    }

    private void findTypes(RecordTypeSymbol recordTypeSymbol) {
        for (RecordFieldSymbol recordFieldSymbol : recordTypeSymbol.fieldDescriptors().values()) {
            findTypes(recordFieldSymbol.typeDescriptor());
        }
    }

    private void findTypes(ArrayTypeSymbol arrayTypeSymbol) {
        findTypes(arrayTypeSymbol.memberTypeDescriptor());
    }

    private void findTypes(UnionTypeSymbol unionTypeSymbol, String typeName, String description) {
        List<TypeSymbol> effectiveTypes = getEffectiveTypes(unionTypeSymbol);
        if (effectiveTypes.size() == 1) {
            findTypes(effectiveTypes.get(0));
            return;
        }

        typeName = typeName == null ? getTypeName(effectiveTypes) : typeName;
        description = description == null ? Description.GENERATED_UNION_TYPE.getDescription() : description;
        Type unionType = addType(typeName, TypeKind.UNION, description, unionTypeSymbol);

        for (TypeSymbol typeSymbol : effectiveTypes) {
            findTypes(typeSymbol);
            String memberTypeName = getTypeName(typeSymbol);
            if (memberTypeName == null) {
                continue;
            }
            Type memberType = this.typeMap.get(memberTypeName);
            unionType.addPossibleType(memberType);
        }
    }

    private void findTypes(IntersectionTypeSymbol intersectionTypeSymbol, String typeName, String description) {
        TypeSymbol effectiveType = getEffectiveType(intersectionTypeSymbol);
        if (typeName == null) {
            findTypes(effectiveType);
        } else {
            // TODO: Do we need to store the intersection type here?
            addType(typeName, TypeKind.OBJECT, description, effectiveType);
        }
    }

    private void findInputTypes(TypeSymbol typeSymbol) {
        String typeName = getTypeName(typeSymbol);
        if (this.typeMap.containsKey(typeName)) {
            return;
        }
        switch (typeSymbol.typeKind()) {
            case STRING:
            case STRING_CHAR:
                addDefaultType(DefaultType.STRING, typeSymbol);
                break;
            case INT:
                addDefaultType(DefaultType.INT, typeSymbol);
                break;
            case FLOAT:
                addDefaultType(DefaultType.FLOAT, typeSymbol);
                break;
            case BOOLEAN:
                addDefaultType(DefaultType.BOOLEAN, typeSymbol);
                break;
            case DECIMAL:
                addDefaultType(DefaultType.DECIMAL, typeSymbol);
                break;
            case TYPE_REFERENCE:
                findInputTypes((TypeReferenceTypeSymbol) typeSymbol, typeName);
                break;
            case ARRAY:
                findInputTypes((ArrayTypeSymbol) typeSymbol);
                break;
            case UNION:
                findInputTypes((UnionTypeSymbol) typeSymbol);
                break;
            case INTERSECTION:
                findInputTypes((IntersectionTypeSymbol) typeSymbol, null, null);
                break;
        }
    }

    private void findInputTypes(TypeReferenceTypeSymbol typeReferenceTypeSymbol, String typeName) {
        if (typeReferenceTypeSymbol.getName().isEmpty()) {
            return;
        }
        Symbol definitionSymbol = typeReferenceTypeSymbol.definition();
        if (definitionSymbol.kind() == SymbolKind.TYPE_DEFINITION) {
            findInputTypes((TypeDefinitionSymbol) definitionSymbol, typeName);
        } else if (definitionSymbol.kind() == SymbolKind.ENUM) {
            findTypes((EnumSymbol) definitionSymbol, typeName);
        }
    }

    private void findInputTypes(ArrayTypeSymbol arrayTypeSymbol) {
        findInputTypes(arrayTypeSymbol.memberTypeDescriptor());
    }

    private void findInputTypes(TypeDefinitionSymbol typeDefinitionSymbol, String typeName) {
        String description = getDescription(typeDefinitionSymbol);
        if (typeDefinitionSymbol.typeDescriptor().typeKind() == TypeDescKind.RECORD) {
            addType(typeName, TypeKind.INPUT_OBJECT, description, typeDefinitionSymbol.typeDescriptor());
            findInputTypes((RecordTypeSymbol) typeDefinitionSymbol.typeDescriptor());
        } else if (typeDefinitionSymbol.typeDescriptor().typeKind() == TypeDescKind.UNION) {
            findInputTypes((UnionTypeSymbol) typeDefinitionSymbol.typeDescriptor());
        } else if (typeDefinitionSymbol.typeDescriptor().typeKind() == TypeDescKind.INTERSECTION) {
            findInputTypes((IntersectionTypeSymbol) typeDefinitionSymbol.typeDescriptor(), typeName, description);
        }
    }

    private void findInputTypes(UnionTypeSymbol unionTypeSymbol) {
        List<TypeSymbol> effectiveTypes = getEffectiveTypes(unionTypeSymbol);
        for (TypeSymbol typeSymbol : effectiveTypes) {
            findInputTypes(typeSymbol);
        }
    }

    private void findInputTypes(IntersectionTypeSymbol intersectionTypeSymbol, String typeName, String description) {
        TypeSymbol effectiveType = getEffectiveType(intersectionTypeSymbol);
        if (typeName == null) {
            findInputTypes(effectiveType);
        } else {
            // TODO: Do we need to store the intersection type here?
            addType(typeName, TypeKind.INPUT_OBJECT, description, effectiveType);
        }
    }

    private void findInputTypes(RecordTypeSymbol recordTypeSymbol) {
        for (RecordFieldSymbol recordFieldSymbol : recordTypeSymbol.fieldDescriptors().values()) {
            findInputTypes(recordFieldSymbol.typeDescriptor());
        }
    }

    private void addDefaultType(DefaultType defaultType, TypeSymbol typeSymbol) {
        addType(defaultType.getName(), TypeKind.SCALAR, defaultType.getDescription(), typeSymbol);
    }

    private Type addType(String name, TypeKind typeKind, String description, TypeSymbol typeSymbol) {
        if (!this.typeMap.containsKey(name)) {
            Type type = new Type(name, typeKind, description, typeSymbol);
            this.typeMap.put(name, type);
            return type;
        }
        return this.typeMap.get(name);
    }
}
