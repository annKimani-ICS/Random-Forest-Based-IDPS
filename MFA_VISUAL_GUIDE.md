# Visual Guide: MFA Setup Flow

## 📸 Step-by-Step Visual Walkthrough

---

## 1️⃣ Security Tab in Dashboard

After logging in, you'll see a new **🔐 Security** tab:

```
┌─────────────────────────────────────────────────────────────┐
│  📊 Dashboard  │  🚨 Alerts  │ 🔐 Security  │  ⚙️ Settings  │
└─────────────────────────────────────────────────────────────┘

┌───────────────────────────────────────────────────────────┐
│  Account Security                                          │
│                                                            │
│  Account: your.email@example.com                          │
│                                                            │
│  Two-Factor Authentication (2FA)                          │
│  Two-factor authentication adds an extra layer of         │
│  security to your account.                                │
│                                                            │
│  Status: ✗ Not Enabled (Recommended)                     │
│                                                            │
│  ┌──────────────────────────────────────────────┐         │
│  │  🔐 Enable Two-Factor Authentication         │         │
│  └──────────────────────────────────────────────┘         │
│                                                            │
│  ┌────────────────────────────────────────────────────┐   │
│  │  ℹ️ How to set up 2FA:                            │   │
│  │  1. Download Google Authenticator on your phone   │   │
│  │  2. Click 'Enable 2FA' and scan the QR code       │   │
│  │  3. Enter the 6-digit code from the app           │   │
│  │  4. Save your recovery codes in a safe place      │   │
│  └────────────────────────────────────────────────────┘   │
└───────────────────────────────────────────────────────────┘
```

---

## 2️⃣ MFA Enrollment Dialog

Click "Enable Two-Factor Authentication" button:

```
┌────────────────────────────────────────────────────────┐
│   🔐 Enable Two-Factor Authentication                  │
│                                                         │
│   Follow these steps to enable 2FA:                    │
│   1. Install Google Authenticator on your phone        │
│   2. Scan the QR code below                           │
│   3. Enter the 6-digit code to verify                 │
│                                                         │
│  ┌───────────────────────────────────────────────┐    │
│  │                                                │    │
│  │         ████████████████████████              │    │
│  │         ██  ██      ██  ██  ████              │    │
│  │         ██  ████  ████  ██  ████              │    │
│  │         ██  ████  ████  ██  ████              │    │
│  │         ██  ████  ████  ██  ████              │    │
│  │         ████████████████████████              │    │
│  │         QR CODE FOR SCANNING                  │    │
│  │                                                │    │
│  │    Manual entry: JBSWY3DPEHPK3PXP            │    │
│  └───────────────────────────────────────────────┘    │
│                                                         │
│   Enter the 6-digit code from your app:                │
│                                                         │
│              ┌─────────────────┐                       │
│              │    000000       │                       │
│              └─────────────────┘                       │
│                                                         │
│     ┌──────────────────┐      ┌──────────────┐        │
│     │ ✓ Activate 2FA   │      │   Cancel     │        │
│     └──────────────────┘      └──────────────┘        │
└────────────────────────────────────────────────────────┘
```

---

## 3️⃣ Google Authenticator App

On your phone, the app looks like this:

```
┌─────────────────────────────┐
│  Google Authenticator       │
├─────────────────────────────┤
│                             │
│  ┌───────────────────────┐  │
│  │  🛡 IDS-IDPS          │  │
│  │  your.email@example.com│  │
│  │                        │  │
│  │      123 456          │  │
│  │      ⏱ 28 seconds     │  │
│  └───────────────────────┘  │
│                             │
│  ┌───────────────────────┐  │
│  │  Other Account        │  │
│  │  789 012              │  │
│  └───────────────────────┘  │
│                             │
│         [+] Add             │
└─────────────────────────────┘
```

---

## 4️⃣ Success - Recovery Codes

After successful verification:

