User = require('../models/user')
jwt = require('jsonwebtoken')
config = require('../../config')
# super secret for creating tokens
superSecret = config.secret

module.exports = (app, express) ->
  apiRouter = express.Router()
  # route to authenticate a user (POST http://localhost:8080/api/authenticate)
  apiRouter.post '/authenticate', (req, res) ->
    console.log req.body.username
    # find the user
    User.findOne(username: req.body.username).select('name username password').exec (err, user) ->
      if err
        throw err
      # no user with that username was found
      if !user
        res.json
          success: false
          message: 'Authentication failed. User not found.'
      else if user
        # check if password matches
        validPassword = user.comparePassword(req.body.password)
        if !validPassword
          res.json
            success: false
            message: 'Authentication failed. Wrong password.'
        else
          # if user is found and password is right
          # create a token
          token = jwt.sign({
            name: user.name
            username: user.username
          }, superSecret, expiresIn: '24h')
          # return the information including token as JSON
          res.json
            success: true
            message: 'Enjoy your token!'
            token: token
      return
    return
  # route middleware to verify a token
  apiRouter.use (req, res, next) ->
    # do logging
    console.log 'Somebody just came to our app!'
    # check header or url parameters or post parameters for token
    token = req.body.token or req.query.token or req.headers['x-access-token']
    # decode token
    if token
      # verifies secret and checks exp
      jwt.verify token, superSecret, (err, decoded) ->
        if err
          return res.json(
            success: false
            message: 'Failed to authenticate token.')
        else
          req.decoded = decoded
        return
    else
      # if there is no token
      # return an HTTP response of 403 (access forbidden) and an error message
      return res.status(403).send(
        success: false
        message: 'No token provided.')
    next()
    # make sure we go to the next routes and don't stop here
    return
  # test route to make sure everything is working 
  # accessed at GET http://localhost:8080/api
  apiRouter.get '/', (req, res) ->
    res.json message: 'hooray! welcome to our api!'
    return
  # on routes that end in /users
  # ----------------------------------------------------
  apiRouter.route('/users').post((req, res) ->
    user = new User
    # create a new instance of the User model
    user.name = req.body.name
    # set the users name (comes from the request)
    user.username = req.body.username
    # set the users username (comes from the request)
    user.password = req.body.password
    # set the users password (comes from the request)
    user.save (err) ->
      if err
        # duplicate entry
        if err.code == 11000
          return res.json(
            success: false
            message: 'A user with that username already exists. ')
        else
          return res.send(err)
      # return a message
      res.json message: 'User created!'
      return
    return
  ).get (req, res) ->
    User.find (err, users) ->
      if err
        res.send err
      # return the users
      res.json users
      return
    return
  # on routes that end in /users/:user_id
  # ----------------------------------------------------
  apiRouter.route('/users/:user_id').get((req, res) ->
    User.findById req.params.user_id, (err, user) ->
      if err
        res.send err
      # return that user
      res.json user
      return
    return
  ).put((req, res) ->
    User.findById req.params.user_id, (err, user) ->
      if err
        res.send err
      # set the new user information if it exists in the request
      if req.body.name
        user.name = req.body.name
      if req.body.username
        user.username = req.body.username
      if req.body.password
        user.password = req.body.password
      # save the user
      user.save (err) ->
        if err
          res.send err
        # return a message
        res.json message: 'User updated!'
        return
      return
    return
  ).delete (req, res) ->
    User.remove { _id: req.params.user_id }, (err, user) ->
      if err
        res.send err
      res.json message: 'Successfully deleted'
      return
    return
  apiRouter
