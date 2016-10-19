(function() {
  var Joi, Validator;

  Joi = require('joi');

  module.exports = Validator = (function() {
    function Validator() {}

    Validator.prototype.subscribe = {
      params: {
        trigger_point: Joi.string().required()
      },
      payload: {
        emails: Joi.array().items(Joi.string().email()).required()
      }
    };

    Validator.prototype.delete_all_subscribers = {
      params: {
        trigger_point: Joi.string().required()
      }
    };

    Validator.prototype.subscribers = {
      params: {
        trigger_point: Joi.string().required()
      }
    };

    Validator.prototype.post = {
      params: {
        trigger_point: Joi.string().required()
      },
      payload: {
        data: Joi.object().required(),
        email: Joi.string().email()
      }
    };

    Validator.prototype.unsubscribe = {
      params: {
        email: Joi.string().email().required()
      },
      payload: {
        trigger_points: Joi.array().items(Joi.string()).required()
      }
    };

    Validator.prototype.unsubscribe_list = {
      params: {
        email: Joi.string().email().required()
      }
    };

    return Validator;

  })();

}).call(this);
