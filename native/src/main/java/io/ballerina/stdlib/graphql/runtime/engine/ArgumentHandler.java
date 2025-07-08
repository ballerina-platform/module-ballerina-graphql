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

package io.ballerina.stdlib.graphql.runtime.engine;

import io.ballerina.runtime.api.Environment;
import io.ballerina.runtime.api.creators.ErrorCreator;
import io.ballerina.runtime.api.creators.TypeCreator;
import io.ballerina.runtime.api.creators.ValueCreator;
import io.ballerina.runtime.api.types.ArrayType;
import io.ballerina.runtime.api.types.Field;
import io.ballerina.runtime.api.types.FiniteType;
import io.ballerina.runtime.api.types.IntersectionType;
import io.ballerina.runtime.api.types.MethodType;
import io.ballerina.runtime.api.types.Parameter;
import io.ballerina.runtime.api.types.PredefinedTypes;
import io.ballerina.runtime.api.types.RecordType;
import io.ballerina.runtime.api.types.Type;
import io.ballerina.runtime.api.types.TypeTags;
import io.ballerina.runtime.api.types.UnionType;
import io.ballerina.runtime.api.utils.JsonUtils;
import io.ballerina.runtime.api.utils.StringUtils;
import io.ballerina.runtime.api.utils.TypeUtils;
import io.ballerina.runtime.api.utils.ValueUtils;
import io.ballerina.runtime.api.values.BArray;
import io.ballerina.runtime.api.values.BError;
import io.ballerina.runtime.api.values.BMap;
import io.ballerina.runtime.api.values.BObject;
import io.ballerina.runtime.api.values.BString;
import io.ballerina.runtime.api.values.BTypedesc;
import io.ballerina.stdlib.constraint.Constraints;
import io.ballerina.stdlib.graphql.runtime.exception.ConstraintValidationException;
import io.ballerina.stdlib.graphql.runtime.exception.IdTypeInputValidationException;

import java.util.ArrayList;
import java.util.Arrays;
import java.util.Map;
import java.util.Objects;

import static io.ballerina.runtime.api.types.TypeTags.INTERSECTION_TAG;
import static io.ballerina.stdlib.graphql.runtime.engine.EngineUtils.ARGUMENTS_FIELD;
import static io.ballerina.stdlib.graphql.runtime.engine.EngineUtils.FILE_INFO_FIELD;
import static io.ballerina.stdlib.graphql.runtime.engine.EngineUtils.NAME_FIELD;
import static io.ballerina.stdlib.graphql.runtime.engine.EngineUtils.VALUE_FIELD;
import static io.ballerina.stdlib.graphql.runtime.engine.EngineUtils.VARIABLE_DEFINITION;
import static io.ballerina.stdlib.graphql.runtime.engine.EngineUtils.VARIABLE_NAME_FIELD;
import static io.ballerina.stdlib.graphql.runtime.engine.EngineUtils.VARIABLE_VALUE_FIELD;
import static io.ballerina.stdlib.graphql.runtime.engine.EngineUtils.isEnum;
import static io.ballerina.stdlib.graphql.runtime.engine.EngineUtils.isIgnoreType;
import static io.ballerina.stdlib.graphql.runtime.utils.Utils.createError;
import static io.ballerina.stdlib.graphql.runtime.utils.Utils.ERROR_TYPE;
import static io.ballerina.stdlib.graphql.runtime.utils.Utils.INTERNAL_NODE;
import static io.ballerina.stdlib.graphql.runtime.utils.Utils.handleFailureAndExit;
import static io.ballerina.stdlib.graphql.runtime.utils.Utils.isContext;
import static io.ballerina.stdlib.graphql.runtime.utils.Utils.isField;
import static io.ballerina.stdlib.graphql.runtime.utils.Utils.isFileUpload;
import static io.ballerina.stdlib.graphql.runtime.utils.Utils.isSubgraphModule;

/**
 * This class processes the arguments passed to a GraphQL document to pass into Ballerina functions.
 */
public final class ArgumentHandler {
    private final BMap<BString, Object> argumentsMap;
    private final MethodType method;
    private final BMap<BString, Object> fileInfo;
    private final BObject context;
    private final BObject field;
    private final BObject responseGenerator;
    private final boolean validation;
    private final BArray idTypeErrors;

