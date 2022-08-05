

/// Annotation on a member of a data model class to indicate that the member should be used on the server only. 
///  
/// In other words, the member should not be present in the client side when the client models are generated.
// Note: The idea here came from the sign-in process where we are taking two trips to the database
//       where the first one gets the hashed password and the second one gets the user if the password is valid.
//       In such case, we can make the hashedPassword part of the User model to get it all in one trip. Though,
//       this may not be an issue so the annotation is not being used yet.  
const Object serverOnly = _ServerOnly();

class _ServerOnly {
  const _ServerOnly();
}
