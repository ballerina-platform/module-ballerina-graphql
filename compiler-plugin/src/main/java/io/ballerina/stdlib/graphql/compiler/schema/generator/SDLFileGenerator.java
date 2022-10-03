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

import io.ballerina.projects.Project;
import io.ballerina.projects.ProjectKind;
import io.ballerina.stdlib.graphql.compiler.schema.types.DefaultDirective;
import io.ballerina.stdlib.graphql.compiler.schema.types.Directive;
import io.ballerina.stdlib.graphql.compiler.schema.types.DirectiveLocation;
import io.ballerina.stdlib.graphql.compiler.schema.types.EnumValue;
import io.ballerina.stdlib.graphql.compiler.schema.types.Field;
import io.ballerina.stdlib.graphql.compiler.schema.types.InputValue;
import io.ballerina.stdlib.graphql.compiler.schema.types.IntrospectionType;
import io.ballerina.stdlib.graphql.compiler.schema.types.ScalarType;
import io.ballerina.stdlib.graphql.compiler.schema.types.Schema;
import io.ballerina.stdlib.graphql.compiler.schema.types.Type;
import io.ballerina.stdlib.graphql.compiler.schema.types.TypeKind;

import java.io.IOException;
import java.io.PrintStream;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.Paths;
import java.util.ArrayList;
import java.util.Collections;
import java.util.List;
import java.util.Map;

import static io.ballerina.projects.util.ProjectConstants.USER_DIR;

/**
 * Generate the SDL schema file for a given Ballerina GraphQL Service.
 */
public class SDLFileGenerator {

    private final Schema schema;
    private final int serviceHashCode;
    private final Project project;
    private final PrintStream stdError = System.err;

    //String formats for SDL schema
    private static final String SDL_SCHEMA_NAME_FORMAT = "schema_%d.graphql";
    private static final String SCHEMA_FORMAT = "%s%s%s%n%n%s";
    private static final String ROOT_TYPE_FORMAT = "schema {%n%s%n}";
    private static final String DIRECTIVE_TYPE_FORMAT = "%sdirective @%s%s on %s";
    private static final String INTERFACE_TYPE_FORMAT = "%sinterface %s%s %s";
    private static final String UNION_TYPE_FORMAT = "%sunion %s%s";
    private static final String SCALAR_TYPE_FORMAT = "%sscalar %s";
    private static final String OBJECT_TYPE_FORMAT = "%stype %s%s %s";
    private static final String ENUM_TYPE_FORMAT = "%senum %s %s";
    private static final String INPUT_TYPE_FORMAT = "input %s %s";
    private static final String FIELD_FORMAT = "%s  %s%s: %s%s";
    private static final String FIELD_BLOCK_FORMAT = "{%n%s%n}";
    private static final String ARGS_FORMAT = "(%s)";
    private static final String DESC_FORMAT = "%s%n";
    private static final String DEPRECATE_FORMAT = "%s(reason: \"%s\")";
    private static final String COMMENT_FORMAT = "%s# %s";
    private static final String IMPLEMENT_FORMAT = " implements %s";
    private static final String POSSIBLE_TYPE_FORMAT = " = %s";
    private static final String INPUT_FIELD_FORMAT = "  %s: %s";
    private static final String ARGS_TYPE_FORMAT = "%s = %s";
    private static final String ARGS_VALUE_FORMAT = "%s: %s";
    private static final String ENUM_VALUE_FORMAT = "  %s%s";
    private static final String NON_NULL_FORMAT = "%s!";
    private static final String LIST_FORMAT = "[%s]";
    private static final String QUERY_FORMAT = "  query: %s";
    private static final String MUTATION_FORMAT = "  mutation: %s";
    private static final String SUBSCRIPTION_FORMAT = "  subscription: %s";
    private static final String DEPRECATE = " @deprecated";

