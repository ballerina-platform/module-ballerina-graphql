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

package io.ballerina.stdlib.graphql.compiler;

import io.ballerina.projects.DiagnosticResult;
import io.ballerina.projects.ProjectEnvironmentBuilder;
import io.ballerina.projects.directory.BuildProject;
import io.ballerina.projects.environment.Environment;
import io.ballerina.projects.environment.EnvironmentBuilder;
import io.ballerina.stdlib.graphql.compiler.service.errors.CompilationError;
import io.ballerina.tools.diagnostics.Diagnostic;
import io.ballerina.tools.diagnostics.DiagnosticSeverity;
import io.ballerina.tools.diagnostics.Location;
import org.testng.Assert;
import org.testng.annotations.Test;

import java.nio.file.Path;
import java.nio.file.Paths;
import java.util.Iterator;

/**
 * This class includes tests for Ballerina Graphql compiler plugin service validation.
 */
public class ServiceValidationTest {

    private static final Path RESOURCE_DIRECTORY = Paths.get("src", "test", "resources", "ballerina_sources",
                                                             "validator_tests").toAbsolutePath();
    private static final Path DISTRIBUTION_PATH = Paths.get("../", "target", "ballerina-runtime")
            .toAbsolutePath();

    @Test
    public void testValidResourceReturnTypes() {
        String packagePath = "valid_service_1";
        DiagnosticResult diagnosticResult = getDiagnosticResult(packagePath);
        Assert.assertEquals(diagnosticResult.errorCount(), 0);
    }

    @Test
    public void testValidResourceInputTypes() {
        String packagePath = "valid_service_2";
        DiagnosticResult diagnosticResult = getDiagnosticResult(packagePath);
        Assert.assertEquals(diagnosticResult.errorCount(), 0);
    }

    @Test
    public void testValidServiceConfigurationAnnotation() {
        String packagePath = "valid_service_3";
        DiagnosticResult diagnosticResult = getDiagnosticResult(packagePath);
        Assert.assertEquals(diagnosticResult.errorCount(), 0);
    }

    @Test
    public void testResourceReturningEnum() {
        String packagePath = "valid_service_4";
        DiagnosticResult diagnosticResult = getDiagnosticResult(packagePath);
        Assert.assertEquals(diagnosticResult.errorCount(), 0);
    }

    @Test
    public void testEnumAsResourceInputParameter() {
        String packagePath = "valid_service_5";
        DiagnosticResult diagnosticResult = getDiagnosticResult(packagePath);
        Assert.assertEquals(diagnosticResult.errorCount(), 0);
    }

    @Test
    public void testValidListenerConfigurations() {
        String packagePath = "valid_service_6";
        DiagnosticResult diagnosticResult = getDiagnosticResult(packagePath);
        Assert.assertEquals(diagnosticResult.errorCount(), 0);
    }

    @Test
    public void testOptionalInputParametersInResources() {
        String packagePath = "valid_service_7";
        DiagnosticResult diagnosticResult = getDiagnosticResult(packagePath);
        Assert.assertEquals(diagnosticResult.errorCount(), 0);
    }

    @Test
    public void testReturningDistinctServiceObjects() {
        String packagePath = "valid_service_8";
        DiagnosticResult diagnosticResult = getDiagnosticResult(packagePath);
        Assert.assertEquals(diagnosticResult.errorCount(), 0);
    }

    @Test
    public void testReturningServiceTypesRecursively() {
        String packagePath = "valid_service_9";
        DiagnosticResult diagnosticResult = getDiagnosticResult(packagePath);
        Assert.assertEquals(diagnosticResult.errorCount(), 0);
    }

    @Test
    public void testFieldsInServiceObject() {
        String packagePath = "valid_service_10";
        DiagnosticResult diagnosticResult = getDiagnosticResult(packagePath);
        Assert.assertEquals(diagnosticResult.errorCount(), 0);
    }

    @Test
    public void testInputObjectTypeInputParameter() {
        String packagePath = "valid_service_11";
        DiagnosticResult diagnosticResult = getDiagnosticResult(packagePath);
        Assert.assertEquals(diagnosticResult.errorCount(), 0);
    }

    @Test
    public void testGraphQLContextAsFirstParameter() {
        String packagePath = "valid_service_12";
        DiagnosticResult diagnosticResult = getDiagnosticResult(packagePath);
        Assert.assertEquals(diagnosticResult.errorCount(), 0);
    }

    @Test
    public void testGraphQLContextInsideReturningServices() {
        String packagePath = "valid_service_13";
        DiagnosticResult diagnosticResult = getDiagnosticResult(packagePath);
        Assert.assertEquals(diagnosticResult.errorCount(), 0);
    }

    @Test
    public void testGraphQLListTypeInputParametersInResources() {
        String packagePath = "valid_service_14";
        DiagnosticResult diagnosticResult = getDiagnosticResult(packagePath);
        Assert.assertEquals(diagnosticResult.errorCount(), 0);
    }

    @Test
    public void testGraphQLFileUpload() {
        String packagePath = "valid_service_15";
        DiagnosticResult diagnosticResult = getDiagnosticResult(packagePath);
        Assert.assertEquals(diagnosticResult.errorCount(), 0);
    }

    @Test
    public void testIntersectionTypes() {
        String packagePath = "valid_service_16";
        DiagnosticResult diagnosticResult = getDiagnosticResult(packagePath);
        Assert.assertEquals(diagnosticResult.errorCount(), 0);
    }

