import ballerina/graphql;

@graphql:ServiceConfig {
    interceptors: [new DestructiveModification()]
}
isolated service /subscription_interceptor6 on subscriptionListener {

    isolated resource function get name() returns string {
        return "Walter White";
    }

    @graphql:ResourceConfig {
        interceptors: new DestructiveModification()
    }
    isolated resource function subscribe messages() returns stream<int, error?> {
        int[] intArray = [1, 2, 3, 4, 5];
        return intArray.toStream();
    }
}

@graphql:ServiceConfig {
    interceptors: new ReturnBeforeResolver()
}
isolated service /subscription_interceptor5 on subscriptionListener {

    isolated resource function get name() returns string {
        return "Walter White";
    }

    isolated resource function subscribe messages() returns stream<int, error?> {
        int[] intArray = [1, 2, 3, 4, 5];
        return intArray.toStream();
    }
}

@graphql:ServiceConfig {
    interceptors: [new Subtraction(), new Multiplication()]
}
isolated service /subscription_interceptor1 on subscriptionListener {

    isolated resource function get name() returns string {
        return "Walter White";
    }

    @graphql:ResourceConfig {
        interceptors: [new Subtraction(), new Multiplication()]
    }
    isolated resource function subscribe messages() returns stream<int, error?> {
        int[] intArray = [1, 2, 3, 4, 5];
        return intArray.toStream();
    }
}

@graphql:ServiceConfig {
    interceptors: [new InterceptAuthor(), new ServiceLevelInterceptor()]
}
isolated service /subscription_interceptor2 on subscriptionListener {

    isolated resource function get name() returns string {
        return "Walter White";
    }

    isolated resource function subscribe books() returns stream<Book?, error?> {
        Book?[] books = [
            {name: "Crime and Punishment", author: "Fyodor Dostoevsky"},
            {name: "A Game of Thrones", author: "George R.R. Martin"},
            ()
        ];
        return books.toStream();
    }

    @graphql:ResourceConfig {
        interceptors: [new InterceptBook()]
    }
    isolated resource function subscribe newBooks() returns stream<Book?, error?> {
        Book?[] books = [
            {name: "Crime and Punishment", author: "Fyodor Dostoevsky"},
            ()
        ];
        return books.toStream();
    }
}

@graphql:ServiceConfig {
    interceptors: new InterceptStudentName()
}
isolated service /subscription_interceptor3 on subscriptionListener {

    isolated resource function get name() returns string {
        return "Walter White";
    }

    isolated resource function subscribe students() returns stream<StudentService, error?> {
        StudentService[] students = [new StudentService(1, "Eren Yeager"), new StudentService(2, "Mikasa Ackerman")];
        return students.toStream();
    }

    @graphql:ResourceConfig {
        interceptors: [new InterceptStudent()]
    }
    isolated resource function subscribe newStudents() returns stream<StudentService, error?> {
        StudentService[] students = [new StudentService(1, "Eren Yeager"), new StudentService(2, "Mikasa Ackerman")];
        return students.toStream();
    }
}

@graphql:ServiceConfig {
    interceptors: new InterceptUnionType1()
}
isolated service /subscription_interceptor4 on subscriptionListener {

    isolated resource function get name() returns string {
        return "Walter White";
    }

    isolated resource function subscribe multipleValues1() returns stream<PeopleService>|error {
        StudentService s = new StudentService(1, "Jesse Pinkman");
        TeacherService t = new TeacherService(0, "Walter White", "Chemistry");
        return [s, t].toStream();
    }

    @graphql:ResourceConfig {
        interceptors: new InterceptUnionType2()
    }
    isolated resource function subscribe multipleValues2() returns stream<PeopleService>|error {
        StudentService s = new StudentService(1, "Harry Potter");
        TeacherService t = new TeacherService(3, "Severus Snape", "Dark Arts");
        return [s, t].toStream();
    }
}
