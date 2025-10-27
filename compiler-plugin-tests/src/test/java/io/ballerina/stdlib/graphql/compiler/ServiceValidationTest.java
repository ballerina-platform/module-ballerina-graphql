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
import io.ballerina.stdlib.graphql.compiler.diagnostics.CompilationDiagnostic;
import io.ballerina.tools.diagnostics.Diagnostic;
import io.ballerina.tools.diagnostics.DiagnosticSeverity;
import io.ballerina.tools.diagnostics.Location;
import org.testng.Assert;
import org.testng.annotations.Test;

import java.nio.file.Path;
import java.nio.file.Paths;
import java.text.MessageFormat;
import java.util.Iterator;

/**
 * This class includes tests for Ballerina Graphql compiler plugin service validation.
 */
public class ServiceValidationTest {

    private static final Path RESOURCE_DIRECTORY = Paths.get("src", "test", "resources", "ballerina_sources",
                                                             "validator_tests").toAbsolutePath();
    private static final Path DISTRIBUTION_PATH = Paths.get("../", "target", "ballerina-runtime").toAbsolutePath();
    private static final String TEST_MODULE_PREFIX = "graphql_test/test_package:0.1.0:";

    @Test(groups = "valid")
    public void testValidReturnTypes() {
        String packagePath = "01_valid_return_types";
        DiagnosticResult diagnosticResult = getDiagnosticResult(packagePath);
        Assert.assertEquals(diagnosticResult.errorCount(), 0);
    }

    @Test(groups = "valid")
    public void testValidInputTypes() {
        String packagePath = "02_valid_input_types";
        DiagnosticResult diagnosticResult = getDiagnosticResult(packagePath);
        Assert.assertEquals(diagnosticResult.errorCount(), 0);
    }

    @Test
    public void testValidServiceConfigurations() {
        String packagePath = "03_valid_service_configurations";
        DiagnosticResult diagnosticResult = getDiagnosticResult(packagePath);
        Assert.assertEquals(diagnosticResult.errorCount(), 0);
    }

    @Test(groups = "valid")
    public void testEnumAsReturnType() {
        String packagePath = "04_enum_as_return_type";
        DiagnosticResult diagnosticResult = getDiagnosticResult(packagePath);
        Assert.assertEquals(diagnosticResult.errorCount(), 0);
    }

    @Test(groups = "valid")
    public void testEnumAsInputType() {
        String packagePath = "05_enum_as_input_type";
        DiagnosticResult diagnosticResult = getDiagnosticResult(packagePath);
        Assert.assertEquals(diagnosticResult.errorCount(), 0);
    }

    @Test(groups = "valid")
    public void testValidListenerConfigurations() {
        String packagePath = "06_valid_listener_configurations";
        DiagnosticResult diagnosticResult = getDiagnosticResult(packagePath);
        Assert.assertEquals(diagnosticResult.errorCount(), 0);
    }

    @Test(groups = "valid")
    public void testOptionalInputParameters() {
        String packagePath = "07_optional_input_parameters";
        DiagnosticResult diagnosticResult = getDiagnosticResult(packagePath);
        Assert.assertEquals(diagnosticResult.errorCount(), 0);
    }

    @Test(groups = "valid")
    public void testDistinctServiceObjectsAsReturnType() {
        String packagePath = "08_distinct_service_objects_as_return_type";
        DiagnosticResult diagnosticResult = getDiagnosticResult(packagePath);
        Assert.assertEquals(diagnosticResult.errorCount(), 0);
    }

    @Test(groups = "valid")
    public void testRecursiveServiceTypes() {
        String packagePath = "09_recursive_service_types";
        DiagnosticResult diagnosticResult = getDiagnosticResult(packagePath);
        Assert.assertEquals(diagnosticResult.errorCount(), 0);
    }

    @Test(groups = "valid")
    public void testServiceObjectFields() {
        String packagePath = "10_service_object_fields";
        DiagnosticResult diagnosticResult = getDiagnosticResult(packagePath);
        Assert.assertEquals(diagnosticResult.errorCount(), 0);
    }

    @Test(groups = "valid")
    public void testInputObjectType() {
        String packagePath = "11_input_object_type";
        DiagnosticResult diagnosticResult = getDiagnosticResult(packagePath);
        Assert.assertEquals(diagnosticResult.errorCount(), 0);
    }

    @Test(groups = "valid")
    public void testContextAsFirstParameter() {
        String packagePath = "12_context_as_first_parameter";
        DiagnosticResult diagnosticResult = getDiagnosticResult(packagePath);
        Assert.assertEquals(diagnosticResult.errorCount(), 0);
    }

    @Test(groups = "valid")
    public void testContextInsideReturningServices() {
        String packagePath = "13_context_inside_returning_services";
        DiagnosticResult diagnosticResult = getDiagnosticResult(packagePath);
        Assert.assertEquals(diagnosticResult.errorCount(), 0);
    }

    @Test(groups = "valid")
    public void testListTypeInputParameters() {
        String packagePath = "14_list_type_input_parameters";
        DiagnosticResult diagnosticResult = getDiagnosticResult(packagePath);
        Assert.assertEquals(diagnosticResult.errorCount(), 0);
    }

    @Test(groups = "valid")
    public void testFileUpload() {
        String packagePath = "15_file_upload";
        DiagnosticResult diagnosticResult = getDiagnosticResult(packagePath);
        Assert.assertEquals(diagnosticResult.errorCount(), 0);
    }

    @Test(groups = "valid")
    public void testIntersectionTypes() {
        String packagePath = "16_intersection_types";
        DiagnosticResult diagnosticResult = getDiagnosticResult(packagePath);
        Assert.assertEquals(diagnosticResult.errorCount(), 0);
    }

    @Test(groups = "valid")
    public void testRecordTypes() {
        String packagePath = "17_record_types";
        DiagnosticResult diagnosticResult = getDiagnosticResult(packagePath);
        Assert.assertEquals(diagnosticResult.errorCount(), 0);
    }

    @Test(groups = "valid")
    public void testInterfaces() {
        String packagePath = "18_interfaces";
        DiagnosticResult diagnosticResult = getDiagnosticResult(packagePath);
        Assert.assertEquals(diagnosticResult.errorCount(), 0);
    }

    @Test(groups = "valid")
    public void testInterfacesImplementingInterfaces() {
        String packagePath = "19_interfaces_implementing_interfaces";
        DiagnosticResult diagnosticResult = getDiagnosticResult(packagePath);
        Assert.assertEquals(diagnosticResult.errorCount(), 0);
    }

    @Test(groups = "valid")
    public void testMultipleInterfaceImplementations() {
        String packagePath = "20_multiple_interface_implementations";
        DiagnosticResult diagnosticResult = getDiagnosticResult(packagePath);
        Assert.assertEquals(diagnosticResult.errorCount(), 0);
    }

    @Test(groups = "valid")
    public void testSubscriptions() {
        String packagePath = "21_subscriptions";
        DiagnosticResult diagnosticResult = getDiagnosticResult(packagePath);
        Assert.assertEquals(diagnosticResult.errorCount(), 0);
    }

    @Test(groups = "valid")
    public void testInterceptors() {
        String packagePath = "22_interceptors";
        DiagnosticResult diagnosticResult = getDiagnosticResult(packagePath);
        Assert.assertEquals(diagnosticResult.errorCount(), 0);
    }

    @Test(groups = "valid")
    public void testDynamicallyAttachingService() {
        String packagePath = "23_dynamically_attaching_service";
        DiagnosticResult diagnosticResult = getDiagnosticResult(packagePath);
        Assert.assertEquals(diagnosticResult.errorCount(), 0);
    }

    @Test(groups = "valid")
    public void testValidEntityWithKeyOnly() {
        String packagePath = "88_valid_entity_with_key_only";
        DiagnosticResult result = getDiagnosticResult(packagePath);
        Assert.assertEquals(result.errorCount(), 0, "Expected no errors for key-only entity definition.");

    }

    @Test(groups = "valid")
    public void testValidEntityWithKeyAndResolveReference() {
        String packagePath = "89_valid_entity_with_key_and_resolve_reference";
        DiagnosticResult result = getDiagnosticResult(packagePath);
        Assert.assertEquals(result.errorCount(), 0, "Expected no errors for entity with resolveReference.");
    }

    @Test(groups = "invalid")
    public void testMultipleListenersOnSameService() {
        String packagePath = "24_multiple_listeners_on_same_service";
        DiagnosticResult diagnosticResult = getDiagnosticResult(packagePath);
        Assert.assertEquals(diagnosticResult.errorCount(), 1);
        Diagnostic diagnostic = diagnosticResult.errors().iterator().next();
        assertError(diagnostic, CompilationDiagnostic.INVALID_MULTIPLE_LISTENERS, 19, 1);
    }

    @Test(groups = "invalid")
    public void testServiceMissingResourceFunction() {
        String packagePath = "25_service_missing_resource_function";
        DiagnosticResult diagnosticResult = getDiagnosticResult(packagePath);
        Assert.assertEquals(diagnosticResult.errorCount(), 1);
        Diagnostic diagnostic = diagnosticResult.errors().iterator().next();
        String message = getErrorMessage(CompilationDiagnostic.MISSING_RESOURCE_FUNCTIONS);
        assertErrorMessage(diagnostic, message, 19, 1);
    }

    @Test(groups = "invalid")
    public void testInvalidResourceAccessor() {
        String packagePath = "26_invalid_resource_accessor";
        DiagnosticResult diagnosticResult = getDiagnosticResult(packagePath);
        Assert.assertEquals(diagnosticResult.errorCount(), 2);
        Iterator<Diagnostic> diagnosticIterator = diagnosticResult.errors().iterator();

        Diagnostic diagnostic = diagnosticIterator.next();
        String message = getErrorMessage(CompilationDiagnostic.INVALID_ROOT_RESOURCE_ACCESSOR, "post", "greeting");
        assertErrorMessage(diagnostic, message, 20, 23);

        diagnostic = diagnosticIterator.next();
        message = getErrorMessage(CompilationDiagnostic.MISSING_RESOURCE_FUNCTIONS);
        assertErrorMessage(diagnostic, message, 19, 1);
    }

