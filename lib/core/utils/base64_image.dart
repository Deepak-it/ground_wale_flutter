import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';

Uint8List? decodeBase64ImageBytes(String? input) {
  final String source = input?.trim() ?? '';
  if (source.isEmpty) {
    return null;
  }

  String value = source;
  if (value.startsWith('data:image') && value.contains(',')) {
    value = value.split(',').last;
  }

  value = value.replaceAll(RegExp(r'\s+'), '');
  value = value.replaceAll('-', '+').replaceAll('_', '/');

  final int remainder = value.length % 4;
  if (remainder != 0) {
    value = value.padRight(value.length + (4 - remainder), '=');
  }

  try {
    return Uint8List.fromList(base64Decode(value));
  } catch (_) {
    return null;
  }
}

Widget buildBase64OrNetworkImage({
  required String? value,
  required BoxFit fit,
  required Widget fallback,
}) {
  final String source = value?.trim() ?? '';
  if (source.isEmpty) {
    return fallback;
  }

  if (source.startsWith('http://') || source.startsWith('https://')) {
    return Image.network(
      source,
      fit: fit,
      errorBuilder: (_, __, ___) => fallback,
    );
  }

  final Uint8List? bytes = decodeBase64ImageBytes(source);
  if (bytes == null) {
    return fallback;
  }

  return Image.memory(
    bytes,
    fit: fit,
    errorBuilder: (_, __, ___) => fallback,
  );
}
