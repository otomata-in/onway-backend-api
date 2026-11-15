class ApiResponse {
  static success(res, data, message = 'Success', statusCode = 200, meta = null) {
    const payload = {
      success: true,
      message,
      data,
    };
    if (meta) {
      payload.meta = meta;
    }
    return res.status(statusCode).json(payload);
  }

  static created(res, data, message = 'Resource created successfully') {
    return this.success(res, data, message, 201);
  }

  static paginated(res, data, total, page, limit, message = 'Success') {
    return this.success(res, data, message, 200, {
      total,
      page: parseInt(page, 10),
      limit: parseInt(limit, 10),
      totalPages: Math.ceil(total / limit),
      hasMore: page * limit < total,
    });
  }
}

module.exports = ApiResponse;

