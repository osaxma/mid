List<Object> endpoints() {
  return [
    EndPoint(),
  ];
}

class EndPoint {
  Future<ReturnData> method1(Data data, String _, int __) => throw UnimplementedError();
}

class ReturnData {
  final int id;
  final String name;
  final InnerData innerData;
  ReturnData({
    required this.id,
    required this.name,
    required this.innerData,
  });
}

class Data {
  final int id;
  final String name;
  final InnerData innerData;
  Data({
    required this.id,
    required this.name,
    required this.innerData,
  });
}

class InnerData {
  final num number;
  final DeepData metaData;
  InnerData({
    required this.number,
    required this.metaData,
  });
}

class DeepData {}