    @Test(groups = "invalid")
    public void testInvalidReturnTypes() {
        String packagePath = "27_invalid_return_types";
        DiagnosticResult diagnosticResult = getDiagnosticResult(packagePath);
        Assert.assertEquals(diagnosticResult.errorCount(), 19);
        Iterator<Diagnostic> diagnosticIterator = diagnosticResult.errors().iterator();

        Diagnostic diagnostic = diagnosticIterator.next();
        String message = getErrorMessage(CompilationDiagnostic.INVALID_RETURN_TYPE, "map", "Query.greeting");
        assertErrorMessage(diagnostic, message, 29, 5);

        diagnostic = diagnosticIterator.next();
        message = getErrorMessage(CompilationDiagnostic.INVALID_RETURN_TYPE, "json", "Query.greeting");
        assertErrorMessage(diagnostic, message, 35, 5);

        diagnostic = diagnosticIterator.next();
        message = getErrorMessage(CompilationDiagnostic.INVALID_RETURN_TYPE, "byte", "Query.greeting");
        assertErrorMessage(diagnostic, message, 42, 5);

        diagnostic = diagnosticIterator.next();
        message = getErrorMessage(CompilationDiagnostic.INVALID_RETURN_TYPE, "byte", "Query.greeting");
        assertErrorMessage(diagnostic, message, 49, 5);

        diagnostic = diagnosticIterator.next();
        message = getErrorMessage(CompilationDiagnostic.INVALID_UNION_MEMBER_TYPE, "float");
        assertErrorMessage(diagnostic, message, 56, 5);

        diagnostic = diagnosticIterator.next();
        message = getErrorMessage(CompilationDiagnostic.INVALID_UNION_MEMBER_TYPE, "decimal");
        assertErrorMessage(diagnostic, message, 56, 5);

        diagnostic = diagnosticIterator.next();
        message = getErrorMessage(CompilationDiagnostic.INVALID_UNION_MEMBER_TYPE, "Person");
        assertErrorMessage(diagnostic, message, 62, 5);

        diagnostic = diagnosticIterator.next();
        message = getErrorMessage(CompilationDiagnostic.INVALID_UNION_MEMBER_TYPE, "string");
        assertErrorMessage(diagnostic, message, 62, 5);

        diagnostic = diagnosticIterator.next();
        message = getErrorMessage(CompilationDiagnostic.INVALID_UNION_MEMBER_TYPE, "Person");
        assertErrorMessage(diagnostic, message, 68, 5);

        diagnostic = diagnosticIterator.next();
        message = getErrorMessage(CompilationDiagnostic.INVALID_UNION_MEMBER_TYPE, "Student");
        assertErrorMessage(diagnostic, message, 68, 5);

        diagnostic = diagnosticIterator.next();
        message = getErrorMessage(CompilationDiagnostic.INVALID_RETURN_TYPE, "service object {}", "Query.foo");
        assertErrorMessage(diagnostic, message, 75, 5);

        diagnostic = diagnosticIterator.next();
        message = getErrorMessage(CompilationDiagnostic.INVALID_FUNCTION, "Interceptor", "execute");
        // This error points to the types.bal in the GraphQL package since this returns the `graphql:Interceptor` type.
        assertErrorMessage(diagnostic, message, 100, 5);

        diagnostic = diagnosticIterator.next();
        message = getErrorMessage(CompilationDiagnostic.MISSING_RESOURCE_FUNCTIONS);
        assertErrorMessage(diagnostic, message, 94, 5);

        diagnostic = diagnosticIterator.next();
        message = getErrorMessage(CompilationDiagnostic.NON_DISTINCT_INTERFACE_IMPLEMENTATION, "ServiceInterceptor");
        assertErrorMessage(diagnostic, message, 84, 24);

        diagnostic = diagnosticIterator.next();
        message = getErrorMessage(CompilationDiagnostic.INVALID_SUBSCRIBE_RESOURCE_RETURN_TYPE, "int", "foo");
        assertErrorMessage(diagnostic, message, 100, 5);

        diagnostic = diagnosticIterator.next();
        message = getErrorMessage(CompilationDiagnostic.INVALID_SUBSCRIBE_RESOURCE_RETURN_TYPE, "int|string", "bar");
        assertErrorMessage(diagnostic, message, 104, 5);

        diagnostic = diagnosticIterator.next();
        message = getErrorMessage(CompilationDiagnostic.INVALID_RETURN_TYPE_CLASS, "Foo", "Query.foo");
        assertErrorMessage(diagnostic, message, 113, 7);

        diagnostic = diagnosticIterator.next();
        message = getErrorMessage(CompilationDiagnostic.INVALID_RETURN_TYPE, "tuple", "Query.foo");
        assertErrorMessage(diagnostic, message, 129, 5);

        diagnostic = diagnosticIterator.next();
        message = getErrorMessage(CompilationDiagnostic.INVALID_RETURN_TYPE, "tuple", "Query.time.time");
        assertErrorMessage(diagnostic, message, 133, 5);
    }

    @Test(groups = "invalid")
    public void testInvalidInputTypes() {
        String packagePath = "28_invalid_input_types";
        DiagnosticResult diagnosticResult = getDiagnosticResult(packagePath);
        Assert.assertEquals(diagnosticResult.errorCount(), 9);
        Iterator<Diagnostic> diagnosticIterator = diagnosticResult.errors().iterator();

        Diagnostic diagnostic = diagnosticIterator.next();
        String message = getErrorMessage(CompilationDiagnostic.INVALID_INPUT_PARAMETER_TYPE, "json", "Query.greet");
        assertErrorMessage(diagnostic, message, 21, 38);

        diagnostic = diagnosticIterator.next();
        message = getErrorMessage(CompilationDiagnostic.INVALID_INPUT_PARAMETER_TYPE, "map<string>", "Query.greet");
        assertErrorMessage(diagnostic, message, 27, 45);

        diagnostic = diagnosticIterator.next();
        message = getErrorMessage(CompilationDiagnostic.INVALID_INPUT_PARAMETER_TYPE, "byte[]", "Query.greet");
        assertErrorMessage(diagnostic, message, 33, 40);

        diagnostic = diagnosticIterator.next();
        assertError(diagnostic, CompilationDiagnostic.INVALID_INPUT_TYPE_UNION, 44, 39);

        diagnostic = diagnosticIterator.next();
        message = getErrorMessage(CompilationDiagnostic.INVALID_INPUT_PARAMETER_TYPE, "byte[]", "Query.greet");
        assertErrorMessage(diagnostic, message, 50, 49);

        diagnostic = diagnosticIterator.next();
        message = getErrorMessage(CompilationDiagnostic.INVALID_INPUT_PARAMETER_TYPE, "any", "Query.greet");
        assertErrorMessage(diagnostic, message, 56, 37);

        diagnostic = diagnosticIterator.next();
        message = getErrorMessage(CompilationDiagnostic.INVALID_INPUT_PARAMETER_TYPE, "anydata", "Query.greet");
        assertErrorMessage(diagnostic, message, 62, 41);

        String subModulePrefix = "graphql_test/test_package.types:0.1.0:";
        diagnostic = diagnosticIterator.next();
        message = getErrorMessage(CompilationDiagnostic.INVALID_INPUT_PARAMETER_TYPE, subModulePrefix + "Headers",
                                  "Query.greet");
        assertErrorMessage(diagnostic, message, 68, 47);

        diagnostic = diagnosticIterator.next();
        message = getErrorMessage(CompilationDiagnostic.INVALID_INPUT_PARAMETER_TYPE, subModulePrefix + "Service",
                                  "Query.greet");
        assertErrorMessage(diagnostic, message, 74, 47);
    }

    @Test(groups = "invalid")
    public void testReturningOnlyErrorOrNil() {
        String packagePath = "29_returning_only_error_or_nill";
        DiagnosticResult diagnosticResult = getDiagnosticResult(packagePath);
        Assert.assertEquals(diagnosticResult.errorCount(), 1);
        Diagnostic diagnostic = diagnosticResult.errors().iterator().next();
        String message = getErrorMessage(CompilationDiagnostic.INVALID_RETURN_TYPE_ERROR_OR_NIL, "Query.greeting");
        assertErrorMessage(diagnostic, message, 20, 5);
    }

    @Test(groups = "invalid")
    public void testReturningOnlyNil() {
        String packagePath = "30_returning_only_nil";
        DiagnosticResult diagnosticResult = getDiagnosticResult(packagePath);
        Assert.assertEquals(diagnosticResult.errorCount(), 1);
        Diagnostic diagnostic = diagnosticResult.errors().iterator().next();
        String message = getErrorMessage(CompilationDiagnostic.INVALID_RETURN_TYPE_NIL, "Query.greeting");
        assertErrorMessage(diagnostic, message, 20, 5);
    }

    @Test(groups = "invalid")
    public void testReturningOnlyError() {
        String packagePath = "31_returning_only_error";
        DiagnosticResult diagnosticResult = getDiagnosticResult(packagePath);
        Assert.assertEquals(diagnosticResult.errorCount(), 1);
        Diagnostic diagnostic = diagnosticResult.errors().iterator().next();
        String message = getErrorMessage(CompilationDiagnostic.INVALID_RETURN_TYPE_ERROR, "Query.greeting");
        assertErrorMessage(diagnostic, message, 20, 5);
    }

