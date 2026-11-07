const jwt = require('jsonwebtoken');

const JWT_SECRET = process.env.JWT_SECRET || 'onway_market_secret_jwt_key_2026';

const authenticateJWT = (req, res, next) => {
  const authHeader = req.headers.authorization;

  if (authHeader) {
    const token = authHeader.split(' ')[1];

    jwt.verify(token, JWT_SECRET, (err, decoded) => {
      if (err) {
        return res.sendStatus(401);
      }
      req.user = decoded;
      next();
    });
  } else {
    res.sendStatus(401);
  }
};

const optionalAuth = (req, res, next) => {
  const authHeader = req.headers.authorization;

  if (authHeader) {
    const token = authHeader.split(' ')[1];

    jwt.verify(token, JWT_SECRET, (err, decoded) => {
      if (err) {
        req.user = null;
      } else {
        req.user = decoded;
      }
      next();
    });
  } else {
    req.user = null;
    next();
  }
};

module.exports = {
  authenticateJWT,
  optionalAuth
};
