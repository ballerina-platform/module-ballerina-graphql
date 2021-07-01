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
import io.ballerina.stdlib.graphql.compiler.PluginConstants.CompilationErrors;
import io.ballerina.tools.diagnostics.Diagnostic;
import io.ballerina.tools.diagnostics.Location;
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
        assertDiagnostic(diagnostic, CompilationErrors.INVALID_MULTIPLE_LISTENERS);
        assertLocation(19, diagnostic.location());
    }

    @Test
    public void testRemoteFunctionsReturningNull() {
        Package currentPackage = loadPackage("invalid_service_2");
        PackageCompilation compilation = currentPackage.getCompilation();
        DiagnosticResult diagnosticResult = compilation.diagnosticResult();
        Assert.assertEquals(diagnosticResult.errorCount(), 1);
        Diagnostic diagnostic = diagnosticResult.errors().iterator().next();
        assertDiagnostic(diagnostic, CompilationErrors.INVALID_RETURN_TYPE_NIL);
        assertLocation(20, diagnostic.location());
    }

    @Test
    public void testInvalidResourceAccessor() {
        Package currentPackage = loadPackage("invalid_service_3");
        PackageCompilation compilation = currentPackage.getCompilation();
        DiagnosticResult diagnosticResult = compilation.diagnosticResult();
        Assert.assertEquals(diagnosticResult.errorCount(), 1);
        Diagnostic diagnostic = diagnosticResult.errors().iterator().next();
        assertDiagnostic(diagnostic, CompilationErrors.INVALID_RESOURCE_FUNCTION_ACCESSOR);
        assertLocation(20, diagnostic.location());
    }

    @Test
    public void testInvalidResourceReturnTypes() {
        Package currentPackage = loadPackage("invalid_service_4");
        PackageCompilation compilation = currentPackage.getCompilation();
        DiagnosticResult diagnosticResult = compilation.diagnosticResult();
        Assert.assertEquals(diagnosticResult.errorCount(), 8);
        Iterator<Diagnostic> diagnosticIterator = diagnosticResult.errors().iterator();
        Diagnostic diagnostic = diagnosticIterator.next();
        assertDiagnostic(diagnostic, CompilationErrors.INVALID_RETURN_TYPE);
        assertLocation(28, diagnostic.location());

        diagnostic = diagnosticIterator.next();
        assertDiagnostic(diagnostic, CompilationErrors.INVALID_RETURN_TYPE);
        assertLocation(34, diagnostic.location());

        diagnostic = diagnosticIterator.next();
        assertDiagnostic(diagnostic, CompilationErrors.INVALID_RETURN_TYPE);
        assertLocation(41, diagnostic.location());

        diagnostic = diagnosticIterator.next();
        assertDiagnostic(diagnostic, CompilationErrors.INVALID_RETURN_TYPE);
        assertLocation(48, diagnostic.location());

        diagnostic = diagnosticIterator.next();
        assertDiagnostic(diagnostic, CompilationErrors.INVALID_RETURN_TYPE);
        assertLocation(55, diagnostic.location());

        diagnostic = diagnosticIterator.next();
        assertDiagnostic(diagnostic, CompilationErrors.INVALID_RETURN_TYPE);
        assertLocation(61, diagnostic.location());

        diagnostic = diagnosticIterator.next();
        assertDiagnostic(diagnostic, CompilationErrors.INVALID_RETURN_TYPE);
        assertLocation(67, diagnostic.location());

        diagnostic = diagnosticIterator.next();
        assertDiagnostic(diagnostic, CompilationErrors.INVALID_RETURN_TYPE);
        assertLocation(74, diagnostic.location());
    }

    @Test
    public void testInvalidResourceInputParameterTypes() {
        Package currentPackage = loadPackage("invalid_service_5");
        PackageCompilation compilation = currentPackage.getCompilation();
        DiagnosticResult diagnosticResult = compilation.diagnosticResult();
        Assert.assertEquals(diagnosticResult.errorCount(), 4);
        Iterator<Diagnostic> diagnosticIterator = diagnosticResult.errors().iterator();

        Diagnostic diagnostic = diagnosticIterator.next();
        assertDiagnostic(diagnostic, CompilationErrors.INVALID_INPUT_PARAM);
        assertLocation(20, diagnostic.location());

        diagnostic = diagnosticIterator.next();
        assertDiagnostic(diagnostic, CompilationErrors.INVALID_INPUT_PARAM);
        assertLocation(26, diagnostic.location());

        diagnostic = diagnosticIterator.next();
        assertDiagnostic(diagnostic, CompilationErrors.INVALID_INPUT_PARAM);
        assertLocation(32, diagnostic.location());

        diagnostic = diagnosticIterator.next();
        assertDiagnostic(diagnostic, CompilationErrors.INVALID_INPUT_PARAM);
        assertLocation(43, diagnostic.location());
    }

    @Test
    public void testInvalidMaxQueryDepthValue() {
        Package currentPackage = loadPackage("invalid_service_6");
        PackageCompilation compilation = currentPackage.getCompilation();
        DiagnosticResult diagnosticResult = compilation.diagnosticResult();
        Assert.assertEquals(diagnosticResult.errorCount(), 2);
        Iterator<Diagnostic> diagnosticIterator = diagnosticResult.errors().iterator();

        Diagnostic diagnostic = diagnosticIterator.next();
        assertDiagnostic(diagnostic, CompilationErrors.INVALID_MAX_QUERY_DEPTH);
        assertLocation(20, diagnostic.location());

        diagnostic = diagnosticIterator.next();
        assertDiagnostic(diagnostic, CompilationErrors.INVALID_MAX_QUERY_DEPTH);
        assertLocation(29, diagnostic.location());
    }

    @Test
    public void testReturningOnlyErrorOrNil() {
        Package currentPackage = loadPackage("invalid_service_7");
        PackageCompilation compilation = currentPackage.getCompilation();
        DiagnosticResult diagnosticResult = compilation.diagnosticResult();
        Assert.assertEquals(diagnosticResult.errorCount(), 1);
        Diagnostic diagnostic = diagnosticResult.errors().iterator().next();
        assertDiagnostic(diagnostic, CompilationErrors.INVALID_RETURN_TYPE_ERROR_OR_NIL);
        assertLocation(20, diagnostic.location());
    }

    @Test
    public void testReturningOnlyNil() {
        Package currentPackage = loadPackage("invalid_service_8");
        PackageCompilation compilation = currentPackage.getCompilation();
        DiagnosticResult diagnosticResult = compilation.diagnosticResult();
        Assert.assertEquals(diagnosticResult.errorCount(), 1);
        Diagnostic diagnostic = diagnosticResult.errors().iterator().next();
        assertDiagnostic(diagnostic, CompilationErrors.INVALID_RETURN_TYPE_NIL);
        assertLocation(20, diagnostic.location());
    }

    @Test
    public void testReturningOnlyError() {
        Package currentPackage = loadPackage("invalid_service_9");
        PackageCompilation compilation = currentPackage.getCompilation();
        DiagnosticResult diagnosticResult = compilation.diagnosticResult();
        Assert.assertEquals(diagnosticResult.errorCount(), 1);
        Diagnostic diagnostic = diagnosticResult.errors().iterator().next();
        assertDiagnostic(diagnostic, CompilationErrors.INVALID_RETURN_TYPE_ERROR);
        assertLocation(20, diagnostic.location());
    }

    @Test
    public void testListenerInitParameters() {
        Package currentPackage = loadPackage("invalid_service_10");
        PackageCompilation compilation = currentPackage.getCompilation();
        DiagnosticResult diagnosticResult = compilation.diagnosticResult();
        Assert.assertEquals(diagnosticResult.errorCount(), 2);
        Iterator<Diagnostic> diagnosticIterator = diagnosticResult.errors().iterator();

        Diagnostic diagnostic = diagnosticIterator.next();
        assertDiagnostic(diagnostic, CompilationErrors.INVALID_LISTENER_INIT);
        assertLocation(26, diagnostic.location());

        diagnostic = diagnosticIterator.next();
        assertDiagnostic(diagnostic, CompilationErrors.INVALID_LISTENER_INIT);
        assertLocation(28, diagnostic.location());
    }

    @Test
    public void testInvalidInputParameterUnions() {
        Package currentPackage = loadPackage("invalid_service_11");
        PackageCompilation compilation = currentPackage.getCompilation();
        DiagnosticResult diagnosticResult = compilation.diagnosticResult();
        Assert.assertEquals(diagnosticResult.errorCount(), 4);
        Iterator<Diagnostic> diagnosticIterator = diagnosticResult.errors().iterator();

        Diagnostic diagnostic = diagnosticIterator.next();
        assertDiagnostic(diagnostic, CompilationErrors.INVALID_INPUT_PARAM);
        assertLocation(20, diagnostic.location());

        diagnostic = diagnosticIterator.next();
        assertDiagnostic(diagnostic, CompilationErrors.INVALID_INPUT_PARAM);
        assertLocation(26, diagnostic.location());

        diagnostic = diagnosticIterator.next();
        assertDiagnostic(diagnostic, CompilationErrors.INVALID_INPUT_PARAM);
        assertLocation(32, diagnostic.location());

        diagnostic = diagnosticIterator.next();
        assertDiagnostic(diagnostic, CompilationErrors.INVALID_INPUT_PARAM);
        assertLocation(38, diagnostic.location());
    }

    @Test
    public void testInvalidResourceReturnTypeUnions() {
        Package currentPackage = loadPackage("invalid_service_12");
        PackageCompilation compilation = currentPackage.getCompilation();
        DiagnosticResult diagnosticResult = compilation.diagnosticResult();
        Assert.assertEquals(diagnosticResult.errorCount(), 3);
        Iterator<Diagnostic> diagnosticIterator = diagnosticResult.errors().iterator();

        Diagnostic diagnostic = diagnosticIterator.next();
        assertDiagnostic(diagnostic, CompilationErrors.INVALID_RETURN_TYPE_MULTIPLE_SERVICES);
        assertLocation(20, diagnostic.location());

        diagnostic = diagnosticIterator.next();
        assertDiagnostic(diagnostic, CompilationErrors.INVALID_RETURN_TYPE_MULTIPLE_SERVICES);
        assertLocation(26, diagnostic.location());

        diagnostic = diagnosticIterator.next();
        assertDiagnostic(diagnostic, CompilationErrors.INVALID_RETURN_TYPE_MULTIPLE_SERVICES);
        assertLocation(32, diagnostic.location());
    }

    @Test
    public void testInvalidAccessorsInServicesReturningFromResources() {
        Package currentPackage = loadPackage("invalid_service_13");
        PackageCompilation compilation = currentPackage.getCompilation();
        DiagnosticResult diagnosticResult = compilation.diagnosticResult();
        Assert.assertEquals(diagnosticResult.errorCount(), 2);
        Iterator<Diagnostic> diagnosticIterator = diagnosticResult.errors().iterator();

        Diagnostic diagnostic = diagnosticIterator.next();
        assertDiagnostic(diagnostic, CompilationErrors.INVALID_RESOURCE_FUNCTION_ACCESSOR);
        assertLocation(46, diagnostic.location());

        diagnostic = diagnosticIterator.next();
        assertDiagnostic(diagnostic, CompilationErrors.INVALID_RESOURCE_FUNCTION_ACCESSOR);
        assertLocation(53, diagnostic.location());
    }

    @Test
    public void testInvalidReturnTypesInServicesReturningFromResources() {
        Package currentPackage = loadPackage("invalid_service_14");
        PackageCompilation compilation = currentPackage.getCompilation();
        DiagnosticResult diagnosticResult = compilation.diagnosticResult();
        Assert.assertEquals(diagnosticResult.errorCount(), 2);
        Iterator<Diagnostic> diagnosticIterator = diagnosticResult.errors().iterator();

        Diagnostic diagnostic = diagnosticIterator.next();
        assertDiagnostic(diagnostic, CompilationErrors.INVALID_RETURN_TYPE);
        assertLocation(46, diagnostic.location());

        diagnostic = diagnosticIterator.next();
        assertDiagnostic(diagnostic, CompilationErrors.INVALID_RETURN_TYPE);
        assertLocation(54, diagnostic.location());
    }

    @Test
    public void testInvalidInputParametersInServicesReturningFromResources() {
        Package currentPackage = loadPackage("invalid_service_15");
        PackageCompilation compilation = currentPackage.getCompilation();
        DiagnosticResult diagnosticResult = compilation.diagnosticResult();
        Assert.assertEquals(diagnosticResult.errorCount(), 2);
        Iterator<Diagnostic> diagnosticIterator = diagnosticResult.errors().iterator();

        Diagnostic diagnostic = diagnosticIterator.next();
        assertDiagnostic(diagnostic, CompilationErrors.INVALID_INPUT_PARAM);
        assertLocation(46, diagnostic.location());

        diagnostic = diagnosticIterator.next();
        assertDiagnostic(diagnostic, CompilationErrors.INVALID_INPUT_PARAM);
        assertLocation(53, diagnostic.location());
    }

    @Test
    public void testInvalidListenerInitParameters() {
        Package currentPackage = loadPackage("invalid_service_16");
        PackageCompilation compilation = currentPackage.getCompilation();
        DiagnosticResult diagnosticResult = compilation.diagnosticResult();
        Assert.assertEquals(diagnosticResult.errorCount(), 1);
        Diagnostic diagnostic = diagnosticResult.errors().iterator().next();
        assertDiagnostic(diagnostic, CompilationErrors.INVALID_LISTENER_INIT);
        assertLocation(22, diagnostic.location());
    }

    @Test
    public void testInvalidResourcePath() {
        Package currentPackage = loadPackage("invalid_service_17");
        PackageCompilation compilation = currentPackage.getCompilation();
        DiagnosticResult diagnosticResult = compilation.diagnosticResult();
        Assert.assertEquals(diagnosticResult.errorCount(), 7);
        Iterator<Diagnostic> diagnosticIterator = diagnosticResult.errors().iterator();

        Diagnostic diagnostic = diagnosticIterator.next();
        assertDiagnostic(diagnostic, CompilationErrors.INVALID_FIELD_NAME);
        assertLocation(42, diagnostic.location());

        diagnostic = diagnosticIterator.next();
        assertDiagnostic(diagnostic, CompilationErrors.INVALID_FIELD_NAME);
        assertLocation(26, diagnostic.location());

        diagnostic = diagnosticIterator.next();
        assertDiagnostic(diagnostic, CompilationErrors.INVALID_FIELD_NAME);
        assertLocation(21, diagnostic.location());

        diagnostic = diagnosticIterator.next();
        assertDiagnostic(diagnostic, CompilationErrors.INVALID_FIELD_NAME);
        assertLocation(61, diagnostic.location());

        diagnostic = diagnosticIterator.next();
        assertDiagnostic(diagnostic, CompilationErrors.INVALID_FIELD_NAME);
        assertLocation(65, diagnostic.location());

        diagnostic = diagnosticIterator.next();
        assertDiagnostic(diagnostic, CompilationErrors.INVALID_FIELD_NAME);
        assertLocation(69, diagnostic.location());

        diagnostic = diagnosticIterator.next();
        assertDiagnostic(diagnostic, CompilationErrors.INVALID_FIELD_NAME);
        assertLocation(36, diagnostic.location());
    }

    @Test
    public void testInvalidRemoteFunctionInsideReturningServiceObject() {
        Package currentPackage = loadPackage("invalid_service_18");
        PackageCompilation compilation = currentPackage.getCompilation();
        DiagnosticResult diagnosticResult = compilation.diagnosticResult();
        Assert.assertEquals(diagnosticResult.diagnosticCount(), 1);
        Diagnostic diagnostic = diagnosticResult.errors().iterator().next();
        assertDiagnostic(diagnostic, CompilationErrors.INVALID_FUNCTION);
        assertLocation(30, diagnostic.location());
    }

    @Test
    public void testInvalidRemoteFunctionNoInputParameters() {
        Package currentPackage = loadPackage("invalid_service_19");
        PackageCompilation compilation = currentPackage.getCompilation();
        DiagnosticResult diagnosticResult = compilation.diagnosticResult();
        Assert.assertEquals(diagnosticResult.diagnosticCount(), 1);
        Diagnostic diagnostic = diagnosticResult.errors().iterator().next();
        assertDiagnostic(diagnostic, CompilationErrors.INVALID_INPUT_PARAMETER_TYPE);
        assertLocation(24, diagnostic.location());
    }

    private Package loadPackage(String path) {
        Path projectDirPath = RESOURCE_DIRECTORY.resolve(path);
        BuildProject project = BuildProject.load(getEnvironmentBuilder(), projectDirPath);
        return project.currentPackage();
    }

    private void assertDiagnostic(Diagnostic diagnostic, CompilationErrors error) {
        Assert.assertEquals(diagnostic.diagnosticInfo().code(), error.getErrorCode());
        Assert.assertEquals(diagnostic.diagnosticInfo().messageFormat(),
                            error.getError());
    }

    private static ProjectEnvironmentBuilder getEnvironmentBuilder() {
        Environment environment = EnvironmentBuilder.getBuilder().setBallerinaHome(DISTRIBUTION_PATH).build();
        return ProjectEnvironmentBuilder.getBuilder(environment);
    }

    private static void assertLocation(int expectedLine, Location actual) {
        int correctedLineNumber = expectedLine - 1;
        Assert.assertEquals(actual.lineRange().startLine().line(), correctedLineNumber, "Line Number Mismatch");
    }
}
