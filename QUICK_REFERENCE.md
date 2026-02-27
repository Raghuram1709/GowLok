# Quick Reference Guide - Authentication System

## 🚀 Quick Start

### Installation
```bash
flutter pub get
```

### App Automatically Routes Based on Auth
- **Not logged in** → LoginScreen
- **Logged in** → Main app (AppRouter)

## 📋 Common Tasks

### Check if User is Authenticated
```dart
final authProvider = context.read<AuthProvider>();
if (authProvider.isAuthenticated) {
  print('User is logged in: ${authProvider.userEmail}');
}
```

### Get Current User
```dart
final user = context.read<AuthProvider>().user;
print('User ID: ${user?.id}');
print('User Email: ${user?.email}');
```

### Listen to Auth Changes
```dart
Consumer<AuthProvider>(
  builder: (context, authProvider, _) {
    return Text(authProvider.userEmail ?? 'Not logged in');
  },
)
```

### Logout User
```dart
await context.read<AuthProvider>().signOut();
// Automatically redirects to LoginScreen
```

### Handle Login in Screen
```dart
final success = await context.read<AuthProvider>().signInWithEmail(
  email: 'user@example.com',
  password: 'password123',
);

if (success) {
  // Navigate to app
  Navigator.of(context).pushReplacementNamed('/home');
} else {
  // Error is in authProvider.errorMessage
}
```

## 🎨 UI Components

### AuthTextField
```dart
AuthTextField(
  controller: emailController,
  label: 'Email',
  hint: 'your@email.com',
  prefixIcon: Icons.email_outlined,
  validator: AuthValidator.validateEmail,
)
```

### AuthButton
```dart
AuthButton(
  label: 'Sign In',
  isLoading: isLoading,
  onPressed: () => handleLogin(),
)
```

### PasswordStrengthIndicator
```dart
PasswordStrengthIndicator(
  strength: AuthValidator.checkPasswordStrength(password),
)
```

## ✔️ Validation

### Validate Email
```dart
String? error = AuthValidator.validateEmail(emailValue);
// Returns error message or null if valid
```

### Validate Password
```dart
String? error = AuthValidator.validatePassword(passwordValue);
// Returns error message or null if valid
// Minimum 6 characters required
```

### Check Password Strength
```dart
PasswordStrength strength = AuthValidator.checkPasswordStrength(password);
// Returns: empty | weak | medium | strong
```

### Validate Confirmation
```dart
String? error = AuthValidator.validatePasswordConfirmation(
  confirmValue,
  originalPassword,
);
```

## 🔐 AuthValidator Enum

```dart
enum PasswordStrength {
  empty,    // No password
  weak,     // < 6 characters
  medium,   // 6-10 characters
  strong,   // 10+ chars + uppercase + lowercase + numbers + special
}

// Access properties
strength.label    // "Weak", "Medium", "Strong"
strength.value    // 0, 1, 2, 3
```

## 📱 Error Messages

The system automatically converts Supabase errors to user-friendly messages:

```dart
// Supabase Error → User Message
"Invalid login credentials" → "Invalid email or password"
"Email not confirmed" → "Please confirm your email first"
"User already registered" → "Email already registered"
"Password should be at least 6" → "Password must be at least 6 characters"
"Invalid email" → "Please enter a valid email"
```

## 🔄 Auth Flow Diagram

```
App Start
    ↓
AuthGate checks authentication
    ↓
Not Authenticated? → LoginScreen
    ├─→ Sign In → Success → AppRouter (main app)
    ├─→ Sign Up → Signup → Login → Success → AppRouter
    └─→ Forgot Password → Reset Email → Login → Success → AppRouter
    ↓
Authenticated? → AppRouter (main app)
```

## 📂 File Locations

| Component | Location |
|-----------|----------|
| Service | `lib/core/auth/auth_service.dart` |
| State | `lib/core/auth/auth_provider.dart` |
| Validator | `lib/core/auth/auth_validator.dart` |
| Auth Gate | `lib/core/auth/auth_gate.dart` |
| Login Screen | `lib/features/auth/screens/login_screen.dart` |
| Profile Page | `lib/features/profile/profile_page.dart` (contains theme selector & logout) |
| Signup Screen | `lib/features/auth/screens/signup_screen.dart` |
| Reset Screen | `lib/features/auth/screens/reset_password_screen.dart` |
| Text Field | `lib/features/auth/widgets/auth_text_field.dart` |
| Button | `lib/features/auth/widgets/auth_button.dart` |
| Strength Indicator | `lib/features/auth/widgets/password_strength_indicator.dart` |

## 🧪 Testing

### Test Login (Valid Credentials)
1. Open app → LoginScreen
2. Navigate to profile page via bottom nav → open theme dialog, switch light/dark/system

2. Enter registered email and correct password
3. Click "Sign In"
4. Should navigate to AppRouter

### Test Signup
1. Click "Sign up" on LoginScreen
2. Enter new email
3. Enter password (watch strength indicator)
4. Confirm password
5. Click "Sign Up"
6. See success message
7. Redirects to LoginScreen

### Test Password Reset
1. Click "Forgot password?" on LoginScreen
2. Enter registered email
3. Click "Send Reset Link"
4. See confirmation screen
5. (Check email for reset link in real Supabase)

### Test Error Handling
1. Try to login with wrong password
2. See error message in red box
3. Try to signup with existing email
4. See "Email already registered" error
5. Try passwords < 6 characters
6. See validation error

## 🐛 Debugging

### Check Auth State
```dart
final authProvider = context.read<AuthProvider>();
print('Is Authenticated: ${authProvider.isAuthenticated}');
print('User: ${authProvider.user}');
print('Email: ${authProvider.userEmail}');
print('Loading: ${authProvider.isLoading}');
print('Error: ${authProvider.errorMessage}');
```

### View Auth State in Stream
```dart
Supabase.instance.client.auth.onAuthStateChange.listen((event) {
  print('Auth State Changed');
  print('User: ${event.session?.user}');
  print('Event: ${event.event}');
});
```

## 📚 Learn More

- Full documentation: `AUTH_SYSTEM_README.md`
- Implementation summary: `IMPLEMENTATION_SUMMARY.md`
- Completion checklist: `COMPLETION_CHECKLIST.md`

---

**Last Updated**: February 26, 2025  
**Status**: ✅ Production Ready