    @Test(groups = "invalid")
    public void testListenerInitParameters() {
        String packagePath = "32_listener_init_parameters";
        DiagnosticResult diagnosticResult = getDiagnosticResult(packagePath);
        Assert.assertEquals(diagnosticResult.errorCount(), 10);
        Iterator<Diagnostic> diagnosticIterator = diagnosticResult.errors().iterator();

        Diagnostic diagnostic = diagnosticIterator.next();
        assertError(diagnostic, CompilationDiagnostic.INVALID_LISTENER_INIT, 30, 43);

        diagnostic = diagnosticIterator.next();
        assertError(diagnostic, CompilationDiagnostic.INVALID_LISTENER_INIT, 31, 49);

        diagnostic = diagnosticIterator.next();
        assertError(diagnostic, CompilationDiagnostic.INVALID_LISTENER_INIT, 32, 60);

        diagnostic = diagnosticIterator.next();
        assertError(diagnostic, CompilationDiagnostic.INVALID_LISTENER_INIT, 33, 66);

        diagnostic = diagnosticIterator.next();
        assertError(diagnostic, CompilationDiagnostic.INVALID_LISTENER_INIT, 34, 44);

        diagnostic = diagnosticIterator.next();
        assertError(diagnostic, CompilationDiagnostic.INVALID_LISTENER_INIT, 35, 50);

        diagnostic = diagnosticIterator.next();
        assertError(diagnostic, CompilationDiagnostic.INVALID_LISTENER_INIT, 36, 73);

        diagnostic = diagnosticIterator.next();
        assertError(diagnostic, CompilationDiagnostic.INVALID_LISTENER_INIT, 37, 79);

        diagnostic = diagnosticIterator.next();
        assertError(diagnostic, CompilationDiagnostic.INVALID_LISTENER_INIT, 38, 95);

        diagnostic = diagnosticIterator.next();
        assertError(diagnostic, CompilationDiagnostic.INVALID_LISTENER_INIT, 41, 49);
    }

    @Test(groups = "invalid")
    public void testInvalidInputUnions() {
        String packagePath = "33_invalid_input_unions";
        DiagnosticResult diagnosticResult = getDiagnosticResult(packagePath);
        Assert.assertEquals(diagnosticResult.errorCount(), 5);
        Iterator<Diagnostic> diagnosticIterator = diagnosticResult.errors().iterator();

        Diagnostic diagnostic = diagnosticIterator.next();
        assertError(diagnostic, CompilationDiagnostic.INVALID_INPUT_TYPE_UNION, 20, 48);

        diagnostic = diagnosticIterator.next();
        String message = getErrorMessage(CompilationDiagnostic.INVALID_INPUT_PARAMETER_TYPE, "json?", "Query.greet");
        assertErrorMessage(diagnostic, message, 26, 39);

        diagnostic = diagnosticIterator.next();
        message = getErrorMessage(CompilationDiagnostic.INVALID_INPUT_PARAMETER_TYPE, "map<string>?", "Query.greet");
        assertErrorMessage(diagnostic, message, 32, 46);

        diagnostic = diagnosticIterator.next();
        message = getErrorMessage(CompilationDiagnostic.INVALID_INPUT_PARAMETER_TYPE, "byte[]?", "Query.greet");
        assertErrorMessage(diagnostic, message, 38, 41);

        diagnostic = diagnosticIterator.next();
        message = getErrorMessage(CompilationDiagnostic.INVALID_INPUT_PARAMETER_TYPE, "error", "Query.greet");
        assertErrorMessage(diagnostic, message, 44, 46);
    }

    @Test(groups = "invalid")
    public void testInvalidReturnTypeUnions() {
        String packagePath = "34_invalid_return_type_unions";
        DiagnosticResult diagnosticResult = getDiagnosticResult(packagePath);
        Assert.assertEquals(diagnosticResult.errorCount(), 4);
        Iterator<Diagnostic> diagnosticIterator = diagnosticResult.errors().iterator();

        Diagnostic diagnostic = diagnosticIterator.next();
        String message = getErrorMessage(CompilationDiagnostic.INVALID_UNION_MEMBER_TYPE, "Age");
        assertErrorMessage(diagnostic, message, 20, 5);

        diagnostic = diagnosticIterator.next();
        message = getErrorMessage(CompilationDiagnostic.INVALID_UNION_MEMBER_TYPE, "CivilStatus");
        assertErrorMessage(diagnostic, message, 20, 5);

        diagnostic = diagnosticIterator.next();
        message = getErrorMessage(CompilationDiagnostic.INVALID_UNION_MEMBER_TYPE, "Age");
        assertErrorMessage(diagnostic, message, 26, 5);

        diagnostic = diagnosticIterator.next();
        message = getErrorMessage(CompilationDiagnostic.INVALID_UNION_MEMBER_TYPE, "CivilStatus");
        assertErrorMessage(diagnostic, message, 32, 5);
    }

    @Test(groups = "invalid")
    public void testInvalidAccessorsInServicesTypes() {
        String packagePath = "35_invalid_accessor_in_service_types";
        DiagnosticResult diagnosticResult = getDiagnosticResult(packagePath);
        Assert.assertEquals(diagnosticResult.errorCount(), 4);
        Iterator<Diagnostic> diagnosticIterator = diagnosticResult.errors().iterator();

        // Same erroneous class is used in two different GraphQL services. Hence, the duplication of errors.
        Diagnostic diagnostic = diagnosticIterator.next();
        String message = getErrorMessage(CompilationDiagnostic.INVALID_RESOURCE_FUNCTION_ACCESSOR, "post",
                                         "generalGreeting");
        assertErrorMessage(diagnostic, message, 44, 23);

        diagnostic = diagnosticIterator.next();
        assertErrorMessage(diagnostic, message, 44, 23);

        diagnostic = diagnosticIterator.next();
        message = getErrorMessage(CompilationDiagnostic.INVALID_RESOURCE_FUNCTION_ACCESSOR, "post", "status");
        assertErrorMessage(diagnostic, message, 50, 23);

        diagnostic = diagnosticIterator.next();
        assertErrorMessage(diagnostic, message, 50, 23);
    }

    @Test(groups = "invalid")
    public void testInvalidReturnTypesInServicesTypes() {
        String packagePath = "36_invalid_return_types_in_service_types";
        DiagnosticResult diagnosticResult = getDiagnosticResult(packagePath);
        Assert.assertEquals(diagnosticResult.errorCount(), 4);
        Iterator<Diagnostic> diagnosticIterator = diagnosticResult.errors().iterator();

        // Same erroneous class is used in two different GraphQL services. Hence, the duplication of errors.
        Diagnostic diagnostic = diagnosticIterator.next();
        String message = getErrorMessage(CompilationDiagnostic.INVALID_RETURN_TYPE, "json", "Query.greet.greeting");
        assertErrorMessage(diagnostic, message, 45, 23);

        diagnostic = diagnosticIterator.next();
        assertErrorMessage(diagnostic, message, 45, 23);

        diagnostic = diagnosticIterator.next();
        message = getErrorMessage(CompilationDiagnostic.INVALID_RETURN_TYPE, "byte", "Query.greet.greeting");
        assertErrorMessage(diagnostic, message, 52, 23);

        diagnostic = diagnosticIterator.next();
        assertErrorMessage(diagnostic, message, 52, 23);
    }

    @Test(groups = "invalid")
    public void testInvalidInputsInServiceTypes() {
        String packagePath = "37_invalid_inputs_in_service_types";
        DiagnosticResult diagnosticResult = getDiagnosticResult(packagePath);
        Assert.assertEquals(diagnosticResult.errorCount(), 4);
        Iterator<Diagnostic> diagnosticIterator = diagnosticResult.errors().iterator();

        // Same erroneous class is used in two different GraphQL services. Hence, the duplication of errors.
        Diagnostic diagnostic = diagnosticIterator.next();
        String message = getErrorMessage(CompilationDiagnostic.INVALID_INPUT_PARAMETER_TYPE, "json",
                                         "Query.greet.generalGreeting");
        assertErrorMessage(diagnostic, message, 44, 48);

        diagnostic = diagnosticIterator.next();
        message = getErrorMessage(CompilationDiagnostic.INVALID_INPUT_PARAMETER_TYPE, "json",
                                  "Query.greet.generalGreeting");
        assertErrorMessage(diagnostic, message, 44, 48);

        diagnostic = diagnosticIterator.next();
        message = getErrorMessage(CompilationDiagnostic.INVALID_INPUT_PARAMETER_TYPE, "map<string>",
                                  "Query.greet.status");
        assertErrorMessage(diagnostic, message, 50, 46);

        diagnostic = diagnosticIterator.next();
        message = getErrorMessage(CompilationDiagnostic.INVALID_INPUT_PARAMETER_TYPE, "map<string>",
                                  "Query.greet.status");
        assertErrorMessage(diagnostic, message, 50, 46);
    }

    @Test(groups = "invalid")
    public void testInvalidListenerInitParameters() {
        String packagePath = "38_invalid_listener_init_parameters";
        DiagnosticResult diagnosticResult = getDiagnosticResult(packagePath);
        Assert.assertEquals(diagnosticResult.errorCount(), 4);
        Iterator<Diagnostic> diagnosticIterator = diagnosticResult.errors().iterator();

        Diagnostic diagnostic = diagnosticIterator.next();
        assertError(diagnostic, CompilationDiagnostic.INVALID_LISTENER_INIT, 24, 43);

        diagnostic = diagnosticIterator.next();
        assertError(diagnostic, CompilationDiagnostic.INVALID_LISTENER_INIT, 25, 49);

        diagnostic = diagnosticIterator.next();
        assertError(diagnostic, CompilationDiagnostic.INVALID_LISTENER_INIT, 26, 60);

        diagnostic = diagnosticIterator.next();
        assertError(diagnostic, CompilationDiagnostic.INVALID_LISTENER_INIT, 27, 66);
    }

    @Test(groups = "invalid")
    public void testInvalidResourcePath() {
        String packagePath = "39_invalid_resource_paths";
        DiagnosticResult diagnosticResult = getDiagnosticResult(packagePath);
        Assert.assertEquals(diagnosticResult.errorCount(), 8);
        Iterator<Diagnostic> diagnosticIterator = diagnosticResult.errors().iterator();

        Diagnostic diagnostic = diagnosticIterator.next();
        String message = getErrorMessage(CompilationDiagnostic.INVALID_FIELD_NAME, "Query.__liftCount", "__liftCount");
        assertErrorMessage(diagnostic, message, 42, 5);

        diagnostic = diagnosticIterator.next();
        message = getErrorMessage(CompilationDiagnostic.INVALID_FIELD_NAME, "Query.lift.__id", "__id");
        assertErrorMessage(diagnostic, message, 50, 5);

        diagnostic = diagnosticIterator.next();
        message = getErrorMessage(CompilationDiagnostic.INVALID_FIELD_NAME, "Query.lift.getStatus.__elevationgain",
                                  "__elevationgain");
        assertErrorMessage(diagnostic, message, 50, 5);

        diagnostic = diagnosticIterator.next();
        message = getErrorMessage(CompilationDiagnostic.INVALID_FIELD_NAME, "Query.mountain.name.__first", "__first");
        assertErrorMessage(diagnostic, message, 61, 5);

        diagnostic = diagnosticIterator.next();
        message = getErrorMessage(CompilationDiagnostic.INVALID_FIELD_NAME, "Query.mountain.__name.last", "__name");
        assertErrorMessage(diagnostic, message, 65, 5);

        diagnostic = diagnosticIterator.next();
        message = getErrorMessage(CompilationDiagnostic.INVALID_FIELD_NAME, "Query.__mountain.id", "__mountain");
        assertErrorMessage(diagnostic, message, 69, 5);

        diagnostic = diagnosticIterator.next();
        message = getErrorMessage(CompilationDiagnostic.INVALID_FIELD_NAME, "Query.mountain.getTrail.__name", "__name");
        assertErrorMessage(diagnostic, message, 36, 23);

        diagnostic = diagnosticIterator.next();
        message = getErrorMessage(CompilationDiagnostic.INVALID_FIELD_NAME, "Mutation.__addTrail", "__addTrail");
        assertErrorMessage(diagnostic, message, 77, 5);
    }

