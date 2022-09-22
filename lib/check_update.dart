import './globalvars.dart';
import './html_parser/collection_parser.dart';
import './bdwm/req.dart';
import './utils.dart';

const String innerLinkForBBS = "https://bbs.pku.edu.cn/v2/collection-read.php?path=groups%2FGROUP_0%2FPersonalCorpus%2FO%2Fonepiece%2FD93F86C79%2FA862DAFBA";
const String curVersionForBBS = "1.4.3";

bool isNewVersion(List<int> onlineNumbers, List<int> localNumbers) {
  if (onlineNumbers[0] > localNumbers[0]) { return true; }
  if (onlineNumbers[0] < localNumbers[0]) { return false; }
  if (onlineNumbers[1] > localNumbers[1]) { return true; }
  if (onlineNumbers[1] < localNumbers[1]) { return false; }
  return onlineNumbers[2] > localNumbers[2];
}

Future<bool> checkUpdate() async {
  var url = innerLinkForBBS;
  var resp = await bdwmClient.get(url, headers: genHeaders2());
  if (resp == null) {
    return false;
  }
  var versionOnline = await checkUpdateParser(resp.body);
  if (versionOnline.isEmpty) { return false; }
  try {
    List<int> versionOnlineNumbers = versionOnline.split(".").map((e) => int.parse(e)).toList();
    List<int> versionLocalNumbers = curVersionForBBS.split(".").map((e) => int.parse(e)).toList();
    bool thereIsNewVersion = isNewVersion(versionOnlineNumbers, versionLocalNumbers);
    if (thereIsNewVersion) {
      quickNotify("新版本", versionOnline);
    }
  } catch (e) {
    quickNotify("新版本检查失败", e.toString());
  }
  return true;
}

Future<void> checkUpdateByTime() async {
  String lastTimeStr = globalConfigInfo.getLastCheckTime();
  var ld = DateTime.tryParse(lastTimeStr);
  var curDT = DateTime.now();
  if (ld==null) {
    var doCheck = await checkUpdate();
    if (doCheck) {
      await globalConfigInfo.setLastCheckTime(curDT.toIso8601String());
    }
    return;
  }
  var deltaDT = curDT.difference(ld);
  if (deltaDT.inDays >= 7) {
    var doCheck = await checkUpdate();
    if (doCheck) {
      await globalConfigInfo.setLastCheckTime(curDT.toIso8601String());
    }
  }
}
