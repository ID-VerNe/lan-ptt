// SPDX-License-Identifier: GPL-3.0-or-later

import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:lan_ptt/core/protocol/frame.dart';
import 'package:lan_ptt/core/protocol/frame_type.dart';

void main() {
  group('Frame wire format', () {
    test('encodes the 6-byte header in big-endian order', () {
      final Frame frame = Frame(
        type: FrameType.audio,
        senderId: 7,
        seq: 0x1234,
        payload: Uint8List.fromList(<int>[1, 2, 3]),
      );
      final Uint8List bytes = frame.encode();

      expect(bytes.length, Frame.headerSize + 3);
      expect(
        bytes.sublist(0, Frame.headerSize).toList(),
        <int>[0x01, 0x07, 0x12, 0x34, 0x00, 0x03],
      );
      expect(bytes.sublist(Frame.headerSize).toList(), <int>[1, 2, 3]);
    });

    test('round-trips type, senderId, seq and payload at seq boundary', () {
      final Frame original = Frame(
        type: FrameType.roster,
        senderId: 42,
        seq: 65535,
        payload: Uint8List.fromList(
          List<int>.generate(64, (int i) => i % 251),
        ),
      );
      final Frame? decoded = Frame.decode(original.encode());

      expect(decoded, isNotNull);
      expect(decoded!.type, FrameType.roster);
      expect(decoded.senderId, 42);
      expect(decoded.seq, 65535);
      expect(decoded.payload.toList(), original.payload.toList());
    });

    test('accepts an empty payload (heartbeat / pttState)', () {
      final Frame frame = Frame(
        type: FrameType.heartbeat,
        senderId: 1,
        seq: 0,
        payload: Uint8List(0),
      );

      expect(frame.encode().length, Frame.headerSize);
      expect(Frame.decode(frame.encode())!.payload.isEmpty, isTrue);
    });

    test('rejects truncated buffers and trailing bytes', () {
      final Uint8List bytes = Frame(
        type: FrameType.audio,
        senderId: 1,
        seq: 1,
        payload: Uint8List.fromList(<int>[9, 9]),
      ).encode();

      expect(Frame.decode(Uint8List.sublistView(bytes, 0, 5)), isNull);
      expect(Frame.decode(Uint8List.sublistView(bytes, 0, 7)), isNull);
      expect(
        Frame.decode(Uint8List.fromList(<int>[...bytes, 0])),
        isNull,
      );
    });

    test('rejects an oversized declared length', () {
      // len = 0x0201 = 513 > maxPayloadSize
      final Uint8List header = Uint8List.fromList(
        <int>[0x01, 0x01, 0x00, 0x01, 0x02, 0x01],
      );
      expect(Frame.decode(header), isNull);
    });

    test('rejects frame types removed with encryption / chat', () {
      for (final int value in <int>[0x09, 0x0a, 0x0b, 0x0c, 0x0d, 0x0e]) {
        final Uint8List bytes = Uint8List.fromList(
          <int>[value, 1, 0, 1, 0, 0],
        );
        expect(
          Frame.decode(bytes),
          isNull,
          reason: 'type 0x${value.toRadixString(16)} must be rejected',
        );
      }
    });

    test('rejects payloads larger than maxPayloadSize at construction', () {
      expect(
        () => Frame(
          type: FrameType.audio,
          senderId: 1,
          seq: 1,
          payload: Uint8List(Frame.maxPayloadSize + 1),
        ),
        throwsArgumentError,
      );
    });

    test('FrameType.fromValue covers exactly the retained 8 types', () {
      expect(FrameType.values.length, 8);
      for (int value = 0x01; value <= 0x08; value++) {
        expect(FrameType.fromValue(value), isNotNull);
      }
      expect(FrameType.fromValue(0x00), isNull);
      expect(FrameType.fromValue(0xff), isNull);
    });
  });
}
