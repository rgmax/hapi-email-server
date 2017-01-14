(function() {
  var Path, Q, _, fs, jade;

  _ = require("lodash");

  Q = require("q");

  jade = require('jade');

  Path = require('path');

  fs = require('fs-extra');

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
            return _this.check_if_email_unsubscribed(email, trigger_point).then(function(unsubscribed) {
              if (unsubscribed) {
                return new Error("Email has un-subscribed from trigger point: " + trigger_point);
              }
              return _this.render_emails_data(trigger_event, data, [email]).then(function(emails_data) {
                return _this.send(emails_data[0]);
              });
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
        var deferred, file;
        deferred = Q.defer();
        if (options.config.mock) {
          if (options.config.trace) {
            console.log("From: " + email_data.from);
            console.log("To: " + email_data.to);
            console.log("Subject: " + email_data.subject);
            console.log(email_data.html);
          }
          if (options.config.dump) {
            file = Path.join(options.config.dump_path, email_data.to + "_" + email_data.subject + ".html");
            this.dir_ensure(file).then(function(err) {
              return fs.writeFile(file, email_data.html, function(error) {
                if (error) {
                  return deferred.resolve(new Error(error));
                } else {
                  return deferred.resolve(file);
                }
              });
            });
          } else {
            deferred.resolve(true);
          }
        } else {
          mailgun.messages().send(email_data, function(error, body) {
            if (error) {
              return deferred.resolve(new Error(error));
            } else {
              return deferred.resolve(body);
            }
          });
        }
        return deferred.promise;
      };

      Trigger.check_if_email_unsubscribed = function(email, trigger_point) {
        return this.get_email_unsubscribes(email).then(function(trigger_points) {
          if (trigger_points.indexOf(trigger_point) >= 0) {
            return true;
          }
          return false;
        });
      };

      Trigger.get_email_unsubscribes = function(email) {
        var key;
        key = this._unsubscribe_key(email);
        return bucket.get(key).then(function(d) {
          if (d instanceof Error) {
            return [];
          }
          return d.value.trigger_points;
        });
      };

      Trigger.unsubscribe = function(email, trigger_points) {
        var _this, key, promises;
        if (trigger_points.length === 0) {
          return this.delete_all_unsubscribe(email);
        }
        key = this._unsubscribe_key(email);
        _this = this;
        promises = [];
        _.each(trigger_points, function(trigger_point) {
          return promises.push(_this.get_trigger_event(trigger_point));
        });
        return Q.all(promises).then(function(results) {
          var doc, error_found;
          error_found = false;
          _.each(results, function(result) {
            if (result instanceof Error) {
              return error_found = true;
            }
          });
          if (error_found) {
            return new Error('List contains unknown trigger events.');
          }
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
        });
      };

      Trigger.delete_all_unsubscribe = function(email) {
        var doc, key;
        key = this._unsubscribe_key(email);
        doc = {
          trigger_points: []
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

      Trigger.delete_all_subscribers = function(trigger_point) {
        var _this;
        _this = this;
        return this.get_trigger_event(trigger_point).then(function(trigger_event) {
          var doc, trigger_key;
          if (trigger_event instanceof Error) {
            return trigger_event;
          }
          trigger_key = _this._trigger_key(trigger_point);
          doc = {
            subscribers: []
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

      Trigger.render_emails_data = function(trigger_event, data, emails) {
        var emails_data, html, ref, subject, template;
        template = Path.join(options.config.root, options.config.trigger_events[trigger_event].template);
        html = jade.renderFile(template, _.extend({}, data, {
          base: options.url,
          scheme: options.scheme
        }));
        subject = ((ref = data.meta) != null ? ref.subject : void 0) != null ? data.meta.subject : options.config.trigger_events[trigger_event].subject;
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

      Trigger.dir_ensure = function(path) {
        var deferred;
        deferred = Q.defer();
        fs.ensureDir(Path.dirname(path), function(err) {
          return deferred.resolve();
        });
        return deferred.promise;
      };

      return Trigger;

    })();
  };

}).call(this);
