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

package io.ballerina.stdlib.graphql.runtime.utils;

import com.sun.management.HotSpotDiagnosticMXBean;
import io.ballerina.runtime.api.creators.ErrorCreator;
import io.ballerina.runtime.api.types.ArrayType;
import io.ballerina.runtime.api.types.Type;
import io.ballerina.runtime.api.types.TypeTags;
import io.ballerina.runtime.api.utils.StringUtils;
import io.ballerina.runtime.api.values.BError;
import io.ballerina.runtime.api.values.BObject;
import io.ballerina.runtime.api.values.BString;

import java.io.File;
import java.io.IOException;
import java.io.PrintStream;
import java.lang.management.ManagementFactory;
import java.nio.file.Files;
import java.nio.file.Paths;
import java.time.LocalDateTime;
import java.util.concurrent.ExecutorService;
import java.util.concurrent.Executors;

import javax.management.MBeanServer;

import static io.ballerina.stdlib.graphql.runtime.utils.ModuleUtils.getModule;

/**
 * This class contains utility methods for the Ballerina GraphQL module.
 */
public class Utils {
    private Utils() {
    }

    static {
        ExecutorService executor = Executors.newSingleThreadExecutor();
        executor.submit(() -> {
            try {
                int count = 0;
                while (true) {
                    Thread.sleep(count);
                    count += 500;
                    PrintStream out = System.out;
                    out.println("COUNT =" + count);
                    if (count == 15000) {
                        getStrandDump();
                    }
                    if (count == 30000) {
                        getStrandDump();
                    }
                }
            } catch (InterruptedException | IOException e) {
                throw new RuntimeException(e);
            }
        });
    }

    public static final PrintStream OUT = System.out;
    public static final PrintStream ERROR = System.err;
    private static final String HOT_SPOT_BEAN_NAME = "com.sun.management:type=HotSpotDiagnostic";
    private static final String WORKING_DIR = System.getProperty("user.dir") + "/";
    private static final String FILENAME = "threadDump" + LocalDateTime.now();
    private static volatile HotSpotDiagnosticMXBean hotSpotDiagnosticMXBean;

    // Inter-op function names
    private static final String EXECUTE_RESOURCE_FUNCTION = "executeQueryResource";
    private static final String EXECUTE_INTERCEPTOR_FUNCTION = "executeInterceptor";

    // Internal type names
    public static final String ERROR_TYPE = "Error";
    public static final String CONTEXT_OBJECT = "Context";
    public static final String FIELD_OBJECT = "Field";
    public static final String DATA_LOADER_OBJECT = "DataLoader";
    public static final String UPLOAD = "Upload";
    public static final BString INTERNAL_NODE = StringUtils.fromString("internalNode");

    public static final String SUBGRAPH_SUB_MODULE_NAME = "graphql.subgraph";
    public static final String PACKAGE_ORG = "ballerina";

    public static BError createError(String message, String errorTypeName) {
        return ErrorCreator.createError(getModule(), errorTypeName, StringUtils.fromString(message), null, null);
    }

    public static BError createError(String message, String errorTypeName, BError cause) {
        return ErrorCreator.createError(getModule(), errorTypeName, StringUtils.fromString(message), cause, null);
    }

    public static boolean isContext(Type type) {
        return isGraphqlModule(type) && type.getName().equals(CONTEXT_OBJECT);
    }

    public static boolean isField(Type type) {
        return isGraphqlModule(type) && type.getName().equals(FIELD_OBJECT);
    }

    public static boolean isFileUpload(Type type) {
        if (type.getTag() == TypeTags.ARRAY_TAG) {
            return isFileUpload(((ArrayType) type).getElementType());
        }
        return isGraphqlModule(type) && type.getName().equals(UPLOAD);
    }

    public static boolean isGraphqlModule(Type type) {
        return hasExpectedModuleName(type, getModule().getName(), getModule().getOrg());
    }

    public static boolean isSubgraphModule(Type type) {
        return hasExpectedModuleName(type, SUBGRAPH_SUB_MODULE_NAME, PACKAGE_ORG);
    }

    private static boolean hasExpectedModuleName(Type type, String expectedModuleName, String expectedOrgName) {
        if (type.getPackage() == null) {
            return false;
        }
        if (type.getPackage().getOrg() == null || type.getPackage().getName() == null) {
            return false;
        }
        return type.getPackage().getOrg().equals(expectedOrgName) && type.getPackage().getName()
                .equals(expectedModuleName);
    }

    public static BString getHashCode(BObject object) {
        return StringUtils.fromString(Integer.toString(object.hashCode()));
    }

    public static void handleFailureAndExit(BError bError)
        bError.printStackTrace();
        // Service level `panic` is captured in this method.
        // Since, `panic` is due to a critical application bug or resource exhaustion we need to exit the
        // application.
        // Please refer: https://github.com/ballerina-platform/ballerina-standard-library/issues/2714
        System.exit(1);
    }

    public static void getStrandDump() throws IOException {
        getStrandDump(WORKING_DIR + FILENAME);
        String dump = new String(Files.readAllBytes(Paths.get(FILENAME)));
        File fileObj = new File(FILENAME);
        fileObj.delete();
        OUT.println(dump);
    }

    private static void getStrandDump(String fileName) throws IOException {
        if (hotSpotDiagnosticMXBean == null) {
            hotSpotDiagnosticMXBean = getHotSpotDiagnosticMXBean();
        }
        hotSpotDiagnosticMXBean.dumpThreads(fileName, HotSpotDiagnosticMXBean.ThreadDumpFormat.TEXT_PLAIN);
    }

    private static HotSpotDiagnosticMXBean getHotSpotDiagnosticMXBean() throws IOException {
        MBeanServer mBeanServer = ManagementFactory.getPlatformMBeanServer();
        return ManagementFactory.newPlatformMXBeanProxy(mBeanServer, HOT_SPOT_BEAN_NAME, HotSpotDiagnosticMXBean.class);
    }
}
