(function() {
  var _;

  _ = require('lodash');

  module.exports = function(server, options) {
    var Trigger;
    Trigger = require("../models/trigger")(server, options);
    return {
      subscribe: function(request, reply) {
        var emails, trigger_point;
        trigger_point = request.params.trigger_point;
        emails = request.payload.emails;
        return Trigger.subscribe(trigger_point, emails).then(function(result) {
          if (result instanceof Error) {
            return reply.fail(result.message);
          }
          return reply.success(true);
        });
      },
      delete_all_subscribers: function(request, reply) {
        var trigger_point;
        trigger_point = request.params.trigger_point;
        return Trigger.delete_all_subscribers(trigger_point).then(function(result) {
          if (result instanceof Error) {
            return reply.fail(result.message);
          }
          return reply.success(true);
        });
      },
      subscribers: function(request, reply) {
        var trigger_point;
        trigger_point = request.params.trigger_point;
        return Trigger.get_subscribers(trigger_point).then(function(result) {
          if (result instanceof Error) {
            return reply.nice({
              list: [],
              total: 0
            });
          }
          return reply.nice({
            list: result,
            total: result.length
          });
        });
      },
      post: function(request, reply) {
        var data, email, trigger_point;
        trigger_point = request.params.trigger_point;
        data = request.payload.data;
        email = request.payload.email;
        if ((email != null) && _.isArray(email) === false) {
          email = [email];
        }
        return Trigger.post(trigger_point, data, email).then(function(result) {
          if (result instanceof Error) {
            return reply.fail(result.message);
          }
          return reply.success(true);
        }).done();
      },
      unsubscribe: function(request, reply) {
        var email, trigger_points;
        email = request.params.email;
        trigger_points = request.payload.trigger_points != null ? request.payload.trigger_points : [];
        return Trigger.unsubscribe(email, trigger_points).then(function(result) {
          if (result instanceof Error) {
            return reply.fail(result.message);
          }
          return reply.success(true);
        });
      },
      unsubscribe_list: function(request, reply) {
        var email;
        email = request.params.email;
        return Trigger.get_email_unsubscribes(email).then(function(result) {
          if (result instanceof Error) {
            return reply.fail(result.message);
          }
          return reply.nice({
            list: result,
            total: result.length
          });
        });
      }
    };
  };

}).call(this);
