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
    3. `flutter doctor` 看一看结果
2. `git clone https://github.com/wukgdu/bdwm_viewer.git`
3. 进入目录（删除pubspec.lock，应该不用，下一步不行了就删掉）
4. `flutter pub get`
5. 调试 `flutter run` （选择一个target）
6. 编译 `flutter build apk --split-per-abi`

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
    9. [ ] 附件管理
3. 个人文集
    1. [x] 看自己和他人文集
    2. [x] 查看版面精华区
    3. [x] 收入文章到文集
    4. [ ] 管理文集
4. 搜索
    1. [x] 帖子高级搜索
    2. [x] 搜索用户
    3. [x] 搜索版面
5. 用户
    1. [x] 关注用户
    2. [ ] 拉黑用户
    3. [ ] 查看关注/拉黑用户
    4. [x] 看用户信息
6. 消息
    1. 看
        1. [x] 看deliver消息，跳转到回复帖子
        2. [x] 看其他人新到消息
        3. [ ] 看历史联系人消息 
    2. [ ] 发
    3. [x] 新到提醒
7. 站内信
    1. [ ] 看
    2. [ ] 发
    3. [x] 新到提醒

## 问题反馈
https://github.com/wukgdu/bdwm_viewer/issues

欢迎发pull requests