    //Schema delimiters
    private static final String LINE_SEPARATOR = System.getProperty("line.separator");
    private static final String INDENTATION = "  ";
    private static final String EMPTY_STRING = "";
    private static final String COMMA_SIGN = ", ";
    private static final String AND_SIGN = " & ";
    private static final String PIPE_SIGN = "|";

    public SDLFileGenerator(Schema schema, int serviceHashCode, Project project) {
        this.schema = schema;
        this.serviceHashCode = serviceHashCode;
        this.project = project;
    }

    public void generate() {
        String schema = getSDLSchemaString();
        writeFile(schema);
    }

    private String getSDLSchemaString() {
        String rootType = createRootType();
        String directives = getDirectives();
        String types = getTypes();
        return getFormattedString(SCHEMA_FORMAT, createDescription(this.schema.getDescription()), rootType, directives,
                                  types);
    }

    private String createRootType() {
        List<String> rootOperations = new ArrayList<>();
        Type query = this.schema.getQueryType();
        rootOperations.add(getFormattedString(QUERY_FORMAT, query.getName()));

        Type mutation = this.schema.getMutationType();
        if (mutation != null) {
            rootOperations.add(getFormattedString(MUTATION_FORMAT, mutation.getName()));
        }

        Type subscription = this.schema.getSubscriptionType();
        if (subscription != null) {
            rootOperations.add(getFormattedString(SUBSCRIPTION_FORMAT, subscription.getName()));
        }
        return getFormattedString(ROOT_TYPE_FORMAT, String.join(LINE_SEPARATOR, rootOperations));
    }

    private String getDirectives() {
        List<String> directives = new ArrayList<>();
        for (Directive directive : this.schema.getDirectives()) {
            if (!isDefaultDirective(directive)) {
                directives.add(createDirective(directive));
            }
        }
        String formatedDirectives = String.join(LINE_SEPARATOR + LINE_SEPARATOR, directives);
        if (directives.isEmpty()) {
            return formatedDirectives;
        }
        return LINE_SEPARATOR + LINE_SEPARATOR + formatedDirectives;
    }

    private String getTypes() {
        List<String> types = new ArrayList<>();
        for (Map.Entry<String, Type> entry : this.schema.getTypes().entrySet()) {
            if (!isIntrospectionType(entry.getValue()) && !isBuiltInScalarType(entry.getValue())) {
                types.add(createType(entry.getValue()));
            }
        }
        return String.join(LINE_SEPARATOR + LINE_SEPARATOR, types);
    }

    private String createDirective(Directive directive) {
        return getFormattedString(DIRECTIVE_TYPE_FORMAT, createDescription(directive.getDescription()),
                                  directive.getName(), createArgs(directive.getArgs()),
                                  createDirectiveLocation(directive.getLocations()));
    }

    private String createType(Type type) {
        if (type.getKind().equals(TypeKind.SCALAR)) {
            return createScalarType(type);
        }
        if (type.getKind().equals(TypeKind.OBJECT)) {
            return createObjectType(type);
        }
        if (type.getKind().equals(TypeKind.INTERFACE)) {
            return createInterfaceType(type);
        }
        if (type.getKind().equals(TypeKind.UNION)) {
            return createUnionType(type);
        }
        if (type.getKind().equals(TypeKind.ENUM)) {
            return createEnumType(type);
        }
        if (type.getKind().equals(TypeKind.INPUT_OBJECT)) {
            return createInputObjectType(type);
        }
        return EMPTY_STRING;
    }

    private String createScalarType(Type type) {
        return getFormattedString(SCALAR_TYPE_FORMAT, createDescription(type.getDescription()), type.getName());
    }

    private String createObjectType(Type type) {
        return getFormattedString(OBJECT_TYPE_FORMAT, createDescription(type.getDescription()), type.getName(),
                                  createInterfaceImplements(type), createFields(type));
    }

    private String createInterfaceType(Type type) {
        return getFormattedString(INTERFACE_TYPE_FORMAT, createDescription(type.getDescription()), type.getName(),
                                  createInterfaceImplements(type), createFields(type));
    }

