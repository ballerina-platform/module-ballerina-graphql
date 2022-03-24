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
import io.ballerina.compiler.api.symbols.ParameterKind;
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
import io.ballerina.compiler.api.symbols.resourcepath.util.PathSegment;
import io.ballerina.stdlib.graphql.compiler.schema.types.Description;
import io.ballerina.stdlib.graphql.compiler.schema.types.EnumValue;
import io.ballerina.stdlib.graphql.compiler.schema.types.Field;
import io.ballerina.stdlib.graphql.compiler.schema.types.InputValue;
import io.ballerina.stdlib.graphql.compiler.schema.types.ScalarType;
import io.ballerina.stdlib.graphql.compiler.schema.types.Schema;
import io.ballerina.stdlib.graphql.compiler.schema.types.Type;
import io.ballerina.stdlib.graphql.compiler.schema.types.TypeKind;
import io.ballerina.stdlib.graphql.compiler.schema.types.TypeName;
import io.ballerina.stdlib.graphql.compiler.service.InterfaceFinder;

import java.util.List;

import static io.ballerina.stdlib.graphql.compiler.Utils.getEffectiveType;
import static io.ballerina.stdlib.graphql.compiler.Utils.getEffectiveTypes;
import static io.ballerina.stdlib.graphql.compiler.Utils.isRemoteMethod;
import static io.ballerina.stdlib.graphql.compiler.Utils.isResourceMethod;
import static io.ballerina.stdlib.graphql.compiler.schema.generator.GeneratorUtils.MAP_KEY_ARGUMENT_DESCRIPTION;
import static io.ballerina.stdlib.graphql.compiler.schema.generator.GeneratorUtils.MAP_KEY_ARGUMENT_NAME;
import static io.ballerina.stdlib.graphql.compiler.schema.generator.GeneratorUtils.MUTATION_TYPE_NAME;
import static io.ballerina.stdlib.graphql.compiler.schema.generator.GeneratorUtils.QUERY_TYPE_NAME;
import static io.ballerina.stdlib.graphql.compiler.schema.generator.GeneratorUtils.getDeprecationReason;
import static io.ballerina.stdlib.graphql.compiler.schema.generator.GeneratorUtils.getDescription;
import static io.ballerina.stdlib.graphql.compiler.schema.generator.GeneratorUtils.getTypeName;
import static io.ballerina.stdlib.graphql.compiler.schema.generator.GeneratorUtils.getWrapperType;

/**
 * Finds the GraphQL types associated with a Ballerina service.
 */
public class TypeFinder {
    private final Schema schema;
    private final InterfaceFinder interfaceFinder;

    public TypeFinder(InterfaceFinder interfaceFinder, ServiceDeclarationSymbol serviceDeclarationSymbol) {
        this.interfaceFinder = interfaceFinder;
        this.schema = new Schema(getDescription(serviceDeclarationSymbol));
    }

    public Schema findType(ServiceDeclarationSymbol serviceDeclarationSymbol) {
        Type queryType = getQueryType(serviceDeclarationSymbol);
        Type mutationType = getMutationType(serviceDeclarationSymbol);

        this.schema.setQueryType(queryType);
        this.schema.setMutationType(mutationType);
        IntrospectionTypeCreator introspectionTypeCreator = new IntrospectionTypeCreator(this.schema);
        introspectionTypeCreator.addIntrospectionTypes();
        return this.schema;
    }

    private Type getQueryType(ServiceDeclarationSymbol serviceDeclarationSymbol) {
        Type queryType = addType(TypeName.QUERY.getName(), TypeKind.OBJECT);
        for (MethodSymbol methodSymbol : serviceDeclarationSymbol.methods().values()) {
            if (isResourceMethod(methodSymbol)) {
                queryType.addField(getField((ResourceMethodSymbol) methodSymbol));
            }
        }
        return queryType;
    }

    private Type getMutationType(ServiceDeclarationSymbol serviceDeclarationSymbol) {
        Type mutationType = addType(TypeName.MUTATION.getName(), TypeKind.OBJECT);
        for (MethodSymbol methodSymbol : serviceDeclarationSymbol.methods().values()) {
            if (isRemoteMethod(methodSymbol)) {
                mutationType.addField(getField(methodSymbol));
            }
        }
        if (!mutationType.getFields().isEmpty()) {
            return mutationType;
        }
        return null;
    }

