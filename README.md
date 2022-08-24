# mid 

> ⚠️ warning: the project is still experimental! 

`mid` is a tool to build an end-to-end typesafe API in dart. The tool generates an API server and a client library in addition to handling requests and managing communication between the server and the client. 

In short:

- You write this on the server side:
    ```dart
    class App extends EndPoints {
        final Database database;

        App(this.database);

        Future<UserData> getUserData(int uid) async {
            final user = await database.getUserById(uid);
            return user;
        }

        Stream<List<Post>> timeline(int uid) {
            return database.timelineStream(uid);
        }

        Future<void> updateProfile(UserProfile profile) {
            await database.updateProfile(profile);
        }
    }
    ```

- And `mid` enables you to do this on the client side:

    ```dart
    final client = TheClient(url: 'localhost:8080');

    final UserData data = await client.getUserData(42); 

    final  Stream<List<Post>> posts = await client.timeline(uid); 

    final newProfile = profile.copyWith(photoURL: photoURL);
    await client.updateProfile(newProfile); 
    ```


See the [Quick Start Tutorial](https://github.com/osaxma/mid/tree/main/tutorials/quick_start/README.md) to learn how to use `mid` in no time. 

## Getting Started

### Installation:

```sh
dart pub global activate mid
```

### Tutorials:

- [Quick Start Tutorial](https://github.com/osaxma/mid/tree/main/tutorials/quick_start/README.md) 


### Examples:

- Examples will be added **SOON** to the [examples](https://github.com/osaxma/mid/tree/main/examples) folder. 

### Documentation
The documentation is being created incrementally within [docs](https://github.com/osaxma/mid/tree/main/docs) folder. Currently the following is available:

- [interceptors](https://github.com/osaxma/mid/blob/main/docs/interceptors.md)
- [project_structure](https://github.com/osaxma/mid/blob/main/docs/project_structure.md)
- [serialization](https://github.com/osaxma/mid/blob/main/docs/serialization.md)

## Motivation

To have the ability to call the backend code from the frontend in a type safe manner and as simple as calling a function in pure Dart. 

> Note: `mid` is not intended to generate a REST API, but to generate an API server that can be seamlessly used by a Dart or Flutter frontend with a minimal effort. 


## How does it work
`mid` simply works by converting the public methods for a given list of classes into endpoints on a [shelf][] server by generating a [shelf_router][] and its handlers. In addition, the return type and the parameters types of each method are parsed and analyzed to generate the serialization/deserialization code for each type. 

The client library is generated in a similar manner where each class, method, return type and parameter type is regenerated so that each endpoint becomes a simple function. 

To support streaming data from the server to the client, [shelf_web_socket] is used on the server while [web_socket_channel][] on the client. 

[shelf]: https://pub.dev/packages/shelf
[shelf_router]: https://pub.dev/packages/shelf_router
[shelf_web_socket]: https://pub.dev/packages/shelf_web_socket
[web_socket_channel]: https://pub.dev/packages/web_socket_channel

## Additional Notes 

### Supported Classes
Any class of an `EndPoints`\* type. `mid` will only expose the public methods of the given class and it'll not expose any of its superclass(es).

\* `EndPoints` is just a type -- for now there's nothing to implement. a class just needs to implement, extend or mixin `EndPoints` so it can be converted. 

### Supported Return Types and Method Parameters Types 

- All core Types (`int`, `double`, `num`, `bool`, `String`, `DateTime`, `Duration`, `enum`, `Uri`, `BigInt`)
- User defined Classes\*
- Collections (i.e., `Map`, `Set`, `List`) of any of the above.
- `Future` or `Stream` for any of the above. 

\* `mid` is able to serialize user defined classes and their members recursively as long as they have an unnamed generative constructor with formal parameters only (i.e. all parameters using `this`). An example class would be:

```dart
class UserData {
  final int id;
  final String name;
  final bool isAdmin;
  // `MetaData` must follow the same rules including its members.
  final MetaData? metadata;

  // this is what `mid` is looking for (i.e. no assignment in initializer list or constructor body):
  UserData({
    required this.id,
    required this.name,
    this.metadata,
    this.isAdmin = false,
  });

  /* you can define your own methods, factory constructors, and whatnot */
}
```



<!-- 



```dart
Future<List<Object>> endpoints(Logger logger) async {
    final database = Database(url: String.fromEnvironment('DATABASE_URL'));
    return [
       App(apiKey: apiKey, database: database, logger: logger);,
    ];
}
```

One can also create multiple routes and endpoints such as:


```dart
Future<List<Object>> endpoints(Logger logger) async {
    final database = Database(url: String.fromEnvironment('DATABASE_URL'));
    final storageURL = String.fromEnvironment('STORAGE_KEY');
    final apiKey = String.fromEnvironment('API_KEY');

    final authAPI =  Auth(database: database, logger: logger);

    final storageAPI = Storage(apiKey: apiKey, url: storageURL, database: database, logger: logger);

    final applicationAPI = App(apiKey: apiKey, database: database, logger: logger);

    return [
        authAPI,
        storageAPI,
        applicationAPI,
    ];
}
```


 -->



<!-- 

## Roadmap 

[ ] API versioning and Preventing Unintended Breaking Changes

Disscusion: the idea here is to track methods return types and parameters so they do not break the api for apps, especially the one running an older version.
For instance, adding a new required parameter to a method or changing the name of a parameter can break the api for existing apps. `mid` should keep track of API changes somehow and warn the user when such a change occurs. This could be done by storing the generated APIs in some sort of a database and whenever `mid generate endpoints` is called, `mid` would compare the newly generated API with the previous one and present the user with appropriate warning. 


if @serverOnly is supported for serializable class members, add the following caveat:

When a `Type` is used in a return statement as well as an argument, any member annotated with `@serverOnly` must be optional (i.e. either nullable or with a default value).
```dart 
Future<User> getUserData() {/* */}
Future<void> updateUserData(User user) {/* */}

class User {
    final int id;
    final String name;

    @serverOnly
    final bool isBanned; // <~~ must be optional or nullable 
}
```

The main reason is that when a client invoke `updateUserData`, it'll be impossible to instantiate `User` without a value for `isBanned` since the data coming from the client wouldn't have a value for it. That's because when `User` is generated for the client, it wouldn't have `isBanned` field due to the `@serverOnly` annotation. 

note: 
    - idea 1: I think it's possible to have a lint rule for that (warning: isBanned must have a default value or be nullable)
    - idea 2: change `@serverOnly` so that it accepts an argument of `default value`

 -->


 <!-- 
 about generated code:
 The code generated by `mid` is intended to be human-readable, tho it's quite redundant. In other words, `mid` does not generate any magic code -- it removes the heavylifting of writing the same code repeatedly in both server and client. 

  -->


  <!-- 
  caching:

  cache response for functions where input is the same. On the server, the user may add an annotation such as @Cachable(duration: ....) (also added as headers on http request)
  the args can be hashd as a key for the cache. 
   -->



<!-- 

To Generate coverage:

- run in root project:
    dart test --coverage="coverage"  
- then:
    format_coverage --lcov --in=coverage --out=coverage/coverage.lcov  --report-on=lib
- then:
    genhtml coverage/coverage.lcov -o coverage/html  
- then open it:
    open coverage/html/index.html 
-->



<!-- 
1. **Create a `mid`  project:**
      ```sh
      mid create <project_name>
      ```
      This will create two dart projects in the following structure:
      ```
      <project_name>
            |- <project_name>_client
            |- <project_name>_server
      ```

  2. **open `<project_name>_server/mid/endpoints.dart` and add your endpoints there.**

        for example:

        ```dart
        Future<List<EndPoints>> getEndPoints(Logger logger) async {
            final database = Database(url: String.fromEnvironment('DATABASE_URL'));
            final storageURL = String.fromEnvironment('STORAGE_KEY');
            final apiKey = String.fromEnvironment('API_KEY');

            final authAPI =  Auth(database: database, logger: logger);

            final storageAPI = Storage(apiKey: apiKey, url: storageURL, database: database, logger: logger);

            final applicationAPI = App(apiKey: apiKey, database: database, logger: logger);

            return [
                authAPI,
                storageAPI,
                applicationAPI,
            ];
        }
        ```
        
  
      You can create the endpoints classes inside the `lib` folder, and then import them to the `endpoints` file. 

  3. **Generate server and client libraries:**

      ```sh
      mid generate all 
      ```

  4. **run the server from within `<project_name>_server` directory**

      ```sh
      dart run bin/server.dart
      -> Server listening on port 8000
      ```
  5. **import the client project into your frontend and you're set to go**
    
        a. Inside the root of the fronted project, run the following:

        ```sh
        flutter pub add <project_name>_client --path "/path/to/<project_name>_client"
        ```
        b. Inside the file where you'd like to use the client, import the package:
        ```dart
        import 'package:<project_name>_client/<project_name>_client.dart';
        ```
        c. To get the client, it'll be:
        ```dart
        // replace `ProjectName` with the actual project name
        // replace `localhost:8080` with the actual url and port if different. 
        final client = ProjectNameClient(url: 'localhost:8080'); 
        ```


 -->