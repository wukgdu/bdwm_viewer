# bdwm_viewer

未名BBS
https://bbs.pku.edu.cn
第三方客户端
OBViewer

## 运行

### 使用预编译apk
https://github.com/wukgdu/bdwm_viewer/releases

### 源码构建
1. 安装 flutter 
    1. https://flutter.dev/
    2. 把 flutter/bin 加入环境变量
    3. [Using Flutter in China](https://docs.flutter.dev/community/china)，修改几个资源网址
    4. `flutter doctor` 看一看结果
2. `git clone https://github.com/wukgdu/bdwm_viewer.git`
3. 进入目录
4. `flutter pub get`
5. USB连接安卓手机，`flutter devices`看是否有该设备
6. 调试 `flutter run` （选择一个 target，上一步的手机设备）
    1. 或者直接用 VSCode 调试。但是 VSCode 调试会在一些奇怪的 caught exceptions 止住，比如图片未加载完取消或失败，坑
    2. 此时的签名是 flutter 的 debug 签名，不安全
7. 编译 `flutter build apk --split-per-abi`
    1. 自行编译后的签名会和原本的签名不同，因为签名没有公开
    2. 编译得到的 apk 使用 arm64-v8a 的即可
8. 实现代码在 lib/ 下，欢迎发 pull requests

## 功能
1. 看帖
    1. [x] 十大、热点
    2. [x] 单个帖子（thread）
    3. [x] 彩色文字，签名档，附件图片预览
    4. [x] 版面目录，版面
    5. [x] 收藏版面，帖子赞/踩
2. 发帖
    1. [x] 发帖
    2. [x] 发帖时选择匿名、不可回复、回复提醒，选择签名档
    3. [x] 自删
    4. [x] 回复
    5. [x] 修改
    6. [x] 转载
    7. [x] 转寄
    8. [x] 已发帖选择不可回复
    9. [x] 附件管理
3. 个人文集
    1. [x] 看自己和他人文集
    2. [x] 查看版面精华区
    3. [x] 收入文章到文集
    4. [ ] 管理文集
    5. [x] 收入他人文章
4. 搜索
    1. [x] 帖子高级搜索
    2. [x] 搜索用户
    3. [x] 搜索版面
5. 用户
    1. [x] 关注用户
    2. [x] 拉黑用户
    3. [x] 查看关注/拉黑用户
    4. [x] 看用户信息
6. 消息
    1. 看
        1. [x] 看deliver消息，跳转到回复帖子
        2. [x] 看其他人新到消息
        3. [ ] 看历史联系人
    2. [x] 发
    3. [x] 新到提醒
7. 站内信
    1. [x] 看
    2. [x] 发
    3. [x] 新到提醒
    4. [x] 各种操作

## 问题反馈
https://github.com/wukgdu/bdwm_viewer/issues
