# Security Guidelines

## 🔒 Secret Management

### ✅ DO:
- **Always use environment variables** for secrets (passwords, API keys, JWT secrets)
- **Never commit** `.env` files or files containing actual secrets
- **Use `.env.example`** to document required environment variables with placeholder values
- **Generate secure passwords** using: `python -c "import secrets; print(secrets.token_urlsafe(16))"`
- **Generate JWT secrets** using: `openssl rand -hex 32`
- **Rotate secrets regularly** in production environments

### ❌ DON'T:
- **Never hardcode** passwords, API keys, or secrets in source code
- **Never commit** actual credentials to git
- **Never share** `.env` files or credentials in pull requests or issues
- **Never use** weak/default passwords in production

## 📝 Environment Variables

### Required for Backend Setup:
```bash
# Database (optional - uses postgres superuser by default)
DATABASE_URL=postgresql+psycopg2://postgres@localhost:5432/ids_idps_db

# JWT Secret (REQUIRED)
JWT_SECRET=<generate using: openssl rand -hex 32>

# User Passwords (optional - auto-generated if not set)
ADMIN_PASSWORD=<generate using: python -c "import secrets; print(secrets.token_urlsafe(16))">
ANALYST_PASSWORD=<generate using: python -c "import secrets; print(secrets.token_urlsafe(16))">
```

### Setup Process:
1. Copy `backend/.env.example` to `backend/.env`
2. Generate secure secrets and update `.env` file
3. The `.env` file is automatically ignored by git (see `.gitignore`)

## 🛡️ GitGuardian Compliance

This repository is configured to be GitGuardian-compliant:

- ✅ All hardcoded secrets have been removed from source code
- ✅ Passwords are read from environment variables or auto-generated
- ✅ `.env` files are properly ignored in `.gitignore`
- ✅ Example files (`.env.example`) use placeholder values only

### Files Safe for Git:
- ✅ `backend/.env.example` - Contains only placeholder values
- ✅ `backend/setup.py` - Uses environment variables or generates secure passwords
- ✅ All application code - No hardcoded secrets

### Files Ignored by Git:
- ❌ `backend/.env` - Actual secrets (DO NOT COMMIT)
- ❌ `**/*credentials*.txt` - Credential files
- ❌ `**/*secrets*.env` - Secret environment files

## 🔍 Pre-commit Checks

Before committing, ensure:
1. No hardcoded passwords in source code
2. No `.env` files added to git staging
3. All secrets use environment variables or secure generation
4. Run: `git status` to verify no credential files are staged

## 📞 Security Issues

If you discover a security vulnerability:
1. **DO NOT** create a public issue
2. Contact the maintainers privately
3. Wait for the issue to be resolved before public disclosure

