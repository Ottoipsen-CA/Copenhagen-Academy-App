import '../models/user.dart';
import '../models/auth.dart';
import 'base_repository.dart';

abstract class AuthRepository {
  Future<String?> login(String email, String password);
  Future<void> logout();
  Future<bool> isLoggedIn();
  Future<User?> getCurrentUser();
  Future<User?> registerUser(String email, String fullName, String password);
  Future<User?> updateUser(User user);
} 