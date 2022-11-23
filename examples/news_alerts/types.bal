type NewsRecord record {|
    readonly string id;
    *NewsUpdate;
|};

type NewsUpdate record {|
    string headline;
    string brief;
    string content;
    string publisherId;
|};

type User record {|
    readonly string id;
    *NewUser;
|};

type NewUser record {|
    string name;
    int age;
|};

type Publisher record {|
    readonly string id;
    *NewPublisher;
|};

type NewPublisher record {|
    string name;
    Agency agency;
|};

enum Agency {
    FIRST_NEWS,
    BNN,
    CBC
}

isolated service class News {
    private final string id;
    private final string headline;
    private final string brief;
    private final string content;
    private final string publisherId;

    isolated function init(*NewsRecord newsRecord) {
        self.id = newsRecord.id;
        self.headline = newsRecord.headline;
        self.brief = newsRecord.brief;
        self.content = newsRecord.content;
        self.publisherId = newsRecord.publisherId;
    }

    isolated resource function get id() returns string => self.id;

    isolated resource function get headline() returns string => self.headline;

    isolated resource function get bried() returns string => self.brief;

    isolated resource function get content() returns string => self.content;

    isolated resource function get publisher() returns Publisher {
        lock {
            return publisherTable.get(self.publisherId).cloneReadOnly();
        }
    }
}