    private static final String REPRESENTATION_TYPENAME = "Representation";
    private static final String ADD_CONSTRAINT_ERRORS_METHOD = "addConstraintValidationErrors";
    private static final String CONSTRAINT_ERROR_MESSAGE = "Constraint validation errors found.";
    private static final String ADD_ID_TYPE_ERRORS_METHOD = "addIdTypeInputValidationErrors";
    private static final String ID_TYPE_ERROR_MESSAGE = "ID type input validation error found.";

    private static final BString KIND_FIELD = StringUtils.fromString("kind");

    // graphql.parser types
    private static final int T_STRING = 2;
    private static final int T_INT = 3;
    private static final int T_FLOAT = 4;
    private static final int T_BOOLEAN = 5;
    private static final int T_INPUT_OBJECT = 22;
    private static final int T_LIST = 23;
    private static final ArrayList<String> idsList = new ArrayList<>();
    private static final String ID_ANNOTATION = "ID";
    private static final String PACKAGE_NAME = "ballerina/graphql";
    private static final String RETURN_TYPE_PARAM = "$returns$";
    private static final String ARGUMENT_TYPE_PARAM = "$param$";
    private static final String RECORD_FIELD_TYPE = "$field$";

    @SuppressWarnings("unchecked")
    public ArgumentHandler(MethodType method, BObject context, BObject field, BObject responseGenerator,
                           boolean validation) {
        this.method = method;
        this.fileInfo = (BMap<BString, Object>) context.getNativeData(FILE_INFO_FIELD);
        this.context = context;
        this.field = field;
        populateIdTypeArguments(method.getAnnotations());
        this.argumentsMap = ValueCreator.createMapValue();
        this.responseGenerator = responseGenerator;
        this.validation = validation;
        this.idTypeErrors = ValueCreator.createArrayValue(TypeCreator.createArrayType(PredefinedTypes.TYPE_ERROR));
        BObject fieldNode = this.field.getObjectValue(INTERNAL_NODE);
        this.populateArgumentsMap(fieldNode);
    }

    private void populateIdTypeArguments(BMap<BString, Object> annotations) {
        int i = 0;
        for (Object annotation : annotations.values().toArray()) {
            BMap annotationMap = (BMap) annotation;
            for (Object annotationKey : annotationMap.getKeys()) {
                if (isIdAnnotation(annotationKey)
                        && !annotations.getKeys()[i].getValue().equals(RETURN_TYPE_PARAM)) {
                    String[] annotationValue = annotations.getKeys()[i].getValue().split("\\.");
                    if (annotationValue.length == 2 && annotationValue[0].equals(ARGUMENT_TYPE_PARAM)) {
                        idsList.add(annotationValue[1]);
                    }
                    i++;
                }
            }
        }
    }

    private boolean isIdAnnotation(Object annotationKey) {
        String[] fullTypeName = annotationKey.toString().replaceAll("\\d", "").split("::");
        return fullTypeName[0].equals(PACKAGE_NAME) && fullTypeName[1].equals(ID_ANNOTATION);
    }

    public Object[] getArguments(Environment environment) throws IdTypeInputValidationException {
        if (!this.idTypeErrors.isEmpty()) {
            this.addValidationErrors(environment, this.idTypeErrors, ADD_ID_TYPE_ERRORS_METHOD);
            throw new IdTypeInputValidationException(ID_TYPE_ERROR_MESSAGE);
        }
        return this.getArgumentsForMethod();
    }

