enum Agency {
    FIRST_NEWS,
    BNN,
    CBC
}

type NewsUpdate record {|
    string headline;
    string brief;
    string content;
    string publisherId;
|};

type NewsRecord readonly & record {|
    readonly string id;
    *NewsUpdate;
|};

type NewUser record {|
    string name;
    int age;
|};

type User record {|
    readonly string id;
    *NewUser;
|};

type NewPublisher record {|
    string name;
    string area;
    Agency agency;
|};

type Publisher readonly & record {|
    readonly string id;
    *NewPublisher;
|};

isolated service class News {
    private final readonly & NewsRecord newsRecord;

    isolated function init(NewsRecord newsRecord) {
        self.newsRecord = newsRecord;
    }

    isolated resource function get id() returns string => self.newsRecord.id;

    isolated resource function get headline() returns string => self.newsRecord.headline;

    isolated resource function get brief() returns string => self.newsRecord.brief;

    isolated resource function get content() returns string => self.newsRecord.content;

    isolated resource function get publisher() returns Publisher {
        lock {
            return publisherTable.get(self.newsRecord.publisherId);
        }
    }
}
