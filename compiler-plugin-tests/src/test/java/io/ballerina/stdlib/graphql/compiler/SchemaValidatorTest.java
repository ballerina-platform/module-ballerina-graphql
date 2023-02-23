/*
 * Copyright (c) 2023, WSO2 LLC. (http://www.wso2.org) All Rights Reserved.
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

import io.ballerina.compiler.api.SemanticModel;
import io.ballerina.compiler.syntax.tree.ModulePartNode;
import io.ballerina.compiler.syntax.tree.NonTerminalNode;
import io.ballerina.compiler.syntax.tree.SyntaxTree;
import io.ballerina.projects.Document;
import io.ballerina.projects.DocumentId;
import io.ballerina.projects.Module;
import io.ballerina.projects.ModuleId;
import io.ballerina.projects.Package;
import io.ballerina.projects.Project;
import io.ballerina.projects.ProjectEnvironmentBuilder;
import io.ballerina.projects.directory.BuildProject;
import io.ballerina.projects.environment.Environment;
import io.ballerina.projects.environment.EnvironmentBuilder;
import io.ballerina.stdlib.graphql.commons.types.ObjectKind;
import io.ballerina.stdlib.graphql.commons.types.Schema;
import io.ballerina.stdlib.graphql.commons.types.TypeKind;
import io.ballerina.tools.text.LinePosition;
import io.ballerina.tools.text.LineRange;
import io.ballerina.tools.text.TextDocument;
import io.ballerina.tools.text.TextRange;
import org.eclipse.lsp4j.Position;
import org.eclipse.lsp4j.Range;
import org.testng.Assert;
import org.testng.annotations.Test;

import java.nio.file.Path;
import java.nio.file.Paths;

import static io.ballerina.stdlib.graphql.compiler.Utils.getSchemaObject;

/**
 * This class includes tests to validate the location and objectKind details of the GraphQL Schema.
 */
public class SchemaValidatorTest {
    private static final Path RESOURCE_DIRECTORY = Paths.get("src", "test", "resources",
            "ballerina_sources", "schema_validator_tests").toAbsolutePath();
    private static final Path DISTRIBUTION_PATH = Paths.get("../", "target", "ballerina-runtime")
            .toAbsolutePath();

    private Schema getSchema(String packagePath, LineRange position) {
        Path projectPath = RESOURCE_DIRECTORY.resolve(packagePath);
        BuildProject project = BuildProject.load(getEnvironmentBuilder(), projectPath);
        Package currentPackage = project.currentPackage();
        SemanticModel semanticModel = getDefaultModulesSemanticModel(currentPackage);
        SyntaxTree syntaxTree = getSyntaxTree(project);
        Range range = toRange(position);
        NonTerminalNode node = findSTNode(range, syntaxTree);
        return getSchemaObject(node, semanticModel, project);
    }

    private static ProjectEnvironmentBuilder getEnvironmentBuilder() {
        Environment environment = EnvironmentBuilder.getBuilder().setBallerinaHome(DISTRIBUTION_PATH).build();
        return ProjectEnvironmentBuilder.getBuilder(environment);
    }

    public static SemanticModel getDefaultModulesSemanticModel(Package currentPackage) {
        ModuleId defaultModuleId = currentPackage.getDefaultModule().moduleId();
        return currentPackage.getCompilation().getSemanticModel(defaultModuleId);
    }

    private static SyntaxTree getSyntaxTree(Project project) {
        Package packageName = project.currentPackage();
        Module currentModule = packageName.getDefaultModule();
        DocumentId docId = currentModule.documentIds().iterator().next();
        Document doc = currentModule.document(docId);
        return doc.syntaxTree();
    }

    public static Range toRange(LineRange lineRange) {
        return new Range(toPosition(lineRange.startLine()), toPosition(lineRange.endLine()));
    }

    public static Position toPosition(LinePosition linePosition) {
        return new Position(linePosition.line(), linePosition.offset());
    }

    public static NonTerminalNode findSTNode(Range range, SyntaxTree syntaxTree) {
        TextDocument textDocument = syntaxTree.textDocument();
        Position rangeStart = range.getStart();
        Position rangeEnd = range.getEnd();
        int start = textDocument.textPositionFrom(LinePosition.from(rangeStart.getLine(), rangeStart.getCharacter()));
        int end = textDocument.textPositionFrom(LinePosition.from(rangeEnd.getLine(), rangeEnd.getCharacter()));
        return ((ModulePartNode) syntaxTree.rootNode()).findNode(TextRange.from(start, end - start),
                true);
    }


