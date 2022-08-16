/// Indicates that a method or a member of a class is intended for server use only
///
/// When a method of a class (i.e. route) has this annotation, the method will not be
/// generated as an endpoint.
///
/// Similarly, when a member of a custom type has this annotation, the member will
/// not appear in the client generated code.
///
/// Be cautios when annotating a member of a custom type to avoid using the same type
/// as both a return type and an argument type of an endpoint. When doing so, make sure
/// the annotated member is either nullable or has a default value so the server side
/// type can be constructed from the client type (which wouldn't have the member).
///
/// e.g. `Future<UserData> updateData(UserData data) {....}`
///
/// In the case above, if `UserData` has a [serverOnly] member (e.g. `UserData.isBanned`),
/// then `isBanned` must be either nullable or with a default value. This is necessary so
/// that `UserData` can be constructred from the client data which won't have `isBanned`.
const Object serverOnly = _ServerOnly();

class _ServerOnly {
  const _ServerOnly();
}
