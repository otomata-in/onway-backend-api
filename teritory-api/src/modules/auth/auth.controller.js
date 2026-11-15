const authService = require('./auth.service');
const ApiResponse = require('../../utils/ApiResponse');

const sendOtp = async (req, res, next) => {
  try {
    const result = await authService.sendOtp(req.body.phone);
    return ApiResponse.success(res, result, result.message);
  } catch (err) {
    next(err);
  }
};

const verifyOtp = async (req, res, next) => {
  try {
    const result = await authService.verifyOtp(req.body.phone, req.body.otp);
    return ApiResponse.success(res, result, 'Authentication successful');
  } catch (err) {
    next(err);
  }
};

const refreshToken = async (req, res, next) => {
  try {
    const { refreshToken } = req.body;
    const tokens = await authService.refreshToken(refreshToken);
    return ApiResponse.success(res, tokens, 'Token refreshed');
  } catch (err) {
    next(err);
  }
};

const logout = async (req, res, next) => {
  try {
    const { refreshToken } = req.body;
    await authService.logout(req.user.id, refreshToken);
    return ApiResponse.success(res, { loggedOut: true }, 'Successfully logged out');
  } catch (err) {
    next(err);
  }
};

const getMe = async (req, res) => {
  return ApiResponse.success(res, req.user, 'Current session active');
};

module.exports = {
  sendOtp,
  verifyOtp,
  refreshToken,
  logout,
  getMe,
};
