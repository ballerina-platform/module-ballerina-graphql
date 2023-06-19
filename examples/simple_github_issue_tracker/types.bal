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

import simple_github_issue_tracker.github_gql_client;

# The GitHub User
#
# + login - Logged in user
# + url - Prfile url
# + createdAt - Created date of Profile  
# + updatedAt - Last update date
public type User record {
    string login;
    string url;
    string createdAt;
    string updatedAt;
};

# The GitHub Repository
#
# + id - Repository id  
# + name - The name of the repository.  
# + createdAt - Identifies the date and time when the object was created.  
# + updatedAt - Identifies the date and time when the object was last updated.  
# + hasIssues - State whether there are issues or not  
# + defaultBranch - Name of the default branch
public type Repository record {
    int id;
    string name;
    string? createdAt;
    string? updatedAt;
    boolean hasIssues;
    string defaultBranch;
};

# The GitHub Repository Lisence
#
# + key - Lisence key  
# + name - Lisen name
public type License record {
    string key;
    string name;
};

# Represent create repository input payload
#
# + name - The name of the new repository.
# + description - A short description of the new repository.
# + isPrivate - Whether the repository is private.
# + autoInit - Whether the repository is initialized with a minimal README.
# + template - Whether this repository acts as a template that can be used to generate new repositories.
public type CreateRepositoryInput record {
    string name;
    string description?;
    boolean isPrivate?;
    boolean autoInit?;
    boolean template?;
};

# Represent create issue input payload.
#
# + title - The title for the issue.
# + body - The body for the issue description.
# + assigneeNames - The GitHub usernames of the user assignees for this issue.
# + milestoneId - The Node ID of the milestone for this issue.
# + labelNames - An array of Node IDs of labels for this issue.
# + projectIds - An array of Node IDs for projects associated with this issue.
# + issueTemplate - The name of an issue template in the repository, assigns labels and assignees from the template to the issue
# + clientMutationId - A unique identifier for the client performing the mutation.
public type CreateIssueInput record {
    string title;
    string body?;
    string[] assigneeNames?;
    string milestoneId?;
    string[] labelNames?;
    string[] projectIds?;
    string issueTemplate?;
    string clientMutationId?;
};

# Represent GitHub issue.
#
# + author - The actor who authored the comment.
# + body - Identifies the body of the issue.
# + bodyHTML - The body rendered to HTML.
# + bodyText - Identifies the body of the issue rendered to text.
# + createdAt - Identifies the date and time when the object was created.
# + number - Identifies the issue number.
# + resourcePath - The HTTP path for this issue
# + title - Identifies the issue title.
public type Issue record {
    Actor? author?;
    string? body?;
    string bodyHTML?;
    string bodyText?;
    string createdAt?;
    int number;
    string resourcePath?;
    string title?;
};

# Represent GitHub actor.
#
# + login - The username of the actor.
# + resourcePath - The HTTP path for this actor.
# + url - The HTTP URL for this actor.
# + avatarUrl - A URL pointing to the actor's public avatar.
public type Actor record {
    string login;
    string resourcePath?;
    string url?;
    string avatarUrl?;
};

type GitHubRepository record {
    int id;
    string name;
    boolean 'fork;
    string created_at;
    string updated_at;
    string? language;
    boolean has_issues;
    int forks_count;
    int open_issues_count;
    License lisense?;
    string visibility;
    int forks;
    int open_issues;
    int watchers;
    string default_branch;
};

type GitHubUser record {
    string? name;
    string login;
    int id;
    string url;
    string created_at;
    string updated_at;
    string avatar_url;
    string 'type;
    string? company;
    string blog;
    string? location;
    string? email?;
    int public_repos?;
    int followers?;
    int following?;
};

type GetBranchesResponse record {|
    *github_gql_client:GetBranchesResponse;
|};

type Ref record {|
    Branch?[]? nodes;
|};

type Repo record {|
    Ref refs;
|};

type BranchesResponse record {|
    Repo repository;
|};

# Represents a Repository Branch.
# 
# + name - Name of the branch.
# + id - Unique branch identifier.
# + prefix - The ref's prefix, such as `refs/heads/` or `refs/tags/`.
public type Branch record {|
    string name;
    string id;
    string prefix;      
|};
