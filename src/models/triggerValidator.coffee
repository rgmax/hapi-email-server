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
      data: Joi.object().required()
      email: Joi.string().email()

  unsubscribe:
    params:
      email: Joi.string().email().required()
    payload:
      triggers: Joi.array().items( Joi.string() ).required()