package com.company.Street_Light_Monitor

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.telephony.SmsMessage
import com.google.firebase.auth.FirebaseAuth
import com.google.firebase.firestore.FirebaseFirestore
import com.google.firebase.firestore.FieldValue
import android.util.Log

class SmsReceiver : BroadcastReceiver() {
    
    private val TAG = "SmsReceiver"
    
    override fun onReceive(context: Context, intent: Intent) {
        Log.d(TAG, "🔥 onReceive called! Action: ${intent.action}")
        
        if (intent.action == "android.provider.Telephony.SMS_RECEIVED") {
            Log.d(TAG, "🔥 SMS_RECEIVED action matched!")
            val bundle = intent.extras ?: return
            
            try {
                val pdus = bundle["pdus"] as Array<*>
                Log.d(TAG, "🔥 Found ${pdus.size} PDUs")
                
                val messages = pdus.map { 
                    SmsMessage.createFromPdu(it as ByteArray) 
                }
                
                for (sms in messages) {
                    val sender = sms.displayOriginatingAddress
                    val messageBody = sms.messageBody
                    
                    Log.d(TAG, "🔥🔥🔥 SMS received from: $sender")
                    Log.d(TAG, "🔥🔥🔥 Message: $messageBody")
                    
                    // Check if sender is a registered street light
                    checkAndSaveNotification(sender, messageBody)
                }
                
            } catch (e: Exception) {
                Log.e(TAG, "🔥 Error parsing SMS", e)
            }
        } else {
            Log.w(TAG, "🔥 NOT SMS_RECEIVED action!")
        }
    }
    
    private fun checkAndSaveNotification(sender: String, message: String) {
        Log.d(TAG, "🔥 checkAndSaveNotification called for: $sender")
        
        val currentUser = FirebaseAuth.getInstance().currentUser
        if (currentUser == null) {
            Log.w(TAG, "🔥 User not logged in, skipping notification")
            return
        }
        
        Log.d(TAG, "🔥 Current user: ${currentUser.uid}")
        
        val db = FirebaseFirestore.getInstance()
        
        // Clean phone number (remove +, spaces, etc.)
        val cleanSender = sender.replace("+", "").replace(" ", "").replace("-", "")
        Log.d(TAG, "🔥 cleanSender: $cleanSender")
        
        // Get ALL street_lights and filter in memory
        // This works even if userId/createdBy fields are missing or inconsistent
        db.collection("street_lights")
            .get()
            .addOnSuccessListener { allDocuments ->
                Log.d(TAG, "🔥🔥 Found ${allDocuments.size()} total street lights in database")
                
                // Filter for current user
                val userDocs = allDocuments.filter { doc ->
                    val docUserId = doc.getString("userId") ?: ""
                    val docCreatedBy = doc.getString("createdBy") ?: ""
                    docUserId == currentUser.uid || docCreatedBy == currentUser.uid
                }
                
                Log.d(TAG, "🔥🔥 Filtered to ${userDocs.size} street lights for user ${currentUser.uid}")
                
                if (userDocs.isEmpty()) {
                    Log.w(TAG, "🔥 No street lights found for current user")
                    return@addOnSuccessListener
                }
                
                // Check each document for phone number match
                for (doc in userDocs) {
                    val gsmNumber = doc.getString("gsmNumber") ?: ""
                    val phoneNumber = doc.getString("phoneNumber") ?: ""
                    
                    Log.d(TAG, "🔥 Checking street light ${doc.id}: gsmNumber=$gsmNumber, phoneNumber=$phoneNumber")
                    
                    val cleanGsm = gsmNumber.replace("+", "").replace(" ", "").replace("-", "").takeLast(10)
                    val cleanPhone = phoneNumber.replace("+", "").replace(" ", "").replace("-", "").takeLast(10)
                    val cleanSenderLast10 = cleanSender.takeLast(10)
                    
                    Log.d(TAG, "🔥 Cleaned values (last 10 digits): cleanGsm=$cleanGsm, cleanPhone=$cleanPhone, cleanSender=$cleanSenderLast10")
                    
                    // Check if this SMS is from any of user's street lights (compare last 10 digits)
                    if ((cleanGsm.isNotEmpty() && cleanGsm == cleanSenderLast10) ||
                        (cleanPhone.isNotEmpty() && cleanPhone == cleanSenderLast10)) {
                        Log.d(TAG, "🔥🔥🔥 ✅ MATCH FOUND! Creating notification for street light ${doc.id}")
                        // Create notification
                        createNotification(
                            sender = sender,
                            message = message,
                            streetLightId = doc.id,
                            lightName = doc.getString("name") ?: "Street Light",
                            location = doc.getString("address") ?: "",
                            userId = currentUser.uid
                        )
                        return@addOnSuccessListener // Exit after first match
                    } else {
                        Log.d(TAG, "🔥 ❌ No match for street light ${doc.id}")
                    }
                }
                
                Log.w(TAG, "🔥 No matching street light found for sender: $cleanSender")
            }
            .addOnFailureListener { e ->
                Log.e(TAG, "🔥 Error querying all street lights", e)
            }
    }
    
    private fun createNotification(
        sender: String,
        message: String,
        streetLightId: String,
        lightName: String,
        location: String,
        userId: String
    ) {
        Log.d(TAG, "🔥🔥🔥 createNotification called!")
        Log.d(TAG, "🔥 sender: $sender, lightName: $lightName, userId: $userId")
        
        val db = FirebaseFirestore.getInstance()
        
        val notification = hashMapOf(
            "from" to sender,
            "body" to message,
            "timestamp" to FieldValue.serverTimestamp(),
            "isFixed" to false,
            "relatedLights" to listOf(streetLightId),
            "streetLightId" to streetLightId,
            "lightName" to lightName,
            "name" to lightName,
            "title" to lightName,
            "location" to location,
            "address" to location,
            "userId" to userId,
            "createdBy" to userId,
            "type" to "sms",
            "source" to "sms_device_receiver"
        )
        
        Log.d(TAG, "🔥 Attempting to create notification in Firestore...")
        
        db.collection("notifications")
            .add(notification)
            .addOnSuccessListener { docRef ->
                Log.d(TAG, "🔥🔥🔥 ✅✅✅ Notification created successfully: ${docRef.id}")
            }
            .addOnFailureListener { e ->
                Log.e(TAG, "🔥🔥🔥 ❌❌❌ Error creating notification", e)
            }
    }
}
