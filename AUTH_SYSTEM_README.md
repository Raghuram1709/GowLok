# Authentication System Documentation

## Overview
This document describes the newly built, production-ready authentication system for the GOWLOK application. The system is built on Supabase with a clean architecture, proper state management using Provider, and comprehensive validation.

## Architecture

### 1. Service Layer (`lib/core/auth/auth_service.dart`)
The `AuthService` class provides a clean interface to Supabase authentication methods:

**Key Methods:**
- `signUpWithEmail()` - Register new users
- `signInWithEmail()` - Authenticate existing users
- `resetPassword()` - Initiate password reset flow
- `updatePassword()` - Update user password
- `signOut()` - Sign out current user
- `authStateChanges` - Stream of auth state changes

**Features:**
- Centralized error handling with Supabase exceptions
- User and session management
- Clean separation of concerns

### 2. State Management (`lib/core/auth/auth_provider.dart`)
The `AuthProvider` extends `ChangeNotifier` and manages authentication state:

**State Variables:**
- `user` - Current authenticated user
- `isAuthenticated` - Whether user is logged in
- `isLoading` - Loading state during auth operations
- `errorMessage` - Display-friendly error messages

**Methods:**
- `signUpWithEmail()` - Register with email/password
- `signInWithEmail()` - Login with email/password
- `resetPassword()` - Send password reset email
- `signOut()` - Logout user

**Features:**
- User-friendly error message parsing
- Automatic auth state listening
- Loading state management
- Error handling and display

### 3. Validation (`lib/core/auth/auth_validator.dart`)
The `AuthValidator` class provides comprehensive validation:

**Validators:**
- `validateEmail()` - Email format validation
- `validatePassword()` - Password strength requirements
- `validatePasswordConfirmation()` - Password matching
- `checkPasswordStrength()` - Strength assessment (Weak/Medium/Strong)

**PasswordStrength Enum:**
```dart
enum PasswordStrength {
  empty,    // No password entered
  weak,     // Less than 6 characters
  medium,   // 6-10 characters
  strong,   // 10+ characters with uppercase, lowercase, numbers, special chars
}
```

### 4. Auth Gate (`lib/core/auth/auth_gate.dart`)
The `AuthGate` is a root-level widget that routes based on authentication status:

**Behavior:**
- If not authenticated → Shows `LoginScreen`
- If authenticated → Shows `AppRouter` (main app)
- Listens to auth state changes in real-time

## UI Screens

### Login Screen (`lib/features/auth/screens/login_screen.dart`)
Professional login interface with:
- Email and password input fields
- "Forgot password" link
- Error display with visual feedback
- Loading state handling
- Sign-up navigation
- Form validation

### Sign-up Screen (`lib/features/auth/screens/signup_screen.dart`)
Complete registration interface with:
- Email input
- Password input with real-time strength indicator
- Password confirmation field
- Password strength visual feedback
- Error handling
- Login navigation
- Form validation

### Reset Password Screen (`lib/features/auth/screens/reset_password_screen.dart`)
Password recovery flow with:
- Email input for password reset
- Success confirmation screen
- Email sent verification
- Spam folder notice
- Back to login navigation

## Reusable Widgets

### AuthTextField (`lib/features/auth/widgets/auth_text_field.dart`)
Customizable input field for auth forms:
- Label and hint text
- Icon support (prefix and suffix)
- Visibility toggle for password fields
- Form validation
- Disabled state handling
- Modern styling with border radius

### AuthButton (`lib/features/auth/widgets/auth_button.dart`)
Standard action button for auth screens:
- Loading state with spinner
- Full-width or custom width
- Disabled state handling
- Consistent styling across screens

### PasswordStrengthIndicator (`lib/features/auth/widgets/password_strength_indicator.dart`)
Visual password strength feedback:
- Colored progress bar (Red/Orange/Green)
- Strength label text
- Real-time updates as user types

## Integration Points

### 1. App Setup (`lib/app.dart`)
```dart
class GowlokApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final authService = AuthService(Supabase.instance.client);

    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => AuthProvider(authService)..initialize(),
        ),
      ],
      child: MaterialApp(
        home: const AuthGate(),
        // ... other config
      ),
    );
  }
}
```

### 2. Using AuthProvider in Screens
```dart
Consumer<AuthProvider>(
  builder: (context, authProvider, _) {
    return Column(
      children: [
        if (authProvider.isLoading)
          Center(child: CircularProgressIndicator()),
        if (authProvider.errorMessage != null)
          ErrorWidget(message: authProvider.errorMessage!),
      ],
    );
  },
)
```

## Error Handling

The system provides user-friendly error messages:

| Supabase Error | User Message |
|---|---|
| Invalid login credentials | Invalid email or password |
| Email not confirmed | Please confirm your email first |
| User already registered | Email already registered |
| Password should be at least | Password must be at least 6 characters |
| Invalid email | Please enter a valid email |

## Password Security

### Requirements
- Minimum 6 characters
- Validation for format and match confirmation

### Strength Levels
- **Weak**: < 6 characters
- **Medium**: 6-10 characters
- **Strong**: 10+ characters with uppercase, lowercase, numbers, and special characters

## Session Management

The system automatically:
1. Checks for existing session on app startup via `AuthProvider.initialize()`
2. Listens to Supabase auth state changes in real-time
3. Updates UI reactively when auth state changes
4. Persists session across app restarts (Supabase handles this)

## Best Practices

### When Adding New Auth Features
1. Add service method to `AuthService`
2. Add state/method to `AuthProvider`
3. Add validator if needed to `AuthValidator`
4. Create UI screen or widget

### When Using Authentication
```dart
// Get provider
final authProvider = context.read<AuthProvider>();

// Get current user
final user = authProvider.user;

// Check authentication
if (authProvider.isAuthenticated) {
  // User is logged in
}

// Handle auth operations
final success = await authProvider.signInWithEmail(
  email: 'user@example.com',
  password: 'password123'
);
```

### Testing
- Validators can be tested independently
- AuthService mocking via Supabase client
- AuthProvider can be tested with mock service
- UI screens respond to AuthProvider state changes

## File Structure
```
lib/
├── core/
│   └── auth/
│       ├── auth_service.dart      # Service layer
│       ├── auth_provider.dart      # State management
│       ├── auth_validator.dart     # Validation logic
│       ├── auth_gate.dart          # Root auth check
│       └── exports.dart            # Public exports
├── features/
│   └── auth/
│       ├── screens/
│       │   ├── login_screen.dart
│       │   ├── signup_screen.dart
│       │   └── reset_password_screen.dart
│       ├── widgets/
│       │   ├── auth_text_field.dart
│       │   ├── auth_button.dart
│       │   └── password_strength_indicator.dart
│       └── exports.dart            # Public exports
└── app.dart                        # App setup with auth
```

## Next Steps

1. Test the auth flow with your Supabase instance
2. Customize UI theme to match your brand
3. Add additional fields (name, phone, etc.) during signup
4. Implement email verification if needed
5. Add OAuth providers (Google, GitHub) to AuthService
6. Add biometric authentication if needed

## Troubleshooting

### Provider errors
- Ensure `MultiProvider` wraps the MaterialApp
- Check AuthProvider initialization with `..initialize()`

### Form validation not showing
- Verify Form key is used in FormState.validate()
- Check validator functions return null for valid input

### Auth state not updating
- Verify AuthGate is in the home property
- Check Supabase connection in main.dart

### Password strength not updating
- Verify `onChanged` callback is connected
- Check PasswordStrength enum values