    public void validateInputConstraint(Environment environment) throws ConstraintValidationException {
        if (this.validation) {
            BArray errors = ValueCreator.createArrayValue(TypeCreator.createArrayType(PredefinedTypes.TYPE_ERROR));
            BObject fieldNode = this.field.getObjectValue(INTERNAL_NODE);
            BArray argumentArray = fieldNode.getArrayValue(ARGUMENTS_FIELD);
            for (int i = 0; i < argumentArray.size(); i++) {
                BObject argumentNode = (BObject) argumentArray.get(i);
                BString argumentName = argumentNode.getStringValue(NAME_FIELD);
                Parameter parameter = Objects.requireNonNull(getParameterForArgumentNode(argumentName));
                Object argumentValue = this.argumentsMap.get(argumentName);
                BTypedesc bTypedesc = getTypeDescFromParameter(parameter);
                Object validationResult = Constraints.validate(argumentValue, bTypedesc);
                if (validationResult instanceof BError) {
                    errors.append(validationResult);
                }
            }
            if (!errors.isEmpty()) {
                this.addValidationErrors(environment, errors, ADD_CONSTRAINT_ERRORS_METHOD);
                throw new ConstraintValidationException(CONSTRAINT_ERROR_MESSAGE);
            }
        }
    }

    private void populateArgumentsMap(BObject fieldNode) {
        BArray argumentArray = fieldNode.getArrayValue(ARGUMENTS_FIELD);
        for (int i = 0; i < argumentArray.size(); i++) {
            BObject argumentNode = (BObject) argumentArray.get(i);
            BString argumentName = argumentNode.getStringValue(NAME_FIELD);
            Type parameterType = Objects.requireNonNull(getParameterForArgumentNode(argumentName)).type;
            Object argumentValue;
            boolean isVariableValue = argumentNode.getBooleanValue(VARIABLE_DEFINITION);
            if (isFileUpload(parameterType)) {
                argumentValue = this.getFileUploadParameter(argumentNode, parameterType);
            } else if (isRepresentationArgument(parameterType)) {
                argumentValue = getRepresentationArgument(argumentNode, parameterType);
            } else {
                if (isVariableValue) {
                    argumentValue = argumentNode.get(VARIABLE_VALUE_FIELD);
                } else {
                    argumentValue = argumentNode.get(VALUE_FIELD);
                }
                try {
                    argumentValue = this.getArgumentValue(argumentName.getValue(), argumentValue, parameterType,
                            isVariableValue);
                } catch (IdTypeInputValidationException e) {
                    argumentValue = null;
                }
            }
            this.argumentsMap.put(argumentName, argumentValue);
        }
    }

    private Object getArgumentValue(String argName, Object argValue, Type parameterType, boolean isVariableValue)
            throws IdTypeInputValidationException {
        if (idsList.contains(argName)) {
            Object value = this.getIdArgumentValue(argName, argValue, parameterType, isVariableValue);
            idsList.remove(argName);
            return value;
        }
        if (parameterType.getTag() == TypeTags.RECORD_TYPE_TAG) {
            return this.getInputObjectArgument(argValue, (RecordType) parameterType, isVariableValue);
        } else if (parameterType.getTag() == INTERSECTION_TAG) {
            return this.getIntersectionTypeArgument(argName, argValue, (IntersectionType) parameterType,
                    isVariableValue);
        } else if (parameterType.getTag() == TypeTags.ARRAY_TAG) {
            return this.getArrayTypeArgument(argName, argValue, (ArrayType) parameterType, isVariableValue);
        } else if (parameterType.getTag() == TypeTags.UNION_TAG) {
            return this.getUnionTypeArgument(argName, argValue, (UnionType) parameterType, isVariableValue);
        } else if (parameterType.getTag() == TypeTags.TYPE_REFERENCED_TYPE_TAG) {
            return this.getArgumentValue(argName, argValue, TypeUtils.getReferredType(parameterType), isVariableValue);
        } else {
            return argValue;
        }
    }

    private Object getIdArgumentValue(String argName, Object argValue, Type parameterType, boolean isVariableValue)
            throws IdTypeInputValidationException {
        Object value = argValue;
        if (value instanceof BString) {
            value = getIdValueFromString(argName, value, parameterType, isVariableValue);
        } else if (value instanceof Long) {
            value = getIdValueFromInteger(argName, value, parameterType, isVariableValue);
        } else if (value instanceof BArray bArray) {
            if (parameterType.getTag() == TypeTags.ARRAY_TAG) {
                ArrayType arrayType = (ArrayType) parameterType;
                BArray valueArray = ValueCreator.createArrayValue(arrayType);
                for (Object obj : bArray.getValues()) {
                    Object elementValue = getIdArgumentValue(argName, obj, arrayType.getElementType(),
                            isVariableValue);
                    valueArray.append(elementValue);
                }
                value = valueArray;
            } else if (parameterType.getTag() == TypeTags.UNION_TAG) {
                value = getIdValueFromUnionType(argName, argValue, (UnionType) parameterType, isVariableValue);
            }
        } else if (argValue instanceof BObject bObject) {
            Object objectValue;
            if (isVariableValue) {
                objectValue = bObject.get(VARIABLE_VALUE_FIELD);
                value = getIdArgumentValue(argName, objectValue, parameterType, true);
            } else {
                objectValue = bObject.get(VALUE_FIELD);
                value = getIdArgumentValue(argName, objectValue, parameterType, false);
            }
        }
        return value;
    }