    private Field getField(ResourceMethodSymbol methodSymbol) {
        return getField(methodSymbol, ((PathSegmentList) methodSymbol.resourcePath()).list());
    }

    private Field getField(ResourceMethodSymbol methodSymbol, List<PathSegment> list) {
        if (list.size() == 1) {
            Type fieldType = getType(methodSymbol);
            Field field = new Field(list.get(0).signature(), fieldType, getDescription(methodSymbol));
            addArgs(field, methodSymbol);
            return field;
        } else {
            PathSegment pathSegment = list.get(0);
            Type type = getType(methodSymbol, pathSegment, list);
            return new Field(pathSegment.signature(), getWrapperType(type, TypeKind.NON_NULL));
        }
    }

    private Type getType(ResourceMethodSymbol methodSymbol, PathSegment pathSegment, List<PathSegment> list) {
        Type type = addType(pathSegment.signature(), TypeKind.OBJECT, Description.GENERATED_TYPE.getDescription());
        List<PathSegment> remainingPathList = list.subList(1, list.size());
        type.addField(getField(methodSymbol, remainingPathList));
        return type;
    }

    private Field getField(MethodSymbol methodSymbol) {
        if (methodSymbol.getName().isEmpty()) {
            return null;
        }
        Type fieldType = getType(methodSymbol);
        Field field = new Field(methodSymbol.getName().get(), fieldType, getDescription(methodSymbol));
        addArgs(field, methodSymbol);
        return field;
    }

    private void addArgs(Field field, MethodSymbol methodSymbol) {
        if (methodSymbol.typeDescriptor().params().isEmpty()) {
            return;
        }
        for (ParameterSymbol parameterSymbol : methodSymbol.typeDescriptor().params().get()) {
            if (parameterSymbol.getName().isEmpty()) {
                continue;
            }
            String parameterName = parameterSymbol.getName().get();
            String description = getParameterDescription(parameterName, methodSymbol);
            field.addArg(getArg(parameterName, description, parameterSymbol));
        }
    }

    private InputValue getArg(String parameterName, String description, ParameterSymbol parameterSymbol) {
        Type type = getInputFieldType(parameterSymbol.typeDescriptor());
        String defaultValue = getDefaultValue(parameterSymbol);
        return new InputValue(parameterName, type, description, defaultValue);
    }

    private Type getType(MethodSymbol methodSymbol) {
        if (methodSymbol.typeDescriptor().returnTypeDescriptor().isEmpty()) {
            return null;
        }
        TypeSymbol typeSymbol = methodSymbol.typeDescriptor().returnTypeDescriptor().get();
        return getFieldType(typeSymbol);
    }

    private Type getType(TypeSymbol typeSymbol) {
        String typeName = getTypeName(typeSymbol);
        if (this.schema.containsType(typeName)) {
            return this.schema.getType(typeName);
        }
        switch (typeSymbol.typeKind()) {
            case STRING:
            case STRING_CHAR:
                return addType(ScalarType.STRING);
            case INT:
                return addType(ScalarType.INT);
            case FLOAT:
                return addType(ScalarType.FLOAT);
            case BOOLEAN:
                return addType(ScalarType.BOOLEAN);
            case DECIMAL:
                return addType(ScalarType.DECIMAL);
            case TYPE_REFERENCE:
                return getType((TypeReferenceTypeSymbol) typeSymbol, typeName);
            case ARRAY:
                return getType((ArrayTypeSymbol) typeSymbol);
            case UNION:
                return getType(typeName, null, (UnionTypeSymbol) typeSymbol);
            case INTERSECTION:
                return getType(null, null, (IntersectionTypeSymbol) typeSymbol);
        }
        return null;
    }

    private static boolean isNilable(TypeSymbol typeSymbol) {
        if (typeSymbol.typeKind() != TypeDescKind.UNION) {
            return false;
        }
        UnionTypeSymbol unionTypeSymbol = (UnionTypeSymbol) typeSymbol;
        for (TypeSymbol memberType : unionTypeSymbol.memberTypeDescriptors()) {
            if (memberType.typeKind() == TypeDescKind.NIL) {
                return true;
            }
        }
        return false;
    }

