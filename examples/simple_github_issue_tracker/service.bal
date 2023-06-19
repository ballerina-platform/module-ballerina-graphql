// Copyright (c) 2023 WSO2 LLC. (http://www.wso2.com).
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

import ballerina/graphql;
import ballerina/http;
import ballerina/io;

configurable string authToken = ?;
configurable string owner = ?;

@graphql:ServiceConfig {
    cors: {
        allowOrigins: ["*"]
    },
    graphiql: {
        enabled: true
    }
}
service /graphql on new graphql:Listener(9090) {

    final http:Client githubRestClient;

    function init() returns error? {
        self.githubRestClient = check new ("https://api.github.com", {auth: {token: authToken}});
        io:println("💃 Server ready at http://localhost:9090/graphql");
        io:println("Access the GraphiQL UI at http://localhost:9090/graphiql");
    }

    # Get GitHub User Details
    # 
    # + return - GitHub repository list
    resource function get user() returns User|error {
        GitHubUser user = check self.githubRestClient->/user;
        return transformGitHubUser(user);
    }

    # Get GitHub Repository List
    # 
    # + return - GitHub repository list
    resource function get repositories() returns Repository[]|error {
        GitHubRepository[] repositories = check self.githubRestClient->/users/[owner]/repos;
        return transformGitHubRepositories(repositories);
    }

    # Get Repository
    #
    # + repositoryName - Repository name
    # + return - GitHub repository
    resource function get repository(string repositoryName) returns Repository|error {
        GitHubRepository repository = check self.githubRestClient->/repos/[owner]/[repositoryName];
        return transformGitHubRepository(repository);
    }

    # Create Repository
    #
    # + createRepoInput - Represent create repository input payload
    # + return - GitHub repository or an error
    remote function createRepository(CreateRepositoryInput createRepoInput) returns Repository|error {
        GitHubRepository repository = check self.githubRestClient->/user/repos.post(createRepoInput);
        return transformGitHubRepository(repository);
    }

    # Create Issue
    #
    # + createIssueInput - Create issue input payload  
    # + repositoryName - Repository name
    # + return - GitHub issue
    remote function createIssue(CreateIssueInput createIssueInput, string repositoryName) returns Issue|error {
        Issue issue = check self.githubRestClient->/repos/[owner]/[repositoryName]/issues.post(createIssueInput);
        check produceIssue(issue, repositoryName);
        return issue;
    }

    # Subscribe to issues created
    #
    # + repositoryName - Repository name
    # + return - Stream of issues
    resource function subscribe issues(string repositoryName) returns stream<Issue>|error {
        IssueStream issueStreamGenerator = check new (repositoryName);
        stream<Issue> issueStream = new (issueStreamGenerator);
        return issueStream;
    }
}
