<p align="center"><img src="assets/app-icon.png" width="128" alt="BVN Mac 乌鸦图标"></p>

# BVN for macOS

将自己持有的旧版《死神 VS 火影》AIR 游戏包，构建成可以双击运行的 macOS 应用。

这是一个社区适配工程，基于原版编译内容运行，主要处理 macOS 应用包装、图标和存档/日志位置。**仓库不包含原游戏、角色素材、音乐、存档或 AIR SDK，也不提供完整游戏包下载。** 原作属于剑 jian 及 5DPLAY Game Studio；本项目不是官方发行版。[原作项目](https://github.com/5DPLAY-Game-Studio/BleachVsNaruto)

A community compatibility workbench for a fingerprinted legacy Bleach vs. Naruto package. Bring your own game files and licensed macOS AIR SDK. Original game payloads remain unchanged; this repository contains the adapter, build tools, tests, and app icon.

## 当前状态

- 已在 **Apple M3 / 8 GB / macOS 15.6.1** 构建并运行，维护者已实际试玩，反馈未发现明显问题。
- 宇智波鼬作为优先验证角色，涵盖原包中的常规形态及其他可选形态。
- 保留原游戏的角色、地图、招式与逻辑；使用带运行时的 `.app`，游玩时不需要另装 Java 或 AIR SDK。
- 图标自动随构建安装，存档写入用户应用数据目录，移动应用不会改变存档位置。
- 只验证了上述机器；其他 Mac、手柄、联网和 Windows 原版帧级一致性没有完整验证。

这是 **v0.1.0 的适配工程**。游戏自身的版本不随工程版本改变。

## 支持哪一版

目前仅支持入口文件 `launch.f` 的 SHA-256 为以下值的本地包：

```text
2c565d9693eba6ee4ae4e691cbc8f9783e60fbe15a1d589afbe0a1988dddc8cb
```

该包配置写 3.5.0，游戏标题显示 V3.6Sports，随包改动说明到 3.6Sp9。这些名称不能互相替代。工具校验入口指纹，逐文件记录导入资源哈希；入口相同也不保证所有资源与已测包完全相同。其他版本需要单独验证，不要绕过检查后声称兼容。

## 构建自己的应用

需要 macOS、Python 3、Java 和自己合法获取的 [macOS AIR SDK](https://airsdk.harman.com/)。本次实测 SDK 发布号为 51.3.4.3，运行时内部版本为 51.3.4.2。遵守所用 SDK 的许可条件。

```sh
git clone https://github.com/mizhidaili/bvn-macos.git
cd bvn-macos

# 只读导入原版；输出目录必须尚不存在。
python3 scripts/import_game.py "/path/to/original-game" "work/imported"

# 打包输出和临时构建目录也必须尚不存在。
python3 scripts/build_macos.py --sdk "/path/to/AIRSDK" --game "work/imported" --output "dist/死神VS火影.app" --scratch "work/build-001" --app-id local.bvn.macos.playable
```

双击生成的 `.app`，或将它拖到自己的“应用程序”目录。若要继承自己的原存档，可以在导入时加 `--include-save`；仅在应用数据目录尚无存档时导入，已有进度不会被种子存档覆盖。

构建会编译兼容入口、打包原资源和运行时、安装图标、进行本机 ad-hoc 签名，并验证签名与原资源哈希。**本机签名不等于 Developer ID 签名或 Apple 公证。** 系统首次打开提示取决于下载和签名状态；本项目不要求全局关闭 Gatekeeper。

图标源文件和 `.icns` 均在 `assets/`；修改 PNG 后运行 `python3 scripts/build_icon.py` 可用 macOS 自带工具重新打包图标。

## 存档和原文件保护

上述应用 ID 的存档位于：

```text
~/Library/Application Support/local.bvn.macos.playable/Local Store/
```

原游戏加载到共享 AIR 应用域，兼容的 `FileUtils`、`Loger` 将存档和日志重定向到应用存储目录。覆盖存档前检查 JSON，并保留一份 `.previous` 恢复副本。改应用 ID 会使用另一份存档目录。

原目录始终只读。不要把输出或临时目录放进原游戏目录、SDK 目录，或让它们互相嵌套。工具会拒绝这些位置及已存在的输出目录。

## 验证和已知限制

```sh
python3 -m unittest discover -s tests -p 'test_*.py'
```

本机记录包括 99 个具体角色/形态、52 个援助、12 张地图、14 个本机模式流程，以及代表性伤害、连招、气量、变身和存档测试。它们是基本覆盖和代表性对照，**不是全部角色配对或全部招式的穷举测试**。

原包缺少 `assetss/bgm/naruto.m3` 及运行时请求的 `assetss/bgm/winloop.m3`，没有添加猜测的替代音乐。详细证据边界见 [验证说明](docs/verification.md)，工程循环见 [开发方法](docs/loop-engineering.md)。

报告问题时请提供 macOS/芯片、入口哈希、角色与形态、按键/复现步骤，以及去除私人路径后的错误信息。不要上传完整原包、个人存档或凭据。

## 许可与归属

本适配代码和测试以 **GPL-3.0-or-later** 发布；保留原作和相关接口的归属。图标为本项目生成的原创图形，详见 [第三方与素材说明](THIRD_PARTY_NOTICES.md)。代码许可不自动授权分发原游戏素材、角色音画或 AIR 运行时。

参见 [LICENSE](LICENSE) 和 [THIRD_PARTY_NOTICES.md](THIRD_PARTY_NOTICES.md)。
