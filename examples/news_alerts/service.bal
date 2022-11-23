import ballerina/uuid;
import ballerina/graphql;

@graphql:ServiceConfig {
    graphiql: {
        enabled: ENABLE_GRAPHIQL
    }
}
service /news on new graphql:Listener(9090) {
    resource function get users() returns readonly & User[] {
        lock {
            return from User user in userTable
                select user.cloneReadOnly();
        }
    }

    resource function get publishers() returns readonly & Publisher[] {
        lock {
            return from Publisher publisher in publisherTable
                select publisher.cloneReadOnly();
        }
    }

    resource function subscribe news(string userId) returns stream<News>|error {
        stream<News> newsStream;
        lock {
            if userTable.hasKey(userId) {
                NewsStream newsStreamGenerator = check new (userId);
                newsStream = new (newsStreamGenerator);
            } else {
                return error("User not registered");
            }
        }
        return newsStream;
    }

    remote function publish(NewsUpdate & readonly update) returns NewsRecord|error {
        lock {
            if publisherTable.hasKey(update.publisherId) {
                return produceNews(update).cloneReadOnly();
            }
        }
        return error("Invalid publisher");
    }

    remote function registerUser(NewUser newUser) returns User {
        string id = uuid:createType1AsString();
        lock {
            User user = {id: id, ...newUser.cloneReadOnly()};
            userTable.put(user);
            return user.cloneReadOnly();
        }
    }

    remote function registerPublisher(NewPublisher newPublisher) returns Publisher {
        string id = uuid:createType1AsString();
        lock {
            Publisher publisher = {id: id, ...newPublisher.cloneReadOnly()};
            publisherTable.put(publisher);
            return publisher.cloneReadOnly();
        }
    }
}
