# `mid` - build end-to-end type-safe APIs (Experimental) 

> ⚠️ warning: The project is experimental! ⚠️

`mid` is a tool to build an end-to-end type-safe API. The tool generates an API server and a client library as well as handling requests and managing the communication between the server and the client. 

`mid` simply works by converting the public methods for a given list of classes into endpoints (i.e. `/class_name/method_name`). The return type and the parameters of each method are parsed to generate the requests handlers, the serialization/deserialization code and the client library to be directly used by the frontend -- as simple as calling functions.


For example:

- you write this on the server side:
    ```dart
    class App {
        final Database database;

        App(this.database);

        Future<UserData> getUserData(int uid) async {
            final user = await database.getUserById(uid);
            return user;
        }
    }
    ```

- you will be able to do this on the client side:

    ```dart
    final client = AppClient(url: 'localhost:8080');

    final UserData data = await client.getUserData(42); 
    ```


In order for `mid` to generate the server side and client side code, the endpoints must be provided in the following manner:


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


For more details, see [Getting Started](#getting-started) or [Examples](#examples) and see the [Caveats](#caveats) below.


## Motivation

To have the ability to call the backend code from the frontend in a type safe manner and as simple as calling a function in pure Dart. 

`mid` is not intended to generate a REST API, but to generate an API server that can be seamlessly used by a Dart or Flutter frontend with a minimal effort. 

## Getting Started

0. **Install `mid`:**
      ```sh
      dart pub global activate mid
      ```

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

  2. **open `<project_name>/<project_name>_server/mid/endpoints.dart` and add your endpoints there.**
  
      You can create the endpoints classes inside the `lib` folder, and then import them to the `endpoints` file. 

  3. **Generate endpoints:**

      ```sh
      mid generate endpoints 
      ```

      This will generate the server side code on top of [shelf](https://pub.dev/packages/shelf) server within `mid` folder. 

  4. **Generate teh client code**

      ```sh
      mid generate client 
      ```



## Examples 

Examples will be added soon to the [examples](/examples/) folder. 


## Caveats 

### Supported Classes
Any class. `mid` will only expose the public methods of the given class and it'll not expose any of its superclass(es).

### Supported Return Types and Method Parameters Types 

- All core Types (`int`, `double`, `num`, `bool`, `String`, `DateTime`, `Duration`, etc.)
- User defined Classes\*
- Collections (i.e., `Map`, `Set`, `List`) of the Basic Types or Data Classes.
- `Future` or `Stream` _(not supported yet)_ for any of the above. 

\* `mid` is able to serialize user defined classes and their members recursively as long as they have an unnamed generative constructor with formal parameters only (i.e. all parameters using `this`). An example class would be:

```dart
class UserData {
    final int id;
    final String name;
    // `MetaData` will be serialized even if it doesn't appear in any method return type or parameters types
    final MetaData metadata; 
    
    // Must have unnamed generative constructor with formal parameters (i.e. using `this`). 
    UserData({this.id, this.name, this.metadata});  

    /* 
        you can define your own methods, factory constructors, and whatnot 
    */
}

```




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