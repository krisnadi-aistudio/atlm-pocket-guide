import 'dart:math';

import 'package:atlm_pocket_guide/models.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';

/// Fuzz invarian parser (seed deterministik 20261103 — reproducible).
/// Menjaga invarian yang disepakati debat ronde 10:
/// - tidak crash pada input acak
/// - item kritis tak-kosong & ter-trim; sisa ' - ' harus diapit digit
/// - jumlah seksi == jumlah blok non-kosong; blok kritis dikenali
/// - indeks findSectionForQuery valid
/// Dibuat dari skrip manual 3 Nov 2026 (85.000 iterasi, 0 kegagalan).
void main() {
  test('fuzz invarian parser (seed 20261103)', () {
    final rand = Random(20261103);
    var failures = 0;
    void fail(String m) {
      failures++;
      if (failures <= 10) debugPrint('FUZZ FAIL: $m');
    }

    bool isDigit(String c) {
      final u = c.codeUnitAt(0);
      return u >= 0x30 && u <= 0x39;
    }

    const words = [
      'darah', 'EDTA', 'pH', 'uji', 'sampel', 'dan', 'atau', 'tidak',
      'segera', 'menit', 'suhu', 'ruang', 'heparin', 'tabung'
    ];
    String word() {
      final r = rand.nextDouble();
      if (r < 0.2) return '${rand.nextInt(100)}';
      if (r < 0.3) return '${rand.nextInt(10)},${rand.nextInt(90)}';
      return words[rand.nextInt(words.length)];
    }

    String frag() {
      final parts = <String>[];
      final n = 1 + rand.nextInt(7);
      for (var i = 0; i < n; i++) {
        final r = rand.nextDouble();
        if (r < 0.18) {
          parts.add(' - ');
        } else if (r < 0.24) {
          parts.add('-');
        } else {
          parts.add(word());
        }
      }
      return parts.join(' ');
    }

    // 1. parseCriticalItems
    for (var i = 0; i < 40000; i++) {
      var rest = frag();
      if (rand.nextBool()) rest = '- $rest';
      if (rand.nextDouble() < 0.1) rest = '$rest - ';
      List<String> items;
      try {
        items = parseCriticalItems(rest);
      } catch (e) {
        fail('critical crash "$rest": $e');
        continue;
      }
      for (final it in items) {
        if (it.isEmpty || it != it.trim()) {
          fail('critical item kosong/tak-trim dari "$rest"');
        }
        var j = 0;
        while (true) {
          j = it.indexOf(' - ', j);
          if (j < 0) break;
          final bd = j > 0 && isDigit(it[j - 1]);
          final ad = j + 3 < it.length && isDigit(it[j + 3]);
          if (!(bd && ad)) {
            fail('critical " - " tak-terjaga di "$it"');
            break;
          }
          j += 3;
        }
      }
    }

    // 2. parseBodySections
    const labels = [
      'Prinsip', 'Sampel', 'Alat', 'Reagen', 'Cara pemeriksaan manual',
      'Rumus', 'Interpretasi', 'Nilai rujukan', 'Label Acak'
    ];
    for (var i = 0; i < 20000; i++) {
      final blocks = <String>[];
      final n = 1 + rand.nextInt(5);
      for (var b = 0; b < n; b++) {
        final r = rand.nextDouble();
        if (r < 0.12) {
          blocks.add('Titik kritis: ${frag()}');
        } else if (r < 0.4) {
          var txt = frag();
          if (rand.nextDouble() < 0.4) txt = '$txt\n${frag()}\n${frag()}';
          blocks.add('${labels[rand.nextInt(labels.length)]}: $txt');
        } else {
          blocks.add(frag());
        }
        if (rand.nextDouble() < 0.1) blocks.add('   ');
      }
      final body = blocks.join('\n\n');
      List<BodySection> secs;
      try {
        secs = parseBodySections(body);
      } catch (e) {
        fail('sections crash: $e');
        continue;
      }
      final nonEmpty =
          blocks.where((b) => b.trim().isNotEmpty).toList();
      if (secs.length != nonEmpty.length) {
        fail('sections ${secs.length} != blok ${nonEmpty.length}');
      }
      for (var k = 0;
          k < secs.length && k < nonEmpty.length;
          k++) {
        if (nonEmpty[k].startsWith('Titik kritis:') &&
            secs[k].kind != SectionKind.critical) {
          fail('blok kritis tak dikenali');
        }
      }
    }

    // 3. parseInlineSteps
    for (var i = 0; i < 20000; i++) {
      var t = frag();
      if (rand.nextDouble() < 0.5) {
        t = '1. ${frag()} 2. ${frag()}';
        if (rand.nextBool()) t = '${frag()}\n$t';
      }
      try {
        parseInlineSteps(t);
      } catch (e) {
        fail('steps crash: $e');
      }
    }

    // 4. findSectionForQuery
    for (var i = 0; i < 5000; i++) {
      final body = 'Prinsip: ${frag()}\n\nSampel: ${frag()}\n\n'
          'Titik kritis: ${frag()} - ${frag()}';
      final secs = parseBodySections(body);
      try {
        final idx = findSectionForQuery(secs, frag());
        if (idx != null && (idx < 0 || idx >= secs.length)) {
          fail('find indeks liar $idx');
        }
      } catch (e) {
        fail('find crash: $e');
      }
    }

    expect(failures, 0, reason: 'fuzz menemukan pelanggaran invarian');
  });
}
