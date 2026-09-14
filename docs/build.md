# 构建 Mac 应用

[返回首页](../README.md)

只想游玩，可直接 [下载 Mac 版](https://github.com/mizhidaili/bvn-macos/releases/latest/download/BVN-macOS.zip)。以下步骤供需要自行构建的人使用。

## 准备

需要一台 Mac、Python 3、Java，以及自己获取的 [macOS AIR SDK](https://airsdk.harman.com/)。源码树不附带原游戏或 SDK。

目前适配的是标题显示 **V3.6Sports** 的本地旧版游戏包。包内另有 3.5.0 和 3.6Sp9 的版本标记；仅凭名称不能确定是否兼容。导入工具会自动检查 `launch.f`，当前支持的 SHA-256 是：

```text
2c565d9693eba6ee4ae4e691cbc8f9783e60fbe15a1d589afbe0a1988dddc8cb
```

如果提示版本不符，先确认游戏文件，不要跳过校验。其他版本需要另行适配。

## 生成应用

先下载本项目：

```sh
git clone https://github.com/mizhidaili/bvn-macos.git
cd bvn-macos
```

将下面的 `/path/to/original-game` 换成原游戏文件夹路径，导入一份工作副本：

```sh
python3 scripts/import_game.py "/path/to/original-game" "work/imported"
```

要继承原存档，在这条命令末尾加上 `--include-save`。它只会在 Mac 应用尚无存档时导入，不覆盖已有进度。

再把 `/path/to/AIRSDK` 换成 SDK 文件夹路径，生成应用：

```sh
python3 scripts/build_macos.py \
  --sdk "/path/to/AIRSDK" \
  --game "work/imported" \
  --output "dist/死神VS火影.app" \
  --scratch "work/build-001" \
  --app-id local.bvn.macos.playable
```

双击 `dist/死神VS火影.app` 即可游玩，也可以将它拖到“应用程序”文件夹。生成的应用已包含运行时，游玩时无需另装 Java 或 AIR SDK。

导入目录、应用输出和构建临时目录都必须尚不存在；再次构建时请换用新路径。不要把它们放进原游戏或 SDK 文件夹。工具会保留原文件并校验打包内容。

## 存档

存档保存在这里，移动应用不会改变位置：

```text
~/Library/Application Support/local.bvn.macos.playable/Local Store/
```

更新应用时保持上面命令中的 `--app-id` 不变，即可继续使用原存档。覆盖存档前，程序会保留一份 `.previous` 副本。

## 开发与排查

已测试的环境是 Apple M3、8 GB 内存、macOS 15.6.1，AIR SDK 51.3.4.3（运行时内部版本 51.3.4.2）。应用使用本机签名，尚未进行 Apple 公证。其他设备、手柄和联网功能的验证情况见 [验证记录](verification.md)。

运行脚本测试：

```sh
python3 -m unittest discover -s tests -p 'test_*.py'
```

修改 `assets/app-icon.png` 后，用下面的命令重新生成图标，再构建应用：

```sh
python3 scripts/build_icon.py
```

遇到问题时，请说明 Mac 型号、系统版本和复现步骤；如涉及对局，再补充角色与按键。无需上传完整游戏包或个人存档。

[已知问题与验证记录](verification.md) · [开发过程](loop-engineering.md) · [图标设计](icon.md) · [素材与工具说明](../THIRD_PARTY_NOTICES.md)
