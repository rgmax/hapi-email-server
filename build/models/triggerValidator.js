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
        emails: Joi.array().required()
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

    return Validator;

  })();

}).call(this);
