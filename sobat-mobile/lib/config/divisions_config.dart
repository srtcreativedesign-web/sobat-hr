/// Configuration for all divisions in SOBAT HR
/// 
/// Centralizes division endpoint mapping to avoid duplication
/// and ensure consistency across services.
class DivisionsConfig {
  /// Map of division codes to their base API endpoints
  static const Map<String, String> endpoints = {
    'office': 'payrolls/ho',
    'fnb': 'payrolls/fnb',
    'minimarket': 'payrolls/mm',
    'reflexiology': 'payrolls/ref',
    'wrapping': 'payrolls/wrapping',
    'hans': 'payrolls/hans',
    'celluller': 'payroll-cellullers',
  };

  /// List of all division codes
  static List<String> get allDivisions => endpoints.keys.toList();

  /// Get base endpoint for a division
  /// 
  /// Returns the base endpoint path for the given division code.
  /// Example: 'office' -> 'payrolls/ho'
  static String? getBaseEndpoint(String division) {
    return endpoints[division];
  }

  /// Get full slip endpoint for a division
  /// 
  /// Returns the complete endpoint path for downloading a payslip.
  /// Example: 'office', 123 -> 'payrolls/ho/123/slip'
  static String getSlipEndpoint(String division, int id) {
    final base = endpoints[division];
    if (base == null) {
      throw Exception('Divisi tidak dikenali: $division');
    }
    return '$base/$id/slip';
  }

  /// Get THR slip endpoint
  /// 
  /// THR uses a different endpoint structure than regular payroll
  static String getThrSlipEndpoint(int id) {
    return 'thrs/$id/slip';
  }

  /// Check if a division code is valid
  static bool isValidDivision(String division) {
    return endpoints.containsKey(division);
  }

  /// Get division display name
  static String getDisplayName(String division) {
    const names = {
      'office': 'Head Office',
      'fnb': 'Food & Beverage',
      'minimarket': 'Minimarket',
      'reflexiology': 'Reflexiology',
      'wrapping': 'Wrapping',
      'hans': 'Security (Hans)',
      'celluller': 'Celluller',
    };
    return names[division] ?? division;
  }
}
