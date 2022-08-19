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
2. Open the project in your favorite IDE:
    ```sh
    code quick_start
    ```

3. Head to `quick_start_server/lib/mid/endpoints.dart` file:
    
    a. remove existing code.
    
    b. then paste the following:

    ```dart
    
    // TODO: put endpoints here
    ```

4. Generate the server and client code:
    ```sh
    mid generate all
    ```

5. Head to `quick_start_client/bin/` and create `frontend.dart`:

    Assume this file is your frontend project. Paste the following there:
    ```dart
    // TODO: put client code
    ```

6. Run the frontend app (assuming you're still within `quick_start` directory):
    ```sh
    dart run quick_start_client/bin/frontend.dart
    ```

    This should print the following:




    _file an issue if it doesn't_ 😅