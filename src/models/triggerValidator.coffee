Joi = require 'joi'

module.exports = class Validator

  subscribe:
    params:
      trigger_point: Joi.string().required()
    payload:
      emails: Joi.array().required()

  post:
    params:
      trigger_point: Joi.string().required()
    payload:
      data: Joi.object().required()
      email: Joi.string().email()

  unsubscribe:
    params:
      email: Joi.string().email().required()
    payload:
      trigger_points: Joi.array().items( Joi.string() ).required()