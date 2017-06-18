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
        email: Joi.alternatives()["try"](Joi.string().email(), Joi.array().items(Joi.string().email()))
      }
    };

    Validator.prototype.unsubscribe = {
      params: {
        email: Joi.string().email().required()
      },
      payload: {
        trigger_points: Joi.array().items(Joi.string())
      }
    };

    Validator.prototype.unsubscribe_list = {
      params: {
        email: Joi.string().email().required()
      }
    };

    Validator.prototype.validate_mandrill_apiKey = {
      query: {},
      payload: {
        apiKey: Joi.string().required()
      }
    };

    return Validator;

  })();

}).call(this);