```
┌────────────────────────────────────────────────────────┐
│   ✓ Two-Factor Authentication Enabled!                 │
│                                                         │
│   Save these recovery codes in a safe place.           │
│   You can use them to access your account if you       │
│   lose your phone:                                     │
│                                                         │
│   ┌────────────────────────────────────────────┐      │
│   │   1. A3F8E2D1                              │      │
│   │   2. B9C4F7E2                              │      │
│   │   3. C5D1A8F3                              │      │
│   │   4. D8E2B3C9                              │      │
│   │   5. E1F4C7D6                              │      │
│   │   6. F9A2D5E8                              │      │
│   │   7. G3B7E1C4                              │      │
│   │   8. H8C2F6D9                              │      │
│   │   9. I4D8A3E7                              │      │
│   │  10. J7E1C9F2                              │      │
│   └────────────────────────────────────────────┘      │
│                                                         │
│                    ┌──────────┐                        │
│                    │    OK    │                        │
│                    └──────────┘                        │
└────────────────────────────────────────────────────────┘
```

**⚠️ IMPORTANT**: Copy these codes and save them securely!

---

## 5️⃣ Security Tab After Enabling

Now the Security tab shows MFA is enabled:

```
┌───────────────────────────────────────────────────────────┐
│  Account Security                                          │
│                                                            │
│  Account: your.email@example.com                          │
│                                                            │
│  Two-Factor Authentication (2FA)                          │
│  Two-factor authentication adds an extra layer of         │
│  security to your account.                                │
│                                                            │
│  Status: ✓ Enabled  [GREEN]                              │
│                                                            │
│  ┌──────────────────────────────────────────────┐         │
│  │      🔐 2FA is Enabled                       │         │
│  └──────────────────────────────────────────────┘         │
│  (Button is disabled - MFA already active)               │
└───────────────────────────────────────────────────────────┘
```

---

## 6️⃣ Login Flow with MFA

Next time you log in:

### Initial Login Screen
```
┌──────────────────────────────────────┐
│   🛡 IDS/IDPS                        │
│   Intrusion Detection & Prevention   │
│                                      │
│  ┌────────────────────────────────┐ │
│  │  Email Address                 │ │
│  │  your.email@example.com        │ │
│  └────────────────────────────────┘ │
│                                      │
│  ┌────────────────────────────────┐ │
│  │  Password                      │ │
│  │  ••••••••                      │ │
│  └────────────────────────────────┘ │
│                                      │
│  ┌────────────────────────────────┐ │
│  │         Login                  │ │
│  └────────────────────────────────┘ │
└──────────────────────────────────────┘
```

### MFA Verification Popup
```
┌─────────────────────────────────────┐
│  Two-Factor Authentication          │
│                                     │
│  Enter 6-Digit Code                │
│                                     │
│  Open Google Authenticator and     │
│  enter the code                    │
│                                     │
│       ┌─────────────────┐          │
│       │    1 2 3 4 5 6  │          │
│       └─────────────────┘          │
│                                     │
│       ┌─────────────────┐          │
│       │     Verify      │          │
│       └─────────────────┘          │
└─────────────────────────────────────┘
```

---

## 7️⃣ Users Tab (Admin View)

Admins can see MFA status for all users:

```
┌─────────────────────────────────────────────────────────────────┐
│  👥 Users                                                        │
│                                                                  │
│  Email              │ Role    │ 2FA Status  │ Active │ Actions │
│──────────────────────────────────────────────────────────────────│
│  admin@example.com  │ ADMIN   │ ✓ Enabled   │ Active │   ...   │
│  analyst@test.com   │ ANALYST │ ✗ Disabled  │ Active │   ...   │
│  user@domain.com    │ ANALYST │ ✓ Enabled   │ Active │   ...   │
└─────────────────────────────────────────────────────────────────┘
```

---

## 🔄 Complete Flow Diagram

