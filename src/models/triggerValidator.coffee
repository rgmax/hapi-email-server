Joi = require 'joi'

module.exports = class Validator

  subscribe:
    params:
      trigger_point: Joi.string().required()
    payload:
      emails: Joi.array().items( Joi.string().email() ).required()

  delete_all_subscribers:
    params:
      trigger_point: Joi.string().required()

  subscribers:
    params:
      trigger_point: Joi.string().required()

  post:
    params:
      trigger_point: Joi.string().required()
    payload:
      data: Joi.object().required()
      email: Joi.alternatives().try(
        Joi.string().email(),
        Joi.array().items( Joi.string().email() )
      )

  unsubscribe:
    params:
      email: Joi.string().email().required()
    payload:
      trigger_points: Joi.array().items( Joi.string() )

  unsubscribe_list:
    params:
      email: Joi.string().email().required()

  validate_mandrill_apiKey:
    query: {}
    payload:
      apiKey: Joi.string().required()
