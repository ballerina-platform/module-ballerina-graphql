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
import io.ballerina.projects.Package;
import io.ballerina.projects.ProjectEnvironmentBuilder;
import io.ballerina.projects.directory.BuildProject;
import io.ballerina.projects.environment.Environment;
import io.ballerina.projects.environment.EnvironmentBuilder;
import io.ballerina.stdlib.graphql.compiler.validator.errors.CompilationError;
import io.ballerina.tools.diagnostics.Diagnostic;
import io.ballerina.tools.diagnostics.DiagnosticSeverity;
import org.testng.Assert;
import org.testng.annotations.Test;

import java.nio.file.Path;
import java.nio.file.Paths;
import java.util.Iterator;

/**
 * This class includes tests for Ballerina Graphql compiler plugin.
 */
public class CompilerPluginTest {

    private static final Path RESOURCE_DIRECTORY = Paths.get("src", "test", "resources", "ballerina_sources")
            .toAbsolutePath();
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
    public void testGraphQLMultipleFileUpload() {
        String packagePath = "valid_service_16";
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
        Assert.assertEquals(diagnosticResult.errorCount(), 1);
        Diagnostic diagnostic = diagnosticResult.errors().iterator().next();
        assertError(diagnostic, CompilationError.INVALID_RESOURCE_FUNCTION_ACCESSOR, 20, 23);
    }

    @Test
    public void testInvalidResourceReturnTypes() {
        String packagePath = "invalid_service_4";
        DiagnosticResult diagnosticResult = getDiagnosticResult(packagePath);
        Assert.assertEquals(diagnosticResult.errorCount(), 8);
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
        assertError(diagnostic, CompilationError.INVALID_RETURN_TYPE, 55, 5);

        diagnostic = diagnosticIterator.next();
        assertError(diagnostic, CompilationError.INVALID_RETURN_TYPE, 61, 5);

        diagnostic = diagnosticIterator.next();
        assertError(diagnostic, CompilationError.INVALID_RETURN_TYPE, 67, 5);

        diagnostic = diagnosticIterator.next();
        assertError(diagnostic, CompilationError.INVALID_RETURN_TYPE, 74, 5);
    }

    @Test
    public void testInvalidResourceInputParameterTypes() {
        String packagePath = "invalid_service_5";
        DiagnosticResult diagnosticResult = getDiagnosticResult(packagePath);
        Assert.assertEquals(diagnosticResult.errorCount(), 7);
        Iterator<Diagnostic> diagnosticIterator = diagnosticResult.errors().iterator();

        Diagnostic diagnostic = diagnosticIterator.next();
        assertError(diagnostic, CompilationError.INVALID_RESOURCE_INPUT_PARAM, 20, 38);

        diagnostic = diagnosticIterator.next();
        assertError(diagnostic, CompilationError.INVALID_RESOURCE_INPUT_PARAM, 26, 45);

        diagnostic = diagnosticIterator.next();
        assertError(diagnostic, CompilationError.INVALID_RESOURCE_INPUT_PARAM, 32, 40);

        diagnostic = diagnosticIterator.next();
        assertError(diagnostic, CompilationError.INVALID_RESOURCE_INPUT_PARAM, 43, 39);

        diagnostic = diagnosticIterator.next();
        assertError(diagnostic, CompilationError.INVALID_RESOURCE_INPUT_PARAM, 49, 49);

        diagnostic = diagnosticIterator.next();
        assertError(diagnostic, CompilationError.INVALID_RESOURCE_INPUT_PARAM, 55, 37);

        diagnostic = diagnosticIterator.next();
        assertError(diagnostic, CompilationError.INVALID_RESOURCE_INPUT_PARAM, 61, 41);
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
        Assert.assertEquals(diagnosticResult.errorCount(), 2);
        Iterator<Diagnostic> diagnosticIterator = diagnosticResult.errors().iterator();

        Diagnostic diagnostic = diagnosticIterator.next();
        assertError(diagnostic, CompilationError.INVALID_LISTENER_INIT, 26, 57);

        diagnostic = diagnosticIterator.next();
        assertError(diagnostic, CompilationError.INVALID_LISTENER_INIT, 28, 63);
    }

