(function() {
  exports.register = function(server, options, next) {
    var label, ns;
    label = options.config.label || 'mail';
    ns = server.select(label);
    ns.route(require('./routes')(ns, options));
    return next();
  };

  exports.register.attributes = {
    pkg: require('../package.json')
  };

}).call(this);
