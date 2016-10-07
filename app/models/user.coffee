mongoose = require('mongoose')
Schema = mongoose.Schema
bcrypt = require('bcrypt-nodejs')
# user schema 
UserSchema = new Schema(
  name: String
  username:
    type: String
    required: true
    index: unique: true
  password:
    type: String
    required: true
    select: false)
# hash the password before the user is saved
UserSchema.pre 'save', (next) ->
  user = this
  # hash the password only if the password has been changed or user is new
  if !user.isModified('password')
    return next()
  # generate the hash
  bcrypt.hash user.password, null, null, (err, hash) ->
    if err
      return next(err)
    # change the password to the hashed version
    user.password = hash
    next()
    return
  return
# method to compare a given password with the database hash

UserSchema.methods.comparePassword = (password) ->
  user = this
  bcrypt.compareSync password, user.password

module.exports = mongoose.model('User', UserSchema)
