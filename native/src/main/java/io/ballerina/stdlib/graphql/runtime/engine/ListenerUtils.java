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

package io.ballerina.stdlib.graphql.runtime.engine;

import io.ballerina.runtime.api.Environment;
import io.ballerina.runtime.api.utils.StringUtils;
import io.ballerina.runtime.api.values.BArray;
import io.ballerina.runtime.api.values.BError;
import io.ballerina.runtime.api.values.BObject;
import io.ballerina.runtime.api.values.BString;
import io.ballerina.runtime.observability.ObserveUtils;
import io.ballerina.runtime.observability.ObserverContext;
import io.ballerina.stdlib.graphql.runtime.observability.GraphqlObserverContext;

import java.io.IOException;
import java.io.InputStream;
import java.net.MalformedURLException;
import java.net.URISyntaxException;
import java.net.URL;
import java.nio.charset.StandardCharsets;
import java.util.Arrays;
import java.util.List;
import java.util.stream.Collectors;

import static io.ballerina.runtime.observability.ObservabilityConstants.KEY_OBSERVER_CONTEXT;
import static io.ballerina.runtime.observability.ObservabilityConstants.PROPERTY_ERROR_VALUE;
import static io.ballerina.stdlib.graphql.runtime.utils.Utils.ERROR_TYPE;
import static io.ballerina.stdlib.graphql.runtime.utils.Utils.createError;

/**
 * External utility methods used in Ballerina GraphQL listener.
 */
public final class ListenerUtils {
    private static final String HTTP_SERVICE = "graphql.http.service";
    private static final String WS_SERVICE = "graphql.websocket.service";
    private static final String GRAPHIQL_SERVICE = "graphql.graphiql.service";

    private static final String SAMPLE_URL = "http://localhost:9000/";
    public static final String GRAPHIQL_RESOURCE = "graphiql.html";
    private static final String REGEX_URL = "${url}";
    private static final String FORWARD_SLASH = "/";

    private ListenerUtils() {
    }

    public static void attachHttpServiceToGraphqlService(BObject graphqlService, BObject httpService) {
        graphqlService.addNativeData(HTTP_SERVICE, httpService);
    }

    public static void attachWebsocketServiceToGraphqlService(BObject graphqlService, BObject wsService) {
        graphqlService.addNativeData(WS_SERVICE, wsService);
    }

    public static void attachGraphiqlServiceToGraphqlService(BObject graphqlService, BObject httpService) {
        graphqlService.addNativeData(GRAPHIQL_SERVICE, httpService);
    }

    public static Object getHttpServiceFromGraphqlService(BObject graphqlService) {
        Object httpService = graphqlService.getNativeData(HTTP_SERVICE);
        if (httpService instanceof BObject) {
            return httpService;
        }
        return null;
    }

    public static Object getWebsocketServiceFromGraphqlService(BObject graphqlService) {
        Object wsService = graphqlService.getNativeData(WS_SERVICE);
        if (wsService instanceof BObject) {
            return wsService;
        }
        return null;
    }

    public static Object getGraphiqlServiceFromGraphqlService(BObject graphqlService) {
        Object graphiqlService = graphqlService.getNativeData(GRAPHIQL_SERVICE);
        if (graphiqlService instanceof BObject) {
            return graphiqlService;
        }
        return null;
    }

    public static Object validateGraphiqlPath(BString path) {
        String uri = SAMPLE_URL + path;
        try {
            new URL(uri).toURI();
            return null;
        } catch (URISyntaxException | MalformedURLException e) {
            return createError("Invalid path provided for GraphiQL client", ERROR_TYPE);
        }
    }

    public static BString getBasePath(Object serviceName) {
        if (serviceName instanceof BArray) {
            List<String> strings = Arrays.stream(((BArray) serviceName).getStringArray()).map(
                    ListenerUtils::unescapeValue).collect(Collectors.toList());
            String basePath = String.join(FORWARD_SLASH, strings);
            return sanitizeBasePath(basePath);
        } else {
            String path = ((BString) serviceName).getValue().trim();
            if (path.startsWith(FORWARD_SLASH)) {
                path = path.substring(1);
            }
            String[] pathSplits = path.split(FORWARD_SLASH);
            List<String> strings =
                    Arrays.stream(pathSplits).map(ListenerUtils::unescapeValue).collect(Collectors.toList());
            String basePath = String.join(FORWARD_SLASH, strings);
            return sanitizeBasePath(basePath);
        }
    }