    @Test
    public void testInvalidInputParameterUnions() {
        String packagePath = "invalid_service_10";
        DiagnosticResult diagnosticResult = getDiagnosticResult(packagePath);
        Assert.assertEquals(diagnosticResult.errorCount(), 4);
        Iterator<Diagnostic> diagnosticIterator = diagnosticResult.errors().iterator();

        Diagnostic diagnostic = diagnosticIterator.next();
        assertError(diagnostic, CompilationError.INVALID_RESOURCE_INPUT_PARAM, 20, 48);

        diagnostic = diagnosticIterator.next();
        assertError(diagnostic, CompilationError.INVALID_RESOURCE_INPUT_PARAM, 26, 39);

        diagnostic = diagnosticIterator.next();
        assertError(diagnostic, CompilationError.INVALID_RESOURCE_INPUT_PARAM, 32, 46);

        diagnostic = diagnosticIterator.next();
        assertError(diagnostic, CompilationError.INVALID_RESOURCE_INPUT_PARAM, 38, 41);
    }

    @Test
    public void testInvalidResourceReturnTypeUnions() {
        String packagePath = "invalid_service_11";
        DiagnosticResult diagnosticResult = getDiagnosticResult(packagePath);
        Assert.assertEquals(diagnosticResult.errorCount(), 3);
        Iterator<Diagnostic> diagnosticIterator = diagnosticResult.errors().iterator();

        Diagnostic diagnostic = diagnosticIterator.next();
        assertError(diagnostic, CompilationError.INVALID_RETURN_TYPE_MULTIPLE_SERVICES, 20, 5);

        diagnostic = diagnosticIterator.next();
        assertError(diagnostic, CompilationError.INVALID_RETURN_TYPE_MULTIPLE_SERVICES, 26, 5);

        diagnostic = diagnosticIterator.next();
        assertError(diagnostic, CompilationError.INVALID_RETURN_TYPE_MULTIPLE_SERVICES, 32, 5);
    }

    @Test
    public void testInvalidAccessorsInServicesReturningFromResources() {
        String packagePath = "invalid_service_12";
        DiagnosticResult diagnosticResult = getDiagnosticResult(packagePath);
        Assert.assertEquals(diagnosticResult.errorCount(), 2);
        Iterator<Diagnostic> diagnosticIterator = diagnosticResult.errors().iterator();

        Diagnostic diagnostic = diagnosticIterator.next();
        assertError(diagnostic, CompilationError.INVALID_RESOURCE_FUNCTION_ACCESSOR, 46, 23);

        diagnostic = diagnosticIterator.next();
        assertError(diagnostic, CompilationError.INVALID_RESOURCE_FUNCTION_ACCESSOR, 53, 23);
    }

    @Test
    public void testInvalidReturnTypesInServicesReturningFromResources() {
        String packagePath = "invalid_service_13";
        DiagnosticResult diagnosticResult = getDiagnosticResult(packagePath);
        Assert.assertEquals(diagnosticResult.errorCount(), 2);
        Iterator<Diagnostic> diagnosticIterator = diagnosticResult.errors().iterator();

        Diagnostic diagnostic = diagnosticIterator.next();
        assertError(diagnostic, CompilationError.INVALID_RETURN_TYPE, 46, 23);

        diagnostic = diagnosticIterator.next();
        assertError(diagnostic, CompilationError.INVALID_RETURN_TYPE, 54, 23);
    }

    @Test
    public void testInvalidInputParametersInServicesReturningFromResources() {
        String packagePath = "invalid_service_14";
        DiagnosticResult diagnosticResult = getDiagnosticResult(packagePath);
        Assert.assertEquals(diagnosticResult.errorCount(), 2);
        Iterator<Diagnostic> diagnosticIterator = diagnosticResult.errors().iterator();

        Diagnostic diagnostic = diagnosticIterator.next();
        assertError(diagnostic, CompilationError.INVALID_RESOURCE_INPUT_PARAM, 46, 48);

        diagnostic = diagnosticIterator.next();
        assertError(diagnostic, CompilationError.INVALID_RESOURCE_INPUT_PARAM, 53, 46);
    }