```
┌─────────────────────┐
│   User Logs In      │
│   (First Time)      │
└──────────┬──────────┘
           │
           ▼
┌─────────────────────┐
│  Navigate to        │
│  Security Tab       │
└──────────┬──────────┘
           │
           ▼
┌─────────────────────┐
│  Click "Enable 2FA" │
└──────────┬──────────┘
           │
           ▼
┌─────────────────────┐
│  Scan QR Code       │
│  with Phone         │
└──────────┬──────────┘
           │
           ▼
┌─────────────────────┐
│  Enter 6-digit      │
│  Verification Code  │
└──────────┬──────────┘
           │
           ▼
┌─────────────────────┐
│  Save Recovery      │
│  Codes              │
└──────────┬──────────┘
           │
           ▼
┌─────────────────────┐
│  ✓ MFA Enabled!     │
└─────────────────────┘


     SUBSEQUENT LOGINS:

┌─────────────────────┐
│   Enter Email &     │
│   Password          │
└──────────┬──────────┘
           │
           ▼
┌─────────────────────┐
│  MFA Prompt Appears │
└──────────┬──────────┘
           │
           ▼
┌─────────────────────┐
│  Open Authenticator │
│  App on Phone       │
└──────────┬──────────┘
           │
           ▼
┌─────────────────────┐
│  Enter TOTP Code    │
└──────────┬──────────┘
           │
           ▼
┌─────────────────────┐
│  ✓ Logged In!       │
│  Access Dashboard   │
└─────────────────────┘
```

---

## 📱 Phone Screenshots Guide

### Scanning QR Code

1. **Open Google Authenticator**
   - Tap the app on your phone
   
2. **Add Account**
   - Tap the "+" button (usually bottom right)
   
3. **Choose Method**
   - Tap "Scan a QR code"
   - Or tap "Enter a setup key" for manual entry
   
4. **Scan**
   - Point camera at computer screen
   - QR code should auto-detect
   
5. **Verify**
   - Account "IDS-IDPS" appears in list
   - 6-digit code shows below account name
   - Timer shows seconds remaining

---

## 🎨 Color Coding

Throughout the interface:

- **🟢 Green** (✓): MFA Enabled, Secure, Success
- **🔴 Red** (✗): MFA Disabled, Alert, Warning
- **🔵 Blue**: Primary actions, clickable buttons
- **⚪ White**: Background, neutral areas
- **🟡 Yellow/Orange**: Informational, attention needed

---

## ⌨️ Keyboard Shortcuts

While using MFA:

- **Tab**: Navigate between fields
- **Enter**: Submit/Verify code
- **Esc**: Cancel/Close dialog
- **Numbers 0-9**: Type verification code

---

## 📊 Status Indicators

| Symbol | Meaning |
|--------|---------|
| ✓      | Enabled/Active/Success |
| ✗      | Disabled/Inactive |
| ⚠      | Warning/Attention |
| 🔐     | Security-related |
| ⏱      | Time-sensitive |
| 📱     | Mobile device action |

---

## 🎯 Visual Checklist

Use this checklist as you set up MFA:

- [ ] Downloaded Google Authenticator app
- [ ] Logged into IDS/IDPS GUI
- [ ] Found the Security tab
- [ ] Clicked "Enable 2FA" button
- [ ] Scanned QR code (or entered manually)
- [ ] Saw "IDS-IDPS" account in authenticator
- [ ] Entered 6-digit verification code
- [ ] Clicked "Activate 2FA"
- [ ] Copied and saved recovery codes
- [ ] Saw "✓ Enabled" status in Security tab
- [ ] Tested login with MFA code
- [ ] Successfully logged in with 2FA

---

## 💡 Visual Tips

**QR Code Not Scanning?**
- Move camera closer/farther
- Improve lighting
- Clean phone camera lens
- Try manual entry instead

**Can't See Dialog?**
- Check if it's behind another window
- Click on taskbar to bring to front
- Press Alt+Tab to switch windows

**Code Not Working?**
- Wait for new code (they refresh every 30s)
- Check phone time is set to automatic
- Ensure you're using the right account in app

---

**Need more help?** See the complete guides:
- Quick Start: `QUICK_START_MFA.md`
- Full Guide: `MFA_SETUP_GUIDE.md`
- Technical Details: `MFA_IMPLEMENTATION_SUMMARY.md`

---

*Visual Guide v1.0 - October 2025*

