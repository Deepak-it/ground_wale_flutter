import 'package:flutter/material.dart';
import 'package:ground_wale/core/widgets/app_text_field.dart';

import '../../../core/api/api_session.dart';
import '../../../core/api/ground_wale_api.dart';
import 'package:intl/intl.dart';

class BoxCricketBookingCollectionClient extends StatefulWidget {
  const BoxCricketBookingCollectionClient({super.key});

  @override
  State<BoxCricketBookingCollectionClient> createState() =>
      _BoxCricketBookingCollectionClientState();
}

class _BoxCricketBookingCollectionClientState
    extends State<BoxCricketBookingCollectionClient> {
  static const String _allGroundsValue = '__all_grounds__';

  bool _isLoading = true;
  bool _isSavingPayment = false;
  String _status = 'All';
  String? _selectedGroundId;
  String? _selectedClientKey;
  List<Map<String, dynamic>> _grounds = <Map<String, dynamic>>[];
  List<Map<String, dynamic>> _bookings = <Map<String, dynamic>>[];
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      if (!mounted) {
        return;
      }
      setState(() {});
    });
    _load();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  String _groundId(Map<String, dynamic> ground) {
    return ground['_id']?.toString() ?? ground['id']?.toString() ?? '';
  }

  String _groundName(Map<String, dynamic> ground) {
    final String name =
        ground['groundName']?.toString().trim() ??
        ground['name']?.toString().trim() ??
        '';
    return name.isEmpty ? 'Unnamed Ground' : name;
  }

  String _bookingGroundName(Map<String, dynamic> booking) {
    final String name =
        booking['groundName']?.toString().trim() ??
        booking['ground']?['groundName']?.toString().trim() ??
        booking['ground']?['name']?.toString().trim() ??
        booking['courtName']?.toString().trim() ??
        '';
    return name.isEmpty ? 'Unnamed Ground' : name;
  }

  String _selectedGroundLabel() {
    if (_selectedGroundId == null || _selectedGroundId == _allGroundsValue) {
      return 'All Grounds';
    }
    final Map<String, dynamic>? selected = _grounds
        .cast<Map<String, dynamic>?>()
        .firstWhere(
          (Map<String, dynamic>? ground) =>
              ground != null && _groundId(ground) == _selectedGroundId,
          orElse: () => null,
        );
    if (selected == null) {
      return 'All Grounds';
    }
    return _groundName(selected);
  }

  Future<List<Map<String, dynamic>>> _loadOwnerGrounds() async {
    final String? ownerId = ApiSession.instance.ownerId;
    if (ownerId == null || ownerId.isEmpty) {
      return <Map<String, dynamic>>[];
    }

    return GroundWaleApi.instance.listGrounds(ownerId: ownerId);
  }

  String? _resolveSelectedGroundId(List<Map<String, dynamic>> grounds) {
    if (grounds.isEmpty) {
      return null;
    }

    final String? currentSelection = _selectedGroundId;
    if (currentSelection == _allGroundsValue) {
      return currentSelection;
    }
    if (currentSelection != null &&
        grounds.any(
          (Map<String, dynamic> ground) =>
              _groundId(ground) == currentSelection,
        )) {
      return currentSelection;
    }

    final String preferred = ApiSession.instance.groundId ?? '';
    if (preferred.isNotEmpty &&
        grounds.any(
          (Map<String, dynamic> ground) => _groundId(ground) == preferred,
        )) {
      return preferred;
    }

    return _allGroundsValue;
  }

  Future<void> _load() async {
    if (mounted) {
      setState(() => _isLoading = true);
    }

    final List<Map<String, dynamic>> grounds = await _loadOwnerGrounds();
    final String? selectedGroundId = _resolveSelectedGroundId(grounds);

    if (grounds.isEmpty || selectedGroundId == null) {
      if (!mounted) {
        return;
      }
      setState(() {
        _grounds = <Map<String, dynamic>>[];
        _selectedGroundId = null;
        _bookings = <Map<String, dynamic>>[];
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No grounds found for this owner.')),
      );
      return;
    }

    try {
      final bool loadAllGrounds = selectedGroundId == _allGroundsValue;
      final Iterable<Map<String, dynamic>> targetGrounds = loadAllGrounds
          ? grounds
          : grounds.where(
              (Map<String, dynamic> ground) =>
                  _groundId(ground) == selectedGroundId,
            );

      final List<List<Map<String, dynamic>>> bookingSets = await Future.wait(
        targetGrounds.map((Map<String, dynamic> ground) async {
          final String groundId = _groundId(ground);
          final List<Map<String, dynamic>> bookings = await GroundWaleApi
              .instance
              .listBookings(groundId);
          return bookings
              .map((Map<String, dynamic> booking) {
                return <String, dynamic>{
                  ...booking,
                  'groundId': groundId,
                  'groundName': _groundName(ground),
                };
              })
              .toList(growable: false);
        }),
      );

      final List<Map<String, dynamic>> bookings = bookingSets
          .expand((List<Map<String, dynamic>> items) => items)
          .toList(growable: false);

      if (!mounted) {
        return;
      }
      setState(() {
        _grounds = grounds;
        _selectedGroundId = selectedGroundId;
        _bookings = bookings;
        _isLoading = false;
      });
      if (!loadAllGrounds) {
        ApiSession.instance.setGroundId(selectedGroundId);
      }
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error.toString().replaceFirst('Exception: ', '')),
        ),
      );
    }
  }

  String _bookingId(Map<String, dynamic> booking) {
    return booking['_id']?.toString() ?? booking['id']?.toString() ?? '';
  }

  String _bookingCode(Map<String, dynamic> booking) {
    final String raw =
        booking['bookingCode']?.toString().trim() ??
        booking['bookingNo']?.toString().trim() ??
        booking['bookingNumber']?.toString().trim() ??
        '';
    if (raw.isNotEmpty) {
      return raw.toUpperCase();
    }
    final String id = _bookingId(booking);
    if (id.length >= 4) {
      return 'BK-${id.substring(id.length - 4).toUpperCase()}';
    }
    return 'BK-0000';
  }

  String _teamName(Map<String, dynamic> booking) {
    final String team = booking['teamName']?.toString().trim() ?? '';
    return team.isEmpty ? 'Team' : team;
  }

  String _captainName(Map<String, dynamic> booking) {
    final String captain = booking['captainName']?.toString().trim() ?? '';
    if (captain.isNotEmpty) {
      return captain;
    }
    return _teamName(booking);
  }

  String _captainPhone(Map<String, dynamic> booking) {
    return booking['captainPhone']?.toString().trim() ?? '';
  }

  int _toInt(dynamic value) {
    if (value is int) {
      return value;
    }
    if (value is double) {
      return value.round();
    }
    if (value is String) {
      return int.tryParse(value) ?? 0;
    }
    return 0;
  }

  int _amount(Map<String, dynamic> booking) {
    return _toInt(booking['amount']);
  }

  int _paidFromTransactions(Map<String, dynamic> booking) {
    final List<Map<String, dynamic>> txns = _bookingTransactions(booking);
    if (txns.isEmpty) {
      return 0;
    }

    return txns.fold<int>(0, (int sum, Map<String, dynamic> tx) {
      final String status =
          tx['paymentStatus']?.toString().trim().toLowerCase() ??
          tx['status']?.toString().trim().toLowerCase() ??
          '';
      if (status == 'failed') {
        return sum;
      }
      final int value = _txAmount(tx);
      return value > 0 ? (sum + value) : sum;
    });
  }

  int _paidAmount(Map<String, dynamic> booking) {
    final int amount = _amount(booking);
    final int fromField = _toInt(booking['paidAmount']);
    final int fromTransactions = _paidFromTransactions(booking);
    int paid = fromField > fromTransactions ? fromField : fromTransactions;

    if (paid <= 0) {
      final String rawStatus =
          booking['paymentStatus']?.toString().trim().toLowerCase() ?? '';
      if (rawStatus == 'paid' && amount > 0) {
        paid = amount;
      }
    }

    if (paid < 0) {
      return 0;
    }
    if (amount > 0 && paid > amount) {
      return amount;
    }
    return paid;
  }

  int _dueAmount(Map<String, dynamic> booking) {
    final int due = _amount(booking) - _paidAmount(booking);
    return due < 0 ? 0 : due;
  }

  String _paymentStatus(Map<String, dynamic> booking) {
    final String raw =
        booking['paymentStatus']?.toString().trim().toLowerCase() ?? '';
    final int paid = _paidAmount(booking);
    final int total = _amount(booking);

    if (raw == 'failed' && paid <= 0) {
      return 'failed';
    }
    if (paid <= 0) {
      return 'pending';
    }
    if (total > 0 && paid >= total) {
      return 'paid';
    }
    return 'partial';
  }

  String _paymentMethod(Map<String, dynamic> booking) {
    return booking['paymentMethod']?.toString().trim().toLowerCase() ?? 'upi';
  }

  bool _canCollect(Map<String, dynamic> booking) {
    if (_dueAmount(booking) <= 0) {
      return false;
    }
    final String method = _paymentMethod(booking);
    return method == 'cod' || method == 'cash';
  }

  String _currency(int amount) {
    return 'Rs $amount';
  }

  String _statusLabel(String status) {
    if (status.isEmpty) {
      return 'Pending';
    }
    return '${status.substring(0, 1).toUpperCase()}${status.substring(1)}';
  }

  List<Map<String, dynamic>> _visibleBookings() {
    final String query = _searchController.text.trim().toLowerCase();
    return _bookings.where((Map<String, dynamic> booking) {
      final String? selectedClient = _selectedClientKey;
      if (selectedClient != null && _clientKey(booking) != selectedClient) {
        return false;
      }

      final String status = _paymentStatus(booking);
      final bool matchesStatus = _status == 'All'
          ? true
          : _status == 'Pending'
          ? (status == 'pending' || status == 'partial')
          : status == 'paid';
      if (!matchesStatus) {
        return false;
      }
      if (query.isEmpty) {
        return true;
      }

      final String team = _teamName(booking).toLowerCase();
      final String captain = _captainName(booking).toLowerCase();
      final String code = _bookingCode(booking).toLowerCase();
      final String groundName = _bookingGroundName(booking).toLowerCase();
      return team.contains(query) ||
          captain.contains(query) ||
          code.contains(query) ||
          groundName.contains(query);
    }).toList();
  }

  String _clientKey(Map<String, dynamic> booking) {
    final String phone = _captainPhone(booking);
    if (phone.isNotEmpty) {
      return 'phone:$phone';
    }

    final String userId =
        booking['userId']?.toString().trim() ??
        booking['user']?['_id']?.toString().trim() ??
        booking['user']?['id']?.toString().trim() ??
        '';
    if (userId.isNotEmpty) {
      return 'user:$userId';
    }

    return 'name:${_captainName(booking).trim().toLowerCase()}';
  }

  List<Map<String, dynamic>> _bookingsForClient(String clientKey) {
    return _bookings
        .where(
          (Map<String, dynamic> booking) => _clientKey(booking) == clientKey,
        )
        .toList(growable: false);
  }

  List<Map<String, dynamic>> _clientTransactions(
    List<Map<String, dynamic>> clientBookings,
  ) {
    final List<Map<String, dynamic>> all = <Map<String, dynamic>>[];
    for (final Map<String, dynamic> booking in clientBookings) {
      final List<Map<String, dynamic>> txns = _bookingTransactions(booking);
      for (final Map<String, dynamic> tx in txns) {
        all.add(<String, dynamic>{
          ...tx,
          'bookingCode': _bookingCode(booking),
          'bookingDate': booking['date'],
          'groundName': _bookingGroundName(booking),
        });
      }
    }

    all.sort((Map<String, dynamic> a, Map<String, dynamic> b) {
      final DateTime? ad = DateTime.tryParse(
        (a['createdAt'] ?? a['updatedAt'] ?? a['date'] ?? '').toString(),
      );
      final DateTime? bd = DateTime.tryParse(
        (b['createdAt'] ?? b['updatedAt'] ?? b['date'] ?? '').toString(),
      );
      if (ad == null && bd == null) {
        return 0;
      }
      if (ad == null) {
        return 1;
      }
      if (bd == null) {
        return -1;
      }
      return bd.compareTo(ad);
    });

    return all;
  }

  String _safeDate(String? raw) {
    if (raw == null || raw.trim().isEmpty) {
      return '-';
    }
    try {
      return DateFormat('dd MMM yyyy').format(DateTime.parse(raw).toLocal());
    } catch (_) {
      return raw;
    }
  }

  String _slotDate(Map<String, dynamic> booking) {
    final String date = _safeDate(booking['date']?.toString());
    final String slot =
        '${booking['startTime']?.toString() ?? '--'} - ${booking['endTime']?.toString() ?? '--'}';
    return '$date\n$slot';
  }

  List<Map<String, dynamic>> _bookingTransactions(
    Map<String, dynamic> booking,
  ) {
    final dynamic source =
        booking['transactions'] ??
        booking['paymentHistory'] ??
        booking['payments'] ??
        booking['collections'];

    if (source is List) {
      return source
          .whereType<Map>()
          .map(
            (Map item) => item.map(
              (dynamic key, dynamic value) =>
                  MapEntry<String, dynamic>(key.toString(), value),
            ),
          )
          .toList(growable: false);
    }

    return <Map<String, dynamic>>[
      <String, dynamic>{
        'amount': _paidAmount(booking),
        'status': _paymentStatus(booking),
        'method': _paymentMethod(booking),
        'createdAt':
            booking['updatedAt'] ?? booking['createdAt'] ?? booking['date'],
      },
    ];
  }

  String _txStatus(Map<String, dynamic> tx) {
    final String value =
        tx['paymentStatus']?.toString() ??
        tx['status']?.toString() ??
        tx['type']?.toString() ??
        '';
    return value.isEmpty ? '-' : _statusLabel(value.toLowerCase());
  }

  int _txAmount(Map<String, dynamic> tx) {
    return _toInt(tx['amount'] ?? tx['paidAmount'] ?? tx['value']);
  }

  String _txDate(Map<String, dynamic> tx) {
    final String? raw =
        tx['createdAt']?.toString() ??
        tx['updatedAt']?.toString() ??
        tx['date']?.toString();
    return _safeDate(raw);
  }

  void _openAllTransactionsView(
    List<Map<String, dynamic>> txns,
    Map<String, dynamic> booking,
  ) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (BuildContext context) {
          return Scaffold(
            backgroundColor: const Color(0xFF0F2027),
            appBar: AppBar(
              backgroundColor: const Color(0xFF17313A),
              foregroundColor: const Color(0xFFE6F7F4),
              elevation: 0,
              title: const Text(
                'All Transactions',
                style: TextStyle(fontSize: 14),
              ),
              actions: <Widget>[
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text(
                    'See Less',
                    style: TextStyle(
                      color: Color(0xFF00C9A7),
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            body: txns.isEmpty
                ? const Center(
                    child: Text(
                      'No transactions found',
                      style: TextStyle(color: Color(0x99FFFFFF), fontSize: 11),
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.all(14),
                    itemCount: txns.length,
                    separatorBuilder: (_, __) =>
                        const Divider(color: Color(0x1FFFFFFF), height: 12),
                    itemBuilder: (_, int index) {
                      final Map<String, dynamic> tx = txns[index];
                      final String method =
                          tx['paymentMethod']?.toString() ??
                          tx['method']?.toString() ??
                          _paymentMethod(booking);
                      return Row(
                        children: <Widget>[
                          Expanded(
                            child: Text(
                              '${_txDate(tx)}\n${tx['bookingCode'] ?? ''}',
                              style: const TextStyle(
                                color: Color(0x99FFFFFF),
                                fontSize: 11,
                                height: 1.2,
                              ),
                            ),
                          ),
                          Expanded(
                            child: Text(
                              _currency(_txAmount(tx)),
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                color: Color(0xFFE6F7F4),
                                fontSize: 11,
                              ),
                            ),
                          ),
                          Expanded(
                            child: Text(
                              method.toUpperCase(),
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                color: Color(0xFF9FB9B3),
                                fontSize: 11,
                              ),
                            ),
                          ),
                          Expanded(
                            child: Text(
                              _txStatus(tx),
                              textAlign: TextAlign.end,
                              style: const TextStyle(
                                color: Color(0xFFF59E0B),
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
          );
        },
      ),
    );
  }

  Future<void> _addDueForBooking(Map<String, dynamic> booking) async {
    final TextEditingController dueCtrl = TextEditingController();
    final int? dueToAdd = await showDialog<int>(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Add Due Amount'),
          content: TextField(
            controller: dueCtrl,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(hintText: 'Enter due amount'),
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                final int value = _toInt(
                  dueCtrl.text.replaceAll(RegExp(r'[^0-9]'), ''),
                );
                Navigator.of(dialogContext).pop(value);
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
    dueCtrl.dispose();

    if (dueToAdd == null || dueToAdd <= 0) {
      return;
    }

    final String bookingId = _bookingId(booking);
    if (bookingId.isEmpty) {
      return;
    }

    setState(() => _isSavingPayment = true);
    try {
      final int newTotal = _amount(booking) + dueToAdd;
      final int paid = _paidAmount(booking);
      final String nextStatus = paid <= 0
          ? 'pending'
          : (paid >= newTotal ? 'paid' : 'partial');
      final Map<String, dynamic> updated = await GroundWaleApi.instance
          .updateBookingStatus(bookingId, <String, dynamic>{
            'amount': newTotal,
            'paymentStatus': nextStatus,
          });

      final int index = _bookings.indexWhere(
        (Map<String, dynamic> item) => _bookingId(item) == bookingId,
      );
      if (index >= 0) {
        _bookings[index] = <String, dynamic>{..._bookings[index], ...updated};
      }

      if (!mounted) {
        return;
      }
      setState(() {});
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Due increased by ${_currency(dueToAdd)}')),
      );
    } catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error.toString().replaceFirst('Exception: ', '')),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isSavingPayment = false);
      }
    }
  }

  void _openClientTransactions(Map<String, dynamic> booking) {
    final String clientKey = _clientKey(booking);
    final List<Map<String, dynamic>> clientBookings = _bookingsForClient(
      clientKey,
    );
    final List<Map<String, dynamic>> txns = _clientTransactions(clientBookings);
    final List<Map<String, dynamic>> previewTxns = txns.take(3).toList();
    final int clientTotal = clientBookings.fold<int>(
      0,
      (int sum, Map<String, dynamic> item) => sum + _amount(item),
    );
    final int clientPaid = clientBookings.fold<int>(
      0,
      (int sum, Map<String, dynamic> item) => sum + _paidAmount(item),
    );
    final int clientDue = clientTotal - clientPaid < 0
        ? 0
        : clientTotal - clientPaid;
    final String court =
        booking['courtName']?.toString() ??
        booking['slotName']?.toString() ??
        booking['groundName']?.toString() ??
        'Main Ground';
    final String slotTime =
        '${booking['startTime'] ?? '--'} - ${booking['endTime'] ?? '--'}';

    setState(() {
      _selectedClientKey = clientKey;
      _searchController.text = _captainName(booking);
      _searchController.selection = TextSelection.fromPosition(
        TextPosition(offset: _searchController.text.length),
      );
    });

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF17313A),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (BuildContext context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: SizedBox(
              height: MediaQuery.of(context).size.height * 0.72,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    _captainName(booking),
                    style: const TextStyle(
                      color: Color(0xFFE6F7F4),
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Team: ${_teamName(booking)} | Booking: ${_bookingCode(booking)}',
                    style: const TextStyle(
                      color: Color(0xFF9FB9B3),
                      fontSize: 11,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Ground: ${_bookingGroundName(booking)} | Court: $court',
                    style: const TextStyle(
                      color: Color(0xFF9FB9B3),
                      fontSize: 11,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Date: ${_safeDate(booking['date']?.toString())} | Slot: $slotTime',
                    style: const TextStyle(
                      color: Color(0xFF9FB9B3),
                      fontSize: 11,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Amount: ${_currency(_amount(booking))} | Paid: ${_currency(_paidAmount(booking))} | Due: ${_currency(_dueAmount(booking))}',
                    style: const TextStyle(
                      color: Color(0xFF9FB9B3),
                      fontSize: 11,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Client Total: ${_currency(clientTotal)} | Client Paid: ${_currency(clientPaid)} | Client Due: ${_currency(clientDue)}',
                    style: const TextStyle(
                      color: Color(0xFFE6F7F4),
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: <Widget>[
                      Expanded(
                        child: OutlinedButton(
                          onPressed: _isSavingPayment
                              ? null
                              : () {
                                  final Map<String, dynamic>? target =
                                      clientBookings
                                          .where(
                                            (Map<String, dynamic> item) =>
                                                _canCollect(item),
                                          )
                                          .cast<Map<String, dynamic>?>()
                                          .firstWhere(
                                            (Map<String, dynamic>? item) =>
                                                item != null,
                                            orElse: () => null,
                                          );
                                  if (target == null) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text(
                                          'No due found for top-up',
                                        ),
                                      ),
                                    );
                                    return;
                                  }
                                  Navigator.of(context).pop();
                                  _showAddPaymentSheet(target);
                                },
                          child: const Text('Top-up'),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: OutlinedButton(
                          onPressed: _isSavingPayment
                              ? null
                              : () {
                                  final Map<String, dynamic>? target =
                                      clientBookings
                                          .cast<Map<String, dynamic>?>()
                                          .firstWhere(
                                            (Map<String, dynamic>? item) =>
                                                item != null,
                                            orElse: () => null,
                                          );
                                  if (target == null) {
                                    return;
                                  }
                                  _addDueForBooking(target);
                                },
                          child: const Text('Add Due'),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () {
                            _showNumberHint('Reminder', _captainPhone(booking));
                          },
                          child: const Text('Send Reminder'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'Transactions',
                    style: TextStyle(
                      color: Color(0xFFE6F7F4),
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Expanded(
                    child: previewTxns.isEmpty
                        ? const Center(
                            child: Text(
                              'No transactions found',
                              style: TextStyle(
                                color: Color(0x99FFFFFF),
                                fontSize: 11,
                              ),
                            ),
                          )
                        : ListView.separated(
                            itemCount: previewTxns.length,
                            separatorBuilder: (_, __) => const Divider(
                              color: Color(0x1FFFFFFF),
                              height: 12,
                            ),
                            itemBuilder: (_, int index) {
                              final Map<String, dynamic> tx =
                                  previewTxns[index];
                              final String method =
                                  tx['paymentMethod']?.toString() ??
                                  tx['method']?.toString() ??
                                  _paymentMethod(booking);
                              return Row(
                                children: <Widget>[
                                  Expanded(
                                    child: Text(
                                      '${_txDate(tx)}\n${tx['bookingCode'] ?? ''}',
                                      style: const TextStyle(
                                        color: Color(0x99FFFFFF),
                                        fontSize: 11,
                                        height: 1.2,
                                      ),
                                    ),
                                  ),
                                  Expanded(
                                    child: Text(
                                      _currency(_txAmount(tx)),
                                      textAlign: TextAlign.center,
                                      style: const TextStyle(
                                        color: Color(0xFFE6F7F4),
                                        fontSize: 11,
                                      ),
                                    ),
                                  ),
                                  Expanded(
                                    child: Text(
                                      method.toUpperCase(),
                                      textAlign: TextAlign.center,
                                      style: const TextStyle(
                                        color: Color(0xFF9FB9B3),
                                        fontSize: 11,
                                      ),
                                    ),
                                  ),
                                  Expanded(
                                    child: Text(
                                      _txStatus(tx),
                                      textAlign: TextAlign.end,
                                      style: const TextStyle(
                                        color: Color(0xFFF59E0B),
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ],
                              );
                            },
                          ),
                  ),
                  if (txns.length > 3)
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: () =>
                            _openAllTransactionsView(txns, booking),
                        child: const Text(
                          'View All',
                          style: TextStyle(fontSize: 11),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Future<void> _showAddPaymentSheet(Map<String, dynamic> booking) async {
    final String bookingId = _bookingId(booking);
    if (bookingId.isEmpty) {
      return;
    }

    final int totalAmount = _amount(booking);
    final int alreadyPaid = _paidAmount(booking);
    final int due = _dueAmount(booking);
    if (due <= 0) {
      return;
    }

    final TextEditingController amountCtrl = TextEditingController();

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF0F2027),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (BuildContext ctx) {
        bool isSaving = false;
        return StatefulBuilder(
          builder: (BuildContext _, StateSetter setSheetState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 16,
                right: 16,
                top: 20,
                bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: <Widget>[
                      const Text(
                        'Add Payment',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.of(ctx).pop(),
                        icon: const Icon(Icons.close, color: Colors.white54),
                      ),
                    ],
                  ),
                  Text(
                    'Total: ${_currency(totalAmount)}'
                    '  •  Paid: ${_currency(alreadyPaid)}'
                    '  •  Due: ${_currency(due)}',
                    style: const TextStyle(
                      color: Color(0xFF9FB9B3),
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Amount Collecting Now',
                    style: TextStyle(
                      color: Color(0xFFE6F7F4),
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    height: 44,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0x1FFFFFFF)),
                      color: const Color(0x0FFFFFFF),
                    ),
                    child: TextField(
                      controller: amountCtrl,
                      keyboardType: TextInputType.number,
                      autofocus: true,
                      style: const TextStyle(color: Colors.white, fontSize: 16),
                      decoration: const InputDecoration(
                        border: InputBorder.none,
                        hintText: 'Enter amount',
                        hintStyle: TextStyle(color: Color(0x99FFFFFF)),
                        isDense: true,
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'Payment flow supported for COD/Cash collection only.',
                    style: TextStyle(
                      color: Color(0xFFF59E0B),
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      onPressed: isSaving
                          ? null
                          : () async {
                              final int paying = _toInt(
                                amountCtrl.text.replaceAll(
                                  RegExp(r'[^0-9]'),
                                  '',
                                ),
                              );
                              if (paying <= 0) {
                                ScaffoldMessenger.of(ctx).showSnackBar(
                                  const SnackBar(
                                    content: Text('Enter a valid amount'),
                                  ),
                                );
                                return;
                              }
                              if (paying > due) {
                                ScaffoldMessenger.of(ctx).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      'Amount cannot exceed due ${_currency(due)}',
                                    ),
                                  ),
                                );
                                return;
                              }

                              setSheetState(() => isSaving = true);
                              setState(() => _isSavingPayment = true);
                              try {
                                final int newPaid = alreadyPaid + paying;
                                final Map<String, dynamic> updated =
                                    await GroundWaleApi.instance
                                        .updateBookingStatus(
                                          bookingId,
                                          <String, dynamic>{
                                            'paidAmount': newPaid,
                                            'paymentStatus':
                                                newPaid >= totalAmount
                                                ? 'paid'
                                                : 'partial',
                                          },
                                        );

                                final int index = _bookings.indexWhere(
                                  (Map<String, dynamic> item) =>
                                      _bookingId(item) == bookingId,
                                );
                                if (index >= 0) {
                                  _bookings[index] = updated;
                                  _bookings[index] = <String, dynamic>{
                                    ..._bookings[index],
                                    ...updated,
                                  };
                                }

                                if (!mounted) {
                                  return;
                                }
                                Navigator.of(ctx).pop();
                                setState(() {});
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Payment recorded'),
                                  ),
                                );
                              } catch (error) {
                                if (ctx.mounted) {
                                  ScaffoldMessenger.of(ctx).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        error.toString().replaceFirst(
                                          'Exception: ',
                                          '',
                                        ),
                                      ),
                                    ),
                                  );
                                }
                                setSheetState(() => isSaving = false);
                              } finally {
                                if (mounted) {
                                  setState(() => _isSavingPayment = false);
                                }
                              }
                            },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF00C9A7),
                        foregroundColor: const Color(0xFF1D1D1D),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                      ),
                      child: isSaving
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Color(0xFF1D1D1D),
                              ),
                            )
                          : const Text(
                              'Save Payment',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
    amountCtrl.dispose();
  }

  void _showNumberHint(String title, String phone) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          phone.isEmpty ? '$title number not available.' : '$title: $phone',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final List<Map<String, dynamic>> visible = _visibleBookings();

    final int total = _bookings.fold<int>(
      0,
      (int sum, Map<String, dynamic> booking) => sum + _amount(booking),
    );
    final int paid = _bookings.fold<int>(
      0,
      (int sum, Map<String, dynamic> booking) => sum + _paidAmount(booking),
    );
    final int pending = (total - paid) < 0 ? 0 : (total - paid);

    return Scaffold(
      backgroundColor: const Color(0xFF0F2027),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFF00C9A7)),
            )
          : SafeArea(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 20, 16, 16),
                children: <Widget>[
                  Row(
                    children: <Widget>[
                      SizedBox(
                        width: 44,
                        height: 44,
                        child: IconButton(
                          onPressed: () => Navigator.of(context).pop(),
                          icon: const Icon(
                            Icons.arrow_back_ios_new_rounded,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Text(
                          'Booking Collection',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    initialValue: _selectedGroundId,
                    icon: const Icon(
                      Icons.keyboard_arrow_down_rounded,
                      color: Color(0x99FFFFFF),
                    ),
                    dropdownColor: const Color(0xFF203A43),
                    decoration: InputDecoration(
                      labelText: 'Select Ground',
                      labelStyle: const TextStyle(
                        color: Color(0xB3E6F7F4),
                        fontSize: 13,
                      ),
                      isDense: true,
                      filled: true,
                      fillColor: const Color(0x0FFFFFFF),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(color: Color(0x1FFFFFFF)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(color: Color(0x33FFFFFF)),
                      ),
                    ),
                    items: <DropdownMenuItem<String>>[
                      const DropdownMenuItem<String>(
                        value: _allGroundsValue,
                        child: Text(
                          'All Grounds',
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                      ..._grounds.map((Map<String, dynamic> ground) {
                        final String id = _groundId(ground);
                        return DropdownMenuItem<String>(
                          value: id,
                          child: Text(
                            _groundName(ground),
                            style: const TextStyle(color: Colors.white),
                          ),
                        );
                      }),
                    ],
                    onChanged: (String? value) {
                      if (value == null || value == _selectedGroundId) {
                        return;
                      }
                      setState(() => _selectedGroundId = value);
                      if (value != _allGroundsValue) {
                        ApiSession.instance.setGroundId(value);
                      }
                      _load();
                    },
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: <Widget>[
                      Expanded(
                        child: _summaryCard(
                          'Total Booking Amount',
                          _currency(total),
                          footnote: 'Ground: ${_selectedGroundLabel()}',
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _summaryCard(
                          'Pending Collection Amount',
                          _currency(pending),
                          valueColor: const Color(0xFFF59E0B),
                          footnote: 'Collected: ${_currency(paid)}',
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0x1FFFFFFF)),
                      color: const Color(0x0FFFFFFF),
                    ),
                    child: Row(
                      children: <Widget>[
                        const Icon(
                          Icons.search_rounded,
                          color: Color(0x99FFFFFF),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: AppTextField(
                            controller: _searchController,
                            style: const TextStyle(color: Colors.white),
                            decoration: const InputDecoration(
                              border: InputBorder.none,
                              hintText: 'Search team / captain / booking no',
                              hintStyle: TextStyle(
                                color: Color(0x99FFFFFF),
                                fontSize: 15,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ),
                        if (_searchController.text.trim().isNotEmpty)
                          GestureDetector(
                            onTap: () {
                              _searchController.clear();
                              setState(() {});
                            },
                            child: const Icon(
                              Icons.close_rounded,
                              color: Color(0x99FFFFFF),
                            ),
                          ),
                      ],
                    ),
                  ),
                  if (_selectedClientKey != null) ...<Widget>[
                    const SizedBox(height: 8),
                    Row(
                      children: <Widget>[
                        Expanded(
                          child: Text(
                            'Filtered client: ${_searchController.text.trim()}',
                            style: const TextStyle(
                              color: Color(0xFF9FB9B3),
                              fontSize: 11,
                            ),
                          ),
                        ),
                        TextButton(
                          onPressed: () {
                            setState(() {
                              _selectedClientKey = null;
                              _searchController.clear();
                            });
                          },
                          style: TextButton.styleFrom(
                            foregroundColor: const Color(0xFF00C9A7),
                            minimumSize: Size.zero,
                            padding: EdgeInsets.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                          child: const Text(
                            'Clear Client Filter',
                            style: TextStyle(fontSize: 11),
                          ),
                        ),
                      ],
                    ),
                  ],
                  const SizedBox(height: 12),
                  Row(
                    children: <String>['All', 'Paid', 'Pending'].map((
                      String item,
                    ) {
                      final bool selected = _status == item;
                      return Expanded(
                        child: Padding(
                          padding: EdgeInsets.only(
                            right: item == 'Pending' ? 0 : 8,
                          ),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(8),
                            onTap: () => setState(() => _status = item),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: const Color(0x1FFFFFFF),
                                ),
                                color: selected
                                    ? const Color(0xFF00C9A7)
                                    : const Color(0x0FFFFFFF),
                              ),
                              alignment: Alignment.center,
                              child: Text(
                                item,
                                style: TextStyle(
                                  color: selected
                                      ? const Color(0xFF242424)
                                      : const Color(0x99FFFFFF),
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 16),
                  if (visible.isEmpty)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0x1FFFFFFF)),
                        color: const Color(0x0FFFFFFF),
                      ),
                      child: const Center(
                        child: Text(
                          'No booking records found',
                          style: TextStyle(color: Color(0x99FFFFFF)),
                        ),
                      ),
                    )
                  else
                    Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: const Color(0x1FFFFFFF)),
                        color: const Color(0x0AFFFFFF),
                      ),
                      child: Column(
                        children: <Widget>[
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 8,
                            ),
                            decoration: const BoxDecoration(
                              border: Border(
                                bottom: BorderSide(color: Color(0x1FFFFFFF)),
                              ),
                            ),
                            child: const Row(
                              children: <Widget>[
                                Expanded(
                                  flex: 3,
                                  child: Text(
                                    'Captain',
                                    style: TextStyle(
                                      color: Color(0x99FFFFFF),
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                                Expanded(
                                  flex: 3,
                                  child: Text(
                                    'Slot/Date',
                                    style: TextStyle(
                                      color: Color(0x99FFFFFF),
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                                Expanded(
                                  flex: 2,
                                  child: Text(
                                    'Due/Total',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      color: Color(0x99FFFFFF),
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                                Expanded(
                                  flex: 2,
                                  child: Text(
                                    'Status',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      color: Color(0x99FFFFFF),
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                                Expanded(
                                  flex: 2,
                                  child: Text(
                                    'Action',
                                    textAlign: TextAlign.end,
                                    style: TextStyle(
                                      color: Color(0x99FFFFFF),
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          ...visible.asMap().entries.map((
                            MapEntry<int, Map<String, dynamic>> entry,
                          ) {
                            final Map<String, dynamic> booking = entry.value;
                            final String status = _paymentStatus(booking);
                            final bool canCollect = _canCollect(booking);
                            final bool isLast = entry.key == visible.length - 1;

                            Color statusColor = const Color(0xFFF59E0B);
                            if (status == 'paid') {
                              statusColor = const Color(0xFF08B36A);
                            } else if (status == 'partial') {
                              statusColor = const Color(0xFFF59E0B);
                            }

                            return Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 8,
                              ),
                              decoration: BoxDecoration(
                                border: isLast
                                    ? null
                                    : const Border(
                                        bottom: BorderSide(
                                          color: Color(0x1AFFFFFF),
                                        ),
                                      ),
                              ),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: <Widget>[
                                  Expanded(
                                    flex: 3,
                                    child: InkWell(
                                      onTap: () =>
                                          _openClientTransactions(booking),
                                      child: Text(
                                        _captainName(booking),
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                          color: Color(0xFF1AE2BD),
                                          fontSize: 11,
                                          fontWeight: FontWeight.w600,
                                          decoration: TextDecoration.underline,
                                        ),
                                      ),
                                    ),
                                  ),
                                  Expanded(
                                    flex: 3,
                                    child: Text(
                                      _slotDate(booking),
                                      style: const TextStyle(
                                        color: Color(0x99FFFFFF),
                                        fontSize: 10.5,
                                        height: 1.25,
                                      ),
                                    ),
                                  ),
                                  Expanded(
                                    flex: 2,
                                    child: Text(
                                      '${_currency(_dueAmount(booking))} / ${_currency(_amount(booking))}',
                                      textAlign: TextAlign.center,
                                      style: const TextStyle(
                                        color: Color(0xFFE6F7F4),
                                        fontSize: 10.5,
                                      ),
                                    ),
                                  ),
                                  Expanded(
                                    flex: 2,
                                    child: Text(
                                      _statusLabel(status),
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        color: statusColor,
                                        fontSize: 10.5,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                  Expanded(
                                    flex: 2,
                                    child: Align(
                                      alignment: Alignment.centerRight,
                                      child: canCollect
                                          ? GestureDetector(
                                              onTap: _isSavingPayment
                                                  ? null
                                                  : () => _showAddPaymentSheet(
                                                      booking,
                                                    ),
                                              child: Text(
                                                _isSavingPayment
                                                    ? 'Saving...'
                                                    : 'Add',
                                                style: const TextStyle(
                                                  color: Color(0xFF22C55E),
                                                  fontSize: 10.5,
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              ),
                                            )
                                          : const Text(
                                              '-',
                                              style: TextStyle(
                                                color: Color(0x66FFFFFF),
                                                fontSize: 10.5,
                                              ),
                                            ),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }),
                        ],
                      ),
                    ),
                ],
              ),
            ),
    );
  }

  Widget _summaryCard(
    String title,
    String value, {
    Color valueColor = const Color(0xFFE6F7F4),
    String? footnote,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0x1FFFFFFF)),
        color: const Color(0x0FFFFFFF),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            title,
            style: const TextStyle(
              color: Color(0xFFE6F7F4),
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              color: valueColor,
              fontSize: 24,
              fontWeight: FontWeight.w600,
            ),
          ),
          if (footnote != null && footnote.isNotEmpty) ...<Widget>[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(4),
                color: const Color(0x08FFFFFF),
              ),
              child: Text(
                footnote,
                style: const TextStyle(color: Colors.white, fontSize: 12),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
