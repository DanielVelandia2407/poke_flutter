import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

String friendlyErrorMessage(Object? error) {
  if (error is TimeoutException) {
    return 'La conexión tardó demasiado. Revisa tu red e intenta de nuevo.';
  }
  if (error is SocketException) {
    return 'Parece que no hay internet.';
  }
  if (error is http.ClientException) {
    return 'No pudimos cargar los datos. Intenta más tarde.';
  }
  return 'Algo salió mal. Intenta de nuevo.';
}

class ErrorView extends StatelessWidget {
  final Object? error;
  final VoidCallback onRetry;

  const ErrorView({super.key, required this.error, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Image.asset('assets/images/error.png', height: 160),
          const SizedBox(height: 12),
          Text(friendlyErrorMessage(error)),
          const SizedBox(height: 12),
          FilledButton(onPressed: onRetry, child: const Text('Reintentar')),
        ],
      ),
    );
  }
}
