# === STRIPE SDK KEEP RULES ===
-keep class com.stripe.** { *; }
-dontwarn com.stripe.**

# === React Native Stripe SDK (used by flutter_stripe) ===
-keep class com.reactnativestripesdk.** { *; }
-dontwarn com.reactnativestripesdk.**

# === Prevent R8 from removing required classes for push provisioning ===
-keep class com.stripe.android.pushProvisioning.** { *; }
-dontwarn com.stripe.android.pushProvisioning.**