    private Object getIdValueFromString(String argName, Object argValue, Type parameterType, boolean isVariableValue)
            throws IdTypeInputValidationException {
        String stringValue = ((BString) argValue).getValue();
        try {
            if (parameterType.getTag() == TypeTags.STRING_TAG) {
                return StringUtils.fromString(stringValue);
            } else if (parameterType.getTag() == TypeTags.INT_TAG) {
                return Long.parseLong(stringValue);
            } else if (parameterType.getTag() == TypeTags.FLOAT_TAG) {
                return ValueUtils.convert(JsonUtils.parse(stringValue), parameterType);
            } else if (parameterType.getTag() == TypeTags.DECIMAL_TAG) {
                return ValueUtils.convert(JsonUtils.parse(stringValue), parameterType);
            } else if (parameterType.getTag() == TypeTags.TYPE_REFERENCED_TYPE_TAG) {
                // not validating if this is uuid:Uuid since compiler plugin does that
                return ValueCreator.createRecordValue(parameterType.getPackage(), parameterType.getName(),
                        (BMap<BString, Object>) JsonUtils.parse(stringValue.replaceAll("\\\\", "")));
            } else if (parameterType.getTag() == TypeTags.UNION_TAG) {
                return getIdValueFromUnionType(argName, argValue, (UnionType) parameterType, isVariableValue);
            }
        } catch (NumberFormatException | BError e) {
            BError cause = ErrorCreator.createError(StringUtils.fromString(e.getMessage()));
            BError error = createError(stringValue, ERROR_TYPE, cause);
            this.idTypeErrors.append(error);
            throw new IdTypeInputValidationException(ID_TYPE_ERROR_MESSAGE);
        }
        return argValue;
    }

    private Object getIdValueFromInteger(String argName, Object argValue, Type parameterType,
                                         boolean isVariableValue) throws IdTypeInputValidationException {
        Long longValue = (Long) argValue;
        try {
            if (parameterType.getTag() == TypeTags.STRING_TAG) {
                return StringUtils.fromString(longValue.toString());
            } else if (parameterType.getTag() == TypeTags.FLOAT_TAG || parameterType.getTag() == TypeTags.DECIMAL_TAG) {
                return ValueUtils.convert(longValue, parameterType);
            } else if (parameterType.getTag() == TypeTags.INT_TAG) {
                return longValue;
            } else if (parameterType.getTag() == TypeTags.UNION_TAG) {
                return getIdValueFromUnionType(argName, argValue, (UnionType) parameterType, isVariableValue);
            }
        } catch (NumberFormatException | BError e) {
            BError cause = ErrorCreator.createError(StringUtils.fromString(e.getMessage()));
            BError error = createError(longValue.toString(), ERROR_TYPE, cause);
            this.idTypeErrors.append(error);
            throw new IdTypeInputValidationException(ID_TYPE_ERROR_MESSAGE);
        }
        return argValue;
    }

    private Object getIdValueFromUnionType(String argName, Object argValue, UnionType unionType,
                                           boolean isVariableValue) throws IdTypeInputValidationException {
        if (isEnum(unionType)) {
            return getEnumTypeArgument(argValue, unionType);
        } else if (unionType.isNilable() && argValue == null) {
            return null;
        }
        Type effectiveType = getEffectiveType(unionType);
        return getIdArgumentValue(argName, argValue, effectiveType, isVariableValue);
    }

