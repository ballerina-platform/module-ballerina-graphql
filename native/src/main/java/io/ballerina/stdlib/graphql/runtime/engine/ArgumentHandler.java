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
import io.ballerina.runtime.api.Future;
import io.ballerina.runtime.api.PredefinedTypes;
import io.ballerina.runtime.api.TypeTags;
import io.ballerina.runtime.api.creators.TypeCreator;
import io.ballerina.runtime.api.creators.ValueCreator;
import io.ballerina.runtime.api.types.ArrayType;
import io.ballerina.runtime.api.types.Field;
import io.ballerina.runtime.api.types.FiniteType;
import io.ballerina.runtime.api.types.IntersectionType;
import io.ballerina.runtime.api.types.MethodType;
import io.ballerina.runtime.api.types.Parameter;
import io.ballerina.runtime.api.types.RecordType;
import io.ballerina.runtime.api.types.Type;
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

import java.math.BigDecimal;
import java.nio.charset.StandardCharsets;
import java.util.ArrayList;
import java.util.Arrays;
import java.util.List;
import java.util.Objects;

import static io.ballerina.runtime.api.TypeTags.INTERSECTION_TAG;
import static io.ballerina.stdlib.graphql.runtime.engine.EngineUtils.ARGUMENTS_FIELD;
import static io.ballerina.stdlib.graphql.runtime.engine.EngineUtils.FILE_INFO_FIELD;
import static io.ballerina.stdlib.graphql.runtime.engine.EngineUtils.NAME_FIELD;
import static io.ballerina.stdlib.graphql.runtime.engine.EngineUtils.VALUE_FIELD;
import static io.ballerina.stdlib.graphql.runtime.engine.EngineUtils.VARIABLE_DEFINITION;
import static io.ballerina.stdlib.graphql.runtime.engine.EngineUtils.VARIABLE_NAME_FIELD;
import static io.ballerina.stdlib.graphql.runtime.engine.EngineUtils.VARIABLE_VALUE_FIELD;
import static io.ballerina.stdlib.graphql.runtime.engine.EngineUtils.isEnum;
import static io.ballerina.stdlib.graphql.runtime.engine.EngineUtils.isIgnoreType;
import static io.ballerina.stdlib.graphql.runtime.utils.Utils.INTERNAL_NODE;
import static io.ballerina.stdlib.graphql.runtime.utils.Utils.isContext;
import static io.ballerina.stdlib.graphql.runtime.utils.Utils.isField;
import static io.ballerina.stdlib.graphql.runtime.utils.Utils.isFileUpload;
import static io.ballerina.stdlib.graphql.runtime.utils.Utils.isSubgraphModule;

/**
 * This class processes the arguments passed to a GraphQL document to pass into Ballerina functions.
 */
public class ArgumentHandler {
    private final BMap<BString, Object> argumentsMap;
    private final MethodType method;
    private final BMap<BString, Object> fileInfo;
    private final BObject context;
    private final BObject field;
    private final BObject responseGenerator;
    private final boolean validation;

    private static final String REPRESENTATION_TYPENAME = "Representation";
    private static final String ADD_CONSTRAINT_ERRORS_METHOD = "addConstraintValidationErrors";
    private static final String CONSTRAINT_ERROR_MESSAGE = "Constraint validation errors found.";

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

