import 'package:flutter/material.dart';

import './globalvars.dart';
import './pages/login.dart';
import './pages/top100.dart';
import './pages/user.dart';
import './pages/favorite.dart';

void main() {
  runApp(const MainPage());
}

class MainPage extends StatefulWidget {
  const MainPage({Key? key}) : super(key: key);

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  String pageName = "author";
  double iconWidth = 35;
  String appBarTitle = "";

  PreferredSizeWidget myAppBar() {
    return AppBar(
      title: Text(appBarTitle),
      leading: IconButton(
        icon: const Icon(Icons.list),
        onPressed: () { },
      ),
      leadingWidth: iconWidth-5,
      actions: <Widget>[
        SizedBox(
          width: iconWidth,
          child: IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () { },
          ),
        ),
        SizedBox(
          width: 35,
          child: IconButton(
            icon: const Icon(Icons.home),
            onPressed: () {
              // if (pageName == "hot") {
              //   return;
              // }
              setState(() {
                pageName = "hot";
              });
              // ??? will re-render even if pageName is 'hot'
            },
          )
        ),
        SizedBox(
          width: iconWidth,
          child: IconButton(
            icon: const Icon(Icons.mail),
            onPressed: () { },
          ),
        ),
        SizedBox(
          width: iconWidth,
          child: IconButton(
            icon: const Icon(Icons.search),
            onPressed: () { },
          ),
        ),
        SizedBox(
          width: iconWidth,
          child: IconButton(
            icon: const Icon(Icons.star),
            onPressed: () {
              setState(() {
                pageName = "favorite";
              });
            },
          ),
        ),
        SizedBox(
          width: iconWidth+10,
          child: IconButton(
            icon: const Icon(Icons.person),
            onPressed: () {
              setState(() {
                if (globalUInfo.login == true) {
                  pageName = "me";
                } else {
                  pageName = "login";
                }
              });
            },
          ),
        ),
      ],
    );
  }

  void changeTitle(String title) {
    WidgetsBinding.instance.addPostFrameCallback((_){
      // setState(() {
      //   appBarTitle = title;
      // });
    });
  }
  void afterLogin () {
    setState(() {
      pageName = "login";
    });
  }
  void afterLogout () {
    setState(() {
      pageName = "hot";
    });
  }

  @override
  Widget build(BuildContext context) {
    debugPrint("** main rebuild");
    return MaterialApp(
      title: 'BDWMViewer',
      theme: ThemeData(
        colorScheme: const ColorScheme.light().copyWith(primary: Colors.blueAccent),
      ),
      home: Scaffold(
          appBar: myAppBar(),
          body: Builder(
            builder: (context) {
              globalUIInfo.bodyContext = context;
              return pageName == "hot" ? Top100Page(changeTitle: changeTitle) :
                    pageName == "login" ?
                      globalUInfo.login == false ? LoginPage(pageCallBack: afterLogin, changeTitle: changeTitle,)
                                                 : UserInfoPage(uid: globalUInfo.uid, pageCallBack: afterLogout, changeTitle: changeTitle,) :
                    pageName == "me" ? UserInfoPage(uid: globalUInfo.uid, pageCallBack: afterLogout, changeTitle: changeTitle,) :
                    pageName == "user" ? UserInfoPage(uid: globalUIInfo.userID, pageCallBack: afterLogout, changeTitle: changeTitle,) :
                    pageName == "author" ? UserInfoPage(uid: '22776', pageCallBack: afterLogout, changeTitle: changeTitle,) :
                    pageName == "favorite" ? FavoritePage(changeTitle: changeTitle) :
                    Top100Page(changeTitle: changeTitle);
            },
          )
      ),
    );
  }
}