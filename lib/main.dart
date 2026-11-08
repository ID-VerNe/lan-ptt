// SPDX-License-Identifier: GPL-3.0-or-later

import 'package:flutter/material.dart';

void main() {
  runApp(const LanPttApp());
}

class LanPttApp extends StatelessWidget {
  const LanPttApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'LAN PTT',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo),
        useMaterial3: true,
      ),
      home: const SkeletonScreen(),
    );
  }
}

/// 骨架启动页：仅用于确认工程可以启动并渲染。
/// 房间列表、PTT 按下讲话、成员状态会在 P0 接入 RoomSession 后替换。
class SkeletonScreen extends StatelessWidget {
  const SkeletonScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('LAN PTT')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            const Text(
              '离线局域网对讲 · 骨架版本',
              style: TextStyle(fontSize: 18),
            ),
            const SizedBox(height: 8),
            Text(
              '发现 / 房间 / 音频链路尚未接入',
              style: TextStyle(color: Colors.grey.shade600),
            ),
            const SizedBox(height: 24),
            // P0：把 onPressed 换成 RoomSession 的 floor request / release。
            FilledButton(
              onPressed: null,
              child: const Text('按住说话（未接入）'),
            ),
          ],
        ),
      ),
    );
  }
}
