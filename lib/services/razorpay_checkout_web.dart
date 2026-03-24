import 'dart:async';
import 'dart:js';

class RazorpayCheckoutResult {
  final bool success;
  final String? orderId;
  final String? paymentId;
  final String? signature;
  final int? amountInPaise;
  final String? errorMessage;

  const RazorpayCheckoutResult({
    required this.success,
    this.orderId,
    this.paymentId,
    this.signature,
    this.amountInPaise,
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
}) {
  final completer = Completer<RazorpayCheckoutResult>();

  try {
    final options = JsObject.jsify({
      'key': key,
      'order_id': orderId,
      'amount': amountInPaise,
      'currency': 'INR',
      'name': name,
      'description': description,
      'handler': JsFunction.withThis((_, dynamic response) {
        if (completer.isCompleted) return;

        completer.complete(
          RazorpayCheckoutResult(
            success: true,
            orderId: response['razorpay_order_id']?.toString(),
            paymentId: response['razorpay_payment_id']?.toString(),
            signature: response['razorpay_signature']?.toString(),
            amountInPaise: _parseAmountInPaise(response['amount']),
          ),
        );
      }),
      'modal': JsObject.jsify({
        'ondismiss': JsFunction.withThis((_) {
          if (completer.isCompleted) return;

          completer.complete(
            const RazorpayCheckoutResult(
              success: false,
              errorMessage: 'Payment was cancelled.',
            ),
          );
        }),
      }),
      'prefill': JsObject.jsify({
        'name': customerName ?? '',
        'email': customerEmail ?? '',
        'contact': customerContact ?? '',
      }),
      'theme': JsObject.jsify({'color': '#0F8F82'}),
    });

    final razorpay = JsObject(context['Razorpay'], [options]);
    razorpay.callMethod('on', [
      'payment.failed',
      JsFunction.withThis((_, dynamic response) {
        if (completer.isCompleted) return;

        final error = response['error'];
        completer.complete(
          RazorpayCheckoutResult(
            success: false,
            errorMessage:
                error?['description']?.toString() ??
                'Payment failed. Please try again.',
          ),
        );
      }),
    ]);
    razorpay.callMethod('open');
  } catch (_) {
    if (!completer.isCompleted) {
      completer.complete(
        const RazorpayCheckoutResult(
          success: false,
          errorMessage: 'Unable to open Razorpay checkout.',
        ),
      );
    }
  }

  return completer.future;
}

int? _parseAmountInPaise(dynamic rawAmount) {
  if (rawAmount == null) {
    return null;
  }

  if (rawAmount is int) {
    return rawAmount;
  }

  return int.tryParse(rawAmount.toString());
}