    @SuppressWarnings("unchecked")
    private BMap<BString, Object> getRepresentationValue(Object jsonRepresentation, Type parameterType) {
        BMap<BString, ?> map = JsonUtils.convertJSONToMap(jsonRepresentation, PredefinedTypes.TYPE_MAP);
        return ValueCreator.createRecordValue(parameterType.getPackage(), parameterType.getName(),
                                              (BMap<BString, Object>) map);
    }

    private Object getFileUploadParameter(BObject argumentNode, Type parameterType) {
        if (parameterType.getTag() == TypeTags.ARRAY_TAG) {
            return this.fileInfo.getArrayValue(argumentNode.getStringValue(VARIABLE_NAME_FIELD));
        } else {
            return this.fileInfo.getMapValue(argumentNode.getStringValue(VARIABLE_NAME_FIELD));
        }
    }

    private BMap<BString, Object> getInputObjectArgument(Object argValue, RecordType recordType,
                                                        boolean isVariableValue) throws IdTypeInputValidationException {
        populateInputObjectFieldIdTypeArguments(recordType.getAnnotations());
        BMap<BString, Object> recordValue = recordType.getZeroValue();
        if (argValue == null) {
            return null;
        }
        if (isVariableValue) {
            BMap<BString, Object> variablesMap = (BMap<BString, Object>) argValue;
            Map<String, Field> fields = recordType.getFields();
            BMap<BString, Object> variables = ValueCreator.createMapValue();
            for (Field field : fields.values()) {
                BString fieldName = StringUtils.fromString(field.getFieldName());
                Object value = getArgumentValue(fieldName.getValue(), variablesMap.get(fieldName),
                        field.getFieldType(), true);
                variables.put(fieldName, value);
            }
            return ValueCreator.createRecordValue(recordType.getPackage(), recordType.getName(), variables);
        } else {
            BArray inputObjectFields = (BArray) argValue;
            for (int i = 0; i < inputObjectFields.size(); i++) {
                BObject inputObjectField = (BObject) inputObjectFields.get(i);
                BString inputObjectFieldName = inputObjectField.getStringValue(NAME_FIELD);
                Object inputObjectFieldValue;
                boolean isVariable = inputObjectField.getBooleanValue(VARIABLE_DEFINITION);
                if (isVariable) {
                    inputObjectFieldValue = inputObjectField.get(VARIABLE_VALUE_FIELD);
                } else {
                    inputObjectFieldValue = inputObjectField.get(VALUE_FIELD);
                }
                Field field = recordType.getFields().get(inputObjectFieldName.getValue());
                Object fieldValue = getArgumentValue(inputObjectFieldName.getValue(), inputObjectFieldValue,
                        field.getFieldType(), isVariable);
                recordValue.put(inputObjectFieldName, fieldValue);
            }
            return recordValue;
        }
    }

    private Object getJsonArgument(BObject argumentNode) {
        int kind = (int) argumentNode.getIntValue(KIND_FIELD);
        Object valueField = argumentNode.get(VALUE_FIELD);
        return switch (kind) {
            case T_STRING, T_INT, T_FLOAT, T_BOOLEAN -> JsonUtils.convertToJson(valueField);
            case T_INPUT_OBJECT -> getJsonObject(argumentNode);
            case T_LIST -> getJsonList(argumentNode);
            default -> null;
        };
    }

    private Object getJsonList(BObject argumentNode) {
        BArray valueArray = ValueCreator.createArrayValue(PredefinedTypes.TYPE_JSON_ARRAY);
        BArray argumentArray = argumentNode.getArrayValue(VALUE_FIELD);
        for (int i = 0; i < argumentArray.size(); i++) {
            BObject argumentElementNode = (BObject) argumentArray.get(i);
            Object elementValue = getJsonArgument(argumentElementNode);
            valueArray.append(elementValue);
        }
        return JsonUtils.convertToJson(valueArray);
    }

    private Object getJsonObject(BObject argumentNode) {
        BMap<BString, Object> mapValue = ValueCreator.createMapValue();
        BArray inputObjectFields = argumentNode.getArrayValue(VALUE_FIELD);
        for (int i = 0; i < inputObjectFields.size(); i++) {
            BObject inputObjectField = (BObject) inputObjectFields.get(i);
            BString inputObjectFieldName = inputObjectField.getStringValue(NAME_FIELD);
            Object fieldValue = getJsonArgument(inputObjectField);
            mapValue.put(inputObjectFieldName, fieldValue);
        }
        return JsonUtils.convertToJson(mapValue);
    }

