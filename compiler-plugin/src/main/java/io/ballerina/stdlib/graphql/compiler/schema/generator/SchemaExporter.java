/*
 * Copyright (c) 2026, WSO2 LLC. (http://www.wso2.com).
 *
 * WSO2 LLC. licenses this file to you under the Apache License,
 * Version 2.0 (the "License"); you may not use this file except
 * in compliance with the License.
 * You may obtain a copy of the License at
 *
 *    http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing,
 * software distributed under the License is distributed on an
 * "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
 * KIND, either express or implied.  See the License for the
 * specific language governing permissions and limitations
 * under the License.
 */

package io.ballerina.stdlib.graphql.compiler.schema.generator;

import io.ballerina.projects.Package;
import io.ballerina.projects.Project;
import io.ballerina.projects.plugins.SyntaxNodeAnalysisContext;
import io.ballerina.stdlib.graphql.commons.types.Schema;
import io.ballerina.stdlib.graphql.commons.utils.SdlSchemaStringGenerator;
import io.ballerina.stdlib.graphql.compiler.endpointyaml.generator.FileNameGeneratorUtil;

import java.io.IOException;
import java.nio.file.Files;
import java.nio.file.Path;

import static io.ballerina.stdlib.graphql.compiler.endpointyaml.generator.FileNameGeneratorUtil.resolveContractFileName;

public class SchemaExporter {
    private final Schema schema;
    private static final String ARTIFACT_DIR = "artifact";
    private static final String SDL_EXTENSION = ".graphql";

    private final SyntaxNodeAnalysisContext context;
    private final FileNameGeneratorUtil fileNameGeneratorUtil;

    private String schemaFileName = "";

    public SchemaExporter(Schema schema, SyntaxNodeAnalysisContext context) {
        this.schema = schema;
        this.context = context;

        this.fileNameGeneratorUtil = new FileNameGeneratorUtil(this.context);
    }

    public Schema getSchema() {
        return this.schema;
    }

    public void exportSchema() throws IOException {
        Package currentPackage = this.context.currentPackage();
        Project project = currentPackage.project();
        Path outPath = project.targetDir();
        // Convert the custom Schema object to GraphQLSchema
        String sdlString = SdlSchemaStringGenerator.generate(this.schema);
        writeGqlSchema(outPath, sdlString);
    }

    private void writeGqlSchema(Path outPath, String sdlString) throws IOException {
        this.schemaFileName = this.fileNameGeneratorUtil.getFileName();
        if (this.schemaFileName.endsWith(SDL_EXTENSION)) {
            this.schemaFileName = this.schemaFileName.substring(0,
                    this.schemaFileName.length() - SDL_EXTENSION.length());
        }

        Path artifactDir = outPath.resolve(ARTIFACT_DIR);
        Files.createDirectories(artifactDir);
        String fileName = resolveContractFileName(outPath.resolve(ARTIFACT_DIR),
                this.schemaFileName, context);
        Path path = artifactDir.resolve(fileName + SDL_EXTENSION);
        Files.writeString(path, sdlString);

    }
}
