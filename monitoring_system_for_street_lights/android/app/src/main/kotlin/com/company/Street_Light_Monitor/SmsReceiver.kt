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
        if (intent.action == "android.provider.Telephony.SMS_RECEIVED") {
            val bundle = intent.extras ?: return
            
            try {
                val pdus = bundle["pdus"] as Array<*>
                val messages = pdus.map { 
                    SmsMessage.createFromPdu(it as ByteArray) 
                }
                
                for (sms in messages) {
                    val sender = sms.displayOriginatingAddress
                    val messageBody = sms.messageBody
                    
                    Log.d(TAG, "SMS received from: $sender")
                    Log.d(TAG, "Message: $messageBody")
                    
                    // Check if sender is a registered street light
                    checkAndSaveNotification(sender, messageBody)
                }
                
            } catch (e: Exception) {
                Log.e(TAG, "Error parsing SMS", e)
            }
        }
    }
    
    private fun checkAndSaveNotification(sender: String, message: String) {
        val currentUser = FirebaseAuth.getInstance().currentUser
        if (currentUser == null) {
            Log.w(TAG, "User not logged in, skipping notification")
            return
        }
        
        val db = FirebaseFirestore.getInstance()
        
        // Clean phone number (remove +, spaces, etc.)
        val cleanSender = sender.replace("+", "").replace(" ", "").replace("-", "")
        
        // Query street_lights collection for this phone number
        db.collection("street_lights")
            .whereEqualTo("userId", currentUser.uid)
            .get()
            .addOnSuccessListener { documents ->
                Log.d(TAG, "Found ${documents.size()} street lights for user ${currentUser.uid}")
                
                for (doc in documents) {
                    val gsmNumber = doc.getString("gsmNumber") ?: ""
                    val phoneNumber = doc.getString("phoneNumber") ?: ""
                    
                    Log.d(TAG, "Checking street light ${doc.id}: gsmNumber=$gsmNumber, phoneNumber=$phoneNumber")
                    
                    val cleanGsm = gsmNumber.replace("+", "").replace(" ", "").replace("-", "")
                    val cleanPhone = phoneNumber.replace("+", "").replace(" ", "").replace("-", "")
                    
                    Log.d(TAG, "Cleaned values: cleanGsm=$cleanGsm, cleanPhone=$cleanPhone, cleanSender=$cleanSender")
                    
                    // Check if this SMS is from any of user's street lights
                    if (cleanSender.endsWith(cleanGsm) || cleanSender.endsWith(cleanPhone) || 
                        cleanGsm.endsWith(cleanSender) || cleanPhone.endsWith(cleanSender)) {
                        Log.d(TAG, "✅ MATCH FOUND! Creating notification for street light ${doc.id}")
                        // Create notification
                        createNotification(
                            sender = sender,
                            message = message,
                            streetLightId = doc.id,
                            lightName = doc.getString("name") ?: "Street Light",
                            location = doc.getString("address") ?: "",
                            userId = currentUser.uid
                        )
                        break
                    } else {
                        Log.d(TAG, "❌ No match for street light ${doc.id}")
                    }
                }
                
                if (documents.isEmpty) {
                    Log.w(TAG, "No street lights found for user ${currentUser.uid}")
                }
            }
            .addOnFailureListener { e ->
                Log.e(TAG, "Error querying street lights", e)
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
            "source" to "device_sms_receiver"
        )
        
        db.collection("notifications")
            .add(notification)
            .addOnSuccessListener { docRef ->
                Log.d(TAG, "✅ Notification created: ${docRef.id}")
            }
            .addOnFailureListener { e ->
                Log.e(TAG, "❌ Error creating notification", e)
            }
    }
}
