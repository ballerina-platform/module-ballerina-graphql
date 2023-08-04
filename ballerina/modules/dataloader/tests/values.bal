type AuthorRow record {|
    readonly int id;
    string name;
|};

final isolated table<AuthorRow> key(id) authorTable = table [
    {id: 1, name: "Author 1"},
    {id: 2, name: "Author 2"},
    {id: 3, name: "Author 3"},
    {id: 4, name: "Author 4"},
    {id: 5, name: "Author 5"}
];
