import ballerina/log;
import ballerina/uuid;
import ballerinax/kafka;

configurable decimal POLL_INTERVAL = 100.0;

isolated function produceNews(NewsUpdate newsUpdate) returns NewsRecord|error {
    kafka:Producer producer = check new (kafka:DEFAULT_URL);
    string id = uuid:createType1AsString();
    Agency agency = check getAgency(newsUpdate.publisherId);
    NewsRecord news = {id: id, ...newsUpdate};
    check producer->send({topic: agency, key: id, value: news});
    return news;
}

isolated class NewsStream {
    private final string consumerGroup;
    private final Agency agency;
    private final kafka:Consumer consumer;

    isolated function init(string consumerGroup, Agency agency) returns error? {
        self.consumerGroup = consumerGroup;
        self.agency = agency;
        kafka:ConsumerConfiguration consumerConfiguration = {
            groupId: consumerGroup,
            offsetReset: "earliest",
            topics: agency,
            maxPollRecords: 1 // Limit the number of records to be polled at a time
        };
        self.consumer = check new (kafka:DEFAULT_URL, consumerConfiguration);
    }

    public isolated function next() returns record {|News value;|}? {
        NewsRecord[]|error newsRecords = self.consumer->pollPayload(POLL_INTERVAL);
        if newsRecords is error {
            // Log the error with the consumer group id and return nil
            log:printError("Failed to retrieve data from the Kafka server", newsRecords, id = self.consumerGroup);
            return;
        }
        if newsRecords.length() < 1 {
            // Log the warning with the consumer group id and return nil. This will end the subscription as returning
            // nil will be interpreted as the end of the stream.
            log:printWarn(string `No news available in "${self.agency}"`, id = self.consumerGroup);
            return;
        }
        return {value: new (newsRecords[0])};
    }
}

isolated function getAgency(string publisherId) returns Agency|error {
    lock {
        if publisherTable.hasKey(publisherId) {
            return publisherTable.get(publisherId).agency;
        }
    }
    return error("Publisher not found");
}