    public Object[] getArguments() {
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
                this.addConstraintValidationErrors(environment, errors);
                throw new ConstraintValidationException(CONSTRAINT_ERROR_MESSAGE);
            }
        }
    }

    private void populateArgumentsMap(BObject fieldNode) {
        BArray argumentArray = fieldNode.getArrayValue(ARGUMENTS_FIELD);
        for (int i = 0; i < argumentArray.size(); i++) {
            BObject argumentNode = (BObject) argumentArray.get(i);
            BString argumentName = argumentNode.getStringValue(NAME_FIELD);
            Parameter parameter = Objects.requireNonNull(getParameterForArgumentNode(argumentName));
            Object argumentValue = this.getArgumentValue(argumentNode, parameter.type);
            this.argumentsMap.put(argumentName, argumentValue);
        }
    }

    private Object getArgumentValue(BObject argumentNode, Type parameterType) {
        if (idsList.contains(argumentNode.getStringValue(NAME_FIELD).getValue())) {
            return this.getIdArgumentValue(argumentNode, parameterType);
        }
        if (isFileUpload(parameterType)) {
            return this.getFileUploadParameter(argumentNode, parameterType);
        } else if (isRepresentationArgument(parameterType)) {
            Object jsonRepresentation = this.getJsonArgument(argumentNode);
            return getRepresentationArgument(jsonRepresentation, parameterType);
        } else if (parameterType.getTag() == TypeTags.RECORD_TYPE_TAG) {
            return this.getInputObjectArgument(argumentNode, (RecordType) parameterType);
        } else if (parameterType.getTag() == TypeTags.INTERSECTION_TAG) {
            return this.getIntersectionTypeArgument(argumentNode, (IntersectionType) parameterType);
        } else if (parameterType.getTag() == TypeTags.ARRAY_TAG) {
            return this.getArrayTypeArgument(argumentNode, (ArrayType) parameterType);
        } else if (parameterType.getTag() == TypeTags.UNION_TAG) {
            return this.getUnionTypeArgument(argumentNode, (UnionType) parameterType);
        } else if (parameterType.getTag() == TypeTags.TYPE_REFERENCED_TYPE_TAG) {
            return this.getArgumentValue(argumentNode, TypeUtils.getReferredType(parameterType));
        } else {
            return this.getScalarArgumentValue(argumentNode);
        }
    }

    private Object getIdArgumentValue(BObject argumentNode, Type parameterType) {
        if (argumentNode.get(VALUE_FIELD) instanceof BString) {
            String obj = ((BString) argumentNode.get(VALUE_FIELD)).getValue();
            return getIdValueFromString(obj, parameterType, argumentNode);
        } else if (argumentNode.get(VALUE_FIELD) instanceof BArray) {
            return getIdValueFromBArray(argumentNode, parameterType, (BArray) argumentNode.get(VALUE_FIELD));
        } else if (argumentNode.get(StringUtils.fromString("variableValue")) instanceof BArray) {
            return getIdValueFromBArray(argumentNode, parameterType,
                    ((BArray) argumentNode.get(StringUtils.fromString("variableValue"))));
        }
        return argumentNode.get(VALUE_FIELD);
    }

    private Object getIdValueFromBArray(BObject argumentNode, Type parameterType, BArray bArray) {
        if (parameterType.getTag() == TypeTags.UNION_TAG) {
            for (Type memberType: ((UnionType) parameterType).getMemberTypes()) {
                if (memberType.getTag() == TypeTags.ARRAY_TAG) {
                    return getIdValueFromBArray(argumentNode, memberType, bArray);
                }
            }
        }
        if (((ArrayType) parameterType).getElementType().getTag() == TypeTags.INT_TAG) {
            int i = 0;
            long[] longArray = new long[bArray.size()];
            for (Object obj: bArray.getValues()) {
                BObject bObject = (BObject) obj;
                longArray[i] = bObject.getIntValue(VALUE_FIELD);
                i++;
            }
            return ValueCreator.createArrayValue(longArray);
        } else {
            String[] stringArray = new String[bArray.size()];
            int i = 0;
            for (Object obj: bArray.getValues()) {
                if (obj instanceof BString) {
                    stringArray[i] = ((BString) obj).getValue();
                } else {
                    BObject bObject = (BObject) obj;
                    stringArray[i] = bObject.getStringValue(VALUE_FIELD).getValue();
                }
                i++;
            }
            return getArrayTypeIdValue(parameterType, stringArray);
        }
    }

    private Object getIdValueFromString(String obj, Type parameterType, BObject argumentNode) {
        if (parameterType.getTag() == TypeTags.STRING_TAG) {
            return StringUtils.fromString(obj);
        } else if (parameterType.getTag() == TypeTags.INT_TAG) {
            return Integer.parseInt(obj);
        } else if (parameterType.getTag() == TypeTags.FLOAT_TAG) {
            return ValueUtils.convert(JsonUtils.parse(obj), parameterType);
        } else if (parameterType.getTag() == TypeTags.DECIMAL_TAG) {
            return ValueUtils.convert(JsonUtils.parse(obj), parameterType);
        } else if (parameterType.getTag() == TypeTags.TYPE_REFERENCED_TYPE_TAG) {
            // not validating if this is uuid:Uuid since compiler plugin does that
            return ValueCreator.createRecordValue(parameterType.getPackage(), parameterType.getName(),
                    (BMap<BString, Object>) JsonUtils.parse(obj.replaceAll("\\\\", "")));
        } else if (parameterType.getTag() == TypeTags.UNION_TAG) {
            return getUnionTypeIdValue(parameterType, argumentNode);
        }
        return argumentNode.get(VALUE_FIELD);
    }

    private Object getUnionTypeIdValue(Type parameterType, BObject argumentNode) {
        List<Type> members = ((UnionType) parameterType).getMemberTypes();
        for (Type member : members) {
            if (member.getTag() != TypeTags.NULL_TAG && member.getTag() != TypeTags.ERROR_TAG) {
                return getIdArgumentValue(argumentNode, member);
            }
        }
        return null;
    }

    private Object getArrayTypeIdValue(Type parameterType, String[] stringArray) {
        Type memberType = ((ArrayType) parameterType).getElementType();
        if (memberType.getTag() == TypeTags.INT_TAG) {
            return ValueCreator.createArrayValue(getIntArrayTypeIdValue(stringArray));
        } else if (memberType.getTag() == TypeTags.FLOAT_TAG) {
            return ValueCreator.createArrayValue(Arrays.toString(getFloatArrayTypeIdValue(stringArray))
                    .getBytes(StandardCharsets.UTF_8));
        } else if (memberType.getTag() == TypeTags.DECIMAL_TAG) {
            return ValueCreator.createArrayValue(Arrays.toString(getDecimalArrayTypeIdValue(stringArray))
                    .getBytes(StandardCharsets.UTF_8));
        } else if (memberType.getTag() == TypeTags.STRING_TAG) {
            return ValueCreator.createArrayValue(getStringArrayTypeIdValue(stringArray));
        } else if (memberType.getTag() == TypeTags.TYPE_REFERENCED_TYPE_TAG) {
            return ValueCreator.createArrayValue(getTypeRefArrayTypeIdValue(stringArray, parameterType),
                    (ArrayType) parameterType);
        }
        return null;
    }

    private BMap<BString, Object>[] getTypeRefArrayTypeIdValue(String[] stringValues, Type parameterType) {
        BMap<BString, Object>[] uuidArray = new BMap[stringValues.length];
        for (int i = 0; i < stringValues.length; i++) {
            uuidArray[i] = ValueCreator.createRecordValue(
                    ((ArrayType) parameterType).getElementType().getPackage(),
                    ((ArrayType) parameterType).getElementType().getName(),
                    (BMap<BString, Object>) JsonUtils.parse(stringValues[i].replaceAll("\\\\", "")));
        }
        return uuidArray;
    }

    private BString[] getStringArrayTypeIdValue(String[] stringValues) {
        BString[] bStringArray = new BString[stringValues.length];
        for (int i = 0; i < stringValues.length; i++) {
            bStringArray[i] = StringUtils.fromString(stringValues[i]);
        }
        return bStringArray;
    }

    private BigDecimal[] getDecimalArrayTypeIdValue(String[] stringArray) {
        BigDecimal[] values = new BigDecimal[stringArray.length];
        for (int i = 0; i < stringArray.length; i++) {
            values[i] = new BigDecimal(stringArray[i]);
        }
        return values;
    }

    private float[] getFloatArrayTypeIdValue(String[] stringArray) {
        float[] values = new float[stringArray.length];
        for (int i = 0; i < stringArray.length; i++) {
            values[i] = Float.parseFloat(stringArray[i]);
        }
        return values;
    }

    private long[] getIntArrayTypeIdValue(String[] stringArray) {
        long[] values = new long[stringArray.length];
        for (int i = 0; i < stringArray.length; i++) {
            if (!stringArray[i].equals("")) {
                values[i] = Integer.parseInt(stringArray[i]);
            }
        }
        return values;
    }

    private BMap<BString, Object> getRepresentationArgument(Object jsonRepresentation, Type parameterType) {
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

    @SuppressWarnings("unchecked")
    private BMap<BString, Object> getInputObjectArgument(BObject argumentNode, RecordType recordType) {
        BMap<BString, Object> recordValue = recordType.getZeroValue();
        if (argumentNode.getBooleanValue(VARIABLE_DEFINITION)) {
            BMap<BString, Object> variablesMap = argumentNode.getMapValue(VARIABLE_VALUE_FIELD);
            return JsonUtils.convertJSONToRecord(variablesMap, recordType);
        }
        BArray inputObjectFields = argumentNode.getArrayValue(VALUE_FIELD);
        for (int i = 0; i < inputObjectFields.size(); i++) {
            BObject inputObjectField = (BObject) inputObjectFields.get(i);
            BString inputObjectFieldName = inputObjectField.getStringValue(NAME_FIELD);
            Field field = recordType.getFields().get(inputObjectFieldName.getValue());
            Object fieldValue = getArgumentValue(inputObjectField, field.getFieldType());
            recordValue.put(inputObjectFieldName, fieldValue);
        }
        return recordValue;
    }

    private Object getJsonArgument(BObject argumentNode) {
        int kind = (int) argumentNode.getIntValue(KIND_FIELD);
        Object valueField = argumentNode.get(VALUE_FIELD);
        switch (kind) {
            case T_STRING:
            case T_INT:
            case T_FLOAT:
            case T_BOOLEAN:
                return JsonUtils.convertToJson(valueField);
            case T_INPUT_OBJECT:
                return getJsonObject(argumentNode);
            case T_LIST:
                return getJsonList(argumentNode);
        }
        return null;
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

    private Object getIntersectionTypeArgument(BObject argumentNode, IntersectionType intersectionType) {
        Type effectiveType = TypeUtils.getReferredType(getEffectiveType(intersectionType));
        if (effectiveType.getTag() == TypeTags.ARRAY_TAG) {
            BArray valueArray = getArrayTypeArgument(argumentNode, (ArrayType) effectiveType);
            valueArray.freezeDirect();
            return valueArray;
        }
        BMap<BString, Object> argumentValue = getInputObjectArgument(argumentNode, (RecordType) effectiveType);
        argumentValue.freezeDirect();
        return argumentValue;
    }

    private BArray getArrayTypeArgument(BObject argumentNode, ArrayType arrayType) {
        BArray valueArray = ValueCreator.createArrayValue(arrayType);
        if (argumentNode.getBooleanValue(VARIABLE_DEFINITION)) {
            BArray argumentsArray = argumentNode.getArrayValue(VARIABLE_VALUE_FIELD);
            if (isRepresentationArgument(arrayType.getElementType())) {
                Object[] representations = argumentsArray.getValues();
                Object[] representationRecords = Arrays.stream(representations)
                        .map(entity -> this.getRepresentationArgument(entity, arrayType.getElementType())).toArray();
                return ValueCreator.createArrayValue(representationRecords, arrayType);
            }
            return (BArray) JsonUtils.convertJSON(argumentsArray, arrayType);
        }
        BArray argumentArray = argumentNode.getArrayValue(VALUE_FIELD);
        for (int i = 0; i < argumentArray.size(); i++) {
            BObject argumentElementNode = (BObject) argumentArray.get(i);
            Object elementValue = getArgumentValue(argumentElementNode, arrayType.getElementType());
            valueArray.append(elementValue);
        }
        return valueArray;
    }

    private Object getUnionTypeArgument(BObject argumentNode, UnionType unionType) {
        if (isEnum(unionType)) {
            return getEnumTypeArgument(argumentNode, unionType);
        } else if (unionType.isNilable()) {
            if (argumentNode.getBooleanValue(VARIABLE_DEFINITION) && argumentNode.get(VARIABLE_VALUE_FIELD) == null) {
                return null;
            } else if (!argumentNode.getBooleanValue(VARIABLE_DEFINITION) && argumentNode.get(VALUE_FIELD) == null) {
                return null;
            }
        }
        Type effectiveType = getEffectiveType(unionType);
        return getArgumentValue(argumentNode, effectiveType);
    }

    private Object getEnumTypeArgument(BObject argumentNode, UnionType enumType) {
        BString enumName;
        if (argumentNode.getBooleanValue(VARIABLE_DEFINITION)) {
            enumName = argumentNode.getStringValue(VARIABLE_VALUE_FIELD);
        } else {
            enumName = argumentNode.getStringValue(VALUE_FIELD);
        }
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

    private Object getScalarArgumentValue(BObject argumentNode) {
        if (argumentNode.getBooleanValue(VARIABLE_DEFINITION)) {
            return argumentNode.get(VARIABLE_VALUE_FIELD);
        }
        return argumentNode.get(VALUE_FIELD);
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
        Object[] result = new Object[parameters.length * 2];
        for (int i = 0, j = 0; i < parameters.length; i += 1, j += 2) {
            if (isContext(parameters[i].type)) {
                result[j] = this.context;
                result[j + 1] = true;
                continue;
            }
            if (isField(parameters[i].type)) {
                result[j] = this.field;
                result[j + 1] = true;
                continue;
            }
            if (this.argumentsMap.get(StringUtils.fromString(parameters[i].name)) == null) {
                result[j] = parameters[i].type.getZeroValue();
                result[j + 1] = false;
            } else {
                result[j] = this.argumentsMap.get(StringUtils.fromString(parameters[i].name));
                result[j + 1] = true;
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
        return TypeUtils.getReferredType(type).getTag() == TypeTags.RECORD_TYPE_TAG && isSubgraphModule(type)
                && type.getName().equals(REPRESENTATION_TYPENAME);
    }

    private void addConstraintValidationErrors(Environment environment, BArray errors) {
        Future future = environment.markAsync();
        ExecutionCallback executionCallback = new ExecutionCallback(future);
        BObject fieldNode = this.field.getObjectValue(INTERNAL_NODE);
        Object[] arguments = {errors, true, fieldNode, true};
        environment.getRuntime()
                .invokeMethodAsyncConcurrently(this.responseGenerator, ADD_CONSTRAINT_ERRORS_METHOD, null, null,
                        executionCallback, null, PredefinedTypes.TYPE_NULL, arguments);
    }

    private static BTypedesc getTypeDescFromParameter(Parameter parameter) {
        BTypedesc bTypedesc = ValueCreator.createTypedescValue(parameter.type);
        if (bTypedesc.getDescribingType().getTag() == INTERSECTION_TAG) {
            Type type = getEffectiveType((IntersectionType) bTypedesc.getDescribingType());
            return ValueCreator.createTypedescValue(type);
        }
        return bTypedesc;
    }
}
