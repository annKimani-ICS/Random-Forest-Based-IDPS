# Ubuntu VM Setup Guide - Fix Git Repository Issue

## 🚨 **Issue**: `fatal: not a git repository`

This error occurs when the directory is not a proper Git repository. Here's how to fix it:

## 🔧 **Quick Fix**

### Option 1: Use the Fix Script
```bash
# Download and run the fix script
wget https://raw.githubusercontent.com/annKimani-ICS/Random-Forest-Based-IDPS/feat/sprint4-admin-dashboard/fix_git_repo.sh
chmod +x fix_git_repo.sh
./fix_git_repo.sh
```

### Option 2: Manual Fix
```bash
# Navigate to home directory
cd ~

# Remove existing directory if it exists
rm -rf Random-Forest-Based-IDPS

# Clone the repository properly
git clone https://github.com/annKimani-ICS/Random-Forest-Based-IDPS.git

# Navigate to the cloned directory
cd Random-Forest-Based-IDPS

# Checkout the correct branch
git checkout feat/sprint4-admin-dashboard

# Pull latest changes
git pull origin feat/sprint4-admin-dashboard

# Make scripts executable
chmod +x automated_fix_sprint4.sh
chmod +x fix_git_repo.sh

# Run the automated fix
./automated_fix_sprint4.sh
```

## 🎯 **What This Fixes**

✅ **Clones repository properly** from GitHub  
✅ **Checks out correct branch** (feat/sprint4-admin-dashboard)  
✅ **Pulls latest changes** with all fixes  
✅ **Makes scripts executable**  
✅ **Runs automated setup**  

## 🚀 **Expected Results**

After running the fix:
- ✅ Git repository properly initialized
- ✅ All files and scripts available
- ✅ Automated fix script runs successfully
- ✅ Backend and GUI setup complete
- ✅ Ready for live traffic testing

## 🔍 **Verification**

To verify everything is working:
```bash
# Check git status
git status

# Check branch
git branch --show-current

# Check if scripts exist
ls -la automated_fix_sprint4.sh
ls -la fix_git_repo.sh

# Check if scripts are executable
ls -la | grep "automated_fix_sprint4.sh"
```

## 🎉 **Next Steps**

1. **Run the fix script** (Option 1 or 2 above)
2. **Follow automated setup** prompts
3. **Start backend**: `cd backend && ./start_backend.sh`
4. **Start GUI**: `cd gui && ./start_gui.sh`
5. **Begin live traffic testing**

## 📞 **If Issues Persist**

If you still have issues:
```bash
# Check if you have git installed
git --version

# Check if you have internet connection
ping github.com

# Check if you have proper permissions
ls -la ~
```

**The fix script will handle everything automatically!** 🚀