# SOBAT HR Custom Proguard Rules

# ----------------------------------------------------------------------------
# Note on Flutter & Dart Obfuscation vs. ProGuard:
# Flutter's `--obfuscate` command scrambles Dart class and variable names, 
# but it DOES NOT scramble String literals (e.g., json['employee_id']).
# Because `User.fromJson()` in `lib/models/user.dart` uses manual map string 
# keys to parse data, it is inherently safe against obfuscation breakages.
#
# There is no need for `@Keep` annotations in pure Dart models for JSON mapping.
# ----------------------------------------------------------------------------

# If you ever introduce native Android MethodChannels or Java/Kotlin GSON 
# serialization that relies on exact class naming, you would add rules like:
# -keep class co.sobat.sobat_hr.models.** { *; }
