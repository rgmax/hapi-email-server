exports.register = (server, options, next) ->
  label = options.config.label || 'mail'
  ns = server.select label
  ns.route require('./routes') ns, options
  next()

exports.register.attributes = {
    pkg: require('../package.json')
}
