bool isPasswordStrong(String pwd) {
  if (pwd.length < 8) return false;
  if (!RegExp(r'[A-Z]').hasMatch(pwd)) return false;
  if (!RegExp(r'\d').hasMatch(pwd)) return false;
  return true;
}