    private Type addType(ScalarType scalarType) {
        return this.schema.addType(scalarType);
    }

    private Type addType(String name, TypeKind kind) {
        return addType(name, kind, null);
    }

    private Type addType(String name, TypeKind kind, String description) {
        return this.schema.addType(name, kind, description);
    }

    private Type getType(TypeReferenceTypeSymbol typeSymbol, String name) {
        if (typeSymbol.getName().isEmpty()) {
            return null;
        }
        Symbol definitionSymbol = typeSymbol.definition();
        if (definitionSymbol.kind() == SymbolKind.TYPE_DEFINITION) {
            return getType(name, (TypeDefinitionSymbol) definitionSymbol);
        } else if (definitionSymbol.kind() == SymbolKind.CLASS) {
            return getType(name, (ClassSymbol) definitionSymbol);
        } else if (definitionSymbol.kind() == SymbolKind.ENUM) {
            return getType(name, (EnumSymbol) definitionSymbol);
        }
        return null;
    }

    private Type getType(ArrayTypeSymbol arrayTypeSymbol) {
        TypeSymbol memberTypeSymbol = arrayTypeSymbol.memberTypeDescriptor();
        return getFieldType(memberTypeSymbol);
    }

    private Type getType(String name, TypeDefinitionSymbol typeDefinitionSymbol) {
        String description = getDescription(typeDefinitionSymbol);
        if (typeDefinitionSymbol.typeDescriptor().typeKind() == TypeDescKind.RECORD) {
            return getType(name, description, (RecordTypeSymbol) typeDefinitionSymbol.typeDescriptor());
        } else if (typeDefinitionSymbol.typeDescriptor().typeKind() == TypeDescKind.UNION) {
            return getType(name, description, (UnionTypeSymbol) typeDefinitionSymbol.typeDescriptor());
        } else if (typeDefinitionSymbol.typeDescriptor().typeKind() == TypeDescKind.INTERSECTION) {
            return getType(name, description, (IntersectionTypeSymbol) typeDefinitionSymbol.typeDescriptor());
        }
        return null;
    }

    private Type getType(String name, ClassSymbol classSymbol) {
        Type objectType;
        String description = getDescription(classSymbol);
        if (this.interfaceFinder.isValidInterface(name)) {
            objectType = addType(name, TypeKind.INTERFACE, description);
            getTypesFromInterface(name, objectType);
        } else {
            objectType = addType(name, TypeKind.OBJECT, description);
        }
        for (MethodSymbol methodSymbol : classSymbol.methods().values()) {
            if (isResourceMethod(methodSymbol)) {
                objectType.addField(getField((ResourceMethodSymbol) methodSymbol));
            }
        }
        return objectType;
    }

    private void getTypesFromInterface(String typeName, Type interfaceType) {
        List<ClassSymbol> implementations = this.interfaceFinder.getImplementations(typeName);
        for (ClassSymbol implementation : implementations) {
            // When adding an implementation, the name is already checked. Therefore, no need to check isEmpty().
            //noinspection OptionalGetWithoutIsPresent
            Type implementedType = getType(implementation.getName().get(), implementation);
            interfaceType.addPossibleType(implementedType);
            implementedType.addInterface(interfaceType);
        }
    }

    private Type getType(String name, EnumSymbol enumSymbol) {
        String description = getDescription(enumSymbol);
        Type enumType = addType(name, TypeKind.ENUM, description);
        for (ConstantSymbol enumMember : enumSymbol.members()) {
            addEnumValueToType(enumType, enumMember);
        }
        return enumType;
    }

    private Type getType(String name, String description, RecordTypeSymbol recordTypeSymbol) {
        Type objectType = addType(name, TypeKind.OBJECT, description);
        for (RecordFieldSymbol recordFieldSymbol : recordTypeSymbol.fieldDescriptors().values()) {
            objectType.addField(getField(recordFieldSymbol));
        }
        return objectType;
    }