    public static String unescapeValue(String segment) {
        if (!segment.contains("\\")) {
            return segment.trim();
        }
        return segment.replace("\\", "").trim();
    }

    public static BString sanitizeBasePath(String basePath) {
        basePath = basePath.replace("//", FORWARD_SLASH);
        return StringUtils.fromString(basePath.trim());
    }

    public static Object getHtmlContentFromResources(BString url, Object subscriptionUrl) {
        InputStream htmlAsStream = ClassLoader.getSystemResourceAsStream(GRAPHIQL_RESOURCE);
        try {
            byte[] bytes = htmlAsStream.readAllBytes();
            String htmlAsString = new String(bytes, StandardCharsets.UTF_8);
            StringBuilder graphiqlUrl = new StringBuilder("{ url: \"" + url.getValue() + "\"");
            if (subscriptionUrl != null) {
                graphiqlUrl.append(" , subscriptionUrl: \"")
                        .append(((BString) subscriptionUrl).getValue()).append("\"");
            }
            graphiqlUrl.append(" }");
            htmlAsString = htmlAsString.replace(REGEX_URL, graphiqlUrl.toString());
            return StringUtils.fromString(htmlAsString);
        } catch (IOException e) {
            return createError("Error occurred while loading the GraphiQL client", ERROR_TYPE);
        }
    }

    public static void createAndStartObserverContext(Environment environment, BObject context, BString serviceName,
                                             BString operationType, BString operationName, BString moduleName,
                                                     BString fileName, int startLine, int startColumn) {
        ObserverContext observerContext = new GraphqlObserverContext(operationName.getValue(), serviceName.getValue());
        observerContext.setManuallyClosed(true);
        Object parentContext = context.getNativeData(KEY_OBSERVER_CONTEXT);
        if (parentContext != null) {
            observerContext.setParent((ObserverContext) parentContext);
        } else {
            observerContext.setParent(ObserveUtils.getObserverContextOfCurrentFrame(environment));
        }
        context.addNativeData(KEY_OBSERVER_CONTEXT, observerContext);

        environment.setStrandLocal(KEY_OBSERVER_CONTEXT, observerContext);
        ObserveUtils.startResourceObservation(environment, moduleName, fileName, startLine, startColumn, serviceName,
                operationName, operationType, true, false);
    }

    public static void createObserverContext(Environment environment, BObject context, BString serviceName,
                                             BString operationType) {
        ObserverContext observerContext = new GraphqlObserverContext(operationType.getValue(), serviceName.getValue());
        observerContext.setManuallyClosed(true);
        Object parentContext = context.getNativeData(KEY_OBSERVER_CONTEXT);
        if (parentContext != null) {
            observerContext.setParent((ObserverContext) parentContext);
        } else {
            observerContext.setParent(ObserveUtils.getObserverContextOfCurrentFrame(environment));
        }
        context.addNativeData(KEY_OBSERVER_CONTEXT, observerContext);

        environment.setStrandLocal(KEY_OBSERVER_CONTEXT, observerContext);
    }

    public static void stopObserverContext(Environment environment, BObject context) {
        ObserverContext observerContext = (ObserverContext) context.getNativeData(KEY_OBSERVER_CONTEXT);
        if (observerContext != null && observerContext.isManuallyClosed()) {
            ObserverContext parentContext = observerContext.getParent();
            context.addNativeData(KEY_OBSERVER_CONTEXT, parentContext);
            ObserveUtils.stopObservationWithContext(observerContext);
            environment.setStrandLocal(KEY_OBSERVER_CONTEXT, parentContext);
        }
    }
  
    public static void stopObserverContextWithError(Environment environment, BObject context, BError error) {
        ObserverContext observerContext = (ObserverContext) context.getNativeData(KEY_OBSERVER_CONTEXT);
        if (observerContext != null && observerContext.isManuallyClosed()) {
            observerContext.addProperty(PROPERTY_ERROR_VALUE, error);
            ObserverContext parentContext = observerContext.getParent();
            context.addNativeData(KEY_OBSERVER_CONTEXT, parentContext);
            ObserveUtils.stopObservationWithContext(observerContext);
            environment.setStrandLocal(KEY_OBSERVER_CONTEXT, parentContext);
        }
    }
}
