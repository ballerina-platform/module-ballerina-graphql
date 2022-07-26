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

package io.ballerina.stdlib.graphql.compiler;

import io.ballerina.projects.DiagnosticResult;
import io.ballerina.projects.ProjectEnvironmentBuilder;
import io.ballerina.projects.directory.BuildProject;
import io.ballerina.projects.environment.Environment;
import io.ballerina.projects.environment.EnvironmentBuilder;
import org.testng.Assert;
import org.testng.annotations.Test;

import java.nio.file.Path;
import java.nio.file.Paths;

/**
 * This class includes tests for Ballerina Graphql compiler plugin schema generation.
 */
public class SchemaGenerationTest {

    private static final Path RESOURCE_DIRECTORY = Paths.get("src", "test", "resources", "ballerina_sources",
                                                             "generator_tests").toAbsolutePath();
    private static final Path DISTRIBUTION_PATH = Paths.get("../", "target", "ballerina-runtime")
            .toAbsolutePath();

    @Test
    public void testResolversReturningScalarTypes() {
        String packagePath = "01_scalar_types";
        DiagnosticResult diagnosticResult = getDiagnosticResult(packagePath);
        Assert.assertEquals(diagnosticResult.errorCount(), 0);
    }

    @Test
    public void testResolversReturningRecordTypes() {
        String packagePath = "02_record_types";
        DiagnosticResult diagnosticResult = getDiagnosticResult(packagePath);
        Assert.assertEquals(diagnosticResult.errorCount(), 0);
    }

    @Test
    public void testResolversReturningServiceTypes() {
        String packagePath = "03_service_types";
        DiagnosticResult diagnosticResult = getDiagnosticResult(packagePath);
        Assert.assertEquals(diagnosticResult.errorCount(), 0);
    }

    @Test
    public void testResolversReturningUnionTypes() {
        String packagePath = "04_union_types";
        DiagnosticResult diagnosticResult = getDiagnosticResult(packagePath);
        Assert.assertEquals(diagnosticResult.errorCount(), 0);
    }

    @Test
    public void testResolversReturningInterfaceTypes() {
        String packagePath = "05_interface_types";
        DiagnosticResult diagnosticResult = getDiagnosticResult(packagePath);
        Assert.assertEquals(diagnosticResult.errorCount(), 0);
    }

    @Test
    public void testResolversReturningIntersectionTypes() {
        String packagePath = "06_intersection_types";
        DiagnosticResult diagnosticResult = getDiagnosticResult(packagePath);
        Assert.assertEquals(diagnosticResult.errorCount(), 0);
    }

    @Test
    public void testResolversReturningEnumTypes() {
        String packagePath = "07_enum_types";
        DiagnosticResult diagnosticResult = getDiagnosticResult(packagePath);
        Assert.assertEquals(diagnosticResult.errorCount(), 0);
    }

    @Test
    public void testInputScalarTypes() {
        String packagePath = "08_input_scalar_types";
        DiagnosticResult diagnosticResult = getDiagnosticResult(packagePath);
        Assert.assertEquals(diagnosticResult.errorCount(), 0);
    }

    @Test
    public void testInputEnumTypes() {
        String packagePath = "09_input_enum_types";
        DiagnosticResult diagnosticResult = getDiagnosticResult(packagePath);
        Assert.assertEquals(diagnosticResult.errorCount(), 0);
    }

    @Test
    public void testInputRecordTypes() {
        String packagePath = "10_input_record_types";
        DiagnosticResult diagnosticResult = getDiagnosticResult(packagePath);
        Assert.assertEquals(diagnosticResult.errorCount(), 0);
    }

    @Test
    public void testRecursiveRecordTypes() {
        String packagePath = "11_recursive_record_types";
        DiagnosticResult diagnosticResult = getDiagnosticResult(packagePath);
        Assert.assertEquals(diagnosticResult.errorCount(), 0);
    }

    @Test
    public void testRecursiveServiceTypes() {
        String packagePath = "12_recursive_service_types";
        DiagnosticResult diagnosticResult = getDiagnosticResult(packagePath);
        Assert.assertEquals(diagnosticResult.errorCount(), 0);
    }

    @Test
    public void testHierarchicalResourcePaths() {
        String packagePath = "13_hierarchical_resource_paths";
        DiagnosticResult diagnosticResult = getDiagnosticResult(packagePath);
        Assert.assertEquals(diagnosticResult.errorCount(), 0);
    }

    @Test
    public void testInputScalarTypesWithDefaultValues() {
        String packagePath = "14_input_scalar_types_with_default_values";
        DiagnosticResult diagnosticResult = getDiagnosticResult(packagePath);
        Assert.assertEquals(diagnosticResult.errorCount(), 0);
    }

    @Test
    public void testInputEnumTypesWithDefaultValues() {
        String packagePath = "15_input_enum_types_with_default_values";
        DiagnosticResult diagnosticResult = getDiagnosticResult(packagePath);
        Assert.assertEquals(diagnosticResult.errorCount(), 0);
    }

    @Test
    public void testInputRecordTypesWithDefaultValues() {
        String packagePath = "16_input_record_types_with_default_values";
        DiagnosticResult diagnosticResult = getDiagnosticResult(packagePath);
        Assert.assertEquals(diagnosticResult.errorCount(), 0);
    }

    @Test
    public void testNonSchemaInputs() {
        String packagePath = "17_special_input_types";
        DiagnosticResult diagnosticResult = getDiagnosticResult(packagePath);
        Assert.assertEquals(diagnosticResult.errorCount(), 0);
    }

    @Test
    public void testMutationOperation() {
        String packagePath = "18_mutation_operation";
        DiagnosticResult diagnosticResult = getDiagnosticResult(packagePath);
        Assert.assertEquals(diagnosticResult.errorCount(), 0);
    }

    @Test
    public void testResolversReturningTableTypes() {
        String packagePath = "19_table_types";
        DiagnosticResult diagnosticResult = getDiagnosticResult(packagePath);
        Assert.assertEquals(diagnosticResult.errorCount(), 0);
    }

    @Test
    public void testRecordFieldsWithMapType() {
        String packagePath = "20_map_types";
        DiagnosticResult diagnosticResult = getDiagnosticResult(packagePath);
        Assert.assertEquals(diagnosticResult.errorCount(), 0);
    }

    @Test
    public void testSchemaGenerationWithContextInit() {
        String packagePath = "21_context_init";
        DiagnosticResult diagnosticResult = getDiagnosticResult(packagePath);
        Assert.assertEquals(diagnosticResult.errorCount(), 0);
    }

    @Test
    public void testGraphqlServiceWithHttpService() {
        String packagePath = "22_graphql_service_with_http_service";
        DiagnosticResult diagnosticResult = getDiagnosticResult(packagePath);
        Assert.assertEquals(diagnosticResult.errorCount(), 0);
    }

    private DiagnosticResult getDiagnosticResult(String path) {
        Path projectDirPath = RESOURCE_DIRECTORY.resolve(path);
        BuildProject project = BuildProject.load(getEnvironmentBuilder(), projectDirPath);
        return project.currentPackage().runCodeGenAndModifyPlugins();
    }

    private static ProjectEnvironmentBuilder getEnvironmentBuilder() {
        Environment environment = EnvironmentBuilder.getBuilder().setBallerinaHome(DISTRIBUTION_PATH).build();
        return ProjectEnvironmentBuilder.getBuilder(environment);
    }
}
