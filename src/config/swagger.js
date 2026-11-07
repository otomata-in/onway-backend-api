const swaggerJsdoc = require('swagger-jsdoc');

const options = {
  definition: {
    openapi: '3.0.0',
    info: {
      title: 'OnWay Market API',
      version: '1.0.0',
      description: 'Hyperlocal marketplace API for moving street vendors. Connects buyers with nearby vendors in real-time using location-based services.',
      contact: {
        name: 'OnWay Team',
      },
    },
    servers: [
      {
        url: '/',
        description: 'Current Environment (AWS / Local)',
      },
    ],
    components: {
      securitySchemes: {
        BearerAuth: {
          type: 'http',
          scheme: 'bearer',
          description: 'Auth token received from /auth/verify-otp',
        },
      },
      schemas: {
        // ─── Common ─────────────────────────────────────────────
        ApiResponse: {
          type: 'object',
          properties: {
            success: { type: 'boolean', example: true },
            message: { type: 'string', example: 'Operation successful' },
            data: { type: 'object' },
          },
        },
        ErrorResponse: {
          type: 'object',
          properties: {
            error: { type: 'boolean', example: true },
            message: { type: 'string' },
            code: { type: 'string' },
          },
        },

        // ─── Auth ───────────────────────────────────────────────
        SendOTPRequest: {
          type: 'object',
          required: ['mobile'],
          properties: {
            mobile: { type: 'string', example: '+919876543210', description: 'Phone number with country code' },
          },
        },
        VerifyOTPRequest: {
          type: 'object',
          required: ['mobile', 'otp'],
          properties: {
            mobile: { type: 'string', example: '+919876543210' },
            otp: { type: 'string', example: '12345', minLength: 4, maxLength: 6, description: '5-digit OTP from Twilio SMS' },
          },
        },

        // ─── User ───────────────────────────────────────────────
        User: {
          type: 'object',
          properties: {
            id: { type: 'integer', example: 1 },
            mobile: { type: 'string', example: '+919876543210' },
            role: { type: 'string', enum: ['buyer', 'seller'], example: 'buyer' },
            fcm_token: { type: 'string', nullable: true },
          },
        },

        // ─── Vendor ─────────────────────────────────────────────
        Vendor: {
          type: 'object',
          properties: {
            id: { type: 'integer', example: 1 },
            user_id: { type: 'integer', example: 1 },
            is_active: { type: 'boolean', example: true },
            lat: { type: 'number', format: 'double', example: 12.9716 },
            lng: { type: 'number', format: 'double', example: 77.5946 },
          },
        },
        NearbyVendor: {
          type: 'object',
          properties: {
            id: { type: 'integer' },
            user_id: { type: 'integer' },
            mobile: { type: 'string' },
            lat: { type: 'number', format: 'double' },
            lng: { type: 'number', format: 'double' },
            is_active: { type: 'boolean' },
            distance_km: { type: 'number', format: 'double', example: 1.23 },
          },
        },

        // ─── Item ───────────────────────────────────────────────
        Item: {
          type: 'object',
          properties: {
            id: { type: 'integer' },
            name: { type: 'string', example: 'Fresh Mangoes' },
            price: { type: 'number', format: 'double', example: 150.00 },
            quantity: { type: 'integer', example: 50 },
            is_available: { type: 'boolean', example: true },
          },
        },
        CreateItemRequest: {
          type: 'object',
          required: ['name', 'price'],
          properties: {
            name: { type: 'string', example: 'Fresh Mangoes' },
            price: { type: 'number', example: 150.00 },
            quantity: { type: 'integer', example: 50 },
          },
        },

        // ─── Order ──────────────────────────────────────────────
        Order: {
          type: 'object',
          properties: {
            id: { type: 'integer' },
            buyer_id: { type: 'integer' },
            vendor_id: { type: 'integer' },
            status: { type: 'string', enum: ['requested', 'accepted', 'rejected', 'fulfilled', 'expired'] },
            type: { type: 'string', example: 'token' },
            buyer_lat: { type: 'number', format: 'double' },
            buyer_lng: { type: 'number', format: 'double' },
          },
        },
        CreateOrderRequest: {
          type: 'object',
          required: ['vendor_id', 'items', 'buyer_lat', 'buyer_lng'],
          properties: {
            vendor_id: { type: 'integer', example: 1 },
            buyer_lat: { type: 'number', example: 12.9716 },
            buyer_lng: { type: 'number', example: 77.5946 },
            items: {
              type: 'array',
              items: {
                type: 'object',
                properties: {
                  item_id: { type: 'integer', example: 1 },
                  qty: { type: 'integer', example: 2 },
                },
              },
            },
          },
        },

        // ─── Route ──────────────────────────────────────────────
        VendorRoute: {
          type: 'object',
          properties: {
            id: { type: 'integer' },
            vendor_id: { type: 'integer' },
            name: { type: 'string', example: 'Morning Route' },
            is_active: { type: 'boolean' },
            points: {
              type: 'array',
              items: {
                type: 'object',
                properties: {
                  id: { type: 'integer' },
                  lat: { type: 'number', format: 'double' },
                  lng: { type: 'number', format: 'double' },
                  sequence: { type: 'integer' },
                },
              },
            },
          },
        },
        CreateRouteRequest: {
          type: 'object',
          required: ['name', 'points'],
          properties: {
            name: { type: 'string', example: 'Morning Route' },
            points: {
              type: 'array',
              items: {
                type: 'object',
                required: ['lat', 'lng', 'sequence'],
                properties: {
                  lat: { type: 'number', example: 12.9716 },
                  lng: { type: 'number', example: 77.5946 },
                  sequence: { type: 'integer', example: 0 },
                },
              },
            },
          },
        },

        // ─── ETA ────────────────────────────────────────────────
        VendorETA: {
          type: 'object',
          properties: {
            vendor_id: { type: 'integer' },
            distance_km: { type: 'number', format: 'double', example: 2.5 },
            eta_minutes: { type: 'integer', example: 10 },
            speed_assumption_kmh: { type: 'integer', example: 15 },
            has_active_route: { type: 'boolean' },
          },
        },
      },
    },
    tags: [
      { name: 'Auth', description: 'OTP-based authentication' },
      { name: 'User', description: 'User profile management' },
      { name: 'Seller', description: 'Seller registration and dashboard' },
      { name: 'Inventory', description: 'Seller item management' },
      { name: 'Vendor', description: 'Buyer-facing vendor discovery' },
      { name: 'Order', description: 'Order lifecycle management' },
      { name: 'Route', description: 'Vendor route management' },
      { name: 'Admin', description: 'Admin endpoints' },
    ],
    paths: {
      // ─── Auth ─────────────────────────────────────────────────
      '/auth/send-otp': {
        post: {
          tags: ['Auth'], summary: 'Send OTP to phone number',
          requestBody: { required: true, content: { 'application/json': { schema: { $ref: '#/components/schemas/SendOTPRequest' } } } },
          responses: { 200: { description: 'OTP sent successfully' }, 429: { description: 'Rate limit exceeded' } },
        },
      },
      '/auth/verify-otp': {
        post: {
          tags: ['Auth'], summary: 'Verify OTP and get auth token',
          requestBody: { required: true, content: { 'application/json': { schema: { $ref: '#/components/schemas/VerifyOTPRequest' } } } },
          responses: { 200: { description: 'Auth token + user data' }, 400: { description: 'Invalid or expired OTP' } },
        },
      },
      '/auth/logout': {
        post: {
          tags: ['Auth'], summary: 'Logout and invalidate token',
          security: [{ BearerAuth: [] }],
          responses: { 200: { description: 'Logged out successfully' } },
        },
      },

      // ─── User ─────────────────────────────────────────────────
      '/me': {
        get: {
          tags: ['User'], summary: 'Get current user profile',
          security: [{ BearerAuth: [] }],
          responses: { 200: { description: 'User profile with vendor info if seller' } },
        },
      },
      '/me/location': {
        put: {
          tags: ['User'], summary: 'Update user location',
          security: [{ BearerAuth: [] }],
          requestBody: { required: true, content: { 'application/json': { schema: { type: 'object', properties: { lat: { type: 'number' }, lng: { type: 'number' } } } } } },
          responses: { 200: { description: 'Location updated' } },
        },
      },
      '/users/fcm-token': {
        post: {
          tags: ['User'], summary: 'Save FCM push notification token',
          security: [{ BearerAuth: [] }],
          requestBody: { required: true, content: { 'application/json': { schema: { type: 'object', properties: { fcm_token: { type: 'string' } } } } } },
          responses: { 200: { description: 'FCM token saved' } },
        },
      },

      // ─── Seller ───────────────────────────────────────────────
      '/seller/register': {
        post: {
          tags: ['Seller'], summary: 'Register as a seller (buyer → seller upgrade)',
          security: [{ BearerAuth: [] }],
          responses: { 201: { description: 'Seller registered' }, 400: { description: 'Already a seller' } },
        },
      },
      '/seller/dashboard': {
        get: {
          tags: ['Seller'], summary: 'Get seller dashboard (stats + status)',
          security: [{ BearerAuth: [] }],
          responses: { 200: { description: 'Dashboard data' } },
        },
      },
      '/seller/orders': {
        get: {
          tags: ['Seller'], summary: 'Get seller\'s incoming orders',
          security: [{ BearerAuth: [] }],
          parameters: [
            { in: 'query', name: 'status', schema: { type: 'string', enum: ['requested', 'accepted', 'rejected', 'fulfilled', 'expired'] } },
            { in: 'query', name: 'page', schema: { type: 'integer', default: 1 } },
            { in: 'query', name: 'limit', schema: { type: 'integer', default: 20 } },
          ],
          responses: { 200: { description: 'Paginated seller orders' } },
        },
      },

      // ─── Inventory ────────────────────────────────────────────
      '/seller/items': {
        get: {
          tags: ['Inventory'], summary: 'Get seller\'s items',
          security: [{ BearerAuth: [] }],
          responses: { 200: { description: 'Item list' } },
        },
        post: {
          tags: ['Inventory'], summary: 'Add new item',
          security: [{ BearerAuth: [] }],
          requestBody: { required: true, content: { 'application/json': { schema: { $ref: '#/components/schemas/CreateItemRequest' } } } },
          responses: { 201: { description: 'Item created' } },
        },
      },
      '/seller/items/{id}': {
        put: {
          tags: ['Inventory'], summary: 'Update item',
          security: [{ BearerAuth: [] }],
          parameters: [{ in: 'path', name: 'id', required: true, schema: { type: 'integer' } }],
          responses: { 200: { description: 'Item updated' } },
        },
        delete: {
          tags: ['Inventory'], summary: 'Soft delete item',
          security: [{ BearerAuth: [] }],
          parameters: [{ in: 'path', name: 'id', required: true, schema: { type: 'integer' } }],
          responses: { 200: { description: 'Item deleted' } },
        },
      },

      // ─── Vendor ───────────────────────────────────────────────
      '/vendors/nearby': {
        get: {
          tags: ['Vendor'], summary: 'Find nearby active vendors',
          security: [{ BearerAuth: [] }],
          parameters: [
            { in: 'query', name: 'lat', required: true, schema: { type: 'number' }, description: 'Buyer latitude' },
            { in: 'query', name: 'lng', required: true, schema: { type: 'number' }, description: 'Buyer longitude' },
            { in: 'query', name: 'radius', schema: { type: 'number', default: 5 }, description: 'Radius in km (max 50)' },
          ],
          responses: { 200: { description: 'Array of nearby vendors with distance' } },
        },
      },
      '/vendors/favorites': {
        get: {
          tags: ['Vendor'], summary: 'Get user\'s favorite vendors',
          security: [{ BearerAuth: [] }],
          responses: { 200: { description: 'Favorite vendors list' } },
        },
      },
      '/vendors/{id}': {
        get: {
          tags: ['Vendor'], summary: 'Get vendor details',
          security: [{ BearerAuth: [] }],
          parameters: [{ in: 'path', name: 'id', required: true, schema: { type: 'integer' } }],
          responses: { 200: { description: 'Vendor details with user info' } },
        },
      },
      '/vendors/{id}/items': {
        get: {
          tags: ['Vendor'], summary: 'Get vendor\'s available items',
          security: [{ BearerAuth: [] }],
          parameters: [{ in: 'path', name: 'id', required: true, schema: { type: 'integer' } }],
          responses: { 200: { description: 'Available items' } },
        },
      },
      '/vendors/{id}/route': {
        get: {
          tags: ['Vendor'], summary: 'Get vendor\'s active route (for map)',
          security: [{ BearerAuth: [] }],
          parameters: [{ in: 'path', name: 'id', required: true, schema: { type: 'integer' } }],
          responses: { 200: { description: 'Route with waypoints' } },
        },
      },
      '/vendors/{id}/eta': {
        get: {
          tags: ['Vendor'], summary: 'Get ETA for vendor to reach buyer',
          security: [{ BearerAuth: [] }],
          parameters: [
            { in: 'path', name: 'id', required: true, schema: { type: 'integer' } },
            { in: 'query', name: 'lat', required: true, schema: { type: 'number' } },
            { in: 'query', name: 'lng', required: true, schema: { type: 'number' } },
          ],
          responses: { 200: { description: 'ETA calculation', content: { 'application/json': { schema: { $ref: '#/components/schemas/VendorETA' } } } } },
        },
      },
      '/vendors/{id}/favorite': {
        post: {
          tags: ['Vendor'], summary: 'Toggle favorite vendor (add/remove)',
          security: [{ BearerAuth: [] }],
          parameters: [{ in: 'path', name: 'id', required: true, schema: { type: 'integer' } }],
          responses: { 200: { description: 'Favorite toggled' } },
        },
      },
      '/vendors/status': {
        post: {
          tags: ['Seller'], summary: 'Toggle vendor active status',
          security: [{ BearerAuth: [] }],
          requestBody: { required: true, content: { 'application/json': { schema: { type: 'object', properties: { is_active: { type: 'boolean' } } } } } },
          responses: { 200: { description: 'Status updated' } },
        },
      },
      '/vendors/location': {
        post: {
          tags: ['Seller'], summary: 'Update vendor location (writes Redis + broadcasts)',
          security: [{ BearerAuth: [] }],
          requestBody: { required: true, content: { 'application/json': { schema: { type: 'object', properties: { lat: { type: 'number' }, lng: { type: 'number' } } } } } },
          responses: { 200: { description: 'Location updated + broadcast' } },
        },
      },

      // ─── Order ────────────────────────────────────────────────
      '/orders': {
        post: {
          tags: ['Order'], summary: 'Create order token',
          security: [{ BearerAuth: [] }],
          requestBody: { required: true, content: { 'application/json': { schema: { $ref: '#/components/schemas/CreateOrderRequest' } } } },
          responses: { 201: { description: 'Order created' } },
        },
        get: {
          tags: ['Order'], summary: 'Get buyer\'s orders (paginated)',
          security: [{ BearerAuth: [] }],
          parameters: [
            { in: 'query', name: 'status', schema: { type: 'string' } },
            { in: 'query', name: 'page', schema: { type: 'integer', default: 1 } },
            { in: 'query', name: 'limit', schema: { type: 'integer', default: 20 } },
          ],
          responses: { 200: { description: 'Paginated orders' } },
        },
      },
      '/orders/{id}': {
        get: {
          tags: ['Order'], summary: 'Get order details with items',
          security: [{ BearerAuth: [] }],
          parameters: [{ in: 'path', name: 'id', required: true, schema: { type: 'integer' } }],
          responses: { 200: { description: 'Order details' } },
        },
      },
      '/orders/{id}/accept': {
        post: {
          tags: ['Order'], summary: 'Accept order (seller)',
          security: [{ BearerAuth: [] }],
          parameters: [{ in: 'path', name: 'id', required: true, schema: { type: 'integer' } }],
          responses: { 200: { description: 'Order accepted' } },
        },
      },
      '/orders/{id}/reject': {
        post: {
          tags: ['Order'], summary: 'Reject order (seller)',
          security: [{ BearerAuth: [] }],
          parameters: [{ in: 'path', name: 'id', required: true, schema: { type: 'integer' } }],
          responses: { 200: { description: 'Order rejected' } },
        },
      },
      '/orders/{id}/fulfill': {
        post: {
          tags: ['Order'], summary: 'Fulfill order (seller)',
          security: [{ BearerAuth: [] }],
          parameters: [{ in: 'path', name: 'id', required: true, schema: { type: 'integer' } }],
          responses: { 200: { description: 'Order fulfilled' } },
        },
      },

      // ─── Route ────────────────────────────────────────────────
      '/seller/routes': {
        post: {
          tags: ['Route'], summary: 'Create route with waypoints',
          security: [{ BearerAuth: [] }],
          requestBody: { required: true, content: { 'application/json': { schema: { $ref: '#/components/schemas/CreateRouteRequest' } } } },
          responses: { 201: { description: 'Route created' } },
        },
        get: {
          tags: ['Route'], summary: 'Get all seller routes',
          security: [{ BearerAuth: [] }],
          responses: { 200: { description: 'Route list with points' } },
        },
      },
      '/seller/routes/active': {
        get: {
          tags: ['Route'], summary: 'Get currently active route',
          security: [{ BearerAuth: [] }],
          responses: { 200: { description: 'Active route or null' } },
        },
      },
      '/seller/routes/{id}': {
        put: {
          tags: ['Route'], summary: 'Update route name and/or points',
          security: [{ BearerAuth: [] }],
          parameters: [{ in: 'path', name: 'id', required: true, schema: { type: 'integer' } }],
          responses: { 200: { description: 'Route updated' } },
        },
        delete: {
          tags: ['Route'], summary: 'Delete route (cannot delete active)',
          security: [{ BearerAuth: [] }],
          parameters: [{ in: 'path', name: 'id', required: true, schema: { type: 'integer' } }],
          responses: { 200: { description: 'Route deleted' } },
        },
      },
      '/seller/routes/{id}/activate': {
        post: {
          tags: ['Route'], summary: 'Activate a route (deactivates previous)',
          security: [{ BearerAuth: [] }],
          parameters: [{ in: 'path', name: 'id', required: true, schema: { type: 'integer' } }],
          responses: { 200: { description: 'Route activated' } },
        },
      },

      // ─── Admin ────────────────────────────────────────────────
      '/admin/active-vendors': {
        get: {
          tags: ['Admin'], summary: 'Get all currently active vendors',
          security: [{ BearerAuth: [] }],
          responses: { 200: { description: 'Active vendor list with count' } },
        },
      },
    },
  },
  apis: [], // Paths defined inline above
};

const swaggerSpec = swaggerJsdoc(options);

module.exports = swaggerSpec;
