// SPDX-License-Identifier: Apache-2.0
//
// Portions Copyright 2026 Starlordzz — SunsetRipple, Apache License 2.0
// Source: lib/core/protocol/frame_type.dart @ 0ffd8c40
// Modifications Copyright 2026 ID-VerNe, licensed GPL-3.0-or-later.
// Changes are itemized in NOTICE.changes (Apache-2.0 §4).

/// 精简后的线协议帧类型，只保留无网热点 LAN 对讲必需的 8 类。
///
/// 上游的 handshakeHello / handshakeConfirm / sealed（加密握手）与
/// chat / chatSync / chatDelete（聊天）随「不加密、不做聊天」删除。
/// 数值保持与上游一致，避免与旧包或抓包工具混淆。
enum FrameType {
  audio(0x01),
  joinReq(0x02),
  roster(0x03),
  pttState(0x04),
  heartbeat(0x05),
  leave(0x06),
  hostHandover(0x07),
  hostAnnounce(0x08);

  final int value;

  const FrameType(this.value);

  /// 未知类型返回 null，由 Frame.decode 丢弃该帧。
  static FrameType? fromValue(int value) {
    for (final FrameType type in FrameType.values) {
      if (type.value == value) return type;
    }
    return null;
  }
}
