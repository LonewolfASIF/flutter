// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:typed_data';
import 'dart:ui' as ui;
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  SemanticsUpdateTestBinding();

  testWidgets('Semantics update does not send update for merged nodes.', (WidgetTester tester) async {
    final SemanticsHandle handle = tester.ensureSemantics();
    // Pumps a placeholder to trigger the warm up frame.
    await tester.pumpWidget(
      const Placeholder(),
      // Stops right after the warm up frame.
      null,
      EnginePhase.build,
    );
    // The warm up frame will send update for an empty semantics tree. We
    // ignore this one time update.
    SemanticsUpdateBuilderSpy.observations.clear();

    // Builds the real widget tree.
    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: MergeSemantics(
          child: Semantics(
            label: 'outer',
            // This semantics node should not be part of the semantics update
            // because it is under another semantics container.
            child: Semantics(
              label: 'inner',
              container: true,
              child: const Text('text'),
            ),
          ),
        ),
      ),
    );

    expect(SemanticsUpdateBuilderSpy.observations.length, 2);

    expect(SemanticsUpdateBuilderSpy.observations.containsKey(0), isTrue);
    expect(SemanticsUpdateBuilderSpy.observations[0]!.childrenInTraversalOrder.length, 1);
    expect(SemanticsUpdateBuilderSpy.observations[0]!.childrenInTraversalOrder[0], 1);

    expect(SemanticsUpdateBuilderSpy.observations.containsKey(1), isTrue);
    expect(SemanticsUpdateBuilderSpy.observations[1]!.childrenInTraversalOrder.length, 0);
    expect(SemanticsUpdateBuilderSpy.observations[1]!.label, 'outer\ninner\ntext');

    SemanticsUpdateBuilderSpy.observations.clear();

    // Updates the inner semantics label and verifies it only sends update for
    // the merged parent.
    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: MergeSemantics(
          child: Semantics(
            label: 'outer',
            // This semantics node should not be part of the semantics update
            // because it is under another semantics container.
            child: Semantics(
              label: 'inner-updated',
              container: true,
              child: const Text('text'),
            ),
          ),
        ),
      ),
    );
    expect(SemanticsUpdateBuilderSpy.observations.length, 1);

    expect(SemanticsUpdateBuilderSpy.observations.containsKey(1), isTrue);
    expect(SemanticsUpdateBuilderSpy.observations[1]!.childrenInTraversalOrder.length, 0);
    expect(SemanticsUpdateBuilderSpy.observations[1]!.label, 'outer\ninner-updated\ntext');

    SemanticsUpdateBuilderSpy.observations.clear();
    handle.dispose();
  });

  testWidgets('Semantics update receives attributed text', (WidgetTester tester) async {
    final SemanticsHandle handle = tester.ensureSemantics();
    // Pumps a placeholder to trigger the warm up frame.
    await tester.pumpWidget(
      const Placeholder(),
      // Stops right after the warm up frame.
      null,
      EnginePhase.build,
    );
    // The warm up frame will send update for an empty semantics tree. We
    // ignore this one time update.
    SemanticsUpdateBuilderSpy.observations.clear();

    // Builds the real widget tree.
    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: Semantics(
          attributedLabel: AttributedString(
            'label',
            attributes: <StringAttribute>[
              SpellOutStringAttribute(range: const TextRange(start: 0, end: 5)),
            ],
          ),
          attributedValue: AttributedString(
            'value',
            attributes: <StringAttribute>[
              LocaleStringAttribute(range: const TextRange(start: 0, end: 5), locale: const Locale('en', 'MX')),
            ],
          ),
          attributedHint: AttributedString(
            'hint',
            attributes: <StringAttribute>[
              SpellOutStringAttribute(range: const TextRange(start: 1, end: 2)),
            ],
          ),
          child: const Placeholder(),
        ),
      ),
    );

    expect(SemanticsUpdateBuilderSpy.observations.length, 2);

    expect(SemanticsUpdateBuilderSpy.observations.containsKey(0), isTrue);
    expect(SemanticsUpdateBuilderSpy.observations[0]!.childrenInTraversalOrder.length, 1);
    expect(SemanticsUpdateBuilderSpy.observations[0]!.childrenInTraversalOrder[0], 1);

    expect(SemanticsUpdateBuilderSpy.observations.containsKey(1), isTrue);
    expect(SemanticsUpdateBuilderSpy.observations[1]!.childrenInTraversalOrder.length, 0);
    expect(SemanticsUpdateBuilderSpy.observations[1]!.label, 'label');
    expect(SemanticsUpdateBuilderSpy.observations[1]!.labelAttributes!.length, 1);
    expect(SemanticsUpdateBuilderSpy.observations[1]!.labelAttributes![0] is SpellOutStringAttribute, isTrue);
    expect(SemanticsUpdateBuilderSpy.observations[1]!.labelAttributes![0].range, const TextRange(start: 0, end: 5));

    expect(SemanticsUpdateBuilderSpy.observations[1]!.value, 'value');
    expect(SemanticsUpdateBuilderSpy.observations[1]!.valueAttributes!.length, 1);
    expect(SemanticsUpdateBuilderSpy.observations[1]!.valueAttributes![0] is LocaleStringAttribute, isTrue);
    final LocaleStringAttribute localeAttribute = SemanticsUpdateBuilderSpy.observations[1]!.valueAttributes![0] as LocaleStringAttribute;
    expect(localeAttribute.range, const TextRange(start: 0, end: 5));
    expect(localeAttribute.locale, const Locale('en', 'MX'));

    expect(SemanticsUpdateBuilderSpy.observations[1]!.hint, 'hint');
    expect(SemanticsUpdateBuilderSpy.observations[1]!.hintAttributes!.length, 1);
    expect(SemanticsUpdateBuilderSpy.observations[1]!.hintAttributes![0] is SpellOutStringAttribute, isTrue);
    expect(SemanticsUpdateBuilderSpy.observations[1]!.hintAttributes![0].range, const TextRange(start: 1, end: 2));

    expect(
      tester.widget(find.byType(Semantics)).toString(),
      'Semantics('
        'container: false, '
        'properties: SemanticsProperties, '
        'attributedLabel: "label" [SpellOutStringAttribute(TextRange(start: 0, end: 5))], '
        'attributedValue: "value" [LocaleStringAttribute(TextRange(start: 0, end: 5), en-MX)], '
        'attributedHint: "hint" [SpellOutStringAttribute(TextRange(start: 1, end: 2))], '
        'tooltip: null'// ignore: missing_whitespace_between_adjacent_strings
      ')',
    );

    SemanticsUpdateBuilderSpy.observations.clear();
    handle.dispose();
  });
}

