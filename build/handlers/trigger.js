(function() {
  module.exports = function(server, options) {
    var Trigger;
    Trigger = require("../models/trigger")(server, options);
    return {
      trigger: {
        subscribe: function(request, reply) {
          var emails, trigger_point;
          trigger_point = request.params.trigger_point;
          emails = request.payload.emails;
          return Trigger.subscribe(trigger_point, emails).then(function(result) {
            if (result instanceof Error) {
              return reply.fail(result.message);
            }
            return reply.success(result);
          });
        },
        post: function(request, reply) {
          var data, email, trigger_point;
          trigger_point = request.params.trigger_point;
          data = request.payload.data;
          email = request.payload.email;
          return Trigger.post(trigger_point, data, email).then(function(result) {
            if (result instanceof Error) {
              return reply.fail(result.message);
            }
            return reply.success(result);
          });
        },
        unsubscribe: function(request, reply) {
          var email, trigger_points;
          email = request.params.email;
          trigger_points = request.payload.trigger_points;
          return Trigger.unsubscribe(email, trigger_points).then(function(result) {
            if (result instanceof Error) {
              return reply.fail(result.message);
            }
            return reply.success(result);
          });
        }
      }
    };
  };

}).call(this);
