# 🔔 Background Notifications Setup - Tamil Guide

## என்ன செய்ய போறோம்?

App close-ஆ இருந்தாலும் உங்களுக்கு real-time notification வர வேண்டும் என்றால், **Firebase Cloud Functions** setup செய்ய வேண்டும்.

---

## 📋 முக்கியமான விஷயங்கள்

### ✅ ஏற்கனவே செய்யப்பட்டவை:
- ✅ Firebase Cloud Messaging (FCM) setup done
- ✅ Local notifications working when app is open
- ✅ SMS listener detecting messages
- ✅ Firestore notifications collection ready

### ⚠️ இப்போது செய்ய வேண்டியது:
- 🔥 Firebase **Blaze Plan** (Pay-as-you-go) upgrade வேண்டும்
- ☁️ Cloud Functions deploy செய்ய வேண்டும்

---

## 💰 Cost பற்றி

### Free Tier-ல் கிடைப்பது:
- **2 million function invocations/month** - FREE
- **400,000 GB-seconds compute time** - FREE
- **200,000 CPU-seconds** - FREE

### உங்கள் usage:
- SMS வரும்போது மட்டும் function run ஆகும்
- Daily 10-50 SMS என்றால் → **மாதத்திற்கு ₹0 - ₹10 maximum**
- சாதாரண usage-க்கு free tier போதும்!

---

## 🚀 Setup செய்வது எப்படி?

### Step 1: Firebase Console-ல் Blaze Plan Enable செய்யுங்கள்

1. **Firebase Console** திறக்கவும்: https://console.firebase.google.com
2. உங்கள் project-ஐ select செய்யுங்கள்
3. Left sidebar-ல் கீழே **⚙️ Settings (Upgrade)** click செய்யுங்கள்
4. **"Select a plan"** or **"Upgrade"** button click செய்யுங்கள்
5. **"Blaze (Pay as you go)"** plan-ஐ select செய்யுங்கள்
6. Billing account setup செய்யுங்கள் (Credit/Debit card தேவை)
7. **Upgrade** click செய்யுங்கள்

**குறிப்பு:** Free tier limits-க்குள் இருந்தால் charge ஆகாது!

---

### Step 2: Cloud Functions Deploy செய்யுங்கள்

#### Option A: Automatic Deployment (Recommended)

1. **Windows File Explorer**-ல் போங்கள்
2. உங்கள் project folder-ஐ திறக்கவும்: `E:\Main_project\monitoring_system_for_street_lights`
3. **`deploy_functions.bat`** file-ஐ double-click செய்யுங்கள்
4. Script தானாக எல்லாவற்றையும் செய்யும்:
   - Firebase login check
   - Dependencies install
   - Functions deploy
   - Verification

#### Option B: Manual Deployment

Terminal/PowerShell open செய்து:

```powershell
# 1. Project folder-க்கு போங்கள்
cd E:\Main_project\monitoring_system_for_street_lights

# 2. Firebase login செய்யுங்கள்
firebase login

# 3. Functions folder-க்கு போங்கள்
cd functions

# 4. Dependencies install செய்யுங்கள்
npm install

# 5. Deploy செய்யுங்கள்
firebase deploy --only functions

# 6. Project root-க்கு திரும்புங்கள்
cd ..
```

---

### Step 3: Verify செய்யுங்கள்

1. **Firebase Console** → **Functions** tab-க்கு போங்கள்
2. இந்த function இருக்கணும்: `sendNotificationOnNewSMS`
3. Status: **"Deployed"** என்று இருக்க வேண்டும்

---

## 🧪 Test செய்வது எப்படி?

### Method 1: Real SMS Test

1. **App-ஐ முழுசா close** செய்யுங்கள் (background-லும் இல்லாம)
2. Street light-ன் **registered phone number**-லிருந்து SMS அனுப்புங்கள்
3. உங்கள் phone-ல் **notification வர வேண்டும்** (app close-ஆ இருந்தாலும்!)
4. Notification click செய்தால் app open ஆகி notification detail காட்ட வேண்டும்

### Method 2: Firebase Console Test

1. **Firestore** → **notifications** collection-க்கு போங்கள்
2. Manually ஒரு document create செய்யுங்கள்:
```json
{
  "from": "+919876543210",
  "body": "Test notification",
  "timestamp": [Current timestamp],
  "isFixed": false,
  "lightName": "Test Street Light",
  "location": "Test Location",
  "relatedLights": ["some_light_id"]
}
```
3. Document save ஆனதும் notification வர வேண்டும்!

---

## 🔍 Troubleshooting

### ❌ Issue: "Firebase requires billing to be enabled"

**Solution:**
- Blaze plan upgrade செய்யுங்கள் (Step 1 பாருங்கள்)
- Free tier limits-க்குள் இருக்கும் வரை charge ஆகாது

---

### ❌ Issue: "firebase: command not found"

**Solution:**
```powershell
npm install -g firebase-tools
```

---

### ❌ Issue: Functions deploy failed

**Solution:**
```powershell
# Clean and retry
cd functions
rm -r node_modules
rm package-lock.json
npm install
cd ..
firebase deploy --only functions
```

---

### ❌ Issue: Notification வரல

**Check பண்ணுங்கள்:**

1. **Firebase Console** → **Functions** → **Logs** பாருங்கள்
2. **Firestore Rules** correct-ஆ இருக்கா check செய்யுங்கள்
3. **FCM Token** properly stored-ஆ இருக்கா verify செய்யுங்கள்
4. **App permissions** (Notifications) enabled-ஆ இருக்கா பாருங்கள்

---

## 📱 How It Works

```
1. SMS வருது
   ↓
2. Android SMS Listener detect செய்யுது
   ↓
3. Firestore-ல் notification document create ஆகுது
   ↓
4. Cloud Function trigger ஆகுது (app close-ஆ இருந்தாலும்!)
   ↓
5. FCM token use பண்ணி device-க்கு push notification அனுப்புது
   ↓
6. User-க்கு notification வருது!
```

---

## 🎯 Expected Results

✅ **App open-ஆ இருக்கும்போது:**
- Local notification + Cloud notification (இரண்டும் வரும், deduplication இருக்கு)

✅ **App background-ல் இருக்கும்போது:**
- Cloud notification வரும்

✅ **App close-ஆ இருக்கும்போது:**
- Cloud notification வரும் (இதுதான் புதிதா add ஆவது!)

---

## 💡 Important Notes

1. **Blaze plan மண்டேட்டரி** - Cloud Functions-க்கு free plan போதாது
2. **Normal usage-க்கு cost-ஃப்ரீ** - Free tier limits-க்குள் இருக்கும்
3. **One-time setup** - ஒரு தடவை setup செய்தா போதும்
4. **Automatic scaling** - எத்தனை users-ஆ இருந்தாலும் work ஆகும்

---

## 📞 Support

Problems இருந்தால்:

1. **Firebase Console Logs** check செய்யுங்கள்
2. **functions/index.js** file correct-ஆ இருக்கா verify செய்யுங்கள்
3. Error messages-ஐ carefully படியுங்கள்

---

## ✅ Success Checklist

- [ ] Blaze plan enabled
- [ ] Firebase CLI installed
- [ ] Firebase login successful
- [ ] Cloud Functions deployed
- [ ] Function status "Deployed" in console
- [ ] Test SMS sent
- [ ] Notification received (app closed)
- [ ] Notification click opens app correctly

---

**🎉 இந்த setup complete ஆனதும், app close-ஆ இருந்தாலும் real-time notifications வரும்!**
