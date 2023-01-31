import ballerina/log;
import ballerina/uuid;
import ballerinax/kafka;

configurable decimal POLL_INTERVAL = 100.0;

type NewsProducerRecord record {|
    *kafka:AnydataProducerRecord;
    string key;
    NewsRecord value;
|};

type NewsConsumerRecord record {|
    *kafka:AnydataConsumerRecord;
    NewsRecord value;
|};

final kafka:Producer producer = check new (kafka:DEFAULT_URL);

isolated function produceNews(NewsUpdate newsUpdate) returns NewsRecord|error {
    string id = uuid:createType1AsString();
    Agency agency = check getAgency(newsUpdate.publisherId);
    NewsRecord news = {id: id, ...newsUpdate};
    NewsProducerRecord producerRecord = {
        topic: agency,
        key: id,
        value: news
    };
    check producer->send(producerRecord);
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
            topics: [agency],
            maxPollRecords: 1 // Limit the number of records to be polled at a time
        };
        self.consumer = check new (kafka:DEFAULT_URL, consumerConfiguration);
    }

    public isolated function next() returns record {|News value;|}? {
        NewsConsumerRecord[]|error consumerRecords = self.consumer->poll(POLL_INTERVAL);
        if consumerRecords is error {
            // Log the error with the consumer group id and return nil
            log:printError("Failed to retrieve data from the Kafka server", consumerRecords, id = self.consumerGroup);
            return;
        }
        if consumerRecords.length() < 1 {
            // Log the warning with the consumer group id and return nil
            log:printWarn(string `No news available in "${self.agency}"`, id = self.consumerGroup);
            return;
        }
        return {value: new (consumerRecords[0].value)};
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
