const { errorResponse } = require('../utils/response');

/**
 * Middleware generator for Joi schema validation
 * @param {import('joi').ObjectSchema} schema - Joi validation schema
 * @param {'body'|'query'|'params'} source - Request property to validate
 */
function validate(schema, source = 'body') {
  return (req, res, next) => {
    const { error, value } = schema.validate(req[source], {
      abortEarly: false,
      stripUnknown: true
    });

    if (error) {
      const details = error.details.map((item) => ({
        field: item.path.join('.'),
        message: item.message.replace(/['"]/g, '')
      }));

      return errorResponse(res, 'Validasi input gagal', 400, details);
    }

    // Assign sanitized/cast values back
    req[source] = value;
    return next();
  };
}

module.exports = validate;