    private Object getIntersectionTypeArgument(String argName, Object argValue, IntersectionType intersectionType,
                                               boolean isVariableValue) throws IdTypeInputValidationException {
        Type effectiveType = TypeUtils.getReferredType(getEffectiveType(intersectionType));
        if (effectiveType.getTag() == TypeTags.ARRAY_TAG) {
            BArray valueArray = getArrayTypeArgument(argName, argValue, (ArrayType) effectiveType, isVariableValue);
            valueArray.freezeDirect();
            return valueArray;
        }
        BMap<BString, Object> argumentValue = getInputObjectArgument(argValue, (RecordType) effectiveType,
                isVariableValue);
        argumentValue.freezeDirect();
        return argumentValue;
    }

    private BArray getArrayTypeArgument(String argName, Object argValue, ArrayType arrayType, boolean isVariableValue)
            throws IdTypeInputValidationException {
        BArray argumentArray = (BArray) argValue;
        if (argumentArray == null) {
            return null;
        }
        if (isVariableValue) {
            BArray argumentArrValue = ValueCreator.createArrayValue(arrayType);
            for (int i = 0; i < argumentArray.size(); i++) {
                Object elementValue = argumentArray.get(i);
                Object elementArgValue = getArgumentValue(argName, elementValue, arrayType.getElementType(), true);
                argumentArrValue.append(elementArgValue);
            }
            return argumentArrValue;
        }
        BArray valueArray = ValueCreator.createArrayValue(arrayType);
        for (int i = 0; i < argumentArray.size(); i++) {
            BObject argumentElementNode = (BObject) argumentArray.get(i);
            Object argElementValue;
            boolean isVariable = argumentElementNode.getBooleanValue(VARIABLE_DEFINITION);
            if (isVariable) {
                argElementValue = argumentElementNode.get(VARIABLE_VALUE_FIELD);
            } else {
                argElementValue = argumentElementNode.get(VALUE_FIELD);
            }
            Object elementValue = getArgumentValue(argName, argElementValue, arrayType.getElementType(),
                    isVariable);
            valueArray.append(elementValue);
        }
        return valueArray;
    }

    private Object getUnionTypeArgument(String argName, Object argValue, UnionType unionType,
                                        boolean isVariableValue) throws IdTypeInputValidationException {
        if (isEnum(unionType)) {
            return getEnumTypeArgument(argValue, unionType);
        } else if (unionType.isNilable() && argValue == null) {
            return null;
        }
        Type effectiveType = getEffectiveType(unionType);
        return getArgumentValue(argName, argValue, effectiveType, isVariableValue);
    }

    private Object getEnumTypeArgument(Object argValue, UnionType enumType) {
        BString enumName = (BString) argValue;
        Object result = enumName;
        for (Type memberType : enumType.getMemberTypes()) {
            if (memberType.getTag() == TypeTags.FINITE_TYPE_TAG) {
                FiniteType finiteType = (FiniteType) memberType;
                if (enumName.getValue().equals(finiteType.getName())) {
                    result = finiteType.getZeroValue();
                }
            }
        }
        return result;
    }

    private Parameter getParameterForArgumentNode(BString paramName) {
        for (Parameter parameter : this.method.getParameters()) {
            if (parameter.name.equals(paramName.getValue())) {
                return parameter;
            }
        }
        return null;
    }

    private Object[] getArgumentsForMethod() {
        Parameter[] parameters = this.method.getParameters();
        Object[] result = new Object[parameters.length];
        for (int i = 0; i < parameters.length; i += 1) {
            if (isContext(parameters[i].type)) {
                result[i] = this.context;
                continue;
            }
            if (isField(parameters[i].type)) {
                result[i] = this.field;
                continue;
            }
            if (this.argumentsMap.get(StringUtils.fromString(parameters[i].name)) == null) {
                result[i] = parameters[i].type.getZeroValue();
            } else {
                result[i] = this.argumentsMap.get(StringUtils.fromString(parameters[i].name));
            }
        }
        return result;
    }