    private Field getField(RecordFieldSymbol recordFieldSymbol) {
        if (recordFieldSymbol.getName().isEmpty()) {
            return null;
        }
        String name = recordFieldSymbol.getName().get();
        String description = getDescription(recordFieldSymbol);
        Type type = getType(recordFieldSymbol.typeDescriptor());
        // TODO: Making optional fields nilable is the correct way?
        if (!isNilable(recordFieldSymbol.typeDescriptor()) && !recordFieldSymbol.isOptional()) {
            type = getWrapperType(type, TypeKind.NON_NULL);
        }
        Field field = new Field(name, type, description);
        if (recordFieldSymbol.typeDescriptor().typeKind() == TypeDescKind.MAP) {
            Type argType = getWrapperType(addType(ScalarType.STRING), TypeKind.NON_NULL);
            field.addArg(new InputValue(MAP_KEY_ARGUMENT_NAME, argType, MAP_KEY_ARGUMENT_DESCRIPTION, null));
        }
        return field;
    }

    private Type getType(String name, String description, UnionTypeSymbol unionTypeSymbol) {
        List<TypeSymbol> effectiveTypes = getEffectiveTypes(unionTypeSymbol);
        if (effectiveTypes.size() == 1) {
            return getType(effectiveTypes.get(0));
        }

        String typeName = name == null ? getTypeName(effectiveTypes) : name;
        String typeDescription = description == null ? Description.GENERATED_UNION_TYPE.getDescription() : description;
        Type unionType = addType(typeName, TypeKind.UNION, typeDescription);

        for (TypeSymbol typeSymbol : effectiveTypes) {
            Type possibleType = getType(typeSymbol);
            String memberTypeName = getTypeName(typeSymbol);
            if (memberTypeName == null) {
                continue;
            }
            unionType.addPossibleType(possibleType);
        }
        return unionType;
    }

    private Type getType(String name, String description, IntersectionTypeSymbol intersectionTypeSymbol) {
        TypeSymbol effectiveType = getEffectiveType(intersectionTypeSymbol);
        if (name == null) {
            return getType(effectiveType);
        } else {
            return getType(name, description, (RecordTypeSymbol) effectiveType);
        }
    }

    private static String getParameterDescription(String parameterName, MethodSymbol methodSymbol) {
        if (methodSymbol.documentation().isEmpty()) {
            return null;
        }
        return methodSymbol.documentation().get().parameterMap().get(parameterName);
    }


    private Type getInputType(TypeSymbol typeSymbol) {
        String typeName = getTypeName(typeSymbol);
        if (this.schema.containsType(typeName)) {
            return this.schema.getType(typeName);
        }
        switch (typeSymbol.typeKind()) {
            case STRING:
            case STRING_CHAR:
                return addType(ScalarType.STRING);
            case INT:
                return addType(ScalarType.INT);
            case FLOAT:
                return addType(ScalarType.FLOAT);
            case BOOLEAN:
                return addType(ScalarType.BOOLEAN);
            case DECIMAL:
                return addType(ScalarType.DECIMAL);
            case TYPE_REFERENCE:
                return getInputType((TypeReferenceTypeSymbol) typeSymbol, typeName);
            case ARRAY:
                return getInputType((ArrayTypeSymbol) typeSymbol);
            case UNION:
                return getInputType((UnionTypeSymbol) typeSymbol);
            case INTERSECTION:
                return getInputType(null, null, (IntersectionTypeSymbol) typeSymbol);
        }
        return null;
    }

    private Type getInputType(TypeReferenceTypeSymbol typeReferenceTypeSymbol, String typeName) {
        if (typeReferenceTypeSymbol.getName().isEmpty()) {
            return null;
        }
        Symbol definitionSymbol = typeReferenceTypeSymbol.definition();
        if (definitionSymbol.kind() == SymbolKind.TYPE_DEFINITION) {
            return getInputType(typeName, (TypeDefinitionSymbol) definitionSymbol);
        } else if (definitionSymbol.kind() == SymbolKind.ENUM) {
            return getType(typeName, (EnumSymbol) definitionSymbol);
        }
        return null;
    }

