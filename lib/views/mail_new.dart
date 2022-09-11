import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:async/async.dart';
import 'package:flutter_quill/flutter_quill.dart' as fQuill;

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
  final fQuill.QuillController _controller = fQuill.QuillController.basic();
  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10.0),
      child: Column(
        children: [
          TextButton(
            onPressed: () {
              print(_controller.document.toDelta().toJson());
            },
            child: const Text("show deltas"),
          ),
          fQuill.QuillToolbar.basic(controller: _controller),
          Expanded(
            child: Container(
              child: fQuill.QuillEditor.basic(
                controller: _controller,
                readOnly: false, // true for view only mode
              ),
            ),
          )
        ],
      )
    );
  }
}