    @Test
    public void testRecordTypes() {
        String packagePath = "valid_service_17";
        DiagnosticResult diagnosticResult = getDiagnosticResult(packagePath);
        Assert.assertEquals(diagnosticResult.errorCount(), 0);
    }

    @Test
    public void testInterfaces() {
        String packagePath = "valid_service_18";
        DiagnosticResult diagnosticResult = getDiagnosticResult(packagePath);
        Assert.assertEquals(diagnosticResult.errorCount(), 0);
    }

    @Test
    public void testInterfacesImplementingInterfaces() {
        String packagePath = "valid_service_19";
        DiagnosticResult diagnosticResult = getDiagnosticResult(packagePath);
        Assert.assertEquals(diagnosticResult.errorCount(), 0);
    }

    @Test
    public void testMultipleInterfaceImplementations() {
        String packagePath = "valid_service_20";
        DiagnosticResult diagnosticResult = getDiagnosticResult(packagePath);
        Assert.assertEquals(diagnosticResult.errorCount(), 0);
    }

    @Test
    public void testMultipleInterfaceImplementationsWithUnusedInterface() {
        String packagePath = "valid_service_21";
        DiagnosticResult diagnosticResult = getDiagnosticResult(packagePath);
        Assert.assertEquals(diagnosticResult.errorCount(), 0);
    }

    @Test
    public void testSubscriptionResources() {
        String packagePath = "valid_service_22";
        DiagnosticResult diagnosticResult = getDiagnosticResult(packagePath);
        Assert.assertEquals(diagnosticResult.errorCount(), 0);
    }

    @Test
    public void testInterceptors() {
        String packagePath = "valid_service_23";
        DiagnosticResult diagnosticResult = getDiagnosticResult(packagePath);
        Assert.assertEquals(diagnosticResult.errorCount(), 0);
    }

    @Test
    public void testMultipleListenersOnSameService() {
        String packagePath = "invalid_service_1";
        DiagnosticResult diagnosticResult = getDiagnosticResult(packagePath);
        Assert.assertEquals(diagnosticResult.errorCount(), 1);
        Diagnostic diagnostic = diagnosticResult.errors().iterator().next();
        assertError(diagnostic, CompilationError.INVALID_MULTIPLE_LISTENERS, 19, 1);
    }

    @Test
    public void testMissingResourceFunctionInService() {
        String packagePath = "invalid_service_2";
        DiagnosticResult diagnosticResult = getDiagnosticResult(packagePath);
        Assert.assertEquals(diagnosticResult.errorCount(), 1);
        Diagnostic diagnostic = diagnosticResult.errors().iterator().next();
        assertError(diagnostic, CompilationError.MISSING_RESOURCE_FUNCTIONS, 19, 1);
    }

    @Test
    public void testInvalidResourceAccessor() {
        String packagePath = "invalid_service_3";
        DiagnosticResult diagnosticResult = getDiagnosticResult(packagePath);
        Assert.assertEquals(diagnosticResult.errorCount(), 2);
        Iterator<Diagnostic> diagnosticIterator = diagnosticResult.errors().iterator();

        Diagnostic diagnostic = diagnosticIterator.next();
        assertError(diagnostic, CompilationError.INVALID_ROOT_RESOURCE_ACCESSOR, 20, 23);

        diagnostic = diagnosticIterator.next();
        assertError(diagnostic, CompilationError.MISSING_RESOURCE_FUNCTIONS, 19, 1);
    }

    @Test
    public void testInvalidResourceReturnTypes() {
        String packagePath = "invalid_service_4";
        DiagnosticResult diagnosticResult = getDiagnosticResult(packagePath);
        Assert.assertEquals(diagnosticResult.errorCount(), 12);
        Iterator<Diagnostic> diagnosticIterator = diagnosticResult.errors().iterator();

        Diagnostic diagnostic = diagnosticIterator.next();
        assertError(diagnostic, CompilationError.INVALID_RETURN_TYPE, 28, 5);

        diagnostic = diagnosticIterator.next();
        assertError(diagnostic, CompilationError.INVALID_RETURN_TYPE, 34, 5);

        diagnostic = diagnosticIterator.next();
        assertError(diagnostic, CompilationError.INVALID_RETURN_TYPE, 41, 5);

        diagnostic = diagnosticIterator.next();
        assertError(diagnostic, CompilationError.INVALID_RETURN_TYPE, 48, 5);

        diagnostic = diagnosticIterator.next();
        assertError(diagnostic, CompilationError.INVALID_UNION_MEMBER_TYPE, 55, 5);

        diagnostic = diagnosticIterator.next();
        assertError(diagnostic, CompilationError.INVALID_UNION_MEMBER_TYPE, 55, 5);

        diagnostic = diagnosticIterator.next();
        assertError(diagnostic, CompilationError.INVALID_UNION_MEMBER_TYPE, 61, 5);

        diagnostic = diagnosticIterator.next();
        assertError(diagnostic, CompilationError.INVALID_UNION_MEMBER_TYPE, 61, 5);

        diagnostic = diagnosticIterator.next();
        assertError(diagnostic, CompilationError.INVALID_UNION_MEMBER_TYPE, 67, 5);

        diagnostic = diagnosticIterator.next();
        assertError(diagnostic, CompilationError.INVALID_UNION_MEMBER_TYPE, 67, 5);

        diagnostic = diagnosticIterator.next();
        assertError(diagnostic, CompilationError.INVALID_RETURN_TYPE, 74, 5);

        diagnostic = diagnosticIterator.next();
        assertError(diagnostic, CompilationError.INVALID_RETURN_TYPE, 93, 5);
    }