    private String createUnionType(Type type) {
        return getFormattedString(UNION_TYPE_FORMAT, createDescription(type.getDescription()), type.getName(),
                                  createPossibleTypes(type));
    }

    private String createInputObjectType(Type type) {
        return getFormattedString(INPUT_TYPE_FORMAT, type.getName(), createInputValues(type));
    }

    private String createEnumType(Type type) {
        return getFormattedString(ENUM_TYPE_FORMAT, createDescription(type.getDescription()), type.getName(),
                                  createEnumValues(type));
    }

    private String createDescription(String description) {
        if (description == null || description.isEmpty()) {
            return EMPTY_STRING;
        } else {
            List<String> subStrings = new ArrayList<>();
            for (String subString : description.split(LINE_SEPARATOR)) {
                subStrings.add(getFormattedString(COMMENT_FORMAT, EMPTY_STRING, subString));
            }
            return getFormattedString(DESC_FORMAT, String.join(LINE_SEPARATOR, subStrings));
        }
    }

    private String createFields(Type type) {
        List<String> fields = new ArrayList<>();
        for (Field field : type.getFields()) {
            fields.add(getFormattedString(FIELD_FORMAT, createFieldDescription(field.getDescription()), field.getName(),
                                          createArgs(field.getArgs()), createFieldType(field.getType()),
                                          createDeprecate(field)));
        }
        return getFormattedString(FIELD_BLOCK_FORMAT, String.join(LINE_SEPARATOR, fields));
    }

    private String createEnumValues(Type type) {
        List<String> enumValues = new ArrayList<>();
        for (EnumValue enumValue : type.getEnumValues()) {
            enumValues.add(getFormattedString(ENUM_VALUE_FORMAT, enumValue.getName(), createDeprecate(enumValue)));
        }
        return getFormattedString(FIELD_BLOCK_FORMAT, String.join(LINE_SEPARATOR, enumValues));
    }

    private String createInputValues(Type type) {
        List<String> inputFields = new ArrayList<>();
        for (InputValue inputField : type.getInputFields()) {
            inputFields.add(getFormattedString(INPUT_FIELD_FORMAT, inputField.getName(), createArgType(inputField)));
        }
        return getFormattedString(FIELD_BLOCK_FORMAT, String.join(LINE_SEPARATOR, inputFields));
    }

    private String createPossibleTypes(Type type) {
        List<String> possibleTypes = new ArrayList<>();
        for (Type possibleType : type.getPossibleTypes()) {
            possibleTypes.add(possibleType.getName());
        }
        return getFormattedString(POSSIBLE_TYPE_FORMAT, String.join(PIPE_SIGN, possibleTypes));
    }

    private String createArgs(List<InputValue> inputValues) {
        List<String> args = new ArrayList<>();
        if (inputValues.isEmpty()) {
            return EMPTY_STRING;
        }
        for (InputValue arg : inputValues) {
            args.add(getFormattedString(ARGS_VALUE_FORMAT, arg.getName(), createArgType(arg)));
        }
        return getFormattedString(ARGS_FORMAT, String.join(COMMA_SIGN, args));
    }

    private String createFieldType(Type type) {
        if (type.getKind().equals(TypeKind.NON_NULL)) {
            return getFormattedString(NON_NULL_FORMAT, createFieldType(type.getOfType()));
        } else if (type.getKind().equals(TypeKind.LIST)) {
            return getFormattedString(LIST_FORMAT, createFieldType(type.getOfType()));
        } else {
            return type.getName();
        }
    }

    private String createArgType(InputValue arg) {
        if (arg.getDefaultValue() == null) {
            return createFieldType(arg.getType());
        } else {
            return getFormattedString(ARGS_TYPE_FORMAT, createFieldType(arg.getType()), arg.getDefaultValue());
        }
    }

