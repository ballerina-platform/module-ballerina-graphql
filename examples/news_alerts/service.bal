import ballerina/uuid;
import ballerina/graphql;

configurable boolean ENABLE_GRAPHIQL = ?;

@graphql:ServiceConfig {
    graphiql: {
        enabled: ENABLE_GRAPHIQL
    }
}
service /news on new graphql:Listener(9090) {
    # Retrieve the list of users.
    # + return - The list of all users
    resource function get users() returns readonly & User[] {
        lock {
            return from User user in userTable
                select user.cloneReadOnly();
        }
    }

    # Retrieve the list of publishers.
    # + return - The list of all publishers
    resource function get publishers() returns readonly & Publisher[] {
        lock {
            return from Publisher publisher in publisherTable
                select publisher.cloneReadOnly();
        }
    }

    # Publish a news update. This will return the published news record, or an error if the publisher is not registered.
    # + update - The news update to be published
    # + return - The published news record
    remote function publish(NewsUpdate & readonly update) returns NewsRecord|error {
        lock {
            if publisherTable.hasKey(update.publisherId) {
                return produceNews(update).cloneReadOnly();
            }
        }
        return error("Invalid publisher");
    }

    # Register a new user. This will return the registered user record.
    # + newUser - The information of the new user
    # + return - The registered user record
    remote function registerUser(NewUser newUser) returns User {
        string id = uuid:createType1AsString();
        lock {
            User user = {id: id, ...newUser.cloneReadOnly()};
            userTable.put(user);
            return user.cloneReadOnly();
        }
    }

    # Register a new publisher. This will return the registered publisher record.
    # + newPublisher - The information of the new publisher
    # + return - The registered publisher record
    remote function registerPublisher(NewPublisher newPublisher) returns Publisher {
        string id = uuid:createType1AsString();
        lock {
            Publisher publisher = {id: id, ...newPublisher.cloneReadOnly()};
            publisherTable.put(publisher);
            return publisher.cloneReadOnly();
        }
    }

    # Subscribe to news updates. If the user is not registered, an error will be returned. Otherwise, subscribers will receive the news updates once they are published.
    # + userId - The ID of the user
    # + agency - The news agency to subscribe to
    # + return - The stream of news updates
    resource function subscribe news(string userId, Agency agency) returns stream<News>|error {
        stream<News> newsStream;
        lock {
            if userTable.hasKey(userId) {
                NewsStream newsStreamGenerator = check new (userId, agency);
                newsStream = new (newsStreamGenerator);
            } else {
                return error("User not registered");
            }
        }
        return newsStream;
    }
}
