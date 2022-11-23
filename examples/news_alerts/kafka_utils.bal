import ballerina/uuid;
import ballerinax/kafka;

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
    NewsRecord news = {id: id, ...newsUpdate};
    NewsProducerRecord producerRecord = {
        topic: NEWS_TOPIC,
        key: id,
        value: news
    };
    check producer->send(producerRecord);
    return news;
}
