-keep class com.razorpay.** { *; }
-keepclassmembers class com.razorpay.** { *; }
# Keep all classes in your app's package
-keep class **.saamay.** { *; }

# Keep all your pages package
-keep class **.pages.** { *; }

# Firebase Messaging (optional)
-keep class com.google.firebase.** { *; }
-dontwarn com.google.firebase.**

# Please add these rules to your existing keep rules in order to suppress warnings.
# This is generated automatically by the Android Gradle plugin.
-dontwarn proguard.annotation.Keep
-dontwarn proguard.annotation.KeepClassMembers
# Please add these rules to your existing keep rules in order to suppress warnings.
# This is generated automatically by the Android Gradle plugin.
-dontwarn com.google.android.apps.nbu.paisa.inapp.client.api.PaymentsClient
-dontwarn com.google.android.apps.nbu.paisa.inapp.client.api.Wallet
-dontwarn com.google.android.apps.nbu.paisa.inapp.client.api.WalletUtils