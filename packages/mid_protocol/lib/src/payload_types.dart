
// The idea here is to make a type-safe payloads
// Each type correspond to a certain MessageType
// also in that case we may not need MessageType (tho switch case :/ is necessary). 

// abstract class Payload {}

// class InitPayload extends Payload {
//   final String route;

//   InitPayload(this.route);
// }

// class DataPayload<T> extends Payload {
//   final T data;

//   DataPayload(this.data);
// }

// class ErrorPayload extends Payload {
//   final String errorMessage;

//   ErrorPayload(this.errorMessage);
// }
