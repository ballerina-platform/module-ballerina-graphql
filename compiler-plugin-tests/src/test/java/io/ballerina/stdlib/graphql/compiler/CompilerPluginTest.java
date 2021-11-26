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
import io.ballerina.stdlib.graphql.compiler.validator.errors.CompilationError;
import io.ballerina.tools.diagnostics.Diagnostic;
import io.ballerina.tools.diagnostics.DiagnosticSeverity;
import org.testng.Assert;
import org.testng.annotations.Test;

import java.nio.file.Path;
import java.nio.file.Paths;
import java.util.ArrayList;
import java.util.Comparator;
import java.util.Iterator;
import java.util.List;

/**
 * This class includes tests for Ballerina Graphql compiler plugin.
 */
public class CompilerPluginTest {

    private static final Path RESOURCE_DIRECTORY = Paths.get("src", "test", "resources", "ballerina_sources")
            .toAbsolutePath();
    private static final Path DISTRIBUTION_PATH = Paths.get("../", "target", "ballerina-runtime")
            .toAbsolutePath();
    private final Comparator<Diagnostic> comparator = (left, right) -> right.location().lineRange().startLine().line()
                    - left.location().lineRange().startLine().line();

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
    public void testInputObjectTypeInputParameter() {
        Package currentPackage = loadPackage("valid_service_11");
        PackageCompilation compilation = currentPackage.getCompilation();
        DiagnosticResult diagnosticResult = compilation.diagnosticResult();
        Assert.assertEquals(diagnosticResult.errorCount(), 0);
    }

    @Test
    public void testValidInterfaceTypes1() {
        Package currentPackage = loadPackage("valid_service_12");
        PackageCompilation compilation = currentPackage.getCompilation();
        DiagnosticResult diagnosticResult = compilation.diagnosticResult();
        Assert.assertEquals(diagnosticResult.errorCount(), 0);
    }

    @Test
    public void testValidInterfaceTypes2() {
        Package currentPackage = loadPackage("valid_service_13");
        PackageCompilation compilation = currentPackage.getCompilation();
        DiagnosticResult diagnosticResult = compilation.diagnosticResult();
        Assert.assertEquals(diagnosticResult.errorCount(), 0);
    }

    @Test
    public void testValidMultipleInterfaceImplementations() {
        Package currentPackage = loadPackage("valid_service_14");
        PackageCompilation compilation = currentPackage.getCompilation();
        DiagnosticResult diagnosticResult = compilation.diagnosticResult();
        Assert.assertEquals(diagnosticResult.errorCount(), 0);
    }

    @Test
    public void testGraphQLContextAsFirstParameter() {
        Package currentPackage = loadPackage("valid_service_15");
        PackageCompilation compilation = currentPackage.getCompilation();
        DiagnosticResult diagnosticResult = compilation.diagnosticResult();
        Assert.assertEquals(diagnosticResult.errorCount(), 0);
    }

