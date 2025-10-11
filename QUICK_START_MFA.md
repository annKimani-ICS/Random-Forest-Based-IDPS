# Quick Start: Multi-Factor Authentication

## 🚀 How to Enable MFA (2-Step Verification)

### Step 1: Download Google Authenticator
- **iPhone**: App Store → "Google Authenticator"
- **Android**: Play Store → "Google Authenticator"

### Step 2: Enable MFA in GUI
1. Open the IDS/IDPS Desktop GUI
2. Log in with your email and password
3. Click on the **"🔐 Security"** tab
4. Click the blue **"Enable Two-Factor Authentication"** button

### Step 3: Scan QR Code
1. Open Google Authenticator app on your phone
2. Tap the **"+"** button
3. Select **"Scan a QR code"**
4. Point camera at the QR code on your computer screen

### Step 4: Enter Verification Code
1. Google Authenticator will show a 6-digit code
2. Type this code into the dialog on your computer
3. Click **"Activate 2FA"**

### Step 5: Save Recovery Codes
⚠️ **IMPORTANT**: Save the recovery codes shown after activation!
- Keep them in a password manager or secure location
- These codes let you access your account if you lose your phone

---

## 🔑 Logging In with MFA

After enabling MFA, your login process changes:

1. Enter your **email** and **password** as normal
2. Click **Login**
3. A popup will ask for a **6-digit code**
4. Open **Google Authenticator** on your phone
5. Find the code for **"IDS-IDPS"**
6. Enter the code and click **Verify**
7. You're in! 🎉

**Tips**:
- Codes change every 30 seconds
- If a code expires, wait for the next one
- Keep your phone's time set to automatic

---

## 📱 QR Code Not Working?

If you can't scan the QR code:

1. Look below the QR code for **"Manual entry: XXXX..."**
2. In Google Authenticator, tap **"+"**
3. Select **"Enter a setup key"**
4. Enter:
   - **Account**: IDS-IDPS
   - **Key**: (the code shown on screen)
   - **Type**: Time-based
5. Tap **Add**

---

## ✅ Benefits of MFA

- 🔐 **Extra Security**: Even if someone gets your password, they can't log in
- 📱 **Always Available**: Works offline, no internet needed on phone
- 🌍 **Industry Standard**: Used by Google, Microsoft, banks, etc.
- ⚡ **Quick**: Takes only 3 seconds to verify

---

## ❓ FAQ

**Q: Do I need internet on my phone?**  
A: No! Google Authenticator works completely offline.

**Q: What if I lose my phone?**  
A: Use one of your recovery codes to log in, then set up MFA again.

**Q: Can I use a different authenticator app?**  
A: Yes! Any TOTP app works (Microsoft Authenticator, Authy, 1Password, etc.)

**Q: Is MFA required?**  
A: Currently optional, but strongly recommended for security.

**Q: Can I disable MFA later?**  
A: Currently, contact your administrator to disable MFA.

**Q: How do I know it's working?**  
A: After enabling, you'll see "✓ Enabled" in the Security tab.

---

## 🆘 Troubleshooting

### "Invalid MFA code" error
- ✅ Make sure your phone's time is set to automatic
- ✅ Wait for a new code (they change every 30 seconds)
- ✅ Double-check you're using the right account in the app

### Can't access your account
- ✅ Try a recovery code instead of the TOTP code
- ✅ Contact your system administrator for help

### QR code not showing
- ✅ Make sure the backend server is running
- ✅ Check your network connection
- ✅ Try the manual entry method instead

---

## 📞 Need Help?

Contact your system administrator or refer to the complete guide:
- **Full Guide**: See `MFA_SETUP_GUIDE.md`
- **Technical Details**: See `MFA_IMPLEMENTATION_SUMMARY.md`

---

**Security Tip**: Enable MFA today to protect your account! 🛡️

