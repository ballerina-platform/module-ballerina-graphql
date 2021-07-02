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
import io.ballerina.projects.PackageCompilation;
import io.ballerina.projects.ProjectEnvironmentBuilder;
import io.ballerina.projects.directory.BuildProject;
import io.ballerina.projects.environment.Environment;
import io.ballerina.projects.environment.EnvironmentBuilder;
import io.ballerina.stdlib.graphql.compiler.PluginConstants.CompilationError;
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
    private static final Path DISTRIBUTION_PATH = Paths.get("build", "target", "ballerina-distribution")
            .toAbsolutePath();

    @Test
    public void testValidResourceReturnTypes() {
        Package currentPackage = loadPackage("valid_service_1");
        PackageCompilation compilation = currentPackage.getCompilation();
        DiagnosticResult diagnosticResult = compilation.diagnosticResult();
        Assert.assertEquals(diagnosticResult.errorCount(), 0);
    }

    @Test
    public void testValidResourceInputTypes() {
        Package currentPackage = loadPackage("valid_service_2");
        PackageCompilation compilation = currentPackage.getCompilation();
        DiagnosticResult diagnosticResult = compilation.diagnosticResult();
        Assert.assertEquals(diagnosticResult.errorCount(), 0);
    }

    @Test
    public void testValidServiceConfigurationAnnotation() {
        Package currentPackage = loadPackage("valid_service_3");
        PackageCompilation compilation = currentPackage.getCompilation();
        DiagnosticResult diagnosticResult = compilation.diagnosticResult();
        Assert.assertEquals(diagnosticResult.errorCount(), 0);
    }

    @Test
    public void testResourceReturningEnum() {
        Package currentPackage = loadPackage("valid_service_4");
        PackageCompilation compilation = currentPackage.getCompilation();
        DiagnosticResult diagnosticResult = compilation.diagnosticResult();
        Assert.assertEquals(diagnosticResult.errorCount(), 0);
    }

    @Test
    public void testEnumAsResourceInputParameter() {
        Package currentPackage = loadPackage("valid_service_5");
        PackageCompilation compilation = currentPackage.getCompilation();
        DiagnosticResult diagnosticResult = compilation.diagnosticResult();
        Assert.assertEquals(diagnosticResult.errorCount(), 0);
    }

    @Test
    public void testValidListenerConfigurations() {
        Package currentPackage = loadPackage("valid_service_6");
        PackageCompilation compilation = currentPackage.getCompilation();
        DiagnosticResult diagnosticResult = compilation.diagnosticResult();
        Assert.assertEquals(diagnosticResult.errorCount(), 0);
    }

    @Test
    public void testOptionalInputParametersInResources() {
        Package currentPackage = loadPackage("valid_service_7");
        PackageCompilation compilation = currentPackage.getCompilation();
        DiagnosticResult diagnosticResult = compilation.diagnosticResult();
        Assert.assertEquals(diagnosticResult.errorCount(), 0);
    }

    @Test
    public void testReturningDistinctServiceObjects() {
        Package currentPackage = loadPackage("valid_service_8");
        PackageCompilation compilation = currentPackage.getCompilation();
        DiagnosticResult diagnosticResult = compilation.diagnosticResult();
        Assert.assertEquals(diagnosticResult.errorCount(), 0);
    }

    @Test
    public void testReturningServiceTypesRecursively() {
        Package currentPackage = loadPackage("valid_service_9");
        PackageCompilation compilation = currentPackage.getCompilation();
        DiagnosticResult diagnosticResult = compilation.diagnosticResult();
        Assert.assertEquals(diagnosticResult.errorCount(), 0);
    }

    @Test
    public void testFieldsInServiceObject() {
        Package currentPackage = loadPackage("valid_service_10");
        PackageCompilation compilation = currentPackage.getCompilation();
        DiagnosticResult diagnosticResult = compilation.diagnosticResult();
        Assert.assertEquals(diagnosticResult.errorCount(), 0);
    }

    @Test
    public void testMultipleListenersOnSameService() {
        Package currentPackage = loadPackage("invalid_service_1");
        PackageCompilation compilation = currentPackage.getCompilation();
        DiagnosticResult diagnosticResult = compilation.diagnosticResult();
        Assert.assertEquals(diagnosticResult.errorCount(), 1);
        Diagnostic diagnostic = diagnosticResult.errors().iterator().next();
        assertError(diagnostic, CompilationError.INVALID_MULTIPLE_LISTENERS, 19, 1);
    }

    @Test
    public void testServiceWithoutResourceFunctions() {
        Package currentPackage = loadPackage("invalid_service_2");
        PackageCompilation compilation = currentPackage.getCompilation();
        DiagnosticResult diagnosticResult = compilation.diagnosticResult();
        Assert.assertEquals(diagnosticResult.errorCount(), 1);
        Diagnostic diagnostic = diagnosticResult.errors().iterator().next();
        assertError(diagnostic, CompilationError.MISSING_RESOURCE_FUNCTIONS, 19, 1);
    }

    @Test
    public void testInvalidResourceAccessor() {
        Package currentPackage = loadPackage("invalid_service_3");
        PackageCompilation compilation = currentPackage.getCompilation();
        DiagnosticResult diagnosticResult = compilation.diagnosticResult();
        Assert.assertEquals(diagnosticResult.errorCount(), 1);
        Diagnostic diagnostic = diagnosticResult.errors().iterator().next();
        assertError(diagnostic, CompilationError.INVALID_RESOURCE_FUNCTION_ACCESSOR, 20, 23);
    }

    @Test
    public void testInvalidResourceReturnTypes() {
        Package currentPackage = loadPackage("invalid_service_4");
        PackageCompilation compilation = currentPackage.getCompilation();
        DiagnosticResult diagnosticResult = compilation.diagnosticResult();
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
        Package currentPackage = loadPackage("invalid_service_5");
        PackageCompilation compilation = currentPackage.getCompilation();
        DiagnosticResult diagnosticResult = compilation.diagnosticResult();
        Assert.assertEquals(diagnosticResult.errorCount(), 4);
        Iterator<Diagnostic> diagnosticIterator = diagnosticResult.errors().iterator();

        Diagnostic diagnostic = diagnosticIterator.next();
        assertError(diagnostic, CompilationError.INVALID_INPUT_PARAM, 20, 38);

        diagnostic = diagnosticIterator.next();
        assertError(diagnostic, CompilationError.INVALID_INPUT_PARAM, 26, 45);

        diagnostic = diagnosticIterator.next();
        assertError(diagnostic, CompilationError.INVALID_INPUT_PARAM, 32, 40);

        diagnostic = diagnosticIterator.next();
        assertError(diagnostic, CompilationError.INVALID_INPUT_PARAM, 43, 39);
    }

    @Test
    public void testInvalidMaxQueryDepthValue() {
        Package currentPackage = loadPackage("invalid_service_6");
        PackageCompilation compilation = currentPackage.getCompilation();
        DiagnosticResult diagnosticResult = compilation.diagnosticResult();
        Assert.assertEquals(diagnosticResult.errorCount(), 2);
        Iterator<Diagnostic> diagnosticIterator = diagnosticResult.errors().iterator();

        Diagnostic diagnostic = diagnosticIterator.next();
        assertError(diagnostic, CompilationError.INVALID_MAX_QUERY_DEPTH, 20, 20);

        diagnostic = diagnosticIterator.next();
        assertError(diagnostic, CompilationError.INVALID_MAX_QUERY_DEPTH, 29, 5);
    }

    @Test
    public void testReturningOnlyErrorOrNil() {
        Package currentPackage = loadPackage("invalid_service_7");
        PackageCompilation compilation = currentPackage.getCompilation();
        DiagnosticResult diagnosticResult = compilation.diagnosticResult();
        Assert.assertEquals(diagnosticResult.errorCount(), 1);
        Diagnostic diagnostic = diagnosticResult.errors().iterator().next();
        assertError(diagnostic, CompilationError.INVALID_RETURN_TYPE_ERROR_OR_NIL, 20, 5);
    }

    @Test
    public void testReturningOnlyNil() {
        Package currentPackage = loadPackage("invalid_service_8");
        PackageCompilation compilation = currentPackage.getCompilation();
        DiagnosticResult diagnosticResult = compilation.diagnosticResult();
        Assert.assertEquals(diagnosticResult.errorCount(), 1);
        Diagnostic diagnostic = diagnosticResult.errors().iterator().next();
        assertError(diagnostic, CompilationError.INVALID_RETURN_TYPE_NIL, 20, 5);
    }

    @Test
    public void testReturningOnlyError() {
        Package currentPackage = loadPackage("invalid_service_9");
        PackageCompilation compilation = currentPackage.getCompilation();
        DiagnosticResult diagnosticResult = compilation.diagnosticResult();
        Assert.assertEquals(diagnosticResult.errorCount(), 1);
        Diagnostic diagnostic = diagnosticResult.errors().iterator().next();
        assertError(diagnostic, CompilationError.INVALID_RETURN_TYPE_ERROR, 20, 5);
    }

    @Test
    public void testListenerInitParameters() {
        Package currentPackage = loadPackage("invalid_service_10");
        PackageCompilation compilation = currentPackage.getCompilation();
        DiagnosticResult diagnosticResult = compilation.diagnosticResult();
        Assert.assertEquals(diagnosticResult.errorCount(), 2);
        Iterator<Diagnostic> diagnosticIterator = diagnosticResult.errors().iterator();

        Diagnostic diagnostic = diagnosticIterator.next();
        assertError(diagnostic, CompilationError.INVALID_LISTENER_INIT, 26, 57);

        diagnostic = diagnosticIterator.next();
        assertError(diagnostic, CompilationError.INVALID_LISTENER_INIT, 28, 63);
    }

    @Test
    public void testInvalidInputParameterUnions() {
        Package currentPackage = loadPackage("invalid_service_11");
        PackageCompilation compilation = currentPackage.getCompilation();
        DiagnosticResult diagnosticResult = compilation.diagnosticResult();
        Assert.assertEquals(diagnosticResult.errorCount(), 4);
        Iterator<Diagnostic> diagnosticIterator = diagnosticResult.errors().iterator();

        Diagnostic diagnostic = diagnosticIterator.next();
        assertError(diagnostic, CompilationError.INVALID_INPUT_PARAM, 20, 48);

        diagnostic = diagnosticIterator.next();
        assertError(diagnostic, CompilationError.INVALID_INPUT_PARAM, 26, 39);

        diagnostic = diagnosticIterator.next();
        assertError(diagnostic, CompilationError.INVALID_INPUT_PARAM, 32, 46);

        diagnostic = diagnosticIterator.next();
        assertError(diagnostic, CompilationError.INVALID_INPUT_PARAM, 38, 41);
    }

    @Test
    public void testInvalidResourceReturnTypeUnions() {
        Package currentPackage = loadPackage("invalid_service_12");
        PackageCompilation compilation = currentPackage.getCompilation();
        DiagnosticResult diagnosticResult = compilation.diagnosticResult();
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
        Package currentPackage = loadPackage("invalid_service_13");
        PackageCompilation compilation = currentPackage.getCompilation();
        DiagnosticResult diagnosticResult = compilation.diagnosticResult();
        Assert.assertEquals(diagnosticResult.errorCount(), 2);
        Iterator<Diagnostic> diagnosticIterator = diagnosticResult.errors().iterator();

        Diagnostic diagnostic = diagnosticIterator.next();
        assertError(diagnostic, CompilationError.INVALID_RESOURCE_FUNCTION_ACCESSOR, 46, 23);

        diagnostic = diagnosticIterator.next();
        assertError(diagnostic, CompilationError.INVALID_RESOURCE_FUNCTION_ACCESSOR, 53, 23);
    }

    @Test
    public void testInvalidReturnTypesInServicesReturningFromResources() {
        Package currentPackage = loadPackage("invalid_service_14");
        PackageCompilation compilation = currentPackage.getCompilation();
        DiagnosticResult diagnosticResult = compilation.diagnosticResult();
        Assert.assertEquals(diagnosticResult.errorCount(), 2);
        Iterator<Diagnostic> diagnosticIterator = diagnosticResult.errors().iterator();

        Diagnostic diagnostic = diagnosticIterator.next();
        assertError(diagnostic, CompilationError.INVALID_RETURN_TYPE, 46, 23);

        diagnostic = diagnosticIterator.next();
        assertError(diagnostic, CompilationError.INVALID_RETURN_TYPE, 54, 23);
    }

    @Test
    public void testInvalidInputParametersInServicesReturningFromResources() {
        Package currentPackage = loadPackage("invalid_service_15");
        PackageCompilation compilation = currentPackage.getCompilation();
        DiagnosticResult diagnosticResult = compilation.diagnosticResult();
        Assert.assertEquals(diagnosticResult.errorCount(), 2);
        Iterator<Diagnostic> diagnosticIterator = diagnosticResult.errors().iterator();

        Diagnostic diagnostic = diagnosticIterator.next();
        assertError(diagnostic, CompilationError.INVALID_INPUT_PARAM, 46, 48);

        diagnostic = diagnosticIterator.next();
        assertError(diagnostic, CompilationError.INVALID_INPUT_PARAM, 53, 46);
    }

    @Test
    public void testInvalidListenerInitParameters() {
        Package currentPackage = loadPackage("invalid_service_16");
        PackageCompilation compilation = currentPackage.getCompilation();
        DiagnosticResult diagnosticResult = compilation.diagnosticResult();
        Assert.assertEquals(diagnosticResult.errorCount(), 1);
        Diagnostic diagnostic = diagnosticResult.errors().iterator().next();
        assertError(diagnostic, CompilationError.INVALID_LISTENER_INIT, 22, 57);
    }

    @Test
    public void testInvalidResourcePath() {
        Package currentPackage = loadPackage("invalid_service_17");
        PackageCompilation compilation = currentPackage.getCompilation();
        DiagnosticResult diagnosticResult = compilation.diagnosticResult();
        Assert.assertEquals(diagnosticResult.errorCount(), 7);
        Iterator<Diagnostic> diagnosticIterator = diagnosticResult.errors().iterator();

        Diagnostic diagnostic = diagnosticIterator.next();
        assertError(diagnostic, CompilationError.INVALID_FIELD_NAME, 42, 23);

        diagnostic = diagnosticIterator.next();
        assertError(diagnostic, CompilationError.INVALID_FIELD_NAME, 26, 12);

        diagnostic = diagnosticIterator.next();
        assertError(diagnostic, CompilationError.INVALID_FIELD_NAME, 21, 9);

        diagnostic = diagnosticIterator.next();
        assertError(diagnostic, CompilationError.INVALID_FIELD_NAME, 61, 23);

        diagnostic = diagnosticIterator.next();
        assertError(diagnostic, CompilationError.INVALID_FIELD_NAME, 65, 23);

        diagnostic = diagnosticIterator.next();
        assertError(diagnostic, CompilationError.INVALID_FIELD_NAME, 69, 23);

        diagnostic = diagnosticIterator.next();
        assertError(diagnostic, CompilationError.INVALID_FIELD_NAME, 36, 23);
    }

    @Test
    public void testInvalidRemoteFunctionInsideReturningServiceObject() {
        Package currentPackage = loadPackage("invalid_service_18");
        PackageCompilation compilation = currentPackage.getCompilation();
        DiagnosticResult diagnosticResult = compilation.diagnosticResult();
        Assert.assertEquals(diagnosticResult.errorCount(), 1);
        Diagnostic diagnostic = diagnosticResult.errors().iterator().next();
        assertError(diagnostic, CompilationError.INVALID_FUNCTION, 30, 21);
    }

    @Test
    public void testInvalidRemoteFunctionNoInputParameters() {
        Package currentPackage = loadPackage("invalid_service_19");
        PackageCompilation compilation = currentPackage.getCompilation();
        DiagnosticResult diagnosticResult = compilation.diagnosticResult();
        Assert.assertEquals(diagnosticResult.errorCount(), 1);
        Diagnostic diagnostic = diagnosticResult.errors().iterator().next();
        assertError(diagnostic, CompilationError.MISSING_INPUT_PARAMETER, 24, 5);
    }

    @Test
    public void testRemoteFunctionWithoutReturnType() {
        Package currentPackage = loadPackage("invalid_service_20");
        PackageCompilation compilation = currentPackage.getCompilation();
        DiagnosticResult diagnosticResult = compilation.diagnosticResult();
        Assert.assertEquals(diagnosticResult.errorCount(), 1);
        Diagnostic diagnostic = diagnosticResult.errors().iterator().next();
        assertError(diagnostic, CompilationError.INVALID_RETURN_TYPE_NIL, 24, 5);
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
        Assert.assertEquals((diagnostic.location().lineRange().startLine().line() + 1), line);
        Assert.assertEquals((diagnostic.location().lineRange().startLine().offset() + 1), column);
    }
}
