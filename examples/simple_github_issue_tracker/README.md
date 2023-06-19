# Simple GitHub Issue Tracker

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
   git clone https://github.comballerina-platform/module-ballerina-graphql/examples/simple-github-issue-tracker.git

2. Navigate to the cloned repository:
    ```bash
    cd simple-github-issue-tracker

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
