import 'dart:io';
import 'dart:math';
import 'package:fast_rsa/fast_rsa.dart';
import 'package:flutter/material.dart';

void main() async{
  var listOfNetworkInterfaces = await NetworkInterface.list(type: InternetAddressType.IPv6);

  ServerSocket serverSocket;

  for (var networkInterface in listOfNetworkInterfaces) {
    for (var address in networkInterface.addresses) {
      print(address.address);
    }
  }
  runApp(MaterialApp());
}