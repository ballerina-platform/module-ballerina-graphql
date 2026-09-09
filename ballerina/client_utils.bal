// Copyright (c) 2026 WSO2 LLC. (http://www.wso2.com) All Rights Reserved.
//
// WSO2 LLC. licenses this file to you under the Apache License,
// Version 2.0 (the "License"); you may not use this file except
// in compliance with the License.
// You may obtain a copy of the License at
//
// http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing,
// software distributed under the License is distributed on an
// "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
// KIND, either express or implied.  See the License for the
// specific language governing permissions and limitations
// under the License.

import graphql.parser;

import ballerina/http;

// Maps the GraphQL `ClientConfiguration` to the `http:ClientConfiguration` explicitly. When a new
// HTTP-related field is added to the `ClientConfiguration`, it must be mapped here as well.
isolated function toHttpClientConfig(ClientConfiguration config) returns http:ClientConfiguration {
    return {
        http1Settings: config.http1Settings,
        timeout: config.timeout,
        forwarded: config.forwarded,
        followRedirects: config.followRedirects,
        poolConfig: config.poolConfig,
        cache: config.cache,
        compression: config.compression,
        auth: config.auth,
        circuitBreaker: config.circuitBreaker,
        retryConfig: config.retryConfig,
        cookieConfig: config.cookieConfig,
        responseLimits: config.responseLimits,
        secureSocket: config.secureSocket,
        proxy: config.proxy,
        validation: config.validation
    };
}

isolated function validateOperationKind(string document, string? operationName,
        parser:RootOperationType expectedKind) returns InvalidDocumentError? {
    parser:Parser documentParser = new (document);
    parser:DocumentNode|parser:Error parseResult = documentParser.parse();
    if parseResult is parser:Error {
        ErrorDetail errorDetail = {message: parseResult.message(), locations: [parseResult.detail()]};
        return error InvalidDocumentError(INVALID_DOCUMENT_MESSAGE, parseResult, errors = [errorDetail]);
    }
    parser:OperationNode|ErrorDetail operation = selectOperation(parseResult, operationName);
    if operation is ErrorDetail {
        return error InvalidDocumentError(operation.message, errors = [operation]);
    }
    if operation.getKind() != expectedKind {
        string message = string `expected a ${expectedKind} operation, but found a ${operation.getKind()} operation`;
        return error InvalidDocumentError(message, errors = [{message, locations: [operation.getLocation()]}]);
    }
    return;
}

isolated function resolveWebSocketServiceUrl(string? subscriptionServiceUrl, string serviceUrl)
        returns string|ClientError {
    string url = subscriptionServiceUrl ?: serviceUrl;
    if url.startsWith(WS_SCHEME_PREFIX) || url.startsWith(WSS_SCHEME_PREFIX) {
        return url;
    }
    if url.startsWith(HTTP_SCHEME_PREFIX) {
        return string `${WS_SCHEME_PREFIX}${url.substring(HTTP_SCHEME_PREFIX.length())}`;
    }
    if url.startsWith(HTTPS_SCHEME_PREFIX) {
        return string `${WSS_SCHEME_PREFIX}${url.substring(HTTPS_SCHEME_PREFIX.length())}`;
    }
    if !url.includes(SCHEME_SEPARATOR) {
        return string `${WS_SCHEME_PREFIX}${url}`;
    }
    return error ClientError(string `Failed to derive the WebSocket URL for GraphQL subscriptions from the URL: ${url}`);
}

isolated function validateReconnectConfig(ReconnectConfig? config) returns ClientError? {
    if config is () {
        return;
    }
    if config.maxAttempts <= 0 {
        return error ClientError(string `${INVALID_RECONNECT_CONFIG_MESSAGE}: the maxAttempts must be greater than zero`);
    }
    if config.interval < 0d {
        return error ClientError(string `${INVALID_RECONNECT_CONFIG_MESSAGE}: the interval must not be negative`);
    }
    if config.backOffFactor <= 0.0 {
        return error ClientError(string `${INVALID_RECONNECT_CONFIG_MESSAGE}: the backOffFactor must be greater than zero`);
    }
    if config.maxInterval < config.interval {
        return error ClientError(string `${INVALID_RECONNECT_CONFIG_MESSAGE}: the maxInterval must not be less than the interval`);
    }
    return;
}

isolated function validateKeepAliveConfig(KeepAliveConfig config) returns ClientError? {
    if !config.enabled {
        return;
    }
    if config.pingInterval <= 0d {
        return error ClientError(
                string `${INVALID_KEEPALIVE_CONFIG_MESSAGE}: the pingInterval must be greater than zero`);
    }
    if config.pongTimeout <= 0d {
        return error ClientError(
                string `${INVALID_KEEPALIVE_CONFIG_MESSAGE}: the pongTimeout must be greater than zero`);
    }
    return;
}

isolated function calculateBackOffDelay(ReconnectConfig config, int attemptIndex) returns decimal {
    float factor = config.backOffFactor.pow(<float>attemptIndex);
    decimal delay = config.interval * <decimal>factor;
    return delay > config.maxInterval ? config.maxInterval : delay;
}