    @Test(groups = "invalid")
    public void testInvalidReturnTypeAny() {
        String packagePath = "40_invalid_return_type_any";
        DiagnosticResult diagnosticResult = getDiagnosticResult(packagePath);
        Assert.assertEquals(diagnosticResult.errorCount(), 2);
        Iterator<Diagnostic> diagnosticIterator = diagnosticResult.errors().iterator();

        Diagnostic diagnostic = diagnosticIterator.next();
        String message = getErrorMessage(CompilationDiagnostic.INVALID_RETURN_TYPE_ANY, "Query.name");
        assertErrorMessage(diagnostic, message, 20, 5);

        diagnostic = diagnosticIterator.next();
        message = getErrorMessage(CompilationDiagnostic.INVALID_RETURN_TYPE_ANY, "Query.age");
        assertErrorMessage(diagnostic, message, 24, 5);
    }

    @Test(groups = "invalid")
    public void testServiceWithOnlyRemoteMethods() {
        String packagePath = "41_service_with_only_remote_methods";
        DiagnosticResult diagnosticResult = getDiagnosticResult(packagePath);
        Assert.assertEquals(diagnosticResult.errorCount(), 1);
        Diagnostic diagnostic = diagnosticResult.errors().iterator().next();
        String message = getErrorMessage(CompilationDiagnostic.MISSING_RESOURCE_FUNCTIONS);
        assertErrorMessage(diagnostic, message, 19, 1);
    }

    @Test(groups = "invalid")
    public void testRemoteMethodWithInvalidReturnType() {
        String packagePath = "42_remote_method_with_invalid_return_type";
        DiagnosticResult diagnosticResult = getDiagnosticResult(packagePath);
        Assert.assertEquals(diagnosticResult.errorCount(), 1);
        Diagnostic diagnostic = diagnosticResult.errors().iterator().next();
        String message = getErrorMessage(CompilationDiagnostic.INVALID_RETURN_TYPE, "json", "Mutation.setName");
        assertErrorMessage(diagnostic, message, 23, 5);
    }

    @Test(groups = "invalid")
    public void testRemoteMethodInsideReturningServiceType() {
        String packagePath = "43_remote_methods_inside_returning_service_type";
        DiagnosticResult diagnosticResult = getDiagnosticResult(packagePath);
        Assert.assertEquals(diagnosticResult.errorCount(), 1);
        Diagnostic diagnostic = diagnosticResult.errors().iterator().next();
        String message = getErrorMessage(CompilationDiagnostic.INVALID_FUNCTION, "Person", "setName");
        assertErrorMessage(diagnostic, message, 36, 21);
    }

    @Test(groups = "invalid")
    public void testMissingResourceMethodFromReturningServiceClass() {
        String packagePath = "44_missing_resource_method_from_returning_service_class";
        DiagnosticResult diagnosticResult = getDiagnosticResult(packagePath);
        Assert.assertEquals(diagnosticResult.errorCount(), 1);
        Diagnostic diagnostic = diagnosticResult.errors().iterator().next();
        String message = getErrorMessage(CompilationDiagnostic.MISSING_RESOURCE_FUNCTIONS);
        assertErrorMessage(diagnostic, message, 25, 15);
    }

    @Test(groups = "invalid")
    public void testInvalidInputObjects() {
        String packagePath = "45_invalid_input_objects";
        DiagnosticResult diagnosticResult = getDiagnosticResult(packagePath);
        Assert.assertEquals(diagnosticResult.errorCount(), 11);
        Iterator<Diagnostic> diagnosticIterator = diagnosticResult.errors().iterator();
        Diagnostic diagnostic = diagnosticIterator.next();
        String message = getErrorMessage(CompilationDiagnostic.INVALID_RESOURCE_INPUT_OBJECT_PARAM, "Query.profile",
                                         "Person");
        assertErrorMessage(diagnostic, message, 39, 42);

        diagnostic = diagnosticIterator.next();
        message = getErrorMessage(CompilationDiagnostic.INVALID_RESOURCE_INPUT_OBJECT_PARAM, "Query.book", "Person");
        assertErrorMessage(diagnostic, message, 48, 37);

        diagnostic = diagnosticIterator.next();
        message = getErrorMessage(CompilationDiagnostic.INVALID_RETURN_TYPE_INPUT_OBJECT, "Query.location", "Location");
        assertErrorMessage(diagnostic, message, 61, 5);

        diagnostic = diagnosticIterator.next();
        message = getErrorMessage(CompilationDiagnostic.INVALID_RESOURCE_INPUT_OBJECT_PARAM, "Query.locationArray",
                                  "Location");
        assertErrorMessage(diagnostic, message, 77, 50);

        diagnostic = diagnosticIterator.next();
        message = getErrorMessage(CompilationDiagnostic.INVALID_RESOURCE_INPUT_OBJECT_PARAM, "Query.details", "Person");
        assertErrorMessage(diagnostic, message, 83, 42);

        diagnostic = diagnosticIterator.next();
        message = getErrorMessage(CompilationDiagnostic.INVALID_RESOURCE_INPUT_OBJECT_PARAM, "Query.details", "Person");
        assertErrorMessage(diagnostic, message, 95, 43);

        diagnostic = diagnosticIterator.next();
        message = getErrorMessage(CompilationDiagnostic.INVALID_RESOURCE_INPUT_OBJECT_PARAM, "Query.details", "Person");
        assertErrorMessage(diagnostic, message, 110, 43);

        diagnostic = diagnosticIterator.next();
        message = getErrorMessage(CompilationDiagnostic.INVALID_RESOURCE_INPUT_OBJECT_PARAM, "Query.book", "Person");
        assertErrorMessage(diagnostic, message, 122, 39);

        diagnostic = diagnosticIterator.next();
        message = getErrorMessage(CompilationDiagnostic.INVALID_RESOURCE_INPUT_OBJECT_PARAM, "Query.book", "Person");
        assertErrorMessage(diagnostic, message, 134, 40);

        diagnostic = diagnosticIterator.next();
        message = getErrorMessage(CompilationDiagnostic.INVALID_RETURN_TYPE_INPUT_OBJECT, "Query.person", "Person");
        assertErrorMessage(diagnostic, message, 153, 5);
    }

    @Test(groups = "invalid")
    public void testInvalidContextObject() {
        String packagePath = "47_invalid_context_object";
        DiagnosticResult diagnosticResult = getDiagnosticResult(packagePath);
        Assert.assertEquals(diagnosticResult.errorCount(), 2);
        Iterator<Diagnostic> diagnosticIterator = diagnosticResult.errors().iterator();
        Diagnostic diagnostic = diagnosticIterator.next();
        String message = getErrorMessage(CompilationDiagnostic.INVALID_INPUT_PARAMETER_TYPE,
                                         TEST_MODULE_PREFIX + "Context", "Query.profile");
        assertErrorMessage(diagnostic, message, 21, 43);

        diagnostic = diagnosticIterator.next();
        message = getErrorMessage(CompilationDiagnostic.INVALID_INPUT_PARAMETER_TYPE, TEST_MODULE_PREFIX + "Context",
                                  "Mutation.updateName");
        assertErrorMessage(diagnostic, message, 25, 40);
    }

    @Test(groups = "invalid")
    public void testInvalidRecordFieldType() {
        String packagePath = "48_invalid_record_field_type";
        DiagnosticResult diagnosticResult = getDiagnosticResult(packagePath);
        Assert.assertEquals(diagnosticResult.errorCount(), 1);
        Diagnostic diagnostic = diagnosticResult.errors().iterator().next();
        String message = getErrorMessage(CompilationDiagnostic.INVALID_RETURN_TYPE_ERROR_OR_NIL, "Query.profile.err");
        assertErrorMessage(diagnostic, message, 25, 5);
    }

    @Test(groups = "invalid")
    public void testInvalidListTypeInputs() {
        String packagePath = "49_invalid_list_type_inputs";
        DiagnosticResult diagnosticResult = getDiagnosticResult(packagePath);
        Assert.assertEquals(diagnosticResult.errorCount(), 5);
        Iterator<Diagnostic> diagnosticIterator = diagnosticResult.errors().iterator();

        Diagnostic diagnostic = diagnosticIterator.next();
        String message = getErrorMessage(CompilationDiagnostic.INVALID_RESOURCE_INPUT_OBJECT_PARAM, "Query.profile",
                                         "Person");
        assertErrorMessage(diagnostic, message, 35, 44);

        diagnostic = diagnosticIterator.next();
        assertErrorMessage(diagnostic, message, 44, 44);

        diagnostic = diagnosticIterator.next();
        message = getErrorMessage(CompilationDiagnostic.INVALID_RESOURCE_INPUT_OBJECT_PARAM, "Query.book", "Person");
        assertErrorMessage(diagnostic, message, 59, 39);

        diagnostic = diagnosticIterator.next();
        message = getErrorMessage(CompilationDiagnostic.INVALID_RETURN_TYPE_INPUT_OBJECT, "Query.location", "Location");
        assertErrorMessage(diagnostic, message, 72, 5);

        diagnostic = diagnosticIterator.next();
        message = getErrorMessage(CompilationDiagnostic.INVALID_RESOURCE_INPUT_OBJECT_PARAM, "Query.locationArray",
                                  "Location");
        assertErrorMessage(diagnostic, message, 88, 52);
    }

