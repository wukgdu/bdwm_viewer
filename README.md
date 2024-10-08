# bdwm_viewer

未名BBS
https://bbs.pku.edu.cn
第三方客户端
OBViewer

## 运行

### 使用预编译apk
https://github.com/wukgdu/bdwm_viewer/releases

使用 arm64-v8a 版本即可，如有问题再尝试未标注 abi 的体积最大的 apk

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
    - 或者直接用 VSCode 调试。但是 VSCode 调试会在一些奇怪的 caught exceptions 止住，比如图片未加载完取消或失败，坑
    - 此时的签名是 flutter 的 debug 签名，不安全
7. 编译 `flutter build apk --split-per-abi`
    - 编译得到的 apk 使用 arm64-v8a 的即可
    - 但是此代码无法`build apk`，因为没有签名（我的签名没有公开上传），可参照 https://docs.flutter.cn/deployment/android/#signing-the-app 自行添加签名

实现代码在 lib/ 下，欢迎发 pull requests

## 功能
### BBS 功能
- 看帖
    - [x] 十大、热点
    - [x] 单个帖子（thread）
    - [x] 彩色文字，签名档，附件图片预览
    - [x] 版面目录，版面
    - [x] 收藏版面，帖子赞/踩
    - [x] 代码高亮
- 发帖
    - [x] 发帖，支持富文本编辑
    - [x] 发帖时选择匿名、不可回复、回复提醒，选择签名档
    - [x] 自删
    - [x] 回复
    - [x] 修改
    - [x] 转载
    - [x] 转寄
    - [x] 已发帖选择不可回复
    - [x] 附件管理
- 个人文集
    - [x] 看自己和他人文集
    - [x] 查看版面精华区
    - [x] 收入文章到文集
    - [x] 管理文集
    - [x] 收入他人文章
- 搜索
    - [x] 帖子高级搜索
    - [x] 搜索用户
    - [x] 搜索版面
- 用户
    - [x] 关注用户
    - [x] 拉黑用户
    - [x] 查看关注/拉黑用户
    - [x] 看用户信息
    - [x] 修改个人资料
- 消息
    - [x] 看deliver消息，跳转到回复帖子
    - [x] 看其他人新到消息
    - [ ] 看历史联系人
    - [x] 发消息
    - [x] 选择表情发送
    - [x] 新到提醒
- 站内信
    - [x] 看
    - [x] 发
    - [x] 新到提醒
    - [x] 各种操作
- 精华区收藏夹
    - [x] 查看
    - [x] 添加
    - [x] 删除
- 版务操作
    - [x] 同主题合集/删除/不可回复
    - [x] 高亮/保留/文摘/置顶
    - [x] 原创分/封禁
    - [x] 修改/删除/设为不可回复
    - [x] 删除区帖子放回原处
    - [x] 管理精华区
    - [x] 修改版面介绍
    - [ ] 修改版面备忘录
    - [ ] 投票相关
- 其他
    - [x] 展示进站图片（不一定准）
    - [x] 消息中显示表情
    - [x] 查看版面备忘录
    - [ ] 投票

### 新加功能
- 十大拍照，生成term彩色格式的文字（实验性）
- 不看ta的帖子
- 折线图展示个人统计数据，登录次数、发帖数等
- 使用高级搜索查看本人发帖
- 使用高级搜索查看关注用户的最近发帖
- 记录最近浏览的主题帖（本地）
- 收藏主题帖（本地）
- 发帖时@自动提示用户，正文高亮符合规则的@用户
- 发帖时保存、加载草稿
- 登录时支持游客浏览
- 多账号切换

### 应用功能
- Material Design 2、3切换
- 主题颜色切换
- 图片缓存、预览质量设置
- 调整正文字体大小
- 支持高刷新率
- 定时检查更新

### 安卓功能
- 通知栏提醒新消息（应用运行时）
- 跟随系统的深色模式
- 桌面图标长按显示快捷操作
- 桌面小组件显示十大，点击直达帖子

## 问题反馈
- https://github.com/wukgdu/bdwm_viewer/issues
- 站内信、站内消息
