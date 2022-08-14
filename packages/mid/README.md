<!-- TODO: keep this a brief introduction to the package since packages/mid/README.md should have the details -->
# `mid` - an API generation tool (WIP)
> warning: The project is still a work in progress. Use cautiously and definitely it is not ready for production. 

`mid` will generate an API server and a client library as well as handling requests and managing the communication between the server and the client. 

`mid` simply works by converting the public methods of a class into endpoints where the class name plus the method compose a route (e.g. `/class_name/method_name`). The return type and the parameters of each method are parsed to generate the requests handlers internally as well as generate the client library to be directly used by the frontend -- as simple as calling functions. 

In short, all you have to write is the following _(plus the classes implementations, of course)_ in order to generate the API server and client code:

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

For more details, see [Getting Started](#getting-started) or [Examples](#examples) below but don't forget to read the [Caveats](#caveats) first.


## Motivation

To have the ability to call the backend code from the frontend in a type safe manner and as simple as calling a function in pure Dart. 

`mid` is not intended to generate a REST API, but to generate an API server that can be seamlessly used by a Dart or Flutter frontend with a minimal effort. 

## Caveats

### Supported Classes
Any class. `mid` will only expose the public methods of the given class and it'll not expose the ones for its super class(es).

### Supported Return and Parameters Types 

While `mid` can convert any class to an API server, the types for return statement and parameters are limited to the following:
- Basic Dart Types (`int`, `double`, `num`, `bool`, `String`, `DateTime`)
- Serializable Classes that contains `toJson` method and `fromJson` factory constructors. 
- Iterables (i.e., `Map`, `Set`, `List`) of the Basic Types or Serializable Classes.
- `Future` or `Stream` _(yes, stream)_ for any of the above. 

## Getting Started

0. **Install `mid`:**
      ```sh
      dart pub global activate mid
      ```

1. **Create a shelf server project (skip if you have one)**
      ```
      dart create -t server-shelf
      ```

2. **In the root directory, run:**
    ```sh
    mid init
    ```
    This will create a folder called `mid` containing all of `mid`'s artificats.

3. **Clear `bin/server.dart` and replace it with:**

    ```dart
    import '../mid/server.dart';
    void main(List<String> args) => server(args);
    ```

  4. **open `mid/endpoints.dart` and add your code there.**
  
      You can create a `lib` folder, write your code there then import it to the `endpoints.dart` file. 

  5. **Generate endpoints:**

      ```sh
      mid generate endpoints 
      ```

      This will generate the server side code on top of [shelf](https://pub.dev/packages/shelf) server within `mid` folder. 

  6. **Generate teh client code**

      ```sh
      mid generate client --location='/path/to/client/code'
      ```



## Examples 

Examples will be added soon to the [examples](/examples/) folder. 

<br><br>

## Roadmap 

[ ] API versioning and Preventing Unintended Breaking Changes

Disscusion: the idea here is to track methods return types and parameters so they do not break the api for apps, especially the one running an older version.
For instance, adding a new required parameter to a method or changing the name of a parameter can break the api for existing apps. `mid` should keep track of API changes somehow and warn the user when such a change occurs. This could be done by storing the generated APIs in some sort of a database and whenever `mid generate endpoints` is called, `mid` would compare the newly generated API with the previous one and present the user with appropriate warning. 