    @Test(groups = "invalid")
    public void testInvalidResourcePaths() {
        String packagePath = "50_invalid_resource_paths";
        DiagnosticResult diagnosticResult = getDiagnosticResult(packagePath);
        Assert.assertEquals(diagnosticResult.errorCount(), 5);
        Iterator<Diagnostic> diagnosticIterator = diagnosticResult.errors().iterator();

        Diagnostic diagnostic = diagnosticIterator.next();
        String message = getErrorMessage(CompilationDiagnostic.INVALID_PATH_PARAMETERS, "[string id]");
        assertErrorMessage(diagnostic, message, 20, 5);

        diagnostic = diagnosticIterator.next();
        message = getErrorMessage(CompilationDiagnostic.INVALID_PATH_PARAMETERS, "[string... ids]");
        assertErrorMessage(diagnostic, message, 24, 5);

        diagnostic = diagnosticIterator.next();
        message = getErrorMessage(CompilationDiagnostic.INVALID_RESOURCE_PATH, ".");
        assertErrorMessage(diagnostic, message, 28, 5);

        diagnostic = diagnosticIterator.next();
        message = getErrorMessage(CompilationDiagnostic.INVALID_PATH_PARAMETERS, "[int... ids]");
        assertErrorMessage(diagnostic, message, 32, 5);

        diagnostic = diagnosticIterator.next();
        message = getErrorMessage(CompilationDiagnostic.INVALID_HIERARCHICAL_RESOURCE_PATH, "profile/names");
        assertErrorMessage(diagnostic, message, 36, 5);
    }

    @Test(groups = "invalid")
    public void testFileUploadInInvalidLocations() {
        String packagePath = "51_file_upload_in_invalid_locations";
        DiagnosticResult diagnosticResult = getDiagnosticResult(packagePath);
        Assert.assertEquals(diagnosticResult.errorCount(), 14);
        Iterator<Diagnostic> diagnosticIterator = diagnosticResult.errors().iterator();

        Diagnostic diagnostic = diagnosticIterator.next();
        String message = getErrorMessage(CompilationDiagnostic.INVALID_RETURN_TYPE, "stream",
                                         "Query.getImage.byteStream");
        assertErrorMessage(diagnostic, message, 36, 5);

        diagnostic = diagnosticIterator.next();
        message = getErrorMessage(CompilationDiagnostic.INVALID_RETURN_TYPE, "stream",
                                  "Query.getImageIfExist.byteStream");
        assertErrorMessage(diagnostic, message, 43, 5);

        diagnostic = diagnosticIterator.next();
        message = getErrorMessage(CompilationDiagnostic.INVALID_RETURN_TYPE, "stream", "Query.getImages.byteStream");
        assertErrorMessage(diagnostic, message, 50, 5);

        diagnostic = diagnosticIterator.next();
        message = getErrorMessage(CompilationDiagnostic.INVALID_FILE_UPLOAD_IN_RESOURCE_FUNCTION, "upload");
        assertErrorMessage(diagnostic, message, 57, 58);

        diagnostic = diagnosticIterator.next();
        message = getErrorMessage(CompilationDiagnostic.INVALID_FILE_UPLOAD_IN_RESOURCE_FUNCTION, "uploadMultiple");
        assertErrorMessage(diagnostic, message, 64, 68);

        diagnostic = diagnosticIterator.next();
        message = getErrorMessage(CompilationDiagnostic.INVALID_FILE_UPLOAD_IN_RESOURCE_FUNCTION, "uploadFile");
        assertErrorMessage(diagnostic, message, 71, 63);

        diagnostic = diagnosticIterator.next();
        message = getErrorMessage(CompilationDiagnostic.INVALID_RETURN_TYPE, "stream",
                                  "Mutation.uploadAndGet.byteStream");
        assertErrorMessage(diagnostic, message, 82, 5);

        diagnostic = diagnosticIterator.next();
        message = getErrorMessage(CompilationDiagnostic.INVALID_RETURN_TYPE, "stream",
                                  "Mutation.uploadAndGet.byteStream");
        assertErrorMessage(diagnostic, message, 93, 5);

        diagnostic = diagnosticIterator.next();
        message = getErrorMessage(CompilationDiagnostic.INVALID_RETURN_TYPE, "stream",
                                  "Mutation.uploadAndGetMultiple.byteStream");
        assertErrorMessage(diagnostic, message, 104, 5);

        diagnostic = diagnosticIterator.next();
        message = getErrorMessage(CompilationDiagnostic.MULTI_DIMENSIONAL_UPLOAD_ARRAY, "upload");
        assertErrorMessage(diagnostic, message, 115, 56);

        diagnostic = diagnosticIterator.next();
        message = getErrorMessage(CompilationDiagnostic.INVALID_INPUT_PARAMETER_TYPE, TEST_MODULE_PREFIX + "File",
                                  "Query.uploadFile");
        assertErrorMessage(diagnostic, message, 122, 52);

        diagnostic = diagnosticIterator.next();
        message = getErrorMessage(CompilationDiagnostic.INVALID_INPUT_PARAMETER_TYPE, TEST_MODULE_PREFIX + "File",
                                  "Mutation.upload");
        assertErrorMessage(diagnostic, message, 133, 33);

        diagnostic = diagnosticIterator.next();
        message = getErrorMessage(CompilationDiagnostic.INVALID_RETURN_TYPE, "stream",
                                  "Query.uploadFile.file.byteStream");
        assertErrorMessage(diagnostic, message, 140, 5);

        diagnostic = diagnosticIterator.next();
        message = getErrorMessage(CompilationDiagnostic.INVALID_RETURN_TYPE, "stream",
                                  "Mutation.upload.file.byteStream");
        assertErrorMessage(diagnostic, message, 154, 5);
    }

    @Test(groups = "invalid")
    public void testNonDistinctInterfaceImplementation() {
        String packagePath = "52_non_distinct_interface_implementation";
        DiagnosticResult diagnosticResult = getDiagnosticResult(packagePath);
        Assert.assertEquals(diagnosticResult.errorCount(), 1);
        Diagnostic diagnostic = diagnosticResult.errors().iterator().next();
        String message = getErrorMessage(CompilationDiagnostic.NON_DISTINCT_INTERFACE_IMPLEMENTATION, "Teacher");
        assertErrorMessage(diagnostic, message, 59, 31);
    }

    @Test(groups = "invalid")
    public void testNonDistinctInterface() {
        String packagePath = "53_non_distinct_interface";
        DiagnosticResult diagnosticResult = getDiagnosticResult(packagePath);
        Assert.assertEquals(diagnosticResult.errorCount(), 2);
        Iterator<Diagnostic> diagnosticIterator = diagnosticResult.errors().iterator();

        Diagnostic diagnostic = diagnosticIterator.next();
        String message = getErrorMessage(CompilationDiagnostic.NON_DISTINCT_INTERFACE, "Person");
        assertErrorMessage(diagnostic, message, 20, 5);

        diagnostic = diagnosticIterator.next();
        message = getErrorMessage(CompilationDiagnostic.NON_DISTINCT_INTERFACE_IMPLEMENTATION, "Teacher");
        assertErrorMessage(diagnostic, message, 59, 31);
    }

    @Test(groups = "invalid")
    public void testInvalidResourceFunctionsInInterfaceImplementations() {
        String packagePath = "54_invalid_resource_functions_in_interface_implementations";
        DiagnosticResult diagnosticResult = getDiagnosticResult(packagePath);
        Assert.assertEquals(diagnosticResult.errorCount(), 2);
        Iterator<Diagnostic> diagnosticIterator = diagnosticResult.errors().iterator();

        Diagnostic diagnostic = diagnosticIterator.next();
        String message = getErrorMessage(CompilationDiagnostic.INVALID_RESOURCE_FUNCTION_ACCESSOR, "read", "id");
        assertErrorMessage(diagnostic, message, 54, 32);

        diagnostic = diagnosticIterator.next();
        message = getErrorMessage(CompilationDiagnostic.INVALID_RESOURCE_FUNCTION_ACCESSOR, "post", "subject");
        assertErrorMessage(diagnostic, message, 86, 32);
    }

    @Test(groups = "invalid")
    public void testInvalidReturnTypesInInterfaceImplementations() {
        String packagePath = "55_invalid_return_types_in_interface_implementations";
        DiagnosticResult diagnosticResult = getDiagnosticResult(packagePath);
        Assert.assertEquals(diagnosticResult.errorCount(), 1);
        Diagnostic diagnostic = diagnosticResult.errors().iterator().next();
        String message = getErrorMessage(CompilationDiagnostic.INVALID_RETURN_TYPE, "map", "Query.name.names");
        assertErrorMessage(diagnostic, message, 90, 32);
    }

    @Test(groups = "invalid")
    public void testInvalidSubscribeService() {
        String packagePath = "56_invalid_subscribe_service";
        DiagnosticResult diagnosticResult = getDiagnosticResult(packagePath);
        Assert.assertEquals(diagnosticResult.errorCount(), 3);
        Iterator<Diagnostic> diagnosticIterator = diagnosticResult.errors().iterator();

        Diagnostic diagnostic = diagnosticIterator.next();
        String message = getErrorMessage(CompilationDiagnostic.MISSING_RESOURCE_FUNCTIONS);
        assertErrorMessage(diagnostic, message, 19, 1);

        diagnostic = diagnosticIterator.next();
        message = getErrorMessage(CompilationDiagnostic.INVALID_RETURN_TYPE, "byte",
                                  "Subscription.profiles.bytes");
        assertErrorMessage(diagnostic, message, 31, 5);

        diagnostic = diagnosticIterator.next();
        message = getErrorMessage(CompilationDiagnostic.INVALID_RESOURCE_FUNCTION_ACCESSOR, "subscribe", "age");
        assertErrorMessage(diagnostic, message, 61, 32);
    }

