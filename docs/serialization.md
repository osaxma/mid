# Serialization 

When creating `EndPoints` classes in a `mid` project, the tool allows using User Defined Classes in as a return type or as an argument. In order to generate an end-to-end typesafe API, `mid` needs to serialize these types in both sides -- the client and the server. For the sake of simplicity, let's take the following class as an example for the rest of this document:

- the endpoint:
    ```dart
    class Auth extends EndPoints {
    Future<UserData> getUserData(int userID) => throw UnimplementedError();
    }
    ```
- User Defined Classes:
    ```dart
    class UserData {
      final int id;
      final String name;
      final bool isAdmin;
      final MetaData? metadata;

      UserData({
        required this.id,
        required this.name,
        this.metadata,
        this.isAdmin = false,
      });
    }

    class MetaData {
      final Map<String, dynamic> extra;
      final Connectioninfo connectioninfo;

      MetaData(this.extra, this.connectioninfo);
    }

    class Connectioninfo {
      final String ip;
      final bool isSecure;

      Connectioninfo(this.ip, this.isSecure);
    }

    ```

Since `UserData` is a return type of an endpoint, then `mid` will generate the serialization for it in both the client and the server. `mid` will also recursively inspect each member of `UserData` as well as their members to check if they're User Defined Classes. Once `mid` collects all the User Defined Classes, it will serialize all the of them -- namely: `UserData`, `MetaData`, and `ConnectionInfo` in the given example. This type collection process is carried for each User Defined Types that appear in a return statement or an argument of an endpoint.

The only limitation is that the class must have a unnamed-generative-constructor with formal parameters (i.e. using `this` keyword). This is a limitation because otherwise the serializers need to figure out how each parameter is initialized and that can be quite complex if not impossible. It's advisable that all return types and arguments types of endpoints to be immutable for User Defined Classes -- even better if the User Defined Classes are marked with `@immutable` annotation from the [meta][] package.

[meta]: https://pub.dev/packages/meta

That being said, the following two sections will discuss how each side of the `mid` project is serialized. 

## Server Side Serialization

Since `mid` allows returning any `EndPoints` class whether it's defined within a `mid_server` project or from an external package, this introduces a limitation on how server side serialization is carried. The main issue is the inability to generate the source code in a different package and to avoid modifying the source code of the user. 

While requiring the developer to provide `toJson/toMap` methods or `fromJson/fromMap` factories for serialization, this isn't ideal since the user may need to handle serialization quirks when retreiving data from external sources such as a database or a 3rd party api. For instance, the `key` of the serialized objects may be `snake_case` and needs conversion to `camelCase`, or the `DateTime` may need some preprocessing to add the timezone designator and so on. 

For these reasons, `mid` generates the serialization code in a separate file (i.e. `<project_name>_server/lib/mid/generated/serializers.dart`). Taking the example from earlier, the serialization output would look like the following:

```dart
class UserDataSerializer {
  static Map<String, dynamic> toMap(UserData instance) {
    return {
      'id': instance.id,
      'name': instance.name,
      'metadata': instance.metadata == null ? null : MetaDataSerializer.toMap(instance.metadata!),
      'isAdmin': instance.isAdmin,
    };
  }

  static UserData fromMap(Map<String, dynamic> map) {
    return UserData(
      id: map['id'] as int,
      name: map['name'] as String,
      metadata: map['metadata'] == null ? null : MetaDataSerializer.fromMap(map['metadata']),
      isAdmin: map['isAdmin'] as bool,
    );
  }
}

class MetaDataSerializer {
  static Map<String, dynamic> toMap(MetaData instance) {
    return {
      'extra': instance.extra,
      'connectioninfo': ConnectioninfoSerializer.toMap(instance.connectioninfo),
    };
  }

  static MetaData fromMap(Map<String, dynamic> map) {
    return MetaData(
      map['extra'],
      ConnectioninfoSerializer.fromMap(map['connectioninfo']),
    );
  }
}

class ConnectioninfoSerializer {
  static Map<String, dynamic> toMap(Connectioninfo instance) {
    return {
      'ip': instance.ip,
      'isSecure': instance.isSecure,
    };
  }

  static Connectioninfo fromMap(Map<String, dynamic> map) {
    return Connectioninfo(
      map['ip'] as String,
      map['isSecure'] as bool,
    );
  }
}
```

The generated code above is used by the handlers to deserialize requests and serialize responses. This generated code is placed within the lib directory of the server project `<project_name>_server/lib/mid/generated/serializers.dart` so the developer can feel free to take advantage of them. 

It's also worth noting that User Defined Classes such as `UserData` could have their own serialization method/factories and any other methods (e.g. `copyWith`). `mid` only inspects the constructor of the User Defined Class. 


## Client Side Serialization

Since the client project is entirely generated by `mid`, there is a freedom in how the serialization code is generated. The code is generated at `<project_name>_client/lib/mid/models/` and all the models are exported by the client library (i.e. `package:<project_name>_client/<project_name>_client.dart`)

