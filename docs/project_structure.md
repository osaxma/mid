# Project Structure

When creating a `mid` project using `mid create <project_name>`, the following structure is generated:

```
<project_name>
    |- <project_name>_client
        |- lib
            |- mid
                |- routes
                    |- route_1.dart
                    |- route_2.dart
                |- models
                    |- models.dart 
                |- client.dart
                |- models.dart 
                |- routes.dart 
                |- interceptors.dart 
            |- <project_name>_client.dart 
    |- <project_name>_server
        |- bin
            |- server.dart
        |- lib/mid/
                |- generated
                    |- handlers.dart
                    |- serializers.dart
                |- endpoints.dart
                |- middlewares.dart
```

As it can be seen above, there are two projects created:

```
<project_name>
    |- <project_name>_client
    |- <project_name>_server
```

Each project is postfixed with an identifier. These identifiers are used by `mid generate` to orient itself and find the correct directory for each project. In addition, each project contains `mid` directory within the `lib` folder and that is also used to identify a `mid` project. So it's important to keep these identifers and refrain from changing the project name. 


## Server Project

Let's take a closer look at the server project:
```
|- <project_name>_server
    |- bin
        |- server.dart
    |- lib/mid/
            |- generated
                |- handlers.dart
                |- serializers.dart
            |- endpoints.dart
            |- middlewares.dart
```

- `bin/server.dart` 
    - This file is generated once upon creation.
    - The file contains `ServerConfig` where `port`, `address`, `securityContext`, `interceptors`, and such can be modified/added.
    - The file contains comments about which lines should not be modified. 

- `lib/mid/generated` 
    - `handlers.dart` is a generated file and should not be modified. It contains the handlers for endpoints (both regular and streams).
    - `serializers.dart` contains the serialization for User Defined Types (e.g. `UserData`) that were found in any return statement or an argument of any `EndPoints` method
    - `endpoints.dart` this file contains a single function async `getEndPoints`. The function is mainly intended to allow the developer to perform any initializations as well as creating the instances of each `EndPoints` class. This function is the first function called upon starting the server. 
    - `middlewares.dart` is where `MiddleWare` from the shelf package can be added. (this may change -- see [interceptors docs](interceptors.md) 

Except for `lib/mid`, source files can be created anywhere within `lib` or within the `project`.  

## Client Project 

Now let's take a closer look at the client project:
```
|- <project_name>_client
    |- lib
        |- mid
            |- routes
                |- route_1.dart
                |- route_2.dart
            |- models
                |- model_1.dart 
                |- model_2.dart 
            |- client.dart
            |- models.dart 
            |- routes.dart 
            |- interceptors.dart (to export interceptors types)
        |- <project_name>_client.dart (exports client, models, routes, interceptors)
```
- `lib/mid`
    - `mid/routes/` contains the client generated class for each provided `EndPoints` class on the server side (i.e. the one from `getEndPoints` function).
    - `mid/models/` contains the "data class" for each User Defined Type that was found in any return statement or argument of an `Endpoints` method
    - `mid/client.dart` is the generated client handle requests of each endpoint within any route located in `routes` (e.g. `client.route1.method(...)`).
    - `mid/routes.dart` just a file doing `export` to each route in `lib/mid/routes`
    - `mid/models.dart` just a file doing `export` to each model in `lib/mid/moedls`

- `lib/interceptors.dart` just a file doing `export` for types from `mid_client`, `mid_protocol` and `http` that are necessary to create interceptors.
- `lib/<project_name>_client.dart` is the library file taht `export` both `mid/models.dart` and `mid/client.dart` 

The client project is entirely composed of generated code. If it's necessary to create files and such within the project, refrain from placing anything within `mid` (e.g. `lib/src` is fine). 

