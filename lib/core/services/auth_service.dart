import 'package:firebase_auth/firebase_auth.dart';
import 'package:dedikodu_app/data/repositories/user_repository.dart';

class AuthService {
  final FirebaseAuth? _authInstance;
  
  AuthService({FirebaseAuth? auth}) : _authInstance = auth;
  
  // Lazy getter for FirebaseAuth
  FirebaseAuth get _auth => _authInstance ?? FirebaseAuth.instance;

  // Get current user
  User? get currentUser => _auth.currentUser;

  // Get current user ID
  String? get currentUserId => _auth.currentUser?.uid;

  // Sign in anonymously
  Future<String?> signInAnonymously() async {
    try {
      final userCredential = await _auth.signInAnonymously();
      return userCredential.user?.uid;
    } catch (e) {
      print('Error signing in anonymously: $e');
      return null;
    }
  }

  // Register with email and password
  Future<String?> registerWithEmail(String email, String password) async {
    try {
      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      return userCredential.user?.uid;
    } catch (e) {
      print('Error registering with email: $e');
      rethrow;
    }
  }

  // Sign in with email or username and password
  Future<String?> signInWithEmail(String emailOrUsername, String password) async {
    try {
      String email = emailOrUsername.trim();
      
      // Check if input is username (no @ symbol) or email
      if (!email.contains('@')) {
        // It's a username, need to find the email
        final userRepo = UserRepository();
        final user = await userRepo.getUserByUsername(email);
        
        if (user == null) {
          throw FirebaseAuthException(
            code: 'user-not-found',
            message: 'Kullanıcı adı bulunamadı',
          );
        }
        
        // Use the email from user document
        if (user.email == null) {
          throw FirebaseAuthException(
            code: 'email-not-found',
            message: 'Kullanıcı e-posta adresi bulunamadı',
          );
        }
        
        email = user.email!;
      }
      
      final userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return userCredential.user?.uid;
    } catch (e) {
      print('Error signing in: $e');
      rethrow;
    }
  }

  // Reset password
  Future<void> resetPassword(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
      print('Password reset email sent to: $email');
    } catch (e) {
      print('Error sending password reset email: $e');
      rethrow;
    }
  }

  // Sign out
  Future<void> signOut() async {
    await _auth.signOut();
  }

  // Delete account
  Future<void> deleteAccount() async {
    final user = _auth.currentUser;
    if (user != null) {
      await user.delete();
    }
  }

  // Auth state changes
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Check if user is anonymous
  bool get isAnonymous => _auth.currentUser?.isAnonymous ?? true;
}