    @Test
    public void testGraphQLContextInsideReturningServices() {
        Package currentPackage = loadPackage("valid_service_16");
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
    public void testMissingResourceFunctionInService() {
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
        Package currentPackage = loadPackage("invalid_service_6");
        PackageCompilation compilation = currentPackage.getCompilation();
        DiagnosticResult diagnosticResult = compilation.diagnosticResult();
        Assert.assertEquals(diagnosticResult.errorCount(), 1);
        Diagnostic diagnostic = diagnosticResult.errors().iterator().next();
        assertError(diagnostic, CompilationError.INVALID_RETURN_TYPE_ERROR_OR_NIL, 20, 5);
    }

    @Test
    public void testReturningOnlyNil() {
        Package currentPackage = loadPackage("invalid_service_7");
        PackageCompilation compilation = currentPackage.getCompilation();
        DiagnosticResult diagnosticResult = compilation.diagnosticResult();
        Assert.assertEquals(diagnosticResult.errorCount(), 1);
        Diagnostic diagnostic = diagnosticResult.errors().iterator().next();
        assertError(diagnostic, CompilationError.INVALID_RETURN_TYPE_NIL, 20, 5);
    }

    @Test
    public void testReturningOnlyError() {
        Package currentPackage = loadPackage("invalid_service_8");
        PackageCompilation compilation = currentPackage.getCompilation();
        DiagnosticResult diagnosticResult = compilation.diagnosticResult();
        Assert.assertEquals(diagnosticResult.errorCount(), 1);
        Diagnostic diagnostic = diagnosticResult.errors().iterator().next();
        assertError(diagnostic, CompilationError.INVALID_RETURN_TYPE_ERROR, 20, 5);
    }

    @Test
    public void testListenerInitParameters() {
        Package currentPackage = loadPackage("invalid_service_9");
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
        Package currentPackage = loadPackage("invalid_service_10");
        PackageCompilation compilation = currentPackage.getCompilation();
        DiagnosticResult diagnosticResult = compilation.diagnosticResult();
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
        Package currentPackage = loadPackage("invalid_service_11");
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
        Package currentPackage = loadPackage("invalid_service_12");
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
        Package currentPackage = loadPackage("invalid_service_13");
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
        Package currentPackage = loadPackage("invalid_service_14");
        PackageCompilation compilation = currentPackage.getCompilation();
        DiagnosticResult diagnosticResult = compilation.diagnosticResult();
        Assert.assertEquals(diagnosticResult.errorCount(), 2);
        Iterator<Diagnostic> diagnosticIterator = diagnosticResult.errors().iterator();

        Diagnostic diagnostic = diagnosticIterator.next();
        assertError(diagnostic, CompilationError.INVALID_RESOURCE_INPUT_PARAM, 46, 48);

        diagnostic = diagnosticIterator.next();
        assertError(diagnostic, CompilationError.INVALID_RESOURCE_INPUT_PARAM, 53, 46);
    }

    @Test
    public void testInvalidListenerInitParameters() {
        Package currentPackage = loadPackage("invalid_service_15");
        PackageCompilation compilation = currentPackage.getCompilation();
        DiagnosticResult diagnosticResult = compilation.diagnosticResult();
        Assert.assertEquals(diagnosticResult.errorCount(), 1);
        Diagnostic diagnostic = diagnosticResult.errors().iterator().next();
        assertError(diagnostic, CompilationError.INVALID_LISTENER_INIT, 22, 57);
    }

    @Test
    public void testInvalidResourcePath() {
        Package currentPackage = loadPackage("invalid_service_16");
        PackageCompilation compilation = currentPackage.getCompilation();
        DiagnosticResult diagnosticResult = compilation.diagnosticResult();
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
        Package currentPackage = loadPackage("invalid_service_17");
        PackageCompilation compilation = currentPackage.getCompilation();
        DiagnosticResult diagnosticResult = compilation.diagnosticResult();
        Assert.assertEquals(diagnosticResult.errorCount(), 2);
        Iterator<Diagnostic> diagnosticIterator = diagnosticResult.errors().iterator();

        Diagnostic diagnostic = diagnosticIterator.next();
        assertError(diagnostic, CompilationError.INVALID_RETURN_TYPE_ANY, 20, 5);

        diagnostic = diagnosticIterator.next();
        assertError(diagnostic, CompilationError.INVALID_RETURN_TYPE_ANY, 24, 5);
    }

    @Test
    public void testServiceWithOnlyRemoteMethods() {
        Package currentPackage = loadPackage("invalid_service_18");
        PackageCompilation compilation = currentPackage.getCompilation();
        DiagnosticResult diagnosticResult = compilation.diagnosticResult();
        Assert.assertEquals(diagnosticResult.errorCount(), 1);
        Diagnostic diagnostic = diagnosticResult.errors().iterator().next();
        assertError(diagnostic, CompilationError.MISSING_RESOURCE_FUNCTIONS, 19, 1);
    }

    @Test
    public void testRemoteMethodWithInvalidReturnType() {
        Package currentPackage = loadPackage("invalid_service_19");
        PackageCompilation compilation = currentPackage.getCompilation();
        DiagnosticResult diagnosticResult = compilation.diagnosticResult();
        Assert.assertEquals(diagnosticResult.errorCount(), 1);
        Diagnostic diagnostic = diagnosticResult.errors().iterator().next();
        assertError(diagnostic, CompilationError.INVALID_RETURN_TYPE, 23, 5);
    }

    @Test
    public void testRemoteMethodInsideReturningServiceObject() {
        Package currentPackage = loadPackage("invalid_service_20");
        PackageCompilation compilation = currentPackage.getCompilation();
        DiagnosticResult diagnosticResult = compilation.diagnosticResult();
        Assert.assertEquals(diagnosticResult.errorCount(), 1);
        Diagnostic diagnostic = diagnosticResult.errors().iterator().next();
        assertError(diagnostic, CompilationError.INVALID_FUNCTION, 36, 21);
    }

    @Test
    public void testMissingResourceMethodFromReturningServiceClass() {
        Package currentPackage = loadPackage("invalid_service_21");
        PackageCompilation compilation = currentPackage.getCompilation();
        DiagnosticResult diagnosticResult = compilation.diagnosticResult();
        Assert.assertEquals(diagnosticResult.errorCount(), 1);
        Diagnostic diagnostic = diagnosticResult.errors().iterator().next();
        assertError(diagnostic, CompilationError.MISSING_RESOURCE_FUNCTIONS, 25, 15);
    }

    @Test
    public void testInvalidInputObjects() {
        Package currentPackage = loadPackage("invalid_service_22");
        PackageCompilation compilation = currentPackage.getCompilation();
        DiagnosticResult diagnosticResult = compilation.diagnosticResult();
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
    public void testInvalidInterfacesWithNoResourceFunction() {
        Package currentPackage = loadPackage("invalid_service_23");
        PackageCompilation compilation = currentPackage.getCompilation();
        DiagnosticResult diagnosticResult = compilation.diagnosticResult();
        Assert.assertEquals(diagnosticResult.errorCount(), 3);
        Iterator<Diagnostic> diagnosticIterator = diagnosticResult.errors().iterator();
        Diagnostic diagnostic = diagnosticIterator.next();
        assertError(diagnostic, CompilationError.MISSING_RESOURCE_FUNCTIONS, 21, 24);

        diagnostic = diagnosticIterator.next();
        assertError(diagnostic, CompilationError.MISSING_RESOURCE_FUNCTIONS, 29, 24);

        diagnostic = diagnosticIterator.next();
        assertError(diagnostic, CompilationError.MISSING_RESOURCE_FUNCTIONS, 37, 24);
    }

    @Test
    public void testInvalidInterfacesWithNoDistinctService1() {
        Package currentPackage = loadPackage("invalid_service_24");
        PackageCompilation compilation = currentPackage.getCompilation();
        DiagnosticResult diagnosticResult = compilation.diagnosticResult();
        Assert.assertEquals(diagnosticResult.errorCount(), 1);
        Diagnostic diagnostic = diagnosticResult.errors().iterator().next();
        assertError(diagnostic, CompilationError.NON_DISTINCT_INTERFACE_CLASS, 19, 15);
    }

    @Test
    public void testInvalidInterfaceImplementation() {
        Package currentPackage = loadPackage("invalid_service_25");
        PackageCompilation compilation = currentPackage.getCompilation();
        DiagnosticResult diagnosticResult = compilation.diagnosticResult();
        Assert.assertEquals(diagnosticResult.errorCount(), 2);
        List<Diagnostic> unorderedErrorList = new ArrayList<>(diagnosticResult.errors());
        unorderedErrorList.sort(comparator);
        Iterator<Diagnostic> diagnosticIterator = unorderedErrorList.iterator();
        Diagnostic diagnostic = diagnosticIterator.next();
        assertErrorFormat(diagnostic, CompilationError.INVALID_INTERFACE_IMPLEMENTATION, 56, 15);

        diagnostic = diagnosticIterator.next();
        assertErrorFormat(diagnostic, CompilationError.INVALID_INTERFACE_IMPLEMENTATION, 44, 15);
    }

    @Test
    public void testInvalidInterfaceImplementation2() {
        Package currentPackage = loadPackage("invalid_service_26");
        PackageCompilation compilation = currentPackage.getCompilation();
        DiagnosticResult diagnosticResult = compilation.diagnosticResult();
        Assert.assertEquals(diagnosticResult.errorCount(), 1);
        Diagnostic diagnostic = diagnosticResult.errors().iterator().next();
        assertErrorFormat(diagnostic, CompilationError.INVALID_INTERFACE_IMPLEMENTATION, 44, 15);
    }

    @Test
    public void testInvalidMultipleInterfaceImplementation() {
        Package currentPackage = loadPackage("invalid_service_27");
        PackageCompilation compilation = currentPackage.getCompilation();
        DiagnosticResult diagnosticResult = compilation.diagnosticResult();
        Assert.assertEquals(diagnosticResult.errorCount(), 2);
        List<Diagnostic> unorderedErrorList = new ArrayList<>(diagnosticResult.errors());
        unorderedErrorList.sort(comparator);
        Iterator<Diagnostic> diagnosticIterator = unorderedErrorList.iterator();
        Diagnostic diagnostic = diagnosticIterator.next();
        assertErrorFormat(diagnostic, CompilationError.INVALID_INTERFACE_IMPLEMENTATION, 72, 15);

        diagnostic = diagnosticIterator.next();
        assertErrorFormat(diagnostic, CompilationError.INVALID_INTERFACE_IMPLEMENTATION, 61, 15);
    }

    @Test
    public void testInvalidMultipleInterfaceImplementation2() {
        Package currentPackage = loadPackage("invalid_service_28");
        PackageCompilation compilation = currentPackage.getCompilation();
        DiagnosticResult diagnosticResult = compilation.diagnosticResult();
        Assert.assertEquals(diagnosticResult.errorCount(), 2);
        Diagnostic diagnostic = diagnosticResult.errors().iterator().next();
        assertErrorFormat(diagnostic, CompilationError.INVALID_INTERFACE_IMPLEMENTATION, 43, 15);
    }

    @Test
    public void testGraphQLContextAsAnotherParameter() {
        Package currentPackage = loadPackage("invalid_service_29");
        PackageCompilation compilation = currentPackage.getCompilation();
        DiagnosticResult diagnosticResult = compilation.diagnosticResult();
        Assert.assertEquals(diagnosticResult.errorCount(), 2);
        Iterator<Diagnostic> diagnosticIterator = diagnosticResult.errors().iterator();
        Diagnostic diagnostic = diagnosticIterator.next();
        assertError(diagnostic, CompilationError.INVALID_LOCATION_FOR_CONTEXT_PARAMETER, 20, 64);

        diagnostic = diagnosticIterator.next();
        assertError(diagnostic, CompilationError.INVALID_LOCATION_FOR_CONTEXT_PARAMETER, 24, 61);
    }

    @Test
    public void testInvalidContextObject() {
        Package currentPackage = loadPackage("invalid_service_30");
        PackageCompilation compilation = currentPackage.getCompilation();
        DiagnosticResult diagnosticResult = compilation.diagnosticResult();
        Assert.assertEquals(diagnosticResult.errorCount(), 2);
        Iterator<Diagnostic> diagnosticIterator = diagnosticResult.errors().iterator();
        Diagnostic diagnostic = diagnosticIterator.next();
        assertError(diagnostic, CompilationError.INVALID_RESOURCE_INPUT_PARAM, 21, 43);

        diagnostic = diagnosticIterator.next();
        assertError(diagnostic, CompilationError.INVALID_RESOURCE_INPUT_PARAM, 25, 40);
    }

    @Test
    public void testInvalidRecordFieldType() {
        Package currentPackage = loadPackage("invalid_service_31");
        PackageCompilation compilation = currentPackage.getCompilation();
        DiagnosticResult diagnosticResult = compilation.diagnosticResult();
        Assert.assertEquals(diagnosticResult.errorCount(), 1);
        Iterator<Diagnostic> diagnosticIterator = diagnosticResult.errors().iterator();
        Diagnostic diagnostic = diagnosticIterator.next();
        assertError(diagnostic, CompilationError.INVALID_RETURN_TYPE_ERROR_OR_NIL, 20, 12);
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

    private void assertErrorFormat(Diagnostic diagnostic, CompilationError compilationError, int line, int column) {
        Assert.assertEquals(diagnostic.diagnosticInfo().severity(), DiagnosticSeverity.ERROR);
        Assert.assertEquals(diagnostic.diagnosticInfo().messageFormat(), compilationError.getError());
        // Compiler counts lines and columns from zero
        Assert.assertEquals((diagnostic.location().lineRange().startLine().line() + 1), line);
        Assert.assertEquals((diagnostic.location().lineRange().startLine().offset() + 1), column);
    }
}