    static Type getEffectiveType(IntersectionType intersectionType) {
        for (Type constituentType : intersectionType.getConstituentTypes()) {
            if (constituentType.getTag() != TypeTags.READONLY_TAG) {
                return constituentType;
            }
        }
        return intersectionType;
    }

    private static Type getEffectiveType(UnionType unionType) {
        for (Type memberType : unionType.getOriginalMemberTypes()) {
            if (!isIgnoreType(memberType)) {
                return memberType;
            }
        }
        return unionType;
    }

    private boolean isRepresentationArgument(Type type) {
        Type refferedType = TypeUtils.getReferredType(type);
        if (refferedType.getTag() == TypeTags.ARRAY_TAG) {
            return isRepresentationArgument(((ArrayType) refferedType).getElementType());
        }
        return TypeUtils.getReferredType(type).getTag() == TypeTags.RECORD_TYPE_TAG && isSubgraphModule(type)
                && type.getName().equals(REPRESENTATION_TYPENAME);
    }

    private Object getRepresentationArgument(BObject argumentNode, Type parameterType) {
        if (parameterType.getTag() == TypeTags.ARRAY_TAG) {
            ArrayType arrayType = (ArrayType) parameterType;
            if (argumentNode.getBooleanValue(VARIABLE_DEFINITION)) {
                BArray nestedArgArray = argumentNode.getArrayValue(VARIABLE_VALUE_FIELD);
                Object[] representations = nestedArgArray.getValues();
                Object[] representationRecords = Arrays.stream(representations).map
                        (entity -> this.getRepresentationValue(entity, arrayType.getElementType())).toArray();
                return ValueCreator.createArrayValue(representationRecords, arrayType);
            } else {
                BArray valueArray = ValueCreator.createArrayValue(arrayType);
                BArray nestedArgArray = argumentNode.getArrayValue(VALUE_FIELD);
                for (int j = 0; j < nestedArgArray.size(); j++) {
                    BObject argumentElementNode = (BObject) nestedArgArray.get(j);
                    Object jsonRepresentation = this.getJsonArgument(argumentElementNode);
                    Object elementValue = getRepresentationValue(jsonRepresentation, arrayType.getElementType());
                    valueArray.append(elementValue);
                }
                return valueArray;
            }
        } else {
            Object jsonRepresentation = this.getJsonArgument(argumentNode);
            return getRepresentationValue(jsonRepresentation, parameterType);
        }
    }

    private void addValidationErrors(Environment environment, BArray errors, String methodName) {
        environment.yieldAndRun(() -> {
            BObject fieldNode = this.field.getObjectValue(INTERNAL_NODE);
            Object[] arguments = {errors, fieldNode};
            try {
                return environment.getRuntime().callMethod(this.responseGenerator, methodName,
                        null, arguments);
            } catch (BError bError) {
                handleFailureAndExit(bError);
            }
            return null;
        });
    }


    private static BTypedesc getTypeDescFromParameter(Parameter parameter) {
        BTypedesc bTypedesc = ValueCreator.createTypedescValue(parameter.type);
        if (bTypedesc.getDescribingType().getTag() == INTERSECTION_TAG) {
            Type type = getEffectiveType((IntersectionType) bTypedesc.getDescribingType());
            return ValueCreator.createTypedescValue(type);
        }
        return bTypedesc;
    }

    private void populateInputObjectFieldIdTypeArguments(BMap<BString, Object> annotations) {
        int i = 0;
        for (Object annotation : annotations.values().toArray()) {
            BMap annotationMap = (BMap) annotation;
            for (Object annotationKey : annotationMap.getKeys()) {
                if (isIdAnnotation(annotationKey)) {
                    String[] annotationValue = annotations.getKeys()[i].getValue().split("\\.");
                    if (annotationValue.length == 2 && (annotationValue[0].equals(ARGUMENT_TYPE_PARAM) ||
                            (annotationValue[0].equals(RECORD_FIELD_TYPE)))) {
                        idsList.add(annotationValue[1]);
                    }
                    i++;
                }
            }
        }
    }
}