    @Test(groups = "invalid")
    public void testInvalidInterceptor() {
        String packagePath = "57_invalid_interceptor";
        DiagnosticResult diagnosticResult = getDiagnosticResult(packagePath);
        Assert.assertEquals(diagnosticResult.errorCount(), 2);
        Iterator<Diagnostic> diagnosticIterator = diagnosticResult.errors().iterator();

        Diagnostic diagnostic = diagnosticIterator.next();
        String message = getErrorMessage(CompilationDiagnostic.RESOURCE_METHOD_INSIDE_INTERCEPTOR,
                                         "isolated resource function get name (int id) returns string");
        assertErrorMessage(diagnostic, message, 27, 5);

        diagnostic = diagnosticIterator.next();
        message = getErrorMessage(CompilationDiagnostic.INVALID_REMOTE_METHOD_INSIDE_INTERCEPTOR,
                                  "isolated remote function updateName(string name) returns string");
        assertErrorMessage(diagnostic, message, 34, 5);
    }

    @Test(groups = "invalid")
    public void testAnonymousRecordsAsFieldType() {
        String packagePath = "58_anonymous_records_as_field_type";
        DiagnosticResult diagnosticResult = getDiagnosticResult(packagePath);
        Assert.assertEquals(diagnosticResult.errorCount(), 8);
        Iterator<Diagnostic> diagnosticIterator = diagnosticResult.errors().iterator();

        Diagnostic diagnostic = diagnosticIterator.next();
        String message = getErrorMessage(CompilationDiagnostic.INVALID_ANONYMOUS_FIELD_TYPE,
                                         "record {|int number; string street; string city;|}", "Query.profile.address");
        assertErrorMessage(diagnostic, message, 26, 5);

        diagnostic = diagnosticIterator.next();
        message = getErrorMessage(CompilationDiagnostic.INVALID_ANONYMOUS_FIELD_TYPE,
                                  "record {|int number; string street; string city;|}", "Query.address");
        assertErrorMessage(diagnostic, message, 38, 5);

        diagnostic = diagnosticIterator.next();
        message = getErrorMessage(CompilationDiagnostic.INVALID_ANONYMOUS_FIELD_TYPE,
                                  "record {|string name; int age;|}", "Query.class.profile");
        assertErrorMessage(diagnostic, message, 52, 23);

        diagnostic = diagnosticIterator.next();
        message = getErrorMessage(CompilationDiagnostic.INVALID_ANONYMOUS_INPUT_TYPE,
                                  "record {|string name; int age;|}", "Query.name");
        assertErrorMessage(diagnostic, message, 58, 67);

        diagnostic = diagnosticIterator.next();
        message = getErrorMessage(CompilationDiagnostic.INVALID_ANONYMOUS_INPUT_TYPE,
                                  "record {|string name; int age;|}", "Query.school.name");
        assertErrorMessage(diagnostic, message, 68, 67);

        diagnostic = diagnosticIterator.next();
        message = getErrorMessage(CompilationDiagnostic.INVALID_ANONYMOUS_FIELD_TYPE,
                                  "record {|int number; string street; string city;|}", "Mutation.updateName.address");
        assertErrorMessage(diagnostic, message, 78, 5);

        diagnostic = diagnosticIterator.next();
        message = getErrorMessage(CompilationDiagnostic.INVALID_ANONYMOUS_FIELD_TYPE,
                                  "record {|int number; string street; string city;|}",
                                  "Subscription.profiles.address");
        assertErrorMessage(diagnostic, message, 96, 5);

        diagnostic = diagnosticIterator.next();
        message = getErrorMessage(CompilationDiagnostic.INVALID_ANONYMOUS_FIELD_TYPE,
                                  "record {|int number; string street; string city;|}",
                                  "Query.company.profile.address");
        assertErrorMessage(diagnostic, message, 112, 5);
    }

    @Test(groups = "invalid")
    public void testInvalidUseOfReservedFederatedResolverNames() {
        String packagePath = "59_invalid_use_of_reserved_federation_resolver_names";
        DiagnosticResult diagnosticResult = getDiagnosticResult(packagePath);
        Assert.assertEquals(diagnosticResult.errorCount(), 3);
        Iterator<Diagnostic> diagnosticIterator = diagnosticResult.errors().iterator();

        Diagnostic diagnostic = diagnosticIterator.next();
        String message = getErrorMessage(CompilationDiagnostic.INVALID_USE_OF_RESERVED_RESOURCE_PATH, "_entities");
        assertErrorMessage(diagnostic, message, 20, 23);

        diagnostic = diagnosticIterator.next();
        message = getErrorMessage(CompilationDiagnostic.INVALID_USE_OF_RESERVED_RESOURCE_PATH, "_service");
        assertErrorMessage(diagnostic, message, 24, 23);

        diagnostic = diagnosticIterator.next();
        message = getErrorMessage(CompilationDiagnostic.INVALID_USE_OF_RESERVED_REMOTE_METHOD_NAME, "_entities");
        assertErrorMessage(diagnostic, message, 34, 21);
    }

    @Test(groups = "invalid")
    public void testInvalidEntityMissingResolveReference() {
        String packagePath = "90_invalid_entity_missing_resolve_reference";
        DiagnosticResult result = getDiagnosticResult(packagePath);
        Assert.assertEquals(result.errorCount(), 1, "Expected one validation error when resolveReference is missing.");

        Diagnostic diagnostic = result.errors().iterator().next();
        String expectedMessage = getErrorMessage(CompilationDiagnostic.INVALID_ENTITY_FIELD, "User");
        assertErrorMessage(diagnostic, expectedMessage, 8, 5);
    }
    @Test(groups = "invalid")
    public void testInvalidUseOfReservedFederatedTypeNames() {
        String packagePath = "60_invalid_use_of_reserved_federation_type_names";
        DiagnosticResult diagnosticResult = getDiagnosticResult(packagePath);
        Assert.assertEquals(diagnosticResult.errorCount(), 6);
        Iterator<Diagnostic> diagnosticIterator = diagnosticResult.errors().iterator();

        Diagnostic diagnostic = diagnosticIterator.next();
        String message = getErrorMessage(CompilationDiagnostic.INVALID_USE_OF_RESERVED_TYPE_AS_OUTPUT_TYPE, "Query.any",
                                         "_Any");
        assertErrorMessage(diagnostic, message, 43, 5);

        diagnostic = diagnosticIterator.next();
        message = getErrorMessage(CompilationDiagnostic.INVALID_USE_OF_RESERVED_TYPE_AS_OUTPUT_TYPE,
                                  "Mutation.services", "_Service");
        assertErrorMessage(diagnostic, message, 36, 15);

        diagnostic = diagnosticIterator.next();
        message = getErrorMessage(CompilationDiagnostic.INVALID_USE_OF_RESERVED_TYPE_AS_INPUT_TYPE, "FieldSet");
        assertErrorMessage(diagnostic, message, 51, 45);

        diagnostic = diagnosticIterator.next();
        message = getErrorMessage(CompilationDiagnostic.INVALID_USE_OF_RESERVED_TYPE_AS_OUTPUT_TYPE, "Query.linkImport",
                                  "link__Import");
        assertErrorMessage(diagnostic, message, 55, 5);

        diagnostic = diagnosticIterator.next();
        message = getErrorMessage(CompilationDiagnostic.INVALID_USE_OF_RESERVED_TYPE_AS_OUTPUT_TYPE,
                                  "Query.linkPurpose", "link__Purpose");
        assertErrorMessage(diagnostic, message, 27, 6);

        diagnostic = diagnosticIterator.next();
        message = getErrorMessage(CompilationDiagnostic.INVALID_USE_OF_RESERVED_TYPE_AS_INPUT_TYPE, "link__Purpose");
        assertErrorMessage(diagnostic, message, 63, 51);
    }

    @Test(groups = "invalid")
    public void testUnsupportedTypeAlias() {
        String packagePath = "61_unsupported_type_alias";
        DiagnosticResult diagnosticResult = getDiagnosticResult(packagePath);
        Assert.assertEquals(diagnosticResult.errorCount(), 5);
        Iterator<Diagnostic> diagnosticIterator = diagnosticResult.errors().iterator();

        Diagnostic diagnostic = diagnosticIterator.next();
        String message = getErrorMessage(CompilationDiagnostic.UNSUPPORTED_TYPE_ALIAS, "Id", "int");
        assertErrorMessage(diagnostic, message, 19, 6);

        diagnostic = diagnosticIterator.next();
        assertErrorMessage(diagnostic, message, 19, 6);

        diagnostic = diagnosticIterator.next();
        message = getErrorMessage(CompilationDiagnostic.UNSUPPORTED_TYPE_ALIAS, "PersonInput", "Input");
        assertErrorMessage(diagnostic, message, 37, 6);

        diagnostic = diagnosticIterator.next();
        message = getErrorMessage(CompilationDiagnostic.UNSUPPORTED_TYPE_ALIAS, "PersonInput2", "PersonInput");
        assertErrorMessage(diagnostic, message, 39, 6);

        diagnostic = diagnosticIterator.next();
        message = getErrorMessage(CompilationDiagnostic.UNSUPPORTED_TYPE_ALIAS, "PersonAddress", "Address");
        assertErrorMessage(diagnostic, message, 41, 6);
    }

    @Test(groups = "invalid")
    public void testInvalidUsagesOfIdAnnotation() {
        String packagePath = "62_invalid_usages_of_id_annotation";
        DiagnosticResult diagnosticResult = getDiagnosticResult(packagePath);
        Assert.assertEquals(diagnosticResult.errorCount(), 3);
        Iterator<Diagnostic> diagnosticIterator = diagnosticResult.errors().iterator();

        Diagnostic diagnostic = diagnosticIterator.next();
        String message = getErrorMessage(CompilationDiagnostic.INVALID_USE_OF_ID_ANNOTATION);
        assertErrorMessage(diagnostic, message, 20, 32);

        diagnostic = diagnosticIterator.next();
        assertErrorMessage(diagnostic, message, 32, 40);

        diagnostic = diagnosticIterator.next();
        assertErrorMessage(diagnostic, message, 42, 32);
    }

    @Test(groups = "valid")
    public void testValidUsageOfIdAnnotation() {
        String packagePath = "63_valid_usages_of_id_annotation";
        DiagnosticResult diagnosticResult = getDiagnosticResult(packagePath);
        Assert.assertEquals(diagnosticResult.errorCount(), 0);
    }