    @Test
    public void testInvalidResourceInputParameterTypes() {
        String packagePath = "invalid_service_5";
        DiagnosticResult diagnosticResult = getDiagnosticResult(packagePath);
        Assert.assertEquals(diagnosticResult.errorCount(), 7);
        Iterator<Diagnostic> diagnosticIterator = diagnosticResult.errors().iterator();

        Diagnostic diagnostic = diagnosticIterator.next();
        String message = "Invalid GraphQL input parameter type `json`";
        assertErrorMessage(diagnostic, message, 20, 38);

        diagnostic = diagnosticIterator.next();
        message = "Invalid GraphQL input parameter type `map`";
        assertErrorMessage(diagnostic, message, 26, 45);

        diagnostic = diagnosticIterator.next();
        message = "Invalid GraphQL input parameter type `byte`";
        assertErrorMessage(diagnostic, message, 32, 40);

        diagnostic = diagnosticIterator.next();
        assertError(diagnostic, CompilationError.INVALID_INPUT_TYPE_UNION, 43, 39);

        diagnostic = diagnosticIterator.next();
        message = "Invalid GraphQL input parameter type `byte`";
        assertErrorMessage(diagnostic, message, 49, 49);

        diagnostic = diagnosticIterator.next();
        message = "Invalid GraphQL input parameter type `any`";
        assertErrorMessage(diagnostic, message, 55, 37);

        diagnostic = diagnosticIterator.next();
        message = "Invalid GraphQL input parameter type `anydata`";
        assertErrorMessage(diagnostic, message, 61, 41);
    }

    @Test
    public void testReturningOnlyErrorOrNil() {
        String packagePath = "invalid_service_6";
        DiagnosticResult diagnosticResult = getDiagnosticResult(packagePath);
        Assert.assertEquals(diagnosticResult.errorCount(), 1);
        Diagnostic diagnostic = diagnosticResult.errors().iterator().next();
        assertError(diagnostic, CompilationError.INVALID_RETURN_TYPE_ERROR_OR_NIL, 20, 5);
    }

    @Test
    public void testReturningOnlyNil() {
        String packagePath = "invalid_service_7";
        DiagnosticResult diagnosticResult = getDiagnosticResult(packagePath);
        Assert.assertEquals(diagnosticResult.errorCount(), 1);
        Diagnostic diagnostic = diagnosticResult.errors().iterator().next();
        assertError(diagnostic, CompilationError.INVALID_RETURN_TYPE_NIL, 20, 5);
    }

    @Test
    public void testReturningOnlyError() {
        String packagePath = "invalid_service_8";
        DiagnosticResult diagnosticResult = getDiagnosticResult(packagePath);
        Assert.assertEquals(diagnosticResult.errorCount(), 1);
        Diagnostic diagnostic = diagnosticResult.errors().iterator().next();
        assertError(diagnostic, CompilationError.INVALID_RETURN_TYPE_ERROR, 20, 5);
    }

    @Test
    public void testListenerInitParameters() {
        String packagePath = "invalid_service_9";
        DiagnosticResult diagnosticResult = getDiagnosticResult(packagePath);
        Assert.assertEquals(diagnosticResult.errorCount(), 5);
        Iterator<Diagnostic> diagnosticIterator = diagnosticResult.errors().iterator();

        Diagnostic diagnostic = diagnosticIterator.next();
        assertError(diagnostic, CompilationError.INVALID_LISTENER_INIT, 29, 58);

        diagnostic = diagnosticIterator.next();
        assertError(diagnostic, CompilationError.INVALID_LISTENER_INIT, 30, 64);

        diagnostic = diagnosticIterator.next();
        assertError(diagnostic, CompilationError.INVALID_LISTENER_INIT, 31, 75);

        diagnostic = diagnosticIterator.next();
        assertError(diagnostic, CompilationError.INVALID_LISTENER_INIT, 32, 81);

        diagnostic = diagnosticIterator.next();
        assertError(diagnostic, CompilationError.INVALID_LISTENER_INIT, 34, 64);
    }

    @Test
    public void testInvalidInputParameterUnions() {
        String packagePath = "invalid_service_10";
        DiagnosticResult diagnosticResult = getDiagnosticResult(packagePath);
        Assert.assertEquals(diagnosticResult.errorCount(), 4);
        Iterator<Diagnostic> diagnosticIterator = diagnosticResult.errors().iterator();

        Diagnostic diagnostic = diagnosticIterator.next();
        assertError(diagnostic, CompilationError.INVALID_INPUT_TYPE_UNION, 20, 48);

        diagnostic = diagnosticIterator.next();
        assertErrorFormat(diagnostic, CompilationError.INVALID_INPUT_PARAMETER_TYPE, 26, 39);

        diagnostic = diagnosticIterator.next();
        assertErrorFormat(diagnostic, CompilationError.INVALID_INPUT_PARAMETER_TYPE, 32, 46);

        diagnostic = diagnosticIterator.next();
        assertErrorFormat(diagnostic, CompilationError.INVALID_INPUT_PARAMETER_TYPE, 38, 41);
    }

