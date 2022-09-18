import 'dart:convert';

class Sample {
  final String string;
  final int integer;
  Sample({
    required this.string,
    required this.integer,
  });

  Sample copyWith({
    String? string,
    int? integer,
  }) {
    return Sample(
      string: string ?? this.string,
      integer: integer ?? this.integer,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'string': string,
      'integer': integer,
    };
  }

  factory Sample.fromMap(Map<String, dynamic> map) {
    return Sample(
      string: map['string'] as String,
      integer: map['integer'] as int,
    );
  }

  String toJson() => json.encode(toMap());

  factory Sample.fromJson(String source) => Sample.fromMap(json.decode(source) as Map<String, dynamic>);

  @override
  String toString() => 'Sample(string: $string, integer: $integer)';

  @override
  bool operator ==(covariant Sample other) {
    if (identical(this, other)) return true;

    return other.string == string && other.integer == integer;
  }

  @override
  int get hashCode => string.hashCode ^ integer.hashCode;
}