class SemanticsUpdateTestBinding extends AutomatedTestWidgetsFlutterBinding {
  @override
  ui.SemanticsUpdateBuilder createSemanticsUpdateBuilder() {
    return SemanticsUpdateBuilderSpy();
  }
}

class SemanticsUpdateBuilderSpy extends ui.SemanticsUpdateBuilder {
  static Map<int, SemanticsNodeUpdateObservation> observations = <int, SemanticsNodeUpdateObservation>{};

  @override
  void updateNode({
    required int id,
    required int flags,
    required int actions,
    required int maxValueLength,
    required int currentValueLength,
    required int textSelectionBase,
    required int textSelectionExtent,
    required int platformViewId,
    required int scrollChildren,
    required int scrollIndex,
    required double scrollPosition,
    required double scrollExtentMax,
    required double scrollExtentMin,
    required double elevation,
    required double thickness,
    required Rect rect,
    required String label,
    List<ui.StringAttribute>? labelAttributes,
    required String value,
    List<ui.StringAttribute>? valueAttributes,
    required String increasedValue,
    List<ui.StringAttribute>? increasedValueAttributes,
    required String decreasedValue,
    List<ui.StringAttribute>? decreasedValueAttributes,
    required String hint,
    List<ui.StringAttribute>? hintAttributes,
    String? tooltip,
    TextDirection? textDirection,
    required Float64List transform,
    required Int32List childrenInTraversalOrder,
    required Int32List childrenInHitTestOrder,
    required Int32List additionalActions,
  }) {
    // Makes sure we don't send the same id twice.
    assert(!observations.containsKey(id));
    observations[id] = SemanticsNodeUpdateObservation(
      id: id,
      flags: flags,
      actions: actions,
      maxValueLength: maxValueLength,
      currentValueLength: currentValueLength,
      textSelectionBase: textSelectionBase,
      textSelectionExtent: textSelectionExtent,
      platformViewId: platformViewId,
      scrollChildren: scrollChildren,
      scrollIndex: scrollIndex,
      scrollPosition: scrollPosition,
      scrollExtentMax: scrollExtentMax,
      scrollExtentMin: scrollExtentMin,
      elevation: elevation,
      thickness: thickness,
      rect: rect,
      label: label,
      labelAttributes: labelAttributes,
      hint: hint,
      hintAttributes: hintAttributes,
      value: value,
      valueAttributes: valueAttributes,
      increasedValue: increasedValue,
      increasedValueAttributes: increasedValueAttributes,
      decreasedValue: decreasedValue,
      decreasedValueAttributes: decreasedValueAttributes,
      textDirection: textDirection,
      transform: transform,
      childrenInTraversalOrder: childrenInTraversalOrder,
      childrenInHitTestOrder: childrenInHitTestOrder,
      additionalActions: additionalActions,
    );
  }
}

class SemanticsNodeUpdateObservation {
  const SemanticsNodeUpdateObservation({
    required this.id,
    required this.flags,
    required this.actions,
    required this.maxValueLength,
    required this.currentValueLength,
    required this.textSelectionBase,
    required this.textSelectionExtent,
    required this.platformViewId,
    required this.scrollChildren,
    required this.scrollIndex,
    required this.scrollPosition,
    required this.scrollExtentMax,
    required this.scrollExtentMin,
    required this.elevation,
    required this.thickness,
    required this.rect,
    required this.label,
    this.labelAttributes,
    required this.value,
    this.valueAttributes,
    required this.increasedValue,
    this.increasedValueAttributes,
    required this.decreasedValue,
    this.decreasedValueAttributes,
    required this.hint,
    this.hintAttributes,
    this.textDirection,
    required this.transform,
    required this.childrenInTraversalOrder,
    required this.childrenInHitTestOrder,
    required this.additionalActions,
  });

  final int id;
  final int flags;
  final int actions;
  final int maxValueLength;
  final int currentValueLength;
  final int textSelectionBase;
  final int textSelectionExtent;
  final int platformViewId;
  final int scrollChildren;
  final int scrollIndex;
  final double scrollPosition;
  final double scrollExtentMax;
  final double scrollExtentMin;
  final double elevation;
  final double thickness;
  final Rect rect;
  final String label;
  final List<ui.StringAttribute>? labelAttributes;
  final String value;
  final List<ui.StringAttribute>? valueAttributes;
  final String increasedValue;
  final List<ui.StringAttribute>? increasedValueAttributes;
  final String decreasedValue;
  final List<ui.StringAttribute>? decreasedValueAttributes;
  final String hint;
  final List<ui.StringAttribute>? hintAttributes;
  final TextDirection? textDirection;
  final Float64List transform;
  final Int32List childrenInTraversalOrder;
  final Int32List childrenInHitTestOrder;
  final Int32List additionalActions;
}
