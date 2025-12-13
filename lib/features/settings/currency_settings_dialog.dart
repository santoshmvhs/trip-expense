import 'package:flutter/material.dart';
import '../../services/currency_service.dart';

class CurrencySettingsDialog extends StatefulWidget {
  final String currentCurrency;

  const CurrencySettingsDialog({
    super.key,
    required this.currentCurrency,
  });

  @override
  State<CurrencySettingsDialog> createState() => _CurrencySettingsDialogState();
}

class _CurrencySettingsDialogState extends State<CurrencySettingsDialog> {
  late String _selectedCurrency;
  Map<String, double>? _exchangeRates;
  bool _isLoadingRates = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _selectedCurrency = widget.currentCurrency;
    _loadExchangeRates();
  }

  Future<void> _loadExchangeRates() async {
    setState(() {
      _isLoadingRates = true;
      _errorMessage = null;
    });

    try {
      // Always use INR as base currency
      final rates = await CurrencyService.getExchangeRates('INR');
      setState(() {
        _exchangeRates = rates;
        _isLoadingRates = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to load exchange rates';
        _isLoadingRates = false;
      });
    }
  }

  static const List<Map<String, String>> currencies = [
    {'code': 'INR', 'name': 'Indian Rupee', 'symbol': '₹'},
    {'code': 'USD', 'name': 'US Dollar', 'symbol': '\$'},
    {'code': 'EUR', 'name': 'Euro', 'symbol': '€'},
    {'code': 'GBP', 'name': 'British Pound', 'symbol': '£'},
    {'code': 'JPY', 'name': 'Japanese Yen', 'symbol': '¥'},
    {'code': 'AUD', 'name': 'Australian Dollar', 'symbol': 'A\$'},
    {'code': 'CAD', 'name': 'Canadian Dollar', 'symbol': 'C\$'},
    {'code': 'CHF', 'name': 'Swiss Franc', 'symbol': 'CHF'},
    {'code': 'CNY', 'name': 'Chinese Yuan', 'symbol': '¥'},
    {'code': 'SGD', 'name': 'Singapore Dollar', 'symbol': 'S\$'},
    {'code': 'HKD', 'name': 'Hong Kong Dollar', 'symbol': 'HK\$'},
    {'code': 'THB', 'name': 'Thai Baht', 'symbol': '฿'},
    {'code': 'KRW', 'name': 'South Korean Won', 'symbol': '₩'},
    {'code': 'MXN', 'name': 'Mexican Peso', 'symbol': '\$'},
    {'code': 'NZD', 'name': 'New Zealand Dollar', 'symbol': 'NZ\$'},
    {'code': 'SEK', 'name': 'Swedish Krona', 'symbol': 'kr'},
    {'code': 'NOK', 'name': 'Norwegian Krone', 'symbol': 'kr'},
    {'code': 'DKK', 'name': 'Danish Krone', 'symbol': 'kr'},
    {'code': 'PLN', 'name': 'Polish Zloty', 'symbol': 'zł'},
    {'code': 'ZAR', 'name': 'South African Rand', 'symbol': 'R'},
    {'code': 'BRL', 'name': 'Brazilian Real', 'symbol': 'R\$'},
    {'code': 'RUB', 'name': 'Russian Ruble', 'symbol': '₽'},
    {'code': 'TRY', 'name': 'Turkish Lira', 'symbol': '₺'},
    {'code': 'AED', 'name': 'UAE Dirham', 'symbol': 'د.إ'},
    {'code': 'SAR', 'name': 'Saudi Riyal', 'symbol': '﷼'},
  ];

  String? _getExchangeRate(String currencyCode) {
    if (_exchangeRates == null) {
      return null;
    }
    
    // INR is always the base, so for INR itself, show 1.0
    if (currencyCode == 'INR') {
      return '1.00';
    }
    
    // For other currencies, get the rate from INR to that currency
    final rate = _exchangeRates![currencyCode];
    if (rate == null) return null;
    
    // Format to show meaningful decimal places
    // For rates > 1, show 2 decimals, for rates < 1, show 4 decimals
    if (rate >= 1.0) {
      return rate.toStringAsFixed(2);
    } else {
      return rate.toStringAsFixed(4);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Select Default Currency'),
      content: SizedBox(
        width: double.maxFinite,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Exchange rate info banner
            if (_isLoadingRates)
              const Padding(
                padding: EdgeInsets.all(8.0),
                child: Row(
                  children: [
                    SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                    SizedBox(width: 8),
                    Text('Loading exchange rates...', style: TextStyle(fontSize: 12)),
                  ],
                ),
              )
            else if (_errorMessage != null)
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.orange.shade50,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, size: 16, color: Colors.orange.shade700),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _errorMessage!,
                        style: TextStyle(fontSize: 12, color: Colors.orange.shade700),
                      ),
                    ),
                  ],
                ),
              )
            else if (_exchangeRates != null)
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Row(
                  children: [
                    Icon(Icons.trending_up, size: 16, color: Colors.blue.shade700),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'All rates shown in INR (Indian Rupee)',
                        style: TextStyle(fontSize: 12, color: Colors.blue.shade700),
                      ),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 8),
            Flexible(
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: currencies.length,
                itemBuilder: (context, index) {
                  final currency = currencies[index];
                  final currencyCode = currency['code']!;
                  final exchangeRate = _getExchangeRate(currencyCode);
                  final isSelected = currencyCode == _selectedCurrency;
                  final isCurrent = currencyCode == widget.currentCurrency;

                  return RadioListTile<String>(
                    title: Row(
                      children: [
                        Text('${currency['symbol']} ${currency['name']}'),
                        if (isCurrent)
                          Padding(
                            padding: const EdgeInsets.only(left: 8),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.green.shade100,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                'Current',
                                style: TextStyle(
                                  fontSize: 10,
                                  color: Colors.green.shade700,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(currencyCode),
                        if (exchangeRate != null)
                          Text(
                            currencyCode == 'INR'
                                ? 'Base currency (₹1.00)'
                                : '1 $currencyCode = ₹$exchangeRate',
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.grey.shade600,
                              fontStyle: FontStyle.italic,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                      ],
                    ),
                    value: currencyCode,
                    groupValue: _selectedCurrency,
                    onChanged: (value) {
                      setState(() {
                        _selectedCurrency = value!;
                      });
                    },
                    selected: isSelected,
                  );
                },
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context, _selectedCurrency),
          child: const Text('Save'),
        ),
      ],
    );
  }
}

