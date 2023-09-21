import 'package:flutter/material.dart';

import './constants.dart';
import '../router.dart' show nv2Push;
import '../html_parser/board_parser.dart' show AdminInfo;

Widget _hereDesc = const Center(child: Text("版务"),);

Future<void> jumpToAdminFromBoardCard(BuildContext context, List<AdminInfo> admins, {bool isScrollControlled=true, Widget? desc}) async {
  showBoardInfoBottomSheet(context, admins, isScrollControlled: isScrollControlled, desc: desc ?? _hereDesc).then((adminUid) {
    if (adminUid == null) { return; }
    nv2Push(context, '/user', arguments: adminUid);
  });
  // showBoardInfoBottomSheet(context, admins, isScrollControlled: isScrollControlled, desc: desc ?? _hereDesc);
}

Future<String?> showBoardInfoBottomSheet(BuildContext context, List<AdminInfo> admins, {bool isScrollControlled=true, Widget? desc}) async {
  var opt = await showModalBottomSheet<String>(
    context: context,
    isScrollControlled: isScrollControlled,
    builder: (BuildContext context1) {
      return Container(
        margin: const EdgeInsets.all(10.0),
        child: Wrap(
          children: [
            if (desc != null) ...[
              desc,
              const Divider(),
            ],
            for (var admin in admins) ...[
              ListTile(
                // dense: true,
                onTap: () { Navigator.of(context).pop(admin.uid); },
                // onTap: () { nv2Push(context, '/user', arguments: admin.uid); },
                title: Center(child: Text(admin.userName, style: TextStyle(color: bdwmPrimaryColor),)),
              ),
            ],
            // ListTile(
            //   onTap: () { Navigator.of(context).pop(); },
            //   title: Center(child: Text("取消", style: TextStyle(color: bdwmPrimaryColor),)),
            // ),
          ],
        ),
      );
    }
  );
  return opt;
}
