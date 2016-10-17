Joi = require 'joi'

module.exports = class Validator

  subscribe:
    params:
      trigger_key: Joi.string().required()
    payload:
      emails: Joi.array().items( Joi.string().email() ).required()

  post:
    params:
      trigger_key: Joi.string().required()
    payload:
      email: Joi.string().email()
      data: Joi.object().required()

  unsubscribe:
    params:
      email: Joi.string().email().required()
    payload:
      triggers: Joi.array().items( Joi.string() ).required()