    @Test
    public void testInvalidResourceReturnTypeUnions() {
        String packagePath = "invalid_service_11";
        DiagnosticResult diagnosticResult = getDiagnosticResult(packagePath);
        Assert.assertEquals(diagnosticResult.errorCount(), 4);
        Iterator<Diagnostic> diagnosticIterator = diagnosticResult.errors().iterator();

        Diagnostic diagnostic = diagnosticIterator.next();
        assertError(diagnostic, CompilationError.INVALID_UNION_MEMBER_TYPE, 20, 5);

        diagnostic = diagnosticIterator.next();
        assertError(diagnostic, CompilationError.INVALID_UNION_MEMBER_TYPE, 20, 5);

        diagnostic = diagnosticIterator.next();
        assertError(diagnostic, CompilationError.INVALID_UNION_MEMBER_TYPE, 26, 5);

        diagnostic = diagnosticIterator.next();
        assertError(diagnostic, CompilationError.INVALID_UNION_MEMBER_TYPE, 32, 5);
    }

    @Test
    public void testInvalidAccessorsInServicesReturningFromResources() {
        String packagePath = "invalid_service_12";
        DiagnosticResult diagnosticResult = getDiagnosticResult(packagePath);
        Assert.assertEquals(diagnosticResult.errorCount(), 4);
        Iterator<Diagnostic> diagnosticIterator = diagnosticResult.errors().iterator();

        // Same erroneous class is used in two different GraphQL services. Hence, the duplication of errors.
        Diagnostic diagnostic = diagnosticIterator.next();
        assertError(diagnostic, CompilationError.INVALID_RESOURCE_FUNCTION_ACCESSOR, 44, 23);

        diagnostic = diagnosticIterator.next();
        assertError(diagnostic, CompilationError.INVALID_RESOURCE_FUNCTION_ACCESSOR, 44, 23);

        diagnostic = diagnosticIterator.next();
        assertError(diagnostic, CompilationError.INVALID_RESOURCE_FUNCTION_ACCESSOR, 50, 23);

        diagnostic = diagnosticIterator.next();
        assertError(diagnostic, CompilationError.INVALID_RESOURCE_FUNCTION_ACCESSOR, 50, 23);
    }

    @Test
    public void testInvalidReturnTypesInServicesReturningFromResources() {
        String packagePath = "invalid_service_13";
        DiagnosticResult diagnosticResult = getDiagnosticResult(packagePath);
        Assert.assertEquals(diagnosticResult.errorCount(), 4);
        Iterator<Diagnostic> diagnosticIterator = diagnosticResult.errors().iterator();

        // Same erroneous class is used in two different GraphQL services. Hence, the duplication of errors.
        Diagnostic diagnostic = diagnosticIterator.next();
        assertError(diagnostic, CompilationError.INVALID_RETURN_TYPE, 45, 23);

        diagnostic = diagnosticIterator.next();
        assertError(diagnostic, CompilationError.INVALID_RETURN_TYPE, 45, 23);

        diagnostic = diagnosticIterator.next();
        assertError(diagnostic, CompilationError.INVALID_RETURN_TYPE, 52, 23);

        diagnostic = diagnosticIterator.next();
        assertError(diagnostic, CompilationError.INVALID_RETURN_TYPE, 52, 23);
    }

    @Test
    public void testInvalidInputParametersInServicesReturningFromResources() {
        String packagePath = "invalid_service_14";
        DiagnosticResult diagnosticResult = getDiagnosticResult(packagePath);
        Assert.assertEquals(diagnosticResult.errorCount(), 4);
        Iterator<Diagnostic> diagnosticIterator = diagnosticResult.errors().iterator();

        // Same erroneous class is used in two different GraphQL services. Hence, the duplication of errors.
        Diagnostic diagnostic = diagnosticIterator.next();
        assertErrorFormat(diagnostic, CompilationError.INVALID_INPUT_PARAMETER_TYPE, 44, 48);

        diagnostic = diagnosticIterator.next();
        assertErrorFormat(diagnostic, CompilationError.INVALID_INPUT_PARAMETER_TYPE, 44, 48);

        diagnostic = diagnosticIterator.next();
        assertErrorFormat(diagnostic, CompilationError.INVALID_INPUT_PARAMETER_TYPE, 50, 46);

        diagnostic = diagnosticIterator.next();
        assertErrorFormat(diagnostic, CompilationError.INVALID_INPUT_PARAMETER_TYPE, 50, 46);
    }

    @Test
    public void testInvalidListenerInitParameters() {
        String packagePath = "invalid_service_15";
        DiagnosticResult diagnosticResult = getDiagnosticResult(packagePath);
        Assert.assertEquals(diagnosticResult.errorCount(), 4);
        Iterator<Diagnostic> diagnosticIterator = diagnosticResult.errors().iterator();

        Diagnostic diagnostic = diagnosticIterator.next();
        assertError(diagnostic, CompilationError.INVALID_LISTENER_INIT, 24, 58);

        diagnostic = diagnosticIterator.next();
        assertError(diagnostic, CompilationError.INVALID_LISTENER_INIT, 25, 64);

        diagnostic = diagnosticIterator.next();
        assertError(diagnostic, CompilationError.INVALID_LISTENER_INIT, 26, 75);

        diagnostic = diagnosticIterator.next();
        assertError(diagnostic, CompilationError.INVALID_LISTENER_INIT, 27, 81);
    }