    private String createInterfaceImplements(Type type) {
        List<String> interfaces = new ArrayList<>();
        if (type.getInterfaces().isEmpty()) {
            return EMPTY_STRING;
        }
        for (Type interfaceType : type.getInterfaces()) {
            interfaces.add(interfaceType.getName());
        }
        return getFormattedString(IMPLEMENT_FORMAT, String.join(AND_SIGN, interfaces));
    }

    private String createFieldDescription(String description) {
        if (description == null || description.isEmpty()) {
            return EMPTY_STRING;
        } else {
            List<String> subStrings = new ArrayList<>();
            for (String subString : description.split(LINE_SEPARATOR)) {
                subStrings.add(getFormattedString(COMMENT_FORMAT, INDENTATION, subString));
            }
            return getFormattedString(DESC_FORMAT, String.join(LINE_SEPARATOR, subStrings));
        }
    }

    private String createDirectiveLocation(List<DirectiveLocation> location) {
        List<String> locations = new ArrayList<>();
        for (DirectiveLocation directiveLocation : location) {
            locations.add(directiveLocation.name());
        }
        return String.join(PIPE_SIGN, locations);
    }

    private String createDeprecate(EnumValue enumValue) {
        if (enumValue.isDeprecated()) {
            if (enumValue.getDeprecationReason() != null) {
                return getFormattedString(DEPRECATE_FORMAT, DEPRECATE, enumValue.getDeprecationReason());
            }
            return DEPRECATE;
        }
        return EMPTY_STRING;
    }

    private String createDeprecate(Field field) {
        if (field.isDeprecated()) {
            if (field.getDeprecationReason() != null) {
                return getFormattedString(DEPRECATE_FORMAT, DEPRECATE, field.getDeprecationReason());
            }
            return DEPRECATE;
        }
        return EMPTY_STRING;
    }

    private Boolean isIntrospectionType(Type type) {
        for (IntrospectionType value : IntrospectionType.values()) {
            if (value.getName().equals(type.getName())) {
                return true;
            }
        }
        return false;
    }

    private Boolean isBuiltInScalarType(Type type) {
        for (ScalarType value : ScalarType.values()) {
            if (value.getName().equals(type.getName())) {
                if (value.equals(ScalarType.UPLOAD) || value.equals(ScalarType.DECIMAL)) {
                    return false;
                }
                return true;
            }
        }
        return false;
    }

    private Boolean isDefaultDirective(Directive directive) {
        for (DefaultDirective value : DefaultDirective.values()) {
            if (value.getName().equals(directive.getName())) {
                return true;
            }
        }
        return false;
    }

    private String getFormattedString(String format, String... args) {
        return String.format(format, (Object[]) args);
    }

    private void writeFile(String content) {
        Path filePath = Paths.get(getTargetPath(), getSchemaFileName()).toAbsolutePath();
        try {
            createFileIfNotExists(filePath);
            Files.write(filePath, Collections.singleton(content));
        } catch (IOException e) {
            this.stdError.println("WARNING graphql schema file generation failed: " + e.getMessage());
        }
    }

    private String getTargetPath() {
        if (this.project.kind().equals(ProjectKind.SINGLE_FILE_PROJECT)) {
            return System.getProperty(USER_DIR);
        } else {
            return this.project.targetDir().toString();
        }
    }

    private String getSchemaFileName() {
        return String.format(SDL_SCHEMA_NAME_FORMAT, this.serviceHashCode);
    }

    private static void createFileIfNotExists(Path filePath) throws IOException {
        Path parentDir = filePath.getParent();
        if (parentDir != null && !parentDir.toFile().exists()) {
            try {
                Files.createDirectories(parentDir);
            } catch (IOException e) {
                throw new RuntimeException(e);
            }
        }
        if (!filePath.toFile().exists()) {
            try {
                Files.createFile(filePath);
            } catch (IOException e) {
                throw new RuntimeException(e);
            }
        }
    }
}
