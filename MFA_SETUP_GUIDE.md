# Multi-Factor Authentication (MFA) Setup Guide

## Overview

This IDS/IDPS system now includes **TOTP-based Multi-Factor Authentication** using **Google Authenticator** for enhanced security. This guide will help you set up and use MFA.

---

## 🔐 What is MFA?

Multi-Factor Authentication (MFA) adds an extra layer of security to your account by requiring:
1. **Something you know**: Your password
2. **Something you have**: A time-based code from your authenticator app

---

## 📱 Prerequisites

### Install Google Authenticator

Download and install Google Authenticator on your mobile device:

- **iOS**: [Download from App Store](https://apps.apple.com/app/google-authenticator/id388497605)
- **Android**: [Download from Play Store](https://play.google.com/store/apps/details?id=com.google.android.apps.authenticator2)

**Alternative Authenticator Apps** (compatible with TOTP):
- Microsoft Authenticator
- Authy
- 1Password
- Bitwarden

---

## ✅ How to Enable MFA

### Step 1: Access Security Settings

1. Log in to the IDS/IDPS Desktop GUI
2. Navigate to the **🔐 Security** tab in the dashboard

### Step 2: Start MFA Enrollment

1. Click the **"🔐 Enable Two-Factor Authentication"** button
2. A dialog will appear with a QR code

### Step 3: Scan QR Code

1. Open Google Authenticator on your phone
2. Tap the **"+"** button to add an account
3. Select **"Scan a QR code"**
4. Point your camera at the QR code displayed on screen

**Can't scan the QR code?**
- Use the **"Manual entry"** code shown below the QR code
- In Google Authenticator, select "Enter a setup key" instead

### Step 4: Verify Setup

1. Once added, Google Authenticator will display a 6-digit code
2. Enter this code in the verification field
3. Click **"✓ Activate 2FA"**

### Step 5: Save Recovery Codes

🚨 **IMPORTANT**: After activation, you'll receive **recovery codes**

- **Save these codes** in a secure location (password manager, encrypted file, etc.)
- These codes allow you to access your account if you lose your phone
- Each recovery code can only be used once

---

## 🔑 Logging In with MFA

Once MFA is enabled, the login process changes:

### Login Flow

1. **Enter credentials**: Email and password as usual
2. **MFA prompt**: A dialog will appear asking for a 6-digit code
3. **Open authenticator**: Open Google Authenticator on your phone
4. **Enter code**: Type the 6-digit code shown for "IDS-IDPS"
5. **Verify**: Click "Verify" to complete login

**Code Tips**:
- Codes refresh every 30 seconds
- You have a small time window before and after for code validity
- If a code expires, wait for the next one

---

## 🔧 Technical Details

### TOTP Implementation

- **Algorithm**: Time-based One-Time Password (TOTP)
- **Standard**: RFC 6238
- **Period**: 30 seconds
- **Digits**: 6
- **Hash**: SHA-1
- **Issuer**: IDS-IDPS

### Security Features

✅ Secrets stored encrypted in database  
✅ QR codes generated server-side  
✅ Recovery codes for backup authentication  
✅ Account lockout after failed attempts  
✅ Audit logging for MFA events  

---

## 🛠️ Backend Architecture

### Database Schema

```sql
-- UserMFA table stores TOTP secrets
CREATE TABLE user_mfa (
    user_id UUID PRIMARY KEY,
    totp_secret_base32 TEXT,
    is_enabled BOOLEAN DEFAULT FALSE,
    recovery_codes TEXT[],
    created_at TIMESTAMP,
    updated_at TIMESTAMP
);
```

### API Endpoints

1. **POST /auth/mfa/enroll** - Generate QR code and secret
2. **POST /auth/mfa/activate** - Activate MFA after verification
3. **POST /auth/mfa/verify** - Verify TOTP code during login

### Python Dependencies

```txt
pyotp==2.9.0      # TOTP implementation
qrcode[pil]==7.4.2  # QR code generation
Pillow==10.1.0    # Image processing
```

---

## ❓ Troubleshooting

### "Invalid MFA code" Error

**Possible causes**:
- Code has expired (wait for next code)
- Time sync issue between device and server
- Wrong account selected in authenticator

**Solutions**:
1. Ensure your phone's time is set to automatic
2. Wait for the code to refresh
3. Verify you're using the correct account in the authenticator

### Lost Phone / Can't Access Authenticator

**Solution**: Use recovery codes
1. Enter a recovery code instead of the TOTP code
2. Contact your system administrator if you've lost recovery codes
3. Admin can reset MFA for your account from the Users tab

### QR Code Not Displaying

**Solutions**:
1. Check that backend service is running
2. Verify network connectivity
3. Try manual entry using the secret key

### Time Synchronization Issues

For the TOTP codes to work correctly:
- Server time must be accurate (use NTP)
- Mobile device time must be set to automatic
- Maximum time drift: ±30 seconds

---

## 🔒 Security Best Practices

### For Users

1. ✅ **Enable MFA** on all accounts with sensitive access
2. ✅ **Save recovery codes** securely (password manager recommended)
3. ✅ **Use a unique password** in addition to MFA
4. ✅ **Keep authenticator app updated**
5. ❌ **Never share** your TOTP secret or recovery codes

### For Administrators

1. ✅ **Enforce MFA** for admin accounts (policy level)
2. ✅ **Monitor audit logs** for MFA-related events
3. ✅ **Backup recovery codes** for critical accounts
4. ✅ **Educate users** on MFA setup and usage
5. ✅ **Test disaster recovery** procedures

---

## 📊 Admin: Managing User MFA

Administrators can view and manage MFA status for all users:

### View MFA Status

1. Navigate to **👥 Users** tab
2. The **"2FA Status"** column shows:
   - ✓ Enabled (green)
   - ✗ Disabled (red)

### Reset User MFA (Future Feature)

If a user loses access to their authenticator:
1. Locate user in Users tab
2. Click "Reset MFA" action
3. User must re-enroll on next login

---

## 🚀 Quick Start Example

### User Enrollment Flow

```bash
# 1. User logs in without MFA
POST /auth/login
{
  "email": "analyst@example.com",
  "password": "SecurePass123!"
}
→ Returns access_token (no MFA required)

# 2. User navigates to Security tab and clicks "Enable 2FA"
POST /auth/mfa/enroll
Authorization: Bearer <access_token>
→ Returns QR code and secret

# 3. User scans QR code and enters verification code
POST /auth/mfa/activate
Authorization: Bearer <access_token>
{
  "otp_code": "123456"
}
→ Returns recovery codes and enables MFA

# 4. Next login requires MFA
POST /auth/login
{
  "email": "analyst@example.com",
  "password": "SecurePass123!"
}
→ Returns mfa_required=true and mfa_ticket

POST /auth/mfa/verify
{
  "ticket": "<mfa_ticket>",
  "otp_code": "789012"
}
→ Returns access_token after successful verification
```

---

## 📝 Testing MFA

### Manual Testing Steps

1. **Create test user**:
   ```bash
   # Use backend API or GUI
   email: test@example.com
   password: TestPass123!
   ```

2. **Login and enable MFA**:
   - Login to GUI
   - Go to Security tab
   - Enable 2FA with Google Authenticator

3. **Logout and re-login**:
   - Enter credentials
   - Should prompt for MFA code
   - Enter code from authenticator
   - Should successfully login

4. **Test invalid code**:
   - Attempt login with wrong code
   - Should show error message
   - Check audit logs for failed MFA attempt

---

## 🐛 Known Issues

### None at this time

Report issues to the development team with:
- Error messages
- Steps to reproduce
- Browser/OS information
- Audit log entries (if accessible)

---

## 📚 Additional Resources

- [RFC 6238 - TOTP Specification](https://tools.ietf.org/html/rfc6238)
- [Google Authenticator Documentation](https://support.google.com/accounts/answer/1066447)
- [pyotp Library Documentation](https://pyauth.github.io/pyotp/)

---

## ✨ Future Enhancements

Planned features for future releases:

- [ ] SMS-based MFA as backup option
- [ ] Hardware security key support (FIDO2/U2F)
- [ ] Admin-enforced MFA policies
- [ ] MFA reset by administrators
- [ ] Trusted device registration
- [ ] Email notifications for MFA changes
- [ ] Rate limiting on MFA verification attempts

---

**Questions or Issues?**  
Contact your system administrator or refer to the main project documentation.

---

*Last Updated: October 2025*
*Version: 1.0*

