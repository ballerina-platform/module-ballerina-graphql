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

# The GitHub User
#
# + name - User name  
# + login - Logged in user
# + id - User id  
# + bio - User bio  
# + url - Prfile url 
# + created_at - Created date of Profile  
# + updated_at - Last update date
# + avatar_url - Avatar url  
# + 'type - User type  
# + company - User company  
# + blog - User blog  
# + location - User location  
# + email - User email 
# + public_repos - number if public repos  
# + followers - Number if followers  
# + following - Number of following
type User record {
  string? name;
  string login;
  int id;
  string bio;
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

# The Repository Branch
#
# + id - Branch id  
# + name - Branch name
# + prefix - Branch prefix
public type Branch record {
    string id;
    string name;
    string prefix;
};

# The GitHub Repository
#
# + id - Repository id  
# + name - The name of the repository.  
# + description - The description of the repository.  
# + 'fork - Field Description  
# + created_at - Identifies the date and time when the object was created.  
# + updated_at - Identifies the date and time when the object was last updated.  
# + language - The language composition of the repository.  
# + owner - The owner of the repository.  
# + has_issues - State whether there are issues or not  
# + forks_count - Fork count  
# + open_issues_count - Open issues count  
# + lisense - License type  
# + allow_forking - State wether forking is allowed or not  
# + visibility - Visibility of the repository  
# + forks - Number of forks  
# + open_issues - Number of open issues  
# + watchers - Number of watchers  
# + default_branch - Name of the default branch
public type Repository record {
    int id;
    string name;
    string? description;
    boolean 'fork;
    string created_at;
    string updated_at;
    string? language;
    Owner owner?;
    boolean has_issues;
    int forks_count;
    int open_issues_count;
    License lisense?;
    boolean allow_forking;
    string visibility;
    int forks;
    int open_issues;
    int watchers;
    string default_branch;
};

# The Repository Owner
#
# + login - Logged in user  
# + id - user id  
# + url - Profile url  
# + 'type - User type
public type Owner record {
    string login;
    int id;
    string url;
    string 'type;
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
    string[] assigneeNames;
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
# + bodyResourcePath - The http path for this issue body
# + bodyText - Identifies the body of the issue rendered to text.
# + bodyUrl - The http URL for this issue body
# + closed - `true` if the object is closed (definition of closed may depend on type)
# + closedAt - Identifies the date and time when the object was closed.
# + createdAt - Identifies the date and time when the object was created.
# + createdViaEmail - Check if this comment was created via an email reply.
# + databaseId - Identifies the primary key from the database.
# + id - ID
# + isPinned - Indicates whether or not this issue is currently pinned to the repository issues list
# + isReadByViewer - Is this issue read by the viewer
# + lastEditedAt - The moment the editor made the last edit
# + locked - `true` if the object is locked
# + number - Identifies the issue number.
# + publishedAt - Identifies when the comment was published at.
# + resourcePath - The HTTP path for this issue
# + title - Identifies the issue title.
# + updatedAt - Identifies the date and time when the object was last updated.
# + url - The HTTP URL for this issue
# + viewerDidAuthor - Did the viewer author this comment.
# + viewerCanUpdate - Check if the current viewer can update this object.
public type Issue record {
    Actor? author?;
    string? body?;
    string bodyHTML?;
    string bodyResourcePath?;
    string bodyText?;
    string bodyUrl?;
    boolean closed?;
    string? closedAt?;
    string createdAt?;
    boolean createdViaEmail?;
    int? databaseId?;
    int id;
    boolean? isPinned?;
    boolean? isReadByViewer?;
    string? lastEditedAt?;
    boolean locked?;
    int number;
    string? publishedAt?;
    string resourcePath?;
    string title?;
    string updatedAt?;
    string url?;
    boolean viewerDidAuthor?;
    boolean viewerCanUpdate?;
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
