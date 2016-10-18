Joi = require 'joi'

module.exports = class Validator

  subscribe:
    params:
      trigger_point: Joi.string().required()
    payload:
      emails: Joi.array().items( Joi.string().email() ).required()

  subscribers:
    params:
      trigger_point: Joi.string().required()

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

  unsubscribe_list:
    params:
      email: Joi.string().email().required()
