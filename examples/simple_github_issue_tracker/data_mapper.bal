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

function transformGitHubUser(GitHubUser gitHubUser) returns User => {
    login: gitHubUser.login,
    url: gitHubUser.url,
    createdAt: gitHubUser.created_at,
    updatedAt: gitHubUser.updated_at
};

function transformGitHubRepository(GitHubRepository gitHubRepository) returns Repository => {
    id: gitHubRepository.id,
    name: gitHubRepository.name,
    createdAt: gitHubRepository.created_at,
    updatedAt: gitHubRepository.updated_at,
    hasIssues: gitHubRepository.has_issues,
    defaultBranch: gitHubRepository.default_branch
};

function transformGitHubRepositories(GitHubRepository[] gitHubRepositories) returns Repository[] =>
    from var gitHubRepositoriesItem in gitHubRepositories
select {
    id: gitHubRepositoriesItem.id,
    name: gitHubRepositoriesItem.name,
    createdAt: gitHubRepositoriesItem.created_at,
    updatedAt: gitHubRepositoriesItem.updated_at,
    hasIssues: gitHubRepositoriesItem.has_issues,
    defaultBranch: gitHubRepositoriesItem.default_branch
};

function transformGetBranchesResponse(GetBranchesResponse getBranchesResponse) returns BranchesResponse => {
    repository: {
        refs: {
            nodes: getBranchesResponse.repository?.refs?.nodes
        }
    }
};
