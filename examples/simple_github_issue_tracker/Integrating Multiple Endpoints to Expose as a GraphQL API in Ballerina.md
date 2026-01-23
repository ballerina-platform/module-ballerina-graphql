# Simple GitHub Issue Tracker

[![Star on Github](https://img.shields.io/badge/-Star%20on%20Github-blue?style=social&logo=github)](https://github.com/ballerina-platform/module-ballerina-graphql)

_Authors_: @DimuthuMadushan \
_Reviewers_: @ThisaruGuruge @shafreenAnfar \
_Created_: 2023/02/06 \
_Updated_: 2023/02/06

Git Tracker is a GraphQL service written in Ballerina that connects with the GitHub REST API. It enables tracking and monitoring of Git repositories.

## Features

- Seamless integration with GitHub REST API and GitHub GraphQL API.
- Supports query, mutation, and subscription operations.
- Real-time tracking of repository activities.
- Provides a GraphQL interface for querying Git data.

## Installation

### Prerequisites

- Ballerina - Version Swan Lake 2201.6.0

### Steps

1. Clone the Git Tracker repository:

   ```bash
   git clone https://github.com/ballerina-platform/module-ballerina-graphql.git

2. Navigate to the cloned repository:
    ```bash
    cd module-ballerina-graphql/examples/simple_github_issue_tracker/
3. Configure the application by updating the config.toml file with your GitHub API credentials:
    ```bash
    authToken = "<YOUR_GITHUB_AUTH_TOKEN>"
    owner = "<GITHUB_USERNAME>"

4. Start the kafka server:
    ```bash
    docker-compose -f docker-compose-kafka.yml up
    ```

4. Start the Git Tracker service:
    ```bash
    bal run
    ```

5. Access the Git Tracker service at http://localhost:9090/graphql.

### Usage

Make GraphQL requests to interact with the Git Tracker service. Here's an example:

# Get repository details
    query MyQuery {
        repositories {
            id
            name
            description
            fork
            createdAt
            updatedAt
            language
            hasIssues
            forksCount
            openIssuesCount
            lisense {
                name
            }
        }
    }

Modify the GraphQL query according to your specific requirements.

## Contributing

Contributions are welcome! If you find any issues or have suggestions for improvements, please submit a pull request. For major changes, please open an issue first to discuss your proposed changes.
