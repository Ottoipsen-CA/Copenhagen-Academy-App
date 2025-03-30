import 'package:flutter/material.dart';

class LoadingIndicator extends StatelessWidget {
  final String message;
  final Color color;

  const LoadingIndicator({
    Key? key,
    this.message = 'Loading...',
    this.color = Colors.white,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(color),
          ),
          const SizedBox(height: 16),
          Text(
            message,
            style: TextStyle(
              color: color,
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
} 