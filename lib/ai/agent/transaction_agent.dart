enum TransactionDomain { upiPay, sendMoney, payEMI, billPay, checkBalance }

class TransactionIntent {
  final TransactionDomain domain;
  final double? amount;
  final String? recipient;
  final String? note;

  const TransactionIntent({
    required this.domain,
    this.amount,
    this.recipient,
    this.note,
  });
}

class TransactionAgent {
  static const String agentId = 'transaction_agent';
  static const String displayName = 'Transaction Agent';
  static const String emoji = '💳';

  static bool canHandle(String message) {
    final m = message.toLowerCase();
    return m.contains('pay') ||
        m.contains('send') ||
        m.contains('transfer') ||
        m.contains('upi') ||
        m.contains('emi') ||
        m.contains('bill') ||
        m.contains('recharge') ||
        m.contains('balance check') ||
        m.contains('withdraw');
  }

  static TransactionIntent? parseIntent(String message) {
    final m = message.toLowerCase();
    final amountMatch = RegExp(r'[₹rs\.\s]*(\d+[,\d]*)').firstMatch(m);
    final amount = amountMatch != null
        ? double.tryParse(amountMatch.group(1)!.replaceAll(',', ''))
        : null;
    final recipientMatch = RegExp(r'\bto\s+([\w\s]+)').firstMatch(m);
    final recipient = recipientMatch?.group(1)?.trim();

    if (m.contains('emi')) {
      return TransactionIntent(domain: TransactionDomain.payEMI, amount: amount);
    } else if (m.contains('send') || m.contains('transfer')) {
      return TransactionIntent(
        domain: TransactionDomain.sendMoney,
        amount: amount,
        recipient: recipient,
      );
    } else if (m.contains('upi') || m.contains('pay')) {
      return TransactionIntent(
        domain: TransactionDomain.upiPay,
        amount: amount,
        recipient: recipient,
      );
    } else if (m.contains('bill') || m.contains('recharge')) {
      return TransactionIntent(domain: TransactionDomain.billPay, amount: amount);
    } else if (m.contains('balance')) {
      return const TransactionIntent(domain: TransactionDomain.checkBalance);
    }
    return null;
  }

  static String getToolName(TransactionDomain domain) {
    switch (domain) {
      case TransactionDomain.upiPay:
        return 'executeUPIPayment';
      case TransactionDomain.sendMoney:
        return 'sendMoney';
      case TransactionDomain.payEMI:
        return 'payEMI';
      case TransactionDomain.billPay:
        return 'payBill';
      case TransactionDomain.checkBalance:
        return 'checkBalance';
    }
  }

  static String getStatusText(TransactionDomain domain) {
    switch (domain) {
      case TransactionDomain.upiPay:
        return 'Processing UPI Payment';
      case TransactionDomain.sendMoney:
        return 'Preparing Fund Transfer';
      case TransactionDomain.payEMI:
        return 'Scheduling EMI Payment';
      case TransactionDomain.billPay:
        return 'Processing Bill Payment';
      case TransactionDomain.checkBalance:
        return 'Fetching Balance';
    }
  }
}
