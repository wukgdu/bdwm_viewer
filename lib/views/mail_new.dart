import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:async/async.dart';

import '../bdwm/mail.dart';
import '../views/html_widget.dart';
import '../bdwm/req.dart';
import './constants.dart';
import '../globalvars.dart';
// import '../html_parser/postnew_parser.dart';
import './utils.dart';

class MailNewPage extends StatefulWidget {
  final String? parentid;
  const MailNewPage({super.key, required this.parentid});

  @override
  State<MailNewPage> createState() => _MailNewPageState();
}

class _MailNewPageState extends State<MailNewPage> {
  @override
  Widget build(BuildContext context) {
    return Container(
      child: const Center(child: Text("WIP")),
    );
  }
}