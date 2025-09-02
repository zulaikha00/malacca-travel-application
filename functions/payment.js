// ✅ Import Firebase Callable Functions (v2)
const { onCall } = require("firebase-functions/v2/https");

// ✅ Import Stripe and initialize with your secret key
const stripe = require("stripe")("YOUR_STRIPE_API_KEY_HERE"); // ⚠️ Replace with your real secret key

// ✅ Firebase Logger for debugging
const logger = require("firebase-functions/logger");

// ✅ Import shared Firebase instance (already initialized in firebase.js)
const { admin, db, bucket } = require("./firebase");

// ✅ QR Code generation library
const QRCode = require("qrcode");

// ✅ Google Cloud Storage (optional: if using directly)
const { Storage } = require("@google-cloud/storage");
const storage = new Storage(); // ✅ optional, not used directly since we already use `bucket`

// ✅ Initialize SendGrid
const sgMail = require("@sendgrid/mail");
sgMail.setApiKey("YOUR_SENDGRID_API_KEY_HERE"); // ⚠️ Replace with your real API key

// ❌ DO NOT add admin.initializeApp() here — it's already called in firebase.js

// =======================================================
// 1️⃣ Function: Create Stripe PaymentIntent
// This creates a clientSecret for frontend Stripe payment sheet
// =======================================================
exports.createPaymentIntent = onCall(async (request) => {
  const { amount, email, metadata } = request.data;

  try {
    const paymentIntent = await stripe.paymentIntents.create({
      amount: Math.round(amount * 100), // Convert RM to cents
      currency: "myr",
      automatic_payment_methods: { enabled: true },
      receipt_email: email,
      metadata, // Optional: ticket info, booking ID, etc.
    });

    return {
      clientSecret: paymentIntent.client_secret,
    };
  } catch (error) {
    logger.error("❌ Failed to create PaymentIntent:", error);
    throw new Error("PaymentIntent creation failed: " + error.message);
  }
});

// =======================================================
// 2️⃣ Function: Finalize Booking and Email with QR Code
// Saves booking, generates QR, uploads to Storage, sends email
// =======================================================
exports.finalizeBookingAndEmail = onCall(async (request) => {
  const {
    ticketName,
    ticketQuantities,
    totalAmount,
    userName,
    userPhone,
    userEmail,
    visitDate,
  } = request.data;

  try {
    // 🔹 Step 1: Save booking to Firestore
    const bookingRef = await db.collection("booking").add({
      uid: request.auth.uid, // User who made the booking
      ticket_name: ticketName,
      ticket_quantities: ticketQuantities,
      total_amount: totalAmount,
      user_name: userName,
      user_phone: userPhone,
      user_email: userEmail,
      visit_date: new Date(visitDate),
      timestamp: admin.firestore.FieldValue.serverTimestamp(),
    });

    // 🔹 Step 2: Generate QR Code
    const qrContent = `Booking ID: ${bookingRef.id}\nName: ${userName}\nVisit Date: ${visitDate}`;
    const qrBuffer = await QRCode.toBuffer(qrContent);

    // 🔹 Step 3: Upload QR to Firebase Storage
    const filePath = `qr-codes/${bookingRef.id}.png`;
    const file = bucket.file(filePath);
    await file.save(qrBuffer, {
      metadata: { contentType: "image/png" },
      resumable: false,
    });

    // 🔹 Step 4: Make QR public & get URL
    await file.makePublic();
    const qrUrl = `https://storage.googleapis.com/${bucket.name}/${filePath}`;

    // 🔹 Step 5: Update Firestore with QR URL
    await bookingRef.update({ qr_url: qrUrl });

    // 🔹 Step 6: Send email confirmation with QR
    const emailContent = {
      to: userEmail,
      from: "zulaikhalyka03@gmail.com", // Must be verified in SendGrid
      subject: "🎟️ Your Booking Confirmation with QR Code",
      html: `
        <p>Thank you, <strong>${userName}</strong>, for your booking!</p>
        <p><strong>Visit Date:</strong> ${visitDate}</p>
        <p><strong>Ticket:</strong> ${ticketName}</p>
        <p><strong>Total Paid:</strong> RM ${totalAmount}</p>
        <p>📲 <strong>Scan this QR code at entry:</strong></p>
        <img src="${qrUrl}" width="200" alt="QR Code" />
      `,
    };
    await sgMail.send(emailContent);

    // 🔹 Final response
    return {
      success: true,
      bookingId: bookingRef.id,
      qrUrl: qrUrl,
    };
  } catch (error) {
    logger.error("❌ Failed to finalize booking:", error);
    throw new Error("Booking finalization failed: " + error.message);
  }
});
