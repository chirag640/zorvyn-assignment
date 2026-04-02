class AppCurrency {
  AppCurrency._();

  static const String defaultCode = 'USD';
  static String _currencyCode = defaultCode;

  static const Map<String, String> _symbols = {
    'USD': r'$',
    'INR': '\u20B9',
    'EUR': '\u20AC',
    'GBP': '\u00A3',
    'JPY': '\u00A5',
  };

  static const Map<String, String> _names = {
    'USD': 'US Dollar',
    'INR': 'Indian Rupee',
    'EUR': 'Euro',
    'GBP': 'British Pound',
    'JPY': 'Japanese Yen',
  };

  static String get code => _currencyCode;
  static String get symbol => symbolFor(_currencyCode);

  static List<String> get supportedCodes =>
      _symbols.keys.toList(growable: false);

  static void setCurrencyCode(String code) {
    final normalized = code.trim().toUpperCase();
    if (_symbols.containsKey(normalized)) {
      _currencyCode = normalized;
      return;
    }
    _currencyCode = defaultCode;
  }

  static String symbolFor(String code) {
    final normalized = code.trim().toUpperCase();
    return _symbols[normalized] ?? _symbols[defaultCode]!;
  }

  static String nameFor(String code) {
    final normalized = code.trim().toUpperCase();
    return _names[normalized] ?? _names[defaultCode]!;
  }
}
