// index.js
// 🔗 Central export point for all cloud functions

const functions = require('firebase-functions');

// ✅ Import individual function files
const adminFunctions = require('./admin');
const paymentFunctions = require('./payment');
const deleteUserByUid = require('./delete_user');
const deleteAdminByUid = require('./delete_admin');


// ✅ Export callable functions
exports.createAdmin = adminFunctions.createAdmin;
exports.createPaymentIntent = paymentFunctions.createPaymentIntent;
exports.finalizeBookingAndEmail = paymentFunctions.finalizeBookingAndEmail;
exports.deleteUserByUid = deleteUserByUid;
exports.deleteAdminByUid = deleteAdminByUid
