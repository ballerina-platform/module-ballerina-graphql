import ballerina/log;
import ballerinax/kafka;

# Retrieves the news from the Kafka topic and returns it as a stream. (This class acts as a stream generator)
public isolated class NewsStream {
    private final kafka:Consumer consumer;

    public isolated function init(string consumerGroup) returns error? {
        kafka:ConsumerConfiguration consumerConfiguration = {
            groupId: consumerGroup,
            offsetReset: "earliest",
            topics: [NEWS_TOPIC],
            maxPollRecords: 1
        };
        self.consumer = check new (kafka:DEFAULT_URL, consumerConfiguration);
    }

    public isolated function next() returns record {|News value;|}? {
        NewsConsumerRecord[]|error consumerRecords = self.consumer->poll(POLL_INTERVAL);
        if consumerRecords is error {
            printStackTrace(consumerRecords);
            return;
        }
        if consumerRecords.length() < 1 {
            log:printError("No news available");
            return;
        }
        return {value: new (consumerRecords[0].value)};
    }
}