    @Test
    public void testInvalidResourcePath() {
        String packagePath = "invalid_service_16";
        DiagnosticResult diagnosticResult = getDiagnosticResult(packagePath);
        Assert.assertEquals(diagnosticResult.errorCount(), 8);
        Iterator<Diagnostic> diagnosticIterator = diagnosticResult.errors().iterator();

        Diagnostic diagnostic = diagnosticIterator.next();
        assertError(diagnostic, CompilationError.INVALID_FIELD_NAME, 42, 5);

        diagnostic = diagnosticIterator.next();
        assertError(diagnostic, CompilationError.INVALID_FIELD_NAME, 50, 5);

        diagnostic = diagnosticIterator.next();
        assertError(diagnostic, CompilationError.INVALID_FIELD_NAME, 50, 5);

        diagnostic = diagnosticIterator.next();
        assertError(diagnostic, CompilationError.INVALID_FIELD_NAME, 61, 5);

        diagnostic = diagnosticIterator.next();
        assertError(diagnostic, CompilationError.INVALID_FIELD_NAME, 65, 5);

        diagnostic = diagnosticIterator.next();
        assertError(diagnostic, CompilationError.INVALID_FIELD_NAME, 69, 5);

        diagnostic = diagnosticIterator.next();
        assertError(diagnostic, CompilationError.INVALID_FIELD_NAME, 36, 23);

        diagnostic = diagnosticIterator.next();
        assertError(diagnostic, CompilationError.INVALID_FIELD_NAME, 77, 5);
    }

    @Test
    public void testInvalidReturnTypeAny() {
        String packagePath = "invalid_service_17";
        DiagnosticResult diagnosticResult = getDiagnosticResult(packagePath);
        Assert.assertEquals(diagnosticResult.errorCount(), 2);
        Iterator<Diagnostic> diagnosticIterator = diagnosticResult.errors().iterator();

        Diagnostic diagnostic = diagnosticIterator.next();
        assertError(diagnostic, CompilationError.INVALID_RETURN_TYPE_ANY, 20, 5);

        diagnostic = diagnosticIterator.next();
        assertError(diagnostic, CompilationError.INVALID_RETURN_TYPE_ANY, 24, 5);
    }

    @Test
    public void testServiceWithOnlyRemoteMethods() {
        String packagePath = "invalid_service_18";
        DiagnosticResult diagnosticResult = getDiagnosticResult(packagePath);
        Assert.assertEquals(diagnosticResult.errorCount(), 1);
        Diagnostic diagnostic = diagnosticResult.errors().iterator().next();
        assertError(diagnostic, CompilationError.MISSING_RESOURCE_FUNCTIONS, 19, 1);
    }

    @Test
    public void testRemoteMethodWithInvalidReturnType() {
        String packagePath = "invalid_service_19";
        DiagnosticResult diagnosticResult = getDiagnosticResult(packagePath);
        Assert.assertEquals(diagnosticResult.errorCount(), 1);
        Diagnostic diagnostic = diagnosticResult.errors().iterator().next();
        assertError(diagnostic, CompilationError.INVALID_RETURN_TYPE, 23, 5);
    }

    @Test
    public void testRemoteMethodInsideReturningServiceObject() {
        String packagePath = "invalid_service_20";
        DiagnosticResult diagnosticResult = getDiagnosticResult(packagePath);
        Assert.assertEquals(diagnosticResult.errorCount(), 1);
        Diagnostic diagnostic = diagnosticResult.errors().iterator().next();
        assertError(diagnostic, CompilationError.INVALID_FUNCTION, 36, 21);
    }

    @Test
    public void testMissingResourceMethodFromReturningServiceClass() {
        String packagePath = "invalid_service_21";
        DiagnosticResult diagnosticResult = getDiagnosticResult(packagePath);
        Assert.assertEquals(diagnosticResult.errorCount(), 1);
        Diagnostic diagnostic = diagnosticResult.errors().iterator().next();
        assertError(diagnostic, CompilationError.MISSING_RESOURCE_FUNCTIONS, 25, 15);
    }

    @Test
    public void testInvalidInputObjects() {
        String packagePath = "invalid_service_22";
        DiagnosticResult diagnosticResult = getDiagnosticResult(packagePath);
        Assert.assertEquals(diagnosticResult.errorCount(), 11);
        Iterator<Diagnostic> diagnosticIterator = diagnosticResult.errors().iterator();
        Diagnostic diagnostic = diagnosticIterator.next();
        assertError(diagnostic, CompilationError.INVALID_RESOURCE_INPUT_OBJECT_PARAM, 39, 42);

        diagnostic = diagnosticIterator.next();
        assertError(diagnostic, CompilationError.INVALID_RESOURCE_INPUT_OBJECT_PARAM, 48, 37);

        diagnostic = diagnosticIterator.next();
        assertError(diagnostic, CompilationError.INVALID_RETURN_TYPE_INPUT_OBJECT, 61, 5);

        diagnostic = diagnosticIterator.next();
        assertError(diagnostic, CompilationError.INVALID_RESOURCE_INPUT_OBJECT_PARAM, 77, 50);

        diagnostic = diagnosticIterator.next();
        assertError(diagnostic, CompilationError.INVALID_RESOURCE_INPUT_OBJECT_PARAM, 83, 42);

        diagnostic = diagnosticIterator.next();
        assertError(diagnostic, CompilationError.INVALID_RESOURCE_INPUT_OBJECT_PARAM, 95, 43);

        diagnostic = diagnosticIterator.next();
        assertError(diagnostic, CompilationError.INVALID_RESOURCE_INPUT_OBJECT_PARAM, 110, 43);

        diagnostic = diagnosticIterator.next();
        assertError(diagnostic, CompilationError.INVALID_RESOURCE_INPUT_OBJECT_PARAM, 122, 39);

        diagnostic = diagnosticIterator.next();
        assertError(diagnostic, CompilationError.INVALID_RESOURCE_INPUT_OBJECT_PARAM, 134, 40);

        diagnostic = diagnosticIterator.next();
        assertError(diagnostic, CompilationError.INVALID_RETURN_TYPE_INPUT_OBJECT, 153, 5);
    }