    @Test(groups = "invalid")
    public void testPrefetchMethodWithoutContextParameter() {
        String packagePath = "64_prefetch_method_without_context_parameter";
        DiagnosticResult diagnosticResult = getDiagnosticResult(packagePath);
        Assert.assertEquals(diagnosticResult.errorCount(), 1);
        Iterator<Diagnostic> diagnosticIterator = diagnosticResult.errors().iterator();

        Diagnostic diagnostic = diagnosticIterator.next();
        String message = getErrorMessage(CompilationDiagnostic.MISSING_GRAPHQL_CONTEXT_PARAMETER, "preBooks");
        assertErrorMessage(diagnostic, message, 30, 23);
    }

    @Test(groups = "invalid")
    public void testPrefetchMethodWithInvalidParameters() {
        String packagePath = "65_prefetch_method_with_invalid_parameters";
        DiagnosticResult diagnosticResult = getDiagnosticResult(packagePath);
        Assert.assertEquals(diagnosticResult.errorCount(), 1);
        Iterator<Diagnostic> diagnosticIterator = diagnosticResult.errors().iterator();

        Diagnostic diagnostic = diagnosticIterator.next();
        String message = getErrorMessage(CompilationDiagnostic.INVALID_PARAMETER_IN_PREFETCH_METHOD, "int id",
                                         "preBooks", "books");
        assertErrorMessage(diagnostic, message, 26, 23);
    }

    @Test(groups = "invalid")
    public void testPrefetchMethodWithInvalidReturnType() {
        String packagePath = "66_prefetch_method_with_invalid_return_type";
        DiagnosticResult diagnosticResult = getDiagnosticResult(packagePath);
        Assert.assertEquals(diagnosticResult.errorCount(), 1);
        Iterator<Diagnostic> diagnosticIterator = diagnosticResult.errors().iterator();

        Diagnostic diagnostic = diagnosticIterator.next();
        String message = getErrorMessage(CompilationDiagnostic.INVALID_RETURN_TYPE_IN_PREFETCH_METHOD, "int",
                                         "preBooks");
        assertErrorMessage(diagnostic, message, 30, 23);
    }

    @Test(groups = "valid")
    public void testServiceWithValidDataLoaderConfiguration() {
        String packagePath = "67_service_with_valid_data_loader_configuration";
        DiagnosticResult diagnosticResult = getDiagnosticResult(packagePath);
        Assert.assertEquals(diagnosticResult.errorCount(), 0);
    }

    @Test(groups = "invalid")
    public void testServiceWithInvalidPrefetchMethodNameConfig() {
        String packagePath = "68_service_with_invalid_prefetch_method_name_config";
        DiagnosticResult diagnosticResult = getDiagnosticResult(packagePath);
        Assert.assertEquals(diagnosticResult.errorCount(), 2);
        Iterator<Diagnostic> diagnosticIterator = diagnosticResult.errors().iterator();

        Diagnostic diagnostic = diagnosticIterator.next();
        String message = getErrorMessage(CompilationDiagnostic.UNABLE_TO_FIND_PREFETCH_METHOD, "loadBooks", "books");
        assertErrorMessage(diagnostic, message, 46, 32);

        diagnostic = diagnosticIterator.next();
        message = getErrorMessage(CompilationDiagnostic.UNABLE_TO_FIND_PREFETCH_METHOD, "prefetchUpdateAuthor",
                                  "updateAuthor");
        assertErrorMessage(diagnostic, message, 37, 21);
    }

    @Test(groups = "invalid")
    public void testSubscriptionWithInvalidPrefetchMethodNameConfig() {
        String packagePath = "69_subscription_with_invalid_prefetch_method_name_config";
        DiagnosticResult diagnosticResult = getDiagnosticResult(packagePath);
        Assert.assertEquals(diagnosticResult.errorCount(), 1);
        Iterator<Diagnostic> diagnosticIterator = diagnosticResult.errors().iterator();

        Diagnostic diagnostic = diagnosticIterator.next();
        String message = getErrorMessage(CompilationDiagnostic.INVALID_USAGE_OF_PREFETCH_METHOD_NAME_CONFIG,
                                         "prefetchMethodName", "authors");
        assertErrorMessage(diagnostic, message, 24, 5);
    }

    @Test(groups = "invalid")
    public void testPrefetchMethodConfigurationUsingVariableValue() {
        String packagePath = "70_prefetch_method_configuration_using_variable_value";
        DiagnosticResult diagnosticResult = getDiagnosticResult(packagePath);
        Assert.assertEquals(diagnosticResult.warningCount(), 1);
        Iterator<Diagnostic> diagnosticIterator = diagnosticResult.warnings().iterator();

        Diagnostic diagnostic = diagnosticIterator.next();
        String message = getErrorMessage(CompilationDiagnostic.UNABLE_TO_VALIDATE_PREFETCH_METHOD, "prefetchMethodName",
                                         "updateAuthor");
        assertWarningMessage(diagnostic, message, 36, 5);
    }

    @Test(groups = "invalid")
    public void testInvalidUsageDeprecatedDirective() {
        String packagePath = "71_invalid_usages_of_deprecated_directive";
        DiagnosticResult diagnosticResult = getDiagnosticResult(packagePath);
        Assert.assertEquals(diagnosticResult.warningCount(), 2);
        Iterator<Diagnostic> diagnosticIterator = diagnosticResult.warnings().iterator();

        Diagnostic diagnostic = diagnosticIterator.next();
        String message = getErrorMessage(CompilationDiagnostic.UNSUPPORTED_INPUT_FIELD_DEPRECATION, "Profile");
        assertWarningMessage(diagnostic, message, 21, 12);

        diagnostic = diagnosticIterator.next();
        assertWarningMessage(diagnostic, message, 23, 9);
    }

    @Test(groups = "invalid")
    public void testInvalidUsagesOfSpreadFieldInEntityAnnotation() {
        String packagePath = "72_invalid_usages_of_spread_field_in_entity_annotation";
        DiagnosticResult diagnosticResult = getDiagnosticResult(packagePath);
        Assert.assertEquals(diagnosticResult.warningCount(), 1);
        Iterator<Diagnostic> diagnosticIterator = diagnosticResult.warnings().iterator();

        Diagnostic diagnostic = diagnosticIterator.next();
        String message = getErrorMessage(CompilationDiagnostic.PROVIDE_KEY_VALUE_PAIR_FOR_ENTITY_ANNOTATION);
        assertWarningMessage(diagnostic, message, 25, 5);
    }

    @Test(groups = "invalid")
    public void testInvalidUsagesOfShortHandFieldNotationInEntityAnnotation() {
        String packagePath = "73_invalid_usages_of_short_hand_field_notation_in_entity_annotation";
        DiagnosticResult diagnosticResult = getDiagnosticResult(packagePath);
        Assert.assertEquals(diagnosticResult.warningCount(), 1);
        Iterator<Diagnostic> diagnosticIterator = diagnosticResult.warnings().iterator();

        Diagnostic diagnostic = diagnosticIterator.next();
        String message = getErrorMessage(
                CompilationDiagnostic.PROVIDE_A_STRING_LITERAL_OR_AN_ARRAY_OF_STRING_LITERALS_FOR_KEY_FIELD, "key");
        assertWarningMessage(diagnostic, message, 23, 5);
    }

    @Test(groups = "invalid")
    public void testInvalidUsagesOfVariableInEntityAnnotation() {
        String packagePath = "74_invalid_usages_of_variable_in_entity_annotation";
        DiagnosticResult diagnosticResult = getDiagnosticResult(packagePath);
        Assert.assertEquals(diagnosticResult.warningCount(), 1);
        Iterator<Diagnostic> diagnosticIterator = diagnosticResult.warnings().iterator();

        Diagnostic diagnostic = diagnosticIterator.next();
        String message = getErrorMessage(
                CompilationDiagnostic.PROVIDE_A_STRING_LITERAL_OR_AN_ARRAY_OF_STRING_LITERALS_FOR_KEY_FIELD, "key");
        assertWarningMessage(diagnostic, message, 23, 10);
    }

    @Test(groups = "invalid")
    public void testInvalidUsagesOfVariableInListConstructorInEntityAnnotation() {
        String packagePath = "75_invalid_usages_of_variable_in_list_constructor_in_entity_annotation";
        DiagnosticResult diagnosticResult = getDiagnosticResult(packagePath);
        Assert.assertEquals(diagnosticResult.warningCount(), 1);
        Iterator<Diagnostic> diagnosticIterator = diagnosticResult.warnings().iterator();

        Diagnostic diagnostic = diagnosticIterator.next();
        String message = getErrorMessage(
                CompilationDiagnostic.PROVIDE_A_STRING_LITERAL_OR_AN_ARRAY_OF_STRING_LITERALS_FOR_KEY_FIELD, "key");
        assertWarningMessage(diagnostic, message, 23, 11);
    }

    @Test(groups = "invalid")
    public void testInvalidEmptyRecordTypes() {
        String packagePath = "76_invalid_empty_record_types";
        DiagnosticResult diagnosticResult = getDiagnosticResult(packagePath);
        Assert.assertEquals(diagnosticResult.errorCount(), 4);
        Iterator<Diagnostic> diagnosticIterator = diagnosticResult.errors().iterator();

        Diagnostic diagnostic = diagnosticIterator.next();
        String message = getErrorMessage(CompilationDiagnostic.INVALID_EMPTY_RECORD_OBJECT_TYPE, "Profile",
                "Query.profile");
        assertErrorMessage(diagnostic, message, 27, 5);

        diagnostic = diagnosticIterator.next();
        message = getErrorMessage(CompilationDiagnostic.INVALID_EMPTY_RECORD_INPUT_TYPE, "Profile", "Query.name");
        assertErrorMessage(diagnostic, message, 33, 40);

        diagnostic = diagnosticIterator.next();
        message = getErrorMessage(CompilationDiagnostic.INVALID_EMPTY_RECORD_OBJECT_TYPE, "Profile",
                "Query.name.profile");
        assertErrorMessage(diagnostic, message, 39, 5);

        diagnostic = diagnosticIterator.next();
        message = getErrorMessage(CompilationDiagnostic.INVALID_EMPTY_RECORD_INPUT_TYPE, "Profile", "Query.name");
        assertErrorMessage(diagnostic, message, 45, 44);
    }

