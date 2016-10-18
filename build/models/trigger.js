(function() {
  var Path, Q, _, jade;

  _ = require("lodash");

  Q = require("q");

  jade = require('jade');

  Path = require('path');

  module.exports = function(server, options) {
    var Trigger, bucket, mailgun;
    bucket = options.database;
    mailgun = require('mailgun-js')({
      apiKey: options.config.api_key,
      domain: options.config.domain
    });
    return Trigger = (function() {
      function Trigger() {}

      Trigger.prototype.PREFIX = "postoffice";

      Trigger.prototype.POSTFIX = "unsubscribe";

      Trigger.subscribe = function(trigger_point, emails) {
        var _this;
        _this = this;
        return this.get_trigger_event(trigger_point).then(function(trigger_event) {
          var doc, trigger_key;
          if (trigger_event instanceof Error) {
            return trigger_event;
          }
          trigger_key = _this._trigger_key(trigger_point);
          doc = {
            subscribers: emails
          };
          return bucket.get(trigger_key).then(function(d) {
            if (d instanceof Error) {
              return bucket.insert(trigger_key, doc);
            } else {
              return bucket.replace(trigger_key, doc);
            }
          });
        });
      };

      Trigger.post = function(trigger_point, data, email) {
        var _this;
        _this = this;
        return this.get_trigger_event(trigger_point).then(function(trigger_event) {
          if (trigger_event instanceof Error) {
            return trigger_event;
          }
          if (email != null) {
            return _this.render_emails_data(trigger_event, data, [email]).then(function(emails_data) {
              return _this.send(emails_data[0]);
            });
          } else {
            return _this.get_subscribers(trigger_point).then(function(emails) {
              if (emails instanceof Error) {
                return emails;
              }
              return _this.render_emails_data(trigger_event, data, emails).then(function(emails_data) {
                var promises;
                promises = [];
                _.each(emails_data, function(email_data) {
                  return promises.push(_this.send(email_data));
                });
                return Q.all(promises);
              });
            });
          }
        });
      };

      Trigger.send = function(email_data) {
        var deferred;
        deferred = Q.defer();
        if (options.config.mock) {
          console.log("From: " + email_data.from);
          console.log("To: " + email_data.to);
          console.log("Subject: " + email_data.subject);
          console.log(email_data.html);
          deferred.resolve(true);
        } else {
          mailgun.messages().send(email_data, function(error, body) {
            if (error) {
              return deferred.reject(new Error(error));
            } else {
              return deferred.resolve(body);
            }
          });
        }
        return deferred.promise;
      };

      Trigger.unsubscribe = function(email, trigger_points) {
        var doc, key;
        key = this._unsubscribe_key(email);
        doc = {
          trigger_points: trigger_points
        };
        return bucket.get(key).then(function(d) {
          if (d instanceof Error) {
            return bucket.insert(key, doc);
          } else {
            return bucket.replace(key, doc);
          }
        });
      };

      Trigger.get_trigger_event = function(trigger_point) {
        var parts, trigger_event, trigger_events;
        parts = trigger_point.split(":");
        trigger_event = parts[parts.length - 1];
        trigger_events = _.keys(options.config.trigger_events);
        if (trigger_events.indexOf(trigger_event) < 0) {
          return Q(new Error("Trigger event '" + trigger_event + "' is not defined!"));
        }
        return Q(trigger_event);
      };

      Trigger.get_subscribers = function(trigger_point) {
        var key;
        key = this._trigger_key(trigger_point);
        return bucket.get(key).then(function(d) {
          if (d instanceof Error || d.value.subscribers.length === 0) {
            return new Error("There isn't any subscriber for trigger point: " + trigger_point);
          }
          return d.value.subscribers;
        });
      };

      Trigger.render_emails_data = function(trigger_event, data, emails) {
        var emails_data, html, subject, template;
        template = Path.join(options.config.root, options.config.trigger_events[trigger_event].template);
        html = jade.renderFile(template, _.extend({}, data, {
          base: options.url,
          scheme: options.scheme
        }));
        subject = options.config.trigger_events[trigger_event].subject;
        emails_data = [];
        _.each(emails, function(email) {
          return emails_data.push({
            from: options.config.from,
            to: email,
            subject: subject,
            html: html
          });
        });
        return Q(emails_data);
      };

      Trigger._trigger_key = function(trigger_point) {
        return Trigger.prototype.PREFIX + ":" + trigger_point;
      };

      Trigger._unsubscribe_key = function(email) {
        return Trigger.prototype.PREFIX + ":" + email + ":" + Trigger.prototype.POSTFIX;
      };

      return Trigger;

    })();
  };

}).call(this);