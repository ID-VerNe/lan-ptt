# lan-ptt

无互联网环境下的 Android ↔ Android 对讲机。一台手机开系统 Wi-Fi 热点，其余设备连上即可 PTT 半双工通话；不依赖任何外网服务。

> **当前状态：骨架版本（skeleton）**。本提交只包含许可证合规基线、Flutter 工程骨架与线协议帧格式，音频、发现、房间、PTT 链路尚未接入。详见 [`docs/详细实施方案.md`](docs/详细实施方案.md)。

## 设计约束

| 项 | 约定 |
|---|---|
| 网络 | 仅 Wi-Fi 热点局域网，**无互联网出口**；首版不写建网代码，用户手动开热点 |
| 平台 | Android ↔ Android（保留 Flutter/Dart 层，P0 的原生层为 Kotlin） |
| 延时 | mouth-to-ear **p95 < 120ms**，第三台设备录制法实测 |
| 音质 | Opus；P0 16kHz/20ms/24kbps，P1 升 48kHz/10ms + DTX/FEC/PLC |
| 回授 | PTT 半双工时本地静音为主，硬件 AEC/NS/AGC 为辅 |
| 拓扑 | 星形：房主转发音频，房间 ≤ 6 人 |
| **加密** | **不做**。无密钥交换、无签名、无 sessionToken 握手 |
| **锁屏** | **不做**。仅保留最小 Foreground Service 防止切后台被回收 |
| 许可证 | **GPL-3.0-or-later** |

### 为什么是 GPLv3 而不是 GPLv2

上游 [Starlordzz/sunsetripple](https://github.com/Starlordzz/sunsetripple) 与 [google/oboe](https://github.com/google/oboe) 均为 **Apache-2.0**。Apache-2.0 的专利终止条款与 GPLv2 不兼容、与 **GPLv3 兼容**；挂 GPLv2 就无法合法复用这两份代码。第三方声明与全文见 [`THIRD_PARTY_NOTICES`](THIRD_PARTY_NOTICES)，逐文件修改声明见 [`NOTICE.changes`](NOTICE.changes)。

> 「开源」不等于「任意代码都能 copy」：**无 LICENSE 文件的仓库仍属"保留所有权利"**，本项目不会引入（尤其 `zthenea/MotoIntercom` 的 `startLocalOnlyHotspot` 实现，只能按 Android 官方 API clean-room 重写）。AGPL-3.0 项目同样不引入，避免 §13 覆盖整个合并作品。

## 线协议（已落地部分）

```
[0]     FrameType (1B)
[1]     senderId  (1B)
[2..3]  seq16     (uint16, Big-Endian)
[4..5]  length    (uint16, Big-Endian)
[6..N]  payload   (0..512B)
```

`decode()` 对短包、长度不符、尾部多余字节、超限载荷、未知类型一律返回 `null`；构造时载荷超过 512B 直接抛 `ArgumentError`（绝不静默截断，否则 TCP 字节流会把后续帧解错）。

保留 8 类帧：`audio / joinReq / roster / pttState / heartbeat / leave / hostHandover / hostAnnounce`。上游的 `handshakeHello / handshakeConfirm / sealed / chat*` 随「不加密、不做聊天」删除。

| 面 | 端口 | 协议 |
|---|---|---|
| 控制 | 8988 | TCP，自定界帧 |
| 音频 | 8989 | UDP，房主转发，禁止走 TCP |
| 发现 | 8990 | UDP 广播 `255.255.255.255` + `/24` 定向广播 |

## 目录

```
├── LICENSE                       GPL-3.0-or-later 全文
├── THIRD_PARTY_NOTICES / licenses/  Apache-2.0、BSD-3-Clause 全文
├── NOTICE.changes                Apache-2.0 §4 逐文件修改声明
├── docs/详细实施方案.md            路线 A 的 P0/P1/P2 计划
├── lib/
│   ├── main.dart                 极简启动页（PTT 按钮占位）
│   └── core/protocol/            frame.dart / frame_type.dart
└── test/frame_test.dart          帧格式回归测试
```

Android 原生层（`OpusCodec.kt` / `JitterBuffer.kt` / `PlatformAudioPlugin.kt` / FGS）、`lib/core/{transport,session,audio,diagnostics}` 与 `native/` 将在 P0 按方案移植。

## 构建与测试

```bash
flutter pub get
flutter test
flutter build apk --debug
```

需要 Flutter SDK（Dart ≥ 3.3）。**注意**：本仓库的骨架文件是在没有 Flutter/Dart SDK 的机器上编写的，`flutter test` 尚未在本机实际跑过；首次在带 SDK 的机器上执行时请以 CI/本地结果为准。

## 路线图

- **P0 跑通**：移植会话/传输/发现层，摘除加密耦合，`prebufferFrames 3→2`、AudioRecord/AudioTrack buffer `*4→*2`，两台真机连同一热点可双向 PTT，测出延时基线。
- **P1 路线 A**：Oboe/AAudio + 官方 libopus（48kHz/10ms、DTX/FEC/PLC）、自适应 jitter 20~60ms、floor control、分段延时打点。
- **P2 验收**：mouth-to-ear ≥100 次取 p50/p95/p99，p95 < 120ms；热点拉距、多人并发、房主掉线选举；可选一键开热点。

## 许可证

本项目整体以 **GPL-3.0-or-later** 发布，见 [`LICENSE`](LICENSE)。移植自 Apache-2.0 上游的文件保留其原始授权与版权声明；对这些文件的修改以 GPL-3.0-or-later 提供，两者兼容。

`SPDX-License-Identifier: GPL-3.0-or-later`
