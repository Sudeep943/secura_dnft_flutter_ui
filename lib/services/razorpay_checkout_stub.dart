class RazorpayCheckoutResult {
  final bool success;
  final String? orderId;
  final String? paymentId;
  final String? signature;
  final String? errorMessage;

  const RazorpayCheckoutResult({
    required this.success,
    this.orderId,
    this.paymentId,
    this.signature,
    this.errorMessage,
  });
}

Future<RazorpayCheckoutResult> openRazorpayCheckout({
  required String key,
  required String orderId,
  required int amountInPaise,
  required String name,
  required String description,
  String? customerName,
  String? customerEmail,
  String? customerContact,
}) async {
  return const RazorpayCheckoutResult(
    success: false,
    errorMessage: 'Razorpay checkout is supported only on web in this app.',
  );
}
