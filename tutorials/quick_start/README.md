# Quick Start Tutorial

This is a quick start tutorial that's meant to show how `mid` works.


0. Install `mid` if you haven't:

    ```sh
    dart pub global activate mid
    ```

1. Create a `mid`  project:
    ```sh
    mid create quick_start
    ```
    This will create two dart projects in the following structure:
    ```
    quick_start
        |- quick_start_client
        |- quick_start_server
    ```
2. Open the project in your favorite IDE (e.g. in VS code):
    ```sh
    code quick_start
    ```

3. Create your first endpoints within `quick_start_server` project:

    3.1 Create a file in under `quick_start_server/lib/src` called `quick_start.dart`
    > you can create the file anywhere within lib but avoid creating files within `lib/mid/`

    3.2 Add the following code:
    ```dart
    import 'package:mid/endpoints.dart';

    class Example extends EndPoints {

        String hello(String name) => 'Hello $name!';

        // feel free to add other functions here 
    }
    ```

4. Head to `quick_start_server/lib/mid/endpoints.dart` file:
    
    4.1. Import the `package:quick_start_server/src/example.dart`
    
    4.2 Add the endpoints to the list of returned endpoints such as:

    ```dart
    import 'package:mid/mid.dart';
    import 'package:quick_start_server/src/example.dart';

    Future<List<EndPoints>> getEndPoints() async {
        return <EndPoints>[
            Example(),
        ];
    }
    ```

5. Generate the server and client code by running:
    ```sh
    mid generate all
    ```

5. Now you can import the `client` library into your frotnend project.
    5.1 for simplicity, head to `quick_start_client/bin/` and create `frontend.dart`:

    Assume this file is your frontend. Paste the following there:
    ```dart
    // import the client library
    import 'package:quick_start_client/quick_start_client.dart';

    void main() async {
        // initialize the client
        final client = QuickStartClient(url: 'localhost:8000'); 
        // call the endpoint we created within `Example` route
        final response = await client.example.hello('World');
        print(response);
    }
    ```
6. Run the server (assuming you're still within `quick_start` directory):
    ```sh
    dart run quick_start_server/bin/server.dart
    ```
    This should print the following:
    ```
    Server listening on port 8000
    ```

7. Run the frontend script we just created (assuming you're still within `quick_start` directory):
    ```sh
    dart run quick_start_client/bin/frontend.dart
    ```

    This should print the following:
    ```
    Hello World!
    ```

---

Extras:

- If you like to import the client project into a flutter project quickly, you can do so by running the following within the flutter project (replace `quick_start` with the created project name if different):

    ```
    flutter pub add quick_start_client --source="path" "/path/to/quick_start_client"
    ```

- If you would like to change the server configuration (e.g. port), head to `quick_start_server/bin/server.dart` and change the `ServerConfig`. Also there you can add interceptors for both http and websocket servers.

- If you would like to add client interceptors, check `QuickStartClient` constructor arguments. 

- Please note that the entire `client` library is generated code. You may create your own code within `lib/src` and add any export statements to `quick_starter_client.dart` but make sure not to modify the existing code or anything within `lib/mid`.  


- Finaly the example above was pretty simple but really there isn't anything extra that should be covered here. Just create methods -- e.g.,:
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
