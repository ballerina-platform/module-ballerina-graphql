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
    name: gitHubUser?.name,
    login: gitHubUser.login,
    id: gitHubUser.id,
    url: gitHubUser.url,
    createdAt: gitHubUser.created_at,
    updatedAt: gitHubUser.updated_at,
    avatarUrl: gitHubUser.avatar_url,
    email: gitHubUser?.email,
    publicRepos: gitHubUser.public_repos
};

function transformGitHubRepository(GitHubRepository gitHubRepository) returns Repository => {
    id: gitHubRepository.id,
    name: gitHubRepository.name,
    description: gitHubRepository.description,
    'fork: gitHubRepository.'fork,
    createdAt: gitHubRepository.created_at,
    updatedAt: gitHubRepository.updated_at,
    language: gitHubRepository.language,
    hasIssues: gitHubRepository.has_issues,
    forksCount: gitHubRepository.forks_count,
    openIssuesCount: gitHubRepository.open_issues_count,
    lisense: gitHubRepository.lisense,
    visibility: gitHubRepository.visibility,
    forks: gitHubRepository.forks,
    openIssues: gitHubRepository.open_issues,
    watchers: gitHubRepository.watchers,
    defaultBranch: gitHubRepository.default_branch
};

function transformGitHubRepositories(GitHubRepository[] gitHubRepositories) returns Repository[] =>
    from var gitHubRepositoriesItem in gitHubRepositories
select {
    id: gitHubRepositoriesItem.id,
    name: gitHubRepositoriesItem.name,
    description: gitHubRepositoriesItem.description,
    'fork: gitHubRepositoriesItem.'fork,
    createdAt: gitHubRepositoriesItem.created_at,
    updatedAt: gitHubRepositoriesItem.updated_at,
    language: gitHubRepositoriesItem.language,
    hasIssues: gitHubRepositoriesItem.has_issues,
    forksCount: gitHubRepositoriesItem.forks_count,
    openIssuesCount: gitHubRepositoriesItem.open_issues_count,
    lisense: gitHubRepositoriesItem.lisense,
    visibility: gitHubRepositoriesItem.visibility,
    forks: gitHubRepositoriesItem.forks,
    openIssues: gitHubRepositoriesItem.open_issues,
    watchers: gitHubRepositoriesItem.watchers,
    defaultBranch: gitHubRepositoriesItem.default_branch
};