    @Test
    public void testSchemaLocationDetailsAndObjectKind() {
        String packagePath = "01_graphql_service";
        LineRange position = LineRange.from(packagePath, LinePosition.from(3, 0),
                LinePosition.from(33, 1));
        Schema schema = getSchema(packagePath, position);
        String filePath = RESOURCE_DIRECTORY.resolve(packagePath).resolve("service.bal").toString();

        schema.getQueryType().getFields().stream().filter(field -> field.getName().equals("animals"))
                .findFirst().ifPresent(field -> {
                    Assert.assertEquals(field.getPosition().getFilePath(), filePath);
                    Assert.assertEquals(field.getPosition().getStartLine().getLine(), 14);
                    Assert.assertEquals(field.getPosition().getEndLine().getLine(), 14);
                });

        schema.getMutationType().getFields().stream().filter(field -> field.getName().equals("updateAnimal"))
                .findFirst().ifPresent(field -> {
                    Assert.assertEquals(field.getPosition().getFilePath(), filePath);
                    Assert.assertEquals(field.getPosition().getStartLine().getLine(), 22);
                    Assert.assertEquals(field.getPosition().getEndLine().getLine(), 22);
                });

        schema.getSubscriptionType().getFields().stream().filter(field -> field.getName().equals("names"))
                .findFirst().ifPresent(field -> {
                    Assert.assertEquals(field.getPosition().getFilePath(), filePath);
                    Assert.assertEquals(field.getPosition().getStartLine().getLine(), 26);
                    Assert.assertEquals(field.getPosition().getEndLine().getLine(), 26);
                });

        // Class
        Assert.assertEquals(schema.getType("Elephant").getObjectKind(), ObjectKind.CLASS);
        io.ballerina.stdlib.graphql.commons.types.Position classPos = schema.getType("Elephant").getPosition();
        Assert.assertEquals(classPos.getStartLine().getLine(), 43);
        Assert.assertEquals(classPos.getStartLine().getOffset(), 30);
        Assert.assertEquals(classPos.getEndLine().getOffset(), 38);

        //Record
        Assert.assertEquals(schema.getType("Lion").getObjectKind(), ObjectKind.RECORD);
        io.ballerina.stdlib.graphql.commons.types.Position recordPos = schema.getType("Lion").getPosition();
        Assert.assertEquals(recordPos.getStartLine().getLine(), 71);
        Assert.assertEquals(recordPos.getStartLine().getOffset(), 5);
        Assert.assertEquals(recordPos.getEndLine().getOffset(), 9);
        Assert.assertEquals(recordPos.getFilePath(), filePath);

        // Enum
        io.ballerina.stdlib.graphql.commons.types.Position enumPos = schema.getType("Weekday").getPosition();
        Assert.assertEquals(enumPos.getStartLine().getLine(), 76);
        Assert.assertEquals(enumPos.getStartLine().getOffset(), 5);
        Assert.assertEquals(enumPos.getEndLine().getOffset(), 12);

    }

    @Test
    public void testInputObjectLocationAndType() {
        String packagePath = "02_service_with_input_objects";
        LineRange position = LineRange.from(packagePath, LinePosition.from(14, 0),
                LinePosition.from(19, 1));
        Schema schema = getSchema(packagePath, position);

        // Input Object
        Assert.assertEquals(schema.getType("Person").getKind(), TypeKind.INPUT_OBJECT);
        Assert.assertEquals(schema.getType("Person").getPosition().getStartLine().getLine(), 2);
        Assert.assertEquals(schema.getType("Address").getKind(), TypeKind.INPUT_OBJECT);
        Assert.assertEquals(schema.getType("Address").getPosition().getStartLine().getLine(), 8);
    }

    @Test
    public void testSchemaForResourceWithCompilationError() {
        String packagePath = "03_service_resource_with_no_return";
        LineRange position = LineRange.from(packagePath, LinePosition.from(3, 0),
                LinePosition.from(7, 1));
        Schema schema = getSchema(packagePath, position);
        Assert.assertNotNull(schema);
    }
}