    @Test
    public void testInvalidListenerInitParameters() {
        String packagePath = "invalid_service_15";
        DiagnosticResult diagnosticResult = getDiagnosticResult(packagePath);
        Assert.assertEquals(diagnosticResult.errorCount(), 1);
        Diagnostic diagnostic = diagnosticResult.errors().iterator().next();
        assertError(diagnostic, CompilationError.INVALID_LISTENER_INIT, 22, 57);
    }

    @Test
    public void testInvalidResourcePath() {
        String packagePath = "invalid_service_16";
        DiagnosticResult diagnosticResult = getDiagnosticResult(packagePath);
        Assert.assertEquals(diagnosticResult.errorCount(), 7);
        Iterator<Diagnostic> diagnosticIterator = diagnosticResult.errors().iterator();

        Diagnostic diagnostic = diagnosticIterator.next();
        assertError(diagnostic, CompilationError.INVALID_FIELD_NAME, 42, 5);

        diagnostic = diagnosticIterator.next();
        assertError(diagnostic, CompilationError.INVALID_FIELD_NAME, 26, 12);

        diagnostic = diagnosticIterator.next();
        assertError(diagnostic, CompilationError.INVALID_FIELD_NAME, 21, 9);

        diagnostic = diagnosticIterator.next();
        assertError(diagnostic, CompilationError.INVALID_FIELD_NAME, 61, 5);

        diagnostic = diagnosticIterator.next();
        assertError(diagnostic, CompilationError.INVALID_FIELD_NAME, 65, 5);

        diagnostic = diagnosticIterator.next();
        assertError(diagnostic, CompilationError.INVALID_FIELD_NAME, 69, 5);

        diagnostic = diagnosticIterator.next();
        assertError(diagnostic, CompilationError.INVALID_FIELD_NAME, 36, 23);
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
        Assert.assertEquals(diagnosticResult.errorCount(), 9);
        Iterator<Diagnostic> diagnosticIterator = diagnosticResult.errors().iterator();
        Diagnostic diagnostic = diagnosticIterator.next();
        assertError(diagnostic, CompilationError.INVALID_RESOURCE_INPUT_OBJECT_PARAM, 35, 42);

        diagnostic = diagnosticIterator.next();
        assertError(diagnostic, CompilationError.INVALID_RESOURCE_INPUT_OBJECT_PARAM, 44, 37);

        diagnostic = diagnosticIterator.next();
        assertError(diagnostic, CompilationError.INVALID_RETURN_TYPE_INPUT_OBJECT, 57, 5);

        diagnostic = diagnosticIterator.next();
        assertError(diagnostic, CompilationError.INVALID_RESOURCE_INPUT_OBJECT_PARAM, 73, 50);

        diagnostic = diagnosticIterator.next();
        assertError(diagnostic, CompilationError.INVALID_RESOURCE_INPUT_OBJECT_PARAM, 79, 42);

        diagnostic = diagnosticIterator.next();
        assertError(diagnostic, CompilationError.INVALID_RESOURCE_INPUT_PARAM, 91, 43);

        diagnostic = diagnosticIterator.next();
        assertError(diagnostic, CompilationError.INVALID_RESOURCE_INPUT_PARAM, 106, 43);

        diagnostic = diagnosticIterator.next();
        assertError(diagnostic, CompilationError.INVALID_RESOURCE_INPUT_OBJECT_PARAM, 118, 39);

        diagnostic = diagnosticIterator.next();
        assertError(diagnostic, CompilationError.INVALID_RESOURCE_INPUT_PARAM, 130, 40);
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
        assertError(diagnostic, CompilationError.INVALID_RESOURCE_INPUT_PARAM, 21, 43);

        diagnostic = diagnosticIterator.next();
        assertError(diagnostic, CompilationError.INVALID_RESOURCE_INPUT_PARAM, 25, 40);
    }

    @Test
    public void testInvalidRecordFieldType() {
        String packagePath = "invalid_service_25";
        DiagnosticResult diagnosticResult = getDiagnosticResult(packagePath);
        Assert.assertEquals(diagnosticResult.errorCount(), 1);
        Iterator<Diagnostic> diagnosticIterator = diagnosticResult.errors().iterator();
        Diagnostic diagnostic = diagnosticIterator.next();
        assertError(diagnostic, CompilationError.INVALID_RETURN_TYPE_ERROR_OR_NIL, 20, 12);
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
        assertError(diagnostic, CompilationError.MISSING_RESOURCE_NAME, 28, 5);
    }