Given that, there's nothing much to discuss here and this is the output of the generated client side serialization for the same example:

- `<project_name>_client/lib/mid/models/user_data.dart`
    ```dart
    class UserData {
      const UserData({
        required this.id,
        required this.name,
        this.metadata,
        this.isAdmin = false,
      });
    
      factory UserData.fromMap(Map<String, dynamic> map) {
        return UserData(
          id: map['id'] as int,
          name: map['name'] as String,
          metadata: map['metadata'] == null ? null : MetaData.fromMap(map['metadata']),
          isAdmin: map['isAdmin'] as bool,
        );
      }
    
      factory UserData.fromJson(String source) => UserData.fromMap(json.decode(source));
    
      final int id;
    
      final String name;
    
      final MetaData? metadata;
    
      final bool isAdmin;
    
      String toJson() => json.encode(toMap());
      Map<String, dynamic> toMap() {
        return {
          'id': id,
          'name': name,
          'metadata': metadata?.toMap(),
          'isAdmin': isAdmin,
        };
      }
    
      UserData copyWith({
        int? id,
        String? name,
        MetaData? metadata,
        bool? isAdmin,
      }) {
        return UserData(
          id: id ?? this.id,
          name: name ?? this.name,
          metadata: metadata ?? this.metadata,
          isAdmin: isAdmin ?? this.isAdmin,
        );
      }
    
      @override
      bool operator ==(Object other) {
        if (identical(this, other)) return true;
    
        return other is UserData &&
            other.id == id &&
            other.name == name &&
            other.metadata == metadata &&
            other.isAdmin == isAdmin;
      }
    
      @override
      int get hashCode {
        return id.hashCode ^ name.hashCode ^ metadata.hashCode ^ isAdmin.hashCode;
      }
    
      @override
      String toString() {
        return 'UserData(id: $id, name: $name, metadata: $metadata, isAdmin: $isAdmin)';
      }
    }
    ```
- `<project_name>_client/lib/mid/models/meta_data.dart`
    ```dart
    class MetaData {
      const MetaData({
        required this.extra,
        required this.connectioninfo,
      });

      factory MetaData.fromMap(Map<String, dynamic> map) {
        return MetaData(
          extra: map['extra'],
          connectioninfo: Connectioninfo.fromMap(map['connectioninfo']),
        );
      }

      factory MetaData.fromJson(String source) => MetaData.fromMap(json.decode(source));

      final Map<String, dynamic> extra;

      final Connectioninfo connectioninfo;

      String toJson() => json.encode(toMap());
      Map<String, dynamic> toMap() {
        return {
          'extra': extra,
          'connectioninfo': connectioninfo.toMap(),
        };
      }

      MetaData copyWith({
        Map<String, dynamic>? extra,
        Connectioninfo? connectioninfo,
      }) {
        return MetaData(
          extra: extra ?? this.extra,
          connectioninfo: connectioninfo ?? this.connectioninfo,
        );
      }

      @override
      bool operator ==(Object other) {
        if (identical(this, other)) return true;
        final collectionEquals = const DeepCollectionEquality().equals;

        return other is MetaData && collectionEquals(other.extra, extra) && other.connectioninfo == connectioninfo;
      }

      @override
      int get hashCode {
        return extra.hashCode ^ connectioninfo.hashCode;
      }

      @override
      String toString() {
        return 'MetaData(extra: $extra, connectioninfo: $connectioninfo)';
      }
    }
    ```

- `<project_name>_client/lib/mid/models/connection_info.dart`
    ```dart
    class Connectioninfo {
      const Connectioninfo({
        required this.ip,
        required this.isSecure,
      });

      factory Connectioninfo.fromMap(Map<String, dynamic> map) {
        return Connectioninfo(
          ip: map['ip'] as String,
          isSecure: map['isSecure'] as bool,
        );
      }

      factory Connectioninfo.fromJson(String source) => Connectioninfo.fromMap(json.decode(source));

      final String ip;

      final bool isSecure;

      String toJson() => json.encode(toMap());
      Map<String, dynamic> toMap() {
        return {
          'ip': ip,
          'isSecure': isSecure,
        };
      }

      Connectioninfo copyWith({
        String? ip,
        bool? isSecure,
      }) {
        return Connectioninfo(
          ip: ip ?? this.ip,
          isSecure: isSecure ?? this.isSecure,
        );
      }

      @override
      bool operator ==(Object other) {
        if (identical(this, other)) return true;

        return other is Connectioninfo && other.ip == ip && other.isSecure == isSecure;
      }

      @override
      int get hashCode {
        return ip.hashCode ^ isSecure.hashCode;
      }

      @override
      String toString() {
        return 'Connectioninfo(ip: $ip, isSecure: $isSecure)';
      }
    }
    ```

- `<project_name>_client/lib/mid/models.dart` will contain an export statement for each file:

    ```dart
    export 'models/user_data.dart';
    export 'models/meta_data.dart';
    export 'models/connection_info.dart';
    ```