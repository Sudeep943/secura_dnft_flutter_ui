import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:secura/main.dart';
import 'package:secura/pages/home_page.dart';

void main() {
  testWidgets('Login page renders', (WidgetTester tester) async {
    await tester.pumpWidget(MyApp());

    expect(find.text('Login'), findsOneWidget);
    expect(find.text('Username / Phone'), findsOneWidget);
    expect(find.text('Password'), findsOneWidget);
  });

  testWidgets(
    'Payment details modal enables the earliest-due payment group only',
    (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PaymentDetailsModal(
              duePaymentList: const [],
              dueDetailsByPayment: {
                '{"paymentId":"p1","paymentName":"Test Payment"}': [
                  {
                    'DueId': 'd1',
                    'paymentId': 'p1',
                    'paymentName': 'Test Payment',
                    'collectionCycle': 'Monthly',
                    'dueDate': '2020-01-01',
                    'dueStartDate': '2019-12-01',
                    'dueEndDate': '2020-01-31',
                    'amount': '100',
                    'gstAmount': '0',
                    'totalAmount': '100',
                    'totalAddedCharges': '0',
                    'paymentType': 'Maintenance',
                    'discountedAmount': '0',
                    'fineAmount': '0',
                  },
                  {
                    'DueId': 'd2',
                    'paymentId': 'p1',
                    'paymentName': 'Test Payment',
                    'collectionCycle': 'Quarterly',
                    'dueDate': '2030-01-01',
                    'dueStartDate': '2029-12-01',
                    'dueEndDate': '2030-03-31',
                    'amount': '100',
                    'gstAmount': '0',
                    'totalAmount': '100',
                    'totalAddedCharges': '0',
                    'paymentType': 'Maintenance',
                    'discountedAmount': '0',
                    'fineAmount': '0',
                  },
                ],
                '{"paymentId":"p2","paymentName":"Older Payment"}': [
                  {
                    'DueId': 'd3',
                    'paymentId': 'p2',
                    'paymentName': 'Older Payment',
                    'collectionCycle': 'Monthly',
                    'dueDate': '2019-01-01',
                    'dueStartDate': '2018-12-01',
                    'dueEndDate': '2019-01-31',
                    'amount': '100',
                    'gstAmount': '0',
                    'totalAmount': '100',
                    'totalAddedCharges': '0',
                    'paymentType': 'Maintenance',
                    'discountedAmount': '0',
                    'fineAmount': '0',
                  },
                ],
              },
              formatAsCurrency: (amount) => '₹$amount',
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Overdue'), findsOneWidget);
      expect(find.text('Active Due'), findsOneWidget);
      expect(find.text('Monthly'), findsOneWidget);
      expect(find.text('Quarterly'), findsOneWidget);
      expect(find.text('Due Details'), findsNothing);

      await tester.tap(find.text('Older Payment'));
      await tester.pumpAndSettle();

      expect(find.text('Due Details'), findsOneWidget);
    },
  );
}