    @Test(groups = "invalid")
    public void testInvalidVariableUsageInDefaultParam() {
        String packagePath = "77_invalid_variable_usage_in_default_param";
        DiagnosticResult diagnosticResult = getDiagnosticResult(packagePath);
        Assert.assertEquals(diagnosticResult.warningCount(), 1);
        Iterator<Diagnostic> diagnosticIterator = diagnosticResult.warnings().iterator();

        Diagnostic diagnostic = diagnosticIterator.next();
        String message = getErrorMessage(
                CompilationDiagnostic.PROVIDE_LITERAL_OR_CONSTRUCTOR_EXPRESSION_FOR_DEFAULT_PARAM, "parameter", "a");
        assertWarningMessage(diagnostic, message, 22, 40);
    }

    @Test(groups = "invalid")
    public void testInvalidFunctionCallExpressionAsDefaultParam() {
        String packagePath = "78_invalid_function_call_expression_as_default_param";
        DiagnosticResult diagnosticResult = getDiagnosticResult(packagePath);
        Assert.assertEquals(diagnosticResult.warningCount(), 1);
        Iterator<Diagnostic> diagnosticIterator = diagnosticResult.warnings().iterator();

        Diagnostic diagnostic = diagnosticIterator.next();
        String message = getErrorMessage(
                CompilationDiagnostic.PROVIDE_LITERAL_OR_CONSTRUCTOR_EXPRESSION_FOR_DEFAULT_PARAM, "parameter", "a");
        assertWarningMessage(diagnostic, message, 24, 40);
    }

    @Test(groups = "invalid")
    public void testInvalidShortHandFieldUsageInDefaultParam() {
        String packagePath = "79_invalid_short_hand_field_usage_in_default_param";
        DiagnosticResult diagnosticResult = getDiagnosticResult(packagePath);
        Assert.assertEquals(diagnosticResult.warningCount(), 1);
        Iterator<Diagnostic> diagnosticIterator = diagnosticResult.warnings().iterator();

        Diagnostic diagnostic = diagnosticIterator.next();
        String message = getErrorMessage(CompilationDiagnostic.UNABLE_TO_INFER_DEFAULT_VALUE_PROVIDE_KEY_VALUE_PAIR,
                                         "parameter", "obj");
        assertWarningMessage(diagnostic, message, 26, 45);
    }

    @Test(groups = "invalid")
    public void testInvalidSpreadFieldUsageInDefaultParam() {
        String packagePath = "80_invalid_spread_field_usage_in_default_param";
        DiagnosticResult diagnosticResult = getDiagnosticResult(packagePath);
        Assert.assertEquals(diagnosticResult.warningCount(), 1);
        Iterator<Diagnostic> diagnosticIterator = diagnosticResult.warnings().iterator();

        Diagnostic diagnostic = diagnosticIterator.next();
        String message = getErrorMessage(CompilationDiagnostic.UNABLE_TO_INFER_DEFAULT_VALUE_PROVIDE_KEY_VALUE_PAIR,
                                         "parameter", "obj");
        assertWarningMessage(diagnostic, message, 26, 45);
    }

    @Test(groups = "invalid")
    public void testInvalidSpreadMemberUsageInDefaultParam() {
        String packagePath = "81_invalid_spread_member_usage_in_default_param";
        DiagnosticResult diagnosticResult = getDiagnosticResult(packagePath);
        Assert.assertEquals(diagnosticResult.warningCount(), 1);
        Iterator<Diagnostic> diagnosticIterator = diagnosticResult.warnings().iterator();

        Diagnostic diagnostic = diagnosticIterator.next();
        String message = getErrorMessage(
                CompilationDiagnostic.UNABLE_TO_INFER_DEFAULT_VALUE_AVOID_USING_SPREAD_OPERATION, "parameter", "arr");
        assertWarningMessage(diagnostic, message, 22, 45);
    }

    @Test(groups = "invalid")
    public void testInvalidComplexExpressionUsageDefaultParam() {
        String packagePath = "82_invalid_complex_expression_usage_default_param";
        DiagnosticResult diagnosticResult = getDiagnosticResult(packagePath);
        Assert.assertEquals(diagnosticResult.warningCount(), 1);
        Iterator<Diagnostic> diagnosticIterator = diagnosticResult.warnings().iterator();

        Diagnostic diagnostic = diagnosticIterator.next();
        String message = getErrorMessage(
                CompilationDiagnostic.UNABLE_TO_INFER_DEFAULT_VALUE_AVOID_USING_SPREAD_OPERATION, "parameter",
                "profile");
        assertWarningMessage(diagnostic, message, 35, 61);
    }

    @Test(groups = "invalid")
    public void testInvalidDefaultExpressionInInputObjectField() {
        String packagePath = "83_invalid_default_expression_in_input_object_field";
        DiagnosticResult diagnosticResult = getDiagnosticResult(packagePath);
        Assert.assertEquals(diagnosticResult.warningCount(), 1);
        Iterator<Diagnostic> diagnosticIterator = diagnosticResult.warnings().iterator();

        Diagnostic diagnostic = diagnosticIterator.next();
        String message = getErrorMessage(
                CompilationDiagnostic.PROVIDE_LITERAL_OR_CONSTRUCTOR_EXPRESSION_FOR_DEFAULT_PARAM, "input object field",
                "val");
        assertWarningMessage(diagnostic, message, 22, 15);
    }

    @Test(groups = "invalid")
    public void testInvalidExternalRecordsWithDefaultValuesAsInputObject() {
        String packagePath = "84_invalid_external_records_with_default_values_as_input_object";
        DiagnosticResult diagnosticResult = getDiagnosticResult(packagePath);
        Assert.assertEquals(diagnosticResult.warningCount(), 2);
        Iterator<Diagnostic> diagnosticIterator = diagnosticResult.warnings().iterator();

        Diagnostic diagnostic = diagnosticIterator.next();
        String message = getErrorMessage(
                CompilationDiagnostic.UNABLE_TO_VALIDATE_DEFAULT_VALUES_OF_INPUT_FIELD_AT_COMPILE_TIME, "val3",
                "InputObject");
        assertWarningMessage(diagnostic, message, 28, 6);

        diagnostic = diagnosticIterator.next();
        message = getErrorMessage(
                CompilationDiagnostic.UNABLE_TO_VALIDATE_DEFAULT_VALUES_OF_INPUT_OBJECT_AT_COMPILE_TIME,
                "InputObject3");
        assertWarningMessage(diagnostic, message, 36, 45);
    }

    @Test(groups = "valid")
    public void testValidServerSideCacheConfigurations() {
        String packagePath = "85_valid_server_side_cache_configurations";
        DiagnosticResult diagnosticResult = getDiagnosticResult(packagePath);
        Assert.assertEquals(diagnosticResult.errorCount(), 0);
    }

    @Test(groups = "invalid")
    public void testInvalidServiceConfigModification() {
        String packagePath = "86_invalid_service_config_modification";
        DiagnosticResult diagnosticResult = getDiagnosticResult(packagePath);
        Assert.assertEquals(diagnosticResult.errorCount(), 4);
        Iterator<Diagnostic> diagnosticIterator = diagnosticResult.errors().iterator();

        Diagnostic diagnostic = diagnosticIterator.next();
        String message =
                getErrorMessage(CompilationDiagnostic.INVALID_MODIFICATION_OF_SERVICE_CONFIG_FIELD, "schemaString");
        assertErrorMessage(diagnostic, message, 20, 1);

        diagnostic = diagnosticIterator.next();
        message =
                getErrorMessage(CompilationDiagnostic.INVALID_MODIFICATION_OF_SERVICE_CONFIG_FIELD, "fieldCacheConfig");
        assertErrorMessage(diagnostic, message, 20, 1);

        diagnostic = diagnosticIterator.next();
        message =
                getErrorMessage(CompilationDiagnostic.INVALID_MODIFICATION_OF_SERVICE_CONFIG_FIELD, "schemaString");
        assertErrorMessage(diagnostic, message, 51, 44);

        diagnostic = diagnosticIterator.next();
        message =
                getErrorMessage(CompilationDiagnostic.INVALID_MODIFICATION_OF_SERVICE_CONFIG_FIELD, "fieldCacheConfig");
        assertErrorMessage(diagnostic, message, 51, 44);
    }

    @Test(groups = "valid")
    public void testAnnotationsWithCustomModulePrefix() {
        String packagePath = "87_annotations_with_custom_module_prefix";
        DiagnosticResult diagnosticResult = getDiagnosticResult(packagePath);
        Assert.assertEquals(diagnosticResult.errorCount(), 0);
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

    private void assertError(Diagnostic diagnostic, CompilationDiagnostic compilationDiagnostic, int line, int column) {
        Assert.assertEquals(diagnostic.diagnosticInfo().severity(), DiagnosticSeverity.ERROR);
        Assert.assertEquals(diagnostic.message(), compilationDiagnostic.getDiagnostic());
        assertErrorLocation(diagnostic.location(), line, column);
    }

    private void assertErrorMessage(Diagnostic diagnostic, String message, int line, int column) {
        Assert.assertEquals(diagnostic.diagnosticInfo().severity(), DiagnosticSeverity.ERROR);
        Assert.assertEquals(diagnostic.message(), message);
        assertErrorLocation(diagnostic.location(), line, column);
    }

    private void assertWarningMessage(Diagnostic diagnostic, String message, int line, int column) {
        Assert.assertEquals(diagnostic.diagnosticInfo().severity(), DiagnosticSeverity.WARNING);
        Assert.assertEquals(diagnostic.message(), message);
        assertErrorLocation(diagnostic.location(), line, column);
    }

    private String getErrorMessage(CompilationDiagnostic compilationDiagnostic, Object... args) {
        return MessageFormat.format(compilationDiagnostic.getDiagnostic(), args);
    }

    private void assertErrorLocation(Location location, int line, int column) {
        // Compiler counts lines and columns from zero
        Assert.assertEquals((location.lineRange().startLine().line() + 1), line);
        Assert.assertEquals((location.lineRange().startLine().offset() + 1), column);
    }
}
