# Packages

The `mid` project currently contains the following packages:

- [`mid`](https://github.com/osaxma/mid/blob/main/packages/mid)
    
    This is the cli package which handles the generation of the server and the client libraries. The package also has the definition of `EndPoints` as well as the annotations library (e.g. `@serverOnly`). 

- [`mid_client`](https://github.com/osaxma/mid/blob/main/packages/mid_client)
    
    This package is imported by the generated client. It contains the http and websocket clients as well as the http client interceptor definition. 

- [`mid_server`](https://github.com/osaxma/mid/blob/main/packages/mid_server)

    This package is imported by the generated server. It contains the http and websocket servers and their configuration (i.e. `ServerConfig`) as well as the http server interceptor definition. 

- [`mid_protocol`](https://github.com/osaxma/mid/blob/main/packages/mid_protocol)

    This package contains the websocket messaging protocol, the message interceptor definition, messages definition and messages types. This package is used by both `mid_client` and `mid_server` and it's also imported by both the generated server and the generated client.  

- [`mid_common`](https://github.com/osaxma/mid/blob/main/packages/mid_common)

    A common package that contains functions, constants and other utilities that  are used by all the other packages.   