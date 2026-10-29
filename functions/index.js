const functions = require("firebase-functions");
const admin = require("firebase-admin");
const axios = require("axios");

admin.initializeApp();

// Configurable n8n Webhook URL (can also be set via functions config: firebase functions:config:set n8n.webhook="...")
const N8N_WEBHOOK_URL =
  process.env.N8N_WEBHOOK_URL ||
  "https://n8n.webhook.endpoint/webhook/llb-chennai-events";

/**
 * Triggered automatically when a new customer enquiry is submitted in Firestore
 */
exports.onEnquiryCreated = functions.firestore
  .document("enquiries/{enquiryId}")
  .onCreate(async (snap, context) => {
    const enquiry = snap.data();
    const enquiryId = context.params.enquiryId;

    console.log(`Processing new enquiry ${enquiryId} for ${enquiry.customerName || enquiry.fullName}`);

    const payload = {
      event: enquiry.preferredDate ? "sitevisit.scheduled" : "property.enquiry",
      enquiryId: enquiryId,
      customer: {
        name: enquiry.customerName || enquiry.fullName,
        email: enquiry.email || enquiry.customerEmail,
        phone: enquiry.phone || enquiry.customerPhone,
        preferredDate: enquiry.preferredDate || null,
        preferredTime: enquiry.preferredTime || null,
        needCab: enquiry.needCabPickup || false,
        pickupAddress: enquiry.pickupAddress || "",
        loanRequired: enquiry.loanRequired || false,
        message: enquiry.notes || enquiry.message || "",
      },
      property: {
        id: enquiry.propertyId,
        title: enquiry.propertyTitle,
        price: enquiry.propertyPrice,
        pricePerSqft: enquiry.propertyPricePerSqft,
        areaName: enquiry.propertyLocation || enquiry.propertyArea,
        type: enquiry.propertyType,
        size: enquiry.propertySize,
        facing: enquiry.propertyFacing,
        approval: enquiry.propertyApproval || "CMDA & RERA Approved",
        images: enquiry.propertyImages || [enquiry.propertyImage],
      },
      company: {
        name: "LLB Real Estate (Lokesh Laven Barani)",
        city: "Chennai",
        phone: "+91 98400 00000",
        supportEmail: "sales@llbrealty.com",
      },
      timestamp: new Date().toISOString(),
    };

    // Forward to n8n Webhook
    try {
      const response = await axios.post(N8N_WEBHOOK_URL, payload, {
        headers: { "Content-Type": "application/json" },
        timeout: 10000,
      });
      console.log("Successfully posted to n8n Webhook:", response.status);

      // Update Firestore document with dispatch status
      return snap.ref.update({
        n8nDispatched: true,
        n8nDispatchedAt: admin.firestore.FieldValue.serverTimestamp(),
        n8nStatus: "DELIVERED",
      });
    } catch (error) {
      console.error("Failed to post to n8n Webhook:", error.message);
      return snap.ref.update({
        n8nDispatched: false,
        n8nError: error.message,
      });
    }
  });

/**
 * Callable function to assign Admin roles to authenticated accounts
 */
exports.setAdminRole = functions.https.onCall(async (data, context) => {
  if (!context.auth) {
    throw new functions.https.HttpsError(
      "unauthenticated",
      "Authentication required."
    );
  }

  const callerUid = context.auth.uid;
  const targetEmail = data.email;

  // Verify caller is an existing admin
  const callerDoc = await admin.firestore().collection("users").doc(callerUid).get();
  if (!callerDoc.exists || callerDoc.data().role !== "admin") {
    throw new functions.https.HttpsError(
      "permission-denied",
      "Only existing administrators can assign admin privileges."
    );
  }

  const targetUser = await admin.auth().getUserByEmail(targetEmail);
  await admin.auth().setCustomUserClaims(targetUser.uid, { admin: true });
  await admin.firestore().collection("users").doc(targetUser.uid).update({
    role: "admin",
  });

  return { success: true, message: `Admin privileges granted to ${targetEmail}` };
});