    @Test
    public void testGraphQLContextAsAnotherParameter() {
        String packagePath = "invalid_service_23";
        DiagnosticResult diagnosticResult = getDiagnosticResult(packagePath);
        Assert.assertEquals(diagnosticResult.errorCount(), 2);
        Iterator<Diagnostic> diagnosticIterator = diagnosticResult.errors().iterator();
        Diagnostic diagnostic = diagnosticIterator.next();
        assertError(diagnostic, CompilationError.INVALID_LOCATION_FOR_CONTEXT_PARAMETER, 20, 64);

        diagnostic = diagnosticIterator.next();
        assertError(diagnostic, CompilationError.INVALID_LOCATION_FOR_CONTEXT_PARAMETER, 24, 61);
    }

    @Test
    public void testInvalidContextObject() {
        String packagePath = "invalid_service_24";
        DiagnosticResult diagnosticResult = getDiagnosticResult(packagePath);
        Assert.assertEquals(diagnosticResult.errorCount(), 2);
        Iterator<Diagnostic> diagnosticIterator = diagnosticResult.errors().iterator();
        Diagnostic diagnostic = diagnosticIterator.next();
        assertErrorFormat(diagnostic, CompilationError.INVALID_INPUT_PARAMETER_TYPE, 21, 43);

        diagnostic = diagnosticIterator.next();
        assertErrorFormat(diagnostic, CompilationError.INVALID_INPUT_PARAMETER_TYPE, 25, 40);
    }

    @Test
    public void testInvalidRecordFieldType() {
        String packagePath = "invalid_service_25";
        DiagnosticResult diagnosticResult = getDiagnosticResult(packagePath);
        Assert.assertEquals(diagnosticResult.errorCount(), 1);
        Diagnostic diagnostic = diagnosticResult.errors().iterator().next();
        assertError(diagnostic, CompilationError.INVALID_RETURN_TYPE_ERROR_OR_NIL, 25, 5);
    }

    @Test
    public void testInvalidListTypeInputs() {
        String packagePath = "invalid_service_26";
        DiagnosticResult diagnosticResult = getDiagnosticResult(packagePath);
        Assert.assertEquals(diagnosticResult.errorCount(), 5);
        Iterator<Diagnostic> diagnosticIterator = diagnosticResult.errors().iterator();
        Diagnostic diagnostic = diagnosticIterator.next();
        assertError(diagnostic, CompilationError.INVALID_RESOURCE_INPUT_OBJECT_PARAM, 35, 44);

        diagnostic = diagnosticIterator.next();
        assertError(diagnostic, CompilationError.INVALID_RESOURCE_INPUT_OBJECT_PARAM, 44, 44);

        diagnostic = diagnosticIterator.next();
        assertError(diagnostic, CompilationError.INVALID_RESOURCE_INPUT_OBJECT_PARAM, 59, 39);

        diagnostic = diagnosticIterator.next();
        assertError(diagnostic, CompilationError.INVALID_RETURN_TYPE_INPUT_OBJECT, 72, 5);

        diagnostic = diagnosticIterator.next();
        assertError(diagnostic, CompilationError.INVALID_RESOURCE_INPUT_OBJECT_PARAM, 88, 52);
    }

    @Test
    public void testInvalidResourcePaths() {
        String packagePath = "invalid_service_27";
        DiagnosticResult diagnosticResult = getDiagnosticResult(packagePath);
        Assert.assertEquals(diagnosticResult.errorCount(), 3);
        Iterator<Diagnostic> diagnosticIterator = diagnosticResult.errors().iterator();
        Diagnostic diagnostic = diagnosticIterator.next();
        assertError(diagnostic, CompilationError.INVALID_PATH_PARAMETERS, 20, 5);

        diagnostic = diagnosticIterator.next();
        assertError(diagnostic, CompilationError.INVALID_PATH_PARAMETERS, 24, 5);

        diagnostic = diagnosticIterator.next();
        assertError(diagnostic, CompilationError.INVALID_RESOURCE_PATH, 28, 5);
    }