    private Type getInputType(ArrayTypeSymbol arrayTypeSymbol) {
        TypeSymbol memberTypeSymbol = arrayTypeSymbol.memberTypeDescriptor();
        return getInputFieldType(memberTypeSymbol);
    }

    private Type getInputType(String typeName, TypeDefinitionSymbol typeDefinitionSymbol) {
        String description = getDescription(typeDefinitionSymbol);
        if (typeDefinitionSymbol.typeDescriptor().typeKind() == TypeDescKind.RECORD) {
            return getInputType(typeName, description, (RecordTypeSymbol) typeDefinitionSymbol.typeDescriptor());
        } else if (typeDefinitionSymbol.typeDescriptor().typeKind() == TypeDescKind.UNION) {
            return getInputType((UnionTypeSymbol) typeDefinitionSymbol.typeDescriptor());
        } else if (typeDefinitionSymbol.typeDescriptor().typeKind() == TypeDescKind.INTERSECTION) {
            return getInputType(typeName, description, (IntersectionTypeSymbol) typeDefinitionSymbol.typeDescriptor());
        }
        return null;
    }

    private Type getInputType(String name, String description, RecordTypeSymbol recordTypeSymbol) {
        Type objectType = addType(name, TypeKind.INPUT_OBJECT, description);
        for (RecordFieldSymbol recordFieldSymbol : recordTypeSymbol.fieldDescriptors().values()) {
            objectType.addInputField(getInputField(recordFieldSymbol));
        }
        return objectType;
    }

    private Type getInputType(UnionTypeSymbol unionTypeSymbol) {
        List<TypeSymbol> effectiveTypes = getEffectiveTypes(unionTypeSymbol);
        for (TypeSymbol typeSymbol : effectiveTypes) {
            return getInputType(typeSymbol);
        }
        return null;
    }

    private Type getInputType(String typeName, String description, IntersectionTypeSymbol intersectionTypeSymbol) {
        TypeSymbol effectiveType = getEffectiveType(intersectionTypeSymbol);
        if (typeName == null) {
            return getInputType(effectiveType);
        } else {
            return getInputType(typeName, description, (RecordTypeSymbol) effectiveType);
        }
    }

    private InputValue getInputField(RecordFieldSymbol recordFieldSymbol) {
        if (recordFieldSymbol.getName().isEmpty()) {
            return null;
        }
        String name = recordFieldSymbol.getName().get();
        String description = getDescription(recordFieldSymbol);
        Type type = getInputType(recordFieldSymbol.typeDescriptor());
        String defaultValue = getDefaultValue(recordFieldSymbol);
        return new InputValue(name, type, description, defaultValue);
    }

    private void addEnumValueToType(Type type, ConstantSymbol enumMember) {
        if (enumMember.resolvedValue().isEmpty()) {
            return;
        }
        String memberDescription = getDescription(enumMember);
        String name = enumMember.resolvedValue().get();
        boolean isDeprecated = enumMember.deprecated();
        String deprecationReason = getDeprecationReason(enumMember);
        EnumValue enumValue = new EnumValue(name, memberDescription, isDeprecated, deprecationReason);
        type.addEnumValue(enumValue);
    }

    private Type getFieldType(TypeSymbol typeSymbol) {
        Type type = getType(typeSymbol);
        if (isNilable(typeSymbol)) {
            return type;
        }
        return getWrapperType(type, TypeKind.NON_NULL);
    }

    private Type getInputFieldType(TypeSymbol typeSymbol) {
        Type type = getInputType(typeSymbol);
        if (isNilable(typeSymbol)) {
            return type;
        }
        return getWrapperType(type, TypeKind.NON_NULL);
    }

    // TODO: Get default value
    private String getDefaultValue(RecordFieldSymbol recordFieldSymbol) {
        if (recordFieldSymbol.hasDefaultValue()) {
            return recordFieldSymbol.signature();
        }
        return null;
    }

    // TODO: Get default value
    private String getDefaultValue(ParameterSymbol parameterSymbol) {
        if (parameterSymbol.paramKind() == ParameterKind.DEFAULTABLE) {
            return parameterSymbol.signature();
        }
        return null;
    }
}
