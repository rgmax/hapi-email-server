exports.register = (server, options, next) ->
  next()

exports.register.attributes = {
    pkg: require('../package.json')
}
