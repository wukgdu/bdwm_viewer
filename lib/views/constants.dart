import 'package:flutter/material.dart';

import '../check_update.dart' show curVersionForBBS;

// const bdwmPrimaryColor = Color(0xffea6242);
const bdwmSurfaceColor = Color(0xffe97c62);
Color bdwmPrimaryColor = bdwmSurfaceColor;
const textLinkStyle = TextStyle(
  color: bdwmSurfaceColor,
);
const Color highlightReplyColor = Color(0xffea6242);
const Color highlightPostColor = Color(0xfffff8f0);
const Color highlightColor = Color(0xffea6242);
const Color onlineColor = Color(0xff5cae97);
const Color vip0Color = Color(0xff45c2ee);
const Color vip1Color = Color(0xffe63229);
const Color vip2Color = Color(0xfff3b467);

Color? getVipColor(int vipIdentity, {Color? defaultColor=Colors.grey}) {
  switch (vipIdentity) {
    case 0: return vip0Color;
    case 1: return vip1Color;
    case 2: return vip2Color;
    default: return defaultColor;
  }
}
const action2Name = {
  "top": "置顶", "untop": "取消置顶",
  "mark": "保留", "unmark": "取消保留",
  "digest": "文摘", "undigest": "取消文摘",
  "mark_digest": "设置文摘区保留", "unmark_digest": "取消文摘区保留",
  "highlight_top": "高亮置顶", "unhighlight_top": "取消高亮置顶",
  "highlight": "高亮", "unhighlight": "取消高亮",
  "noreply": "设为不可回复", "unnoreply": "取消不可回复",
  "delete": "删除", "rate": "打原创分", "deny": "封禁",
};

String getActionName(String action) {
  return action2Name[action] ?? action;
}

const Map<String, Object> bdwmRichText = {
  'bc': {
    '#ffffff': 9,
    '#404040': 0,
    '#ff4040': 1,
    '#40ff40': 2,
    '#ffff40': 3,
    '#4040ff': 4,
    '#ff40ff': 5,
    '#40ffff': 6,
    '#fefefe': 7,
  },
  'fc': {
    '#333333': 9,
    '#000000': 0,
    '#c00000': 1,
    '#00c000': 2,
    '#c0c000': 3,
    '#0000c0': 4,
    '#c000c0': 5,
    '#00c0c0': 6,
    '#c0c0c0': 7,
  }
};

const Map<String, Color> topicsLabelColor = {
  '保留': Color(0xff7cbec5),
  '精华': Color(0xff80c269),
  '文摘': Color(0xfffbba7a),
  '置顶': Color(0xffe97c62),
  '原创分': Color(0xff5cae97),
  '原创': Color(0xff5cae97),
};

const serifFont = TextStyle(fontFamily: 'serif');

const signatureOBViewer = [{"content":"发自 onepiece 的客户端 $curVersionForBBS\n","fore_color":8,"back_color":9,"bold":false,"blink":false,"underline":false,"reverse":false,"type":"ansi"},];

const messageEmojis = {
  "[微笑]": "🙂", "[撇嘴]": "😕", "[色]": "😍", "[发呆]": "😐", "[得意]": "😎", "[流泪]": "😢", "[害羞]": "😳", "[闭嘴]": "🤐", "[睡]": "😴", "[大哭]": "😭",
  "[尴尬]": "😅", "[发怒]": "😡", "[调皮]": "😜", "[呲牙]": "😁", "[惊讶]": "😮", "[难过]": "😔",  "[酷]": "", "[冷汗]": "", "[抓狂]": "😫", "[吐]": "🤮",
  "[偷笑]": "🤭", "[愉快]": "", "[白眼]": "🙄", "[傲慢]": "", "[饥饿]": "", "[困]": "", "[惊恐]": "", "[流汗]": "😓", "[憨笑]": "😄", "[悠闲]": "",
  "[奋斗]": "", "[咒骂]": "", "[疑问]": "", "[嘘]": "🤫", "[晕]": "😵", "[疯了]": "", "[衰]": "", "[骷髅]": "💀", "[敲打]": "", "[再见]": "👋",
  "[擦汗]": "", "[抠鼻]": "", "[鼓掌]": "👏", "[糗大了]": "", "[坏笑]": "", "[左哼哼]": "", "[右哼哼]": "", "[哈欠]": "😪", "[鄙视]": "😒", "[委屈]": "😔",
  "[快哭了]": "", "[阴险]": "", "[亲亲]": "", "[吓]": "", "[可怜]": "🙁", "[菜刀]": "", "[西瓜]": "🍉", "[啤酒]": "🍺", "[篮球]": "🏀", "[乒乓]": "🏓",
  "[咖啡]": "☕", "[饭]": "🍚", "[猪头]": "🐷", "[玫瑰]": "🌹", "[凋谢]": "🥀", "[嘴唇]": "👄", "[爱心]": "❤", "[心碎]": "💔", "[蛋糕]": "🎂", "[闪电]": "⚡",
  "[炸弹]": "💣", "[刀]": "🔪", "[足球]": "⚽", "[瓢虫]": "🐞", "[便便]": "💩", "[月亮]": "🌙", "[太阳]": "🌞", "[礼物]": "🎁", "[拥抱]": "", "[强]": "👍",
  "[弱]": "👎", "[握手]": "🤝", "[胜利]": "✌", "[抱拳]": "", "[勾引]": "", "[拳头]": "👊", "[差劲]": "👎", "[爱你]": "🤟", "[NO]": "🙅‍", "[OK]": "‍🆗",
  "[爱情]": "", "[飞吻]": "", "[跳跳]": "", "[发抖]": "{{{(>_<)}}}", "[怄火]": "", "[转圈]": "", "[磕头]": "", "[回头]": "", "[跳绳]": "", "[投降]": "",
};