    @Test
    public void testGraphQLFileUploadInInvalidLocations() {
        String packagePath = "invalid_service_28";
        DiagnosticResult diagnosticResult = getDiagnosticResult(packagePath);
        Assert.assertEquals(diagnosticResult.errorCount(), 14);
        Iterator<Diagnostic> diagnosticIterator = diagnosticResult.errors().iterator();
        Diagnostic diagnostic = diagnosticIterator.next();
        assertError(diagnostic, CompilationError.INVALID_RETURN_TYPE_FILE_UPLOAD, 36, 5);

        diagnostic = diagnosticIterator.next();
        assertError(diagnostic, CompilationError.INVALID_RETURN_TYPE_FILE_UPLOAD, 43, 5);

        diagnostic = diagnosticIterator.next();
        assertError(diagnostic, CompilationError.INVALID_RETURN_TYPE_FILE_UPLOAD, 50, 5);

        diagnostic = diagnosticIterator.next();
        assertError(diagnostic, CompilationError.INVALID_LOCATION_FOR_FILE_UPLOAD_PARAMETER, 57, 62);

        diagnostic = diagnosticIterator.next();
        assertError(diagnostic, CompilationError.INVALID_LOCATION_FOR_FILE_UPLOAD_PARAMETER, 64, 72);

        diagnostic = diagnosticIterator.next();
        assertError(diagnostic, CompilationError.INVALID_RESOURCE_INPUT_PARAM, 71, 67);

        diagnostic = diagnosticIterator.next();
        assertError(diagnostic, CompilationError.INVALID_RETURN_TYPE_FILE_UPLOAD, 82, 5);

        diagnostic = diagnosticIterator.next();
        assertError(diagnostic, CompilationError.INVALID_RETURN_TYPE_FILE_UPLOAD, 93, 5);

        diagnostic = diagnosticIterator.next();
        assertError(diagnostic, CompilationError.INVALID_RETURN_TYPE_FILE_UPLOAD, 104, 5);

        diagnostic = diagnosticIterator.next();
        assertError(diagnostic, CompilationError.INVALID_LOCATION_FOR_FILE_UPLOAD_PARAMETER, 115, 60);

        diagnostic = diagnosticIterator.next();
        assertError(diagnostic, CompilationError.INVALID_INPUT_OBJECT_FIELD_TYPE, 122, 52);

        diagnostic = diagnosticIterator.next();
        assertError(diagnostic, CompilationError.INVALID_INPUT_OBJECT_FIELD_TYPE, 126, 33);

        diagnostic = diagnosticIterator.next();
        assertError(diagnostic, CompilationError.INVALID_RETURN_TYPE_FILE_UPLOAD, 31, 24);

        diagnostic = diagnosticIterator.next();
        assertError(diagnostic, CompilationError.INVALID_RETURN_TYPE_FILE_UPLOAD, 31, 24);
    }

    private DiagnosticResult getDiagnosticResult(String packagePath) {
        return loadPackage(packagePath).getCompilation().diagnosticResult();
    }

    private Package loadPackage(String path) {
        Path projectDirPath = RESOURCE_DIRECTORY.resolve(path);
        BuildProject project = BuildProject.load(getEnvironmentBuilder(), projectDirPath);
        return project.currentPackage();
    }

    private static ProjectEnvironmentBuilder getEnvironmentBuilder() {
        Environment environment = EnvironmentBuilder.getBuilder().setBallerinaHome(DISTRIBUTION_PATH).build();
        return ProjectEnvironmentBuilder.getBuilder(environment);
    }

    private void assertError(Diagnostic diagnostic, CompilationError compilationError, int line, int column) {
        Assert.assertEquals(diagnostic.diagnosticInfo().severity(), DiagnosticSeverity.ERROR);
        Assert.assertEquals(diagnostic.message(), compilationError.getError());
        // Compiler counts lines and columns from zero
        Assert.assertEquals((diagnostic.location().lineRange().startLine().line() + 1), line);
        Assert.assertEquals((diagnostic.location().lineRange().startLine().offset() + 1), column);
    }
}
