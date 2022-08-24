import 'package:flutter/material.dart';

import './globalvars.dart';
import './pages/home.dart';
import './pages/board.dart';
import './pages/login.dart';
import './pages/user.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  globalUInfo.init().then((res) {
    runApp(const MainPage());
  });
}

class MainPage extends StatefulWidget {
  const MainPage({Key? key}) : super(key: key);

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  double iconWidth = 35;

  PreferredSizeWidget myAppBar() {
    return AppBar(
      title: Text("demo"),
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
                } else {
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
    });
  }
  void afterLogout () {
    setState(() {
    });
  }

  @override
  Widget build(BuildContext context) {
    debugPrint("** main rebuild");
    return MaterialApp(
      title: 'BDWMViewer',
      theme: ThemeData(
        // #e97c62
        // colorScheme: const ColorScheme.light().copyWith(primary: Colors.orangeAccent),
        colorScheme: const ColorScheme.light().copyWith(primary: Color(0xffe97c62)),
      ),
      home: HomeApp(),
      // initialRoute: "/home",
      onGenerateRoute: (settings) {
        WidgetBuilder builder;
        switch (settings.name) {
          case "/board":
            String? boardName = settings.arguments as String?;
            builder = (BuildContext context) => BoardApp(boardName: boardName,);
            break;
          case "/login":
            bool needBack = false;
            if (settings.arguments != null) {
              needBack = (settings.arguments as Map)['needBack'] ?? false;
            }
            builder = (BuildContext context) => LoginApp(needBack: needBack,);
            break;
          case "/me":
            if (globalUInfo.login) {
              builder = (BuildContext context) => UserApp(uid: globalUInfo.uid);
            } else {
              builder = (BuildContext context) => LoginApp();
            }
            break;
          case "/user":
            String userID = settings.arguments as String? ?? "15265";
            builder = (BuildContext context) => UserApp(uid: userID, needBack: true,);
            break;
          case "/home":
          default:
            builder = (BuildContext context) => HomeApp();
        }
        return MaterialPageRoute(builder: builder, settings: settings);
      },
    );
  }
}