    @Test
    public void testGraphQLFileUploadInInvalidLocations() {
        String packagePath = "invalid_service_28";
        DiagnosticResult diagnosticResult = getDiagnosticResult(packagePath);
        Assert.assertEquals(diagnosticResult.errorCount(), 14);
        Iterator<Diagnostic> diagnosticIterator = diagnosticResult.errors().iterator();
        Diagnostic diagnostic = diagnosticIterator.next();
        assertError(diagnostic, CompilationError.INVALID_RETURN_TYPE, 36, 5);

        diagnostic = diagnosticIterator.next();
        assertError(diagnostic, CompilationError.INVALID_RETURN_TYPE, 43, 5);

        diagnostic = diagnosticIterator.next();
        assertError(diagnostic, CompilationError.INVALID_RETURN_TYPE, 50, 5);

        diagnostic = diagnosticIterator.next();
        assertError(diagnostic, CompilationError.INVALID_FILE_UPLOAD_IN_RESOURCE_FUNCTION, 57, 58);

        diagnostic = diagnosticIterator.next();
        assertError(diagnostic, CompilationError.INVALID_FILE_UPLOAD_IN_RESOURCE_FUNCTION, 64, 68);

        diagnostic = diagnosticIterator.next();
        assertError(diagnostic, CompilationError.INVALID_FILE_UPLOAD_IN_RESOURCE_FUNCTION, 71, 63);

        diagnostic = diagnosticIterator.next();
        assertError(diagnostic, CompilationError.INVALID_RETURN_TYPE, 82, 5);

        diagnostic = diagnosticIterator.next();
        assertError(diagnostic, CompilationError.INVALID_RETURN_TYPE, 93, 5);

        diagnostic = diagnosticIterator.next();
        assertError(diagnostic, CompilationError.INVALID_RETURN_TYPE, 104, 5);

        diagnostic = diagnosticIterator.next();
        assertError(diagnostic, CompilationError.MULTI_DIMENSIONAL_UPLOAD_ARRAY, 115, 56);

        diagnostic = diagnosticIterator.next();
        assertErrorFormat(diagnostic, CompilationError.INVALID_INPUT_PARAMETER_TYPE, 122, 52);

        diagnostic = diagnosticIterator.next();
        assertErrorFormat(diagnostic, CompilationError.INVALID_INPUT_PARAMETER_TYPE, 133, 33);

        diagnostic = diagnosticIterator.next();
        assertError(diagnostic, CompilationError.INVALID_RETURN_TYPE, 140, 5);

        diagnostic = diagnosticIterator.next();
        assertError(diagnostic, CompilationError.INVALID_RETURN_TYPE, 154, 5);
    }

    @Test
    public void testNonDistinctInterfaceImplementation() {
        String packagePath = "invalid_service_29";
        DiagnosticResult diagnosticResult = getDiagnosticResult(packagePath);
        Assert.assertEquals(diagnosticResult.errorCount(), 1);
        Diagnostic diagnostic = diagnosticResult.errors().iterator().next();
        String message = "Non-distinct service class `Teacher` is used as a GraphQL interface implementation";
        assertErrorMessage(diagnostic, message, 20, 5);
    }

    @Test
    public void testNonDistinctInterface() {
        String packagePath = "invalid_service_30";
        DiagnosticResult diagnosticResult = getDiagnosticResult(packagePath);
        Assert.assertEquals(diagnosticResult.errorCount(), 1);
        Diagnostic diagnostic = diagnosticResult.errors().iterator().next();
        String message = "Non-distinct service class `Person` is used as a GraphQL interface";
        assertErrorMessage(diagnostic, message, 20, 5);
    }

    @Test
    public void testInterfaceImplementationMissingResourceFunction() {
        String packagePath = "invalid_service_31";
        DiagnosticResult diagnosticResult = getDiagnosticResult(packagePath);
        Assert.assertEquals(diagnosticResult.errorCount(), 2);
        Iterator<Diagnostic> diagnosticIterator = diagnosticResult.errors().iterator();

        String message =
                "All the resource functions in the GraphQL interface class `Person` must be implemented in the child " +
                        "class `Student`";
        Diagnostic diagnostic = diagnosticIterator.next();
        assertErrorMessage(diagnostic, message, 20, 5);

        message =
                "All the resource functions in the GraphQL interface class `Person` must be implemented in the child " +
                        "class `Teacher`";
        diagnostic = diagnosticIterator.next();
        assertErrorMessage(diagnostic, message, 20, 5);
    }

    @Test
    public void testInvalidResourceFunctionsInInterfaceImplementations() {
        String packagePath = "invalid_service_32";
        DiagnosticResult diagnosticResult = getDiagnosticResult(packagePath);
        Assert.assertEquals(diagnosticResult.errorCount(), 2);
        Iterator<Diagnostic> diagnosticIterator = diagnosticResult.errors().iterator();

        Diagnostic diagnostic = diagnosticIterator.next();
        assertError(diagnostic, CompilationError.INVALID_RESOURCE_FUNCTION_ACCESSOR, 67, 32);

        diagnostic = diagnosticIterator.next();
        assertError(diagnostic, CompilationError.INVALID_RESOURCE_FUNCTION_ACCESSOR, 99, 32);
    }

    @Test
    public void testInvalidReturnTypesInInterfaceImplementations() {
        String packagePath = "invalid_service_33";
        DiagnosticResult diagnosticResult = getDiagnosticResult(packagePath);
        Assert.assertEquals(diagnosticResult.errorCount(), 1);
        Diagnostic diagnostic = diagnosticResult.errors().iterator().next();
        assertError(diagnostic, CompilationError.INVALID_RETURN_TYPE, 103, 32);
    }

    @Test
    public void testMultipleInterfaceImplementationsWithMissingResources1() {
        String packagePath = "invalid_service_34";
        DiagnosticResult diagnosticResult = getDiagnosticResult(packagePath);
        Assert.assertEquals(diagnosticResult.errorCount(), 1);
        Diagnostic diagnostic = diagnosticResult.errors().iterator().next();
        String message =
                "All the resource functions in the GraphQL interface class `Mammal` must be implemented in the child " +
                        "class `Dog`";
        assertErrorMessage(diagnostic, message, 20, 5);
    }

    @Test
    public void testMultipleInterfaceImplementationsWithMissingResources2() {
        String packagePath = "invalid_service_35";
        DiagnosticResult diagnosticResult = getDiagnosticResult(packagePath);
        Assert.assertEquals(diagnosticResult.errorCount(), 1);
        Diagnostic diagnostic = diagnosticResult.errors().iterator().next();
        String message =
                "All the resource functions in the GraphQL interface class `Pet` must be implemented in the child " +
                        "class `Dog`";
        assertErrorMessage(diagnostic, message, 24, 5);
    }

    @Test
    public void testInvalidSubscribeService() {
        String packagePath = "invalid_service_36";
        DiagnosticResult diagnosticResult = getDiagnosticResult(packagePath);
        Assert.assertEquals(diagnosticResult.errorCount(), 3);
        Iterator<Diagnostic> diagnosticIterator = diagnosticResult.errors().iterator();

        Diagnostic diagnostic = diagnosticIterator.next();
        assertError(diagnostic, CompilationError.MISSING_RESOURCE_FUNCTIONS, 19, 1);

        diagnostic = diagnosticIterator.next();
        assertError(diagnostic, CompilationError.INVALID_RETURN_TYPE, 31, 5);

        diagnostic = diagnosticIterator.next();
        assertError(diagnostic, CompilationError.INVALID_RESOURCE_FUNCTION_ACCESSOR, 61, 32);
    }

    @Test
    public void testInvalidInterceptor() {
        String packagePath = "invalid_service_37";
        DiagnosticResult diagnosticResult = getDiagnosticResult(packagePath);
        Assert.assertEquals(diagnosticResult.errorCount(), 2);
        Iterator<Diagnostic> diagnosticIterator = diagnosticResult.errors().iterator();

        Diagnostic diagnostic = diagnosticIterator.next();
        assertError(diagnostic, CompilationError.RESOURCE_METHOD_INSIDE_INTERCEPTOR, 27, 5);

        diagnostic = diagnosticIterator.next();
        assertError(diagnostic, CompilationError.INVALID_REMOTE_METHOD_INSIDE_INTERCEPTOR, 34, 5);
    }

    @Test
    public void testAnonymousRecordsAsField() {
        String packagePath = "invalid_service_38";
        DiagnosticResult diagnosticResult = getDiagnosticResult(packagePath);
        Assert.assertEquals(diagnosticResult.errorCount(), 5);
        Iterator<Diagnostic> diagnosticIterator = diagnosticResult.errors().iterator();

        Diagnostic diagnostic = diagnosticIterator.next();
        String message = "Anonymous record `record {|int number; string street; string city;|}` cannot be used as " +
                "a GraphQL schema type";
        assertErrorMessage(diagnostic, message, 26, 5);

        diagnostic = diagnosticIterator.next();
        assertErrorMessage(diagnostic, message, 38, 5);

        diagnostic = diagnosticIterator.next();
        message = "Anonymous record `record {|string name; int age;|}` cannot be used as a GraphQL schema type";
        assertErrorMessage(diagnostic, message, 52, 23);

        diagnostic = diagnosticIterator.next();
        assertErrorMessage(diagnostic, message, 58, 67);

        diagnostic = diagnosticIterator.next();
        assertErrorMessage(diagnostic, message, 68, 67);
    }

    private DiagnosticResult getDiagnosticResult(String packagePath) {
        Path projectDirPath = RESOURCE_DIRECTORY.resolve(packagePath);
        BuildProject project = BuildProject.load(getEnvironmentBuilder(), projectDirPath);
        return project.currentPackage().runCodeGenAndModifyPlugins();
    }

    private static ProjectEnvironmentBuilder getEnvironmentBuilder() {
        Environment environment = EnvironmentBuilder.getBuilder().setBallerinaHome(DISTRIBUTION_PATH).build();
        return ProjectEnvironmentBuilder.getBuilder(environment);
    }

    private void assertError(Diagnostic diagnostic, CompilationError compilationError, int line, int column) {
        Assert.assertEquals(diagnostic.diagnosticInfo().severity(), DiagnosticSeverity.ERROR);
        Assert.assertEquals(diagnostic.message(), compilationError.getError());
        assertErrorLocation(diagnostic.location(), line, column);
    }

    private void assertErrorMessage(Diagnostic diagnostic, String message, int line, int column) {
        Assert.assertEquals(diagnostic.diagnosticInfo().severity(), DiagnosticSeverity.ERROR);
        Assert.assertEquals(diagnostic.message(), message);
        assertErrorLocation(diagnostic.location(), line, column);
    }

    private void assertErrorFormat(Diagnostic diagnostic, CompilationError compilationError, int line, int column) {
        Assert.assertEquals(diagnostic.diagnosticInfo().severity(), DiagnosticSeverity.ERROR);
        Assert.assertEquals(diagnostic.diagnosticInfo().messageFormat(), compilationError.getError());
        assertErrorLocation(diagnostic.location(), line, column);
    }

    private void assertErrorLocation(Location location, int line, int column) {
        // Compiler counts lines and columns from zero
        Assert.assertEquals((location.lineRange().startLine().line() + 1), line);
        Assert.assertEquals((location.lineRange().startLine().offset() + 1), column);
    }
}
