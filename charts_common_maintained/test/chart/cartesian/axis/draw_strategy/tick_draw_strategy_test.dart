// Copyright 2018 the Charts project authors. Please see the AUTHORS file
// for details.
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
// http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

import 'dart:math';
import 'package:charts_common_maintained/src/chart/cartesian/axis/draw_strategy/base_tick_draw_strategy.dart';
import 'package:charts_common_maintained/src/chart/cartesian/axis/axis.dart';
import 'package:charts_common_maintained/src/chart/cartesian/axis/spec/axis_spec.dart';
import 'package:charts_common_maintained/src/chart/cartesian/axis/tick.dart';
import 'package:charts_common_maintained/src/chart/common/chart_canvas.dart';
import 'package:charts_common_maintained/src/chart/common/chart_context.dart';
import 'package:charts_common_maintained/src/common/graphics_factory.dart';
import 'package:charts_common_maintained/src/common/line_style.dart';
import 'package:charts_common_maintained/src/common/text_element.dart';
import 'package:charts_common_maintained/src/common/text_measurement.dart';
import 'package:charts_common_maintained/src/common/text_style.dart';

import 'package:mockito/mockito.dart';
import 'package:test/test.dart';

class MockContext extends Mock implements ChartContext {
  @override
  bool get chartContainerIsRtl => false;

  @override
  bool get isRtl => false;
}

/// Implementation of [BaseTickDrawStrategy] that does nothing on draw.
class BaseTickDrawStrategyImpl<D> extends BaseTickDrawStrategy<D> {
  BaseTickDrawStrategyImpl(
    super.chartContext,
    super.graphicsFactory, {
    super.labelStyleSpec,
    super.axisLineStyleSpec,
    super.labelAnchor,
    super.labelJustification,
    super.labelOffsetFromAxisPx,
    super.labelCollisionOffsetFromAxisPx,
    super.labelOffsetFromTickPx,
    super.labelCollisionOffsetFromTickPx,
    super.minimumPaddingBetweenLabelsPx,
    super.labelRotation,
    super.labelCollisionRotation,
  });

  @override
  void draw(
    ChartCanvas canvas,
    Tick<D> tick, {
    required AxisOrientation orientation,
    required Rectangle<int> axisBounds,
    required Rectangle<int> drawAreaBounds,
    required bool isFirst,
    required bool isLast,
    bool collision = false,
  }) {}

  @override
  void drawLabel(
    ChartCanvas canvas,
    Tick<D> tick, {
    required AxisOrientation orientation,
    required Rectangle<int> axisBounds,
    required Rectangle<int>? drawAreaBounds,
    bool isFirst = false,
    bool isLast = false,
    bool collision = false,
  }) {
    super.drawLabel(
      canvas,
      tick,
      orientation: orientation,
      axisBounds: axisBounds,
      drawAreaBounds: drawAreaBounds,
      isFirst: isFirst,
      isLast: isLast,
      collision: collision,
    );
  }
}

/// Fake [TextElement] for testing.
///
/// [baseline] returns the same value as the [verticalSliceWidth] specified.
class FakeTextElement implements TextElement {
  static const _defaultVerticalSliceWidth = 15.0;

  @override
  final String text;

  @override
  final TextMeasurement measurement;

  @override
  var textStyle = MockTextStyle();

  @override
  int? maxWidth;

  @override
  MaxWidthStrategy? maxWidthStrategy;

  @override
  TextDirection textDirection;
  double? opacity;

  FakeTextElement(
    this.text,
    this.textDirection,
    double? horizontalSliceWidth,
    double? verticalSliceWidth,
  ) : measurement = TextMeasurement(
        horizontalSliceWidth: horizontalSliceWidth ?? 0,
        verticalSliceWidth: verticalSliceWidth ?? _defaultVerticalSliceWidth,
      );
}

class MockGraphicsFactory extends Mock implements GraphicsFactory {
  final textElements = <String, TextElement>{};

  @override
  TextStyle createTextPaint() => MockTextStyle();

  @override
  TextElement createTextElement(String text) =>
      textElements[text] ?? FakeTextElement(text, TextDirection.ltr, 0, 15);

  @override
  LineStyle createLinePaint() => MockLineStyle();
}

class MockLineStyle extends Mock implements LineStyle {}

class MockTextStyle extends Mock implements TextStyle {}

class DrawTextCall {
  DrawTextCall(this.textElement, this.offsetX, this.offsetY, this.rotation);

  final TextElement textElement;
  final int offsetX;
  final int offsetY;
  final double rotation;
}

class MockChartCanvas extends Mock implements ChartCanvas {
  final drawTextCalls = <DrawTextCall>[];

  @override
  void drawText(
    TextElement textElement,
    int offsetX,
    int offsetY, {
    double rotation = 0.0,
  }) {
    drawTextCalls.add(DrawTextCall(textElement, offsetX, offsetY, rotation));
  }
}

/// Helper function to create [Tick] for testing.
Tick<String> createTick(
  String value,
  double locationPx, {
  double? horizontalWidth,
  double? verticalWidth,
  TextDirection textDirection = TextDirection.ltr,
  bool collision = false,
}) {
  return Tick<String>(
    value: value,
    locationPx: locationPx,
    textElement: FakeTextElement(
      value,
      textDirection,
      horizontalWidth,
      verticalWidth,
    ),
  );
}

void main() {
  late MockGraphicsFactory graphicsFactory;
  late ChartContext chartContext;

  setUpAll(() {
    graphicsFactory = MockGraphicsFactory();

    chartContext = MockContext();
  });

  group('collision detection - vertically drawn axis', () {
    test('ticks do not collide', () {
      final drawStrategy = BaseTickDrawStrategyImpl(
        chartContext,
        graphicsFactory,
        minimumPaddingBetweenLabelsPx: 2,
      );

      final ticks = [
        createTick('A', 10.0, verticalWidth: 8.0), // 10.0 - 20.0 (18.0 + 2)
        createTick('B', 20.0, verticalWidth: 8.0), // 20.0 - 30.0 (28.0 + 2)
        createTick('C', 30.0, verticalWidth: 8.0), // 30.0 - 40.0 (38.0 + 2)
      ];

      final report = drawStrategy.collides(ticks, AxisOrientation.left);

      expect(report.ticksCollide, isFalse);
    });

    test('ticks collide because it does not have minimum padding', () {
      final drawStrategy = BaseTickDrawStrategyImpl(
        chartContext,
        graphicsFactory,
        minimumPaddingBetweenLabelsPx: 2,
      );

      final ticks = [
        createTick('A', 10.0, verticalWidth: 8.0), // 10.0 - 20.0 (18.0 + 2)
        createTick('B', 20.0, verticalWidth: 9.0), // 20.0 - 31.0 (28.0 + 3)
        createTick('C', 30.0, verticalWidth: 8.0), // 30.0 - 40.0 (38.0 + 2)
      ];

      final report = drawStrategy.collides(ticks, AxisOrientation.left);

      expect(report.ticksCollide, isTrue);
    });

    test('first tick causes collision', () {
      final drawStrategy = BaseTickDrawStrategyImpl(
        chartContext,
        graphicsFactory,
        minimumPaddingBetweenLabelsPx: 0,
      );

      final ticks = [
        createTick('A', 10.0, verticalWidth: 11.0), // 10.0 - 21.0
        createTick('B', 20.0, verticalWidth: 10.0), // 20.0 - 30.0
        createTick('C', 30.0, verticalWidth: 10.0), // 30.0 - 40.0
      ];

      final report = drawStrategy.collides(ticks, AxisOrientation.left);

      expect(report.ticksCollide, isTrue);
    });

    test('last tick causes collision', () {
      final drawStrategy = BaseTickDrawStrategyImpl(
        chartContext,
        graphicsFactory,
        minimumPaddingBetweenLabelsPx: 0,
      );

      final ticks = [
        createTick('A', 10.0, verticalWidth: 10.0), // 10.0 - 20.0
        createTick('B', 20.0, verticalWidth: 10.0), // 20.0 - 30.0
        createTick('C', 29.0, verticalWidth: 10.0), // 29.0 - 40.0
      ];

      final report = drawStrategy.collides(ticks, AxisOrientation.left);

      expect(report.ticksCollide, isTrue);
    });

    test('ticks do not collide for inside tick label anchor', () {
      final drawStrategy = BaseTickDrawStrategyImpl(
        chartContext,
        graphicsFactory,
        minimumPaddingBetweenLabelsPx: 2,
        labelAnchor: TickLabelAnchor.inside,
      );

      final ticks = [
        createTick('A', 10.0, verticalWidth: 8.0), // 10.0 - 20.0 (18.0 + 2)
        createTick('B', 25.0, verticalWidth: 8.0), // 20.0 - 30.0 (25 + 2 + 1)
        createTick('C', 40.0, verticalWidth: 8.0), // 30.0 - 40.0 (40-8-2)
      ];

      final report = drawStrategy.collides(ticks, AxisOrientation.left);

      expect(report.ticksCollide, isFalse);
    });

    test('ticks collide for inside anchor - first tick too large', () {
      final drawStrategy = BaseTickDrawStrategyImpl(
        chartContext,
        graphicsFactory,
        minimumPaddingBetweenLabelsPx: 2,
        labelAnchor: TickLabelAnchor.inside,
      );

      final ticks = [
        createTick('A', 10.0, verticalWidth: 9.0), // 10.0 - 21.0 (19.0 + 2)
        createTick('B', 25.0, verticalWidth: 8.0), // 20.0 - 30.0 (25 + 2 + 1)
        createTick('C', 40.0, verticalWidth: 8.0), // 30.0 - 40.0 (40-8-2)
      ];

      final report = drawStrategy.collides(ticks, AxisOrientation.left);

      expect(report.ticksCollide, isTrue);
    });

    test('ticks collide for inside anchor - center tick too large', () {
      final drawStrategy = BaseTickDrawStrategyImpl(
        chartContext,
        graphicsFactory,
        minimumPaddingBetweenLabelsPx: 2,
        labelAnchor: TickLabelAnchor.inside,
      );

      final ticks = [
        createTick('A', 10.0, verticalWidth: 8.0), // 10.0 - 20.0 (18.0 + 2)
        createTick('B', 25.0, verticalWidth: 9.0), // 19.5 - 30.5 (25 + 2.5 + 1)
        createTick('C', 40.0, verticalWidth: 8.0), // 30.0 - 40.0 (40-8-2)
      ];

      final report = drawStrategy.collides(ticks, AxisOrientation.left);

      expect(report.ticksCollide, isTrue);
    });

    test('ticks collide for inside anchor - last tick too large', () {
      final drawStrategy = BaseTickDrawStrategyImpl(
        chartContext,
        graphicsFactory,
        minimumPaddingBetweenLabelsPx: 2,
        labelAnchor: TickLabelAnchor.inside,
      );

      final ticks = [
        createTick('A', 10.0, verticalWidth: 8.0), // 10.0 - 20.0 (18.0 + 2)
        createTick('B', 25.0, verticalWidth: 8.0), // 20.0 - 30.0 (25 + 2 + 1)
        createTick('C', 40.0, verticalWidth: 9.0), // 29.0 - 40.0 (40-9-2)
      ];

      final report = drawStrategy.collides(ticks, AxisOrientation.left);

      expect(report.ticksCollide, isTrue);
    });
  });

  group('collision detection - horizontally drawn axis', () {
    test('ticks do not collide for TickLabelAnchor.before', () {
      final drawStrategy = BaseTickDrawStrategyImpl(
        chartContext,
        graphicsFactory,
        minimumPaddingBetweenLabelsPx: 2,
        labelAnchor: TickLabelAnchor.before,
      );

      final ticks = [
        createTick('A', 10.0, horizontalWidth: 8.0), // 10.0 - 20.0 (18.0 + 2)
        createTick('B', 20.0, horizontalWidth: 8.0), // 20.0 - 30.0 (28.0 + 2)
        createTick('C', 30.0, horizontalWidth: 8.0), // 30.0 - 40.0 (38.0 + 2)
      ];

      final report = drawStrategy.collides(ticks, AxisOrientation.bottom);

      expect(report.ticksCollide, isFalse);
    });

    test('ticks do not collide for TickLabelAnchor.inside', () {
      final drawStrategy = BaseTickDrawStrategyImpl(
        chartContext,
        graphicsFactory,
        minimumPaddingBetweenLabelsPx: 0,
        labelAnchor: TickLabelAnchor.inside,
      );

      final ticks = [
        createTick(
          'A',
          10.0,
          horizontalWidth: 10.0,
          textDirection: TextDirection.ltr,
        ), // 10.0 - 20.0
        createTick(
          'B',
          25.0,
          horizontalWidth: 10.0,
          textDirection: TextDirection.center,
        ), // 20.0 - 30.0
        createTick(
          'C',
          40.0,
          horizontalWidth: 10.0,
          textDirection: TextDirection.rtl,
        ), // 30.0 - 40.0
      ];

      final report = drawStrategy.collides(ticks, AxisOrientation.bottom);

      expect(report.ticksCollide, isFalse);
    });

    test('ticks collide - first tick too large', () {
      final drawStrategy = BaseTickDrawStrategyImpl(
        chartContext,
        graphicsFactory,
        minimumPaddingBetweenLabelsPx: 0,
        labelAnchor: TickLabelAnchor.inside,
      );

      final ticks = [
        createTick('A', 10.0, horizontalWidth: 11.0), // 10.0 - 21.0
        createTick('B', 25.0, horizontalWidth: 10.0), // 20.0 - 30.0
        createTick('C', 40.0, horizontalWidth: 10.0), // 30.0 - 40.0
      ];

      final report = drawStrategy.collides(ticks, AxisOrientation.bottom);

      expect(report.ticksCollide, isTrue);
    });

    test('ticks collide - middle tick too large', () {
      final drawStrategy = BaseTickDrawStrategyImpl(
        chartContext,
        graphicsFactory,
        minimumPaddingBetweenLabelsPx: 0,
        labelAnchor: TickLabelAnchor.inside,
      );

      final ticks = [
        createTick('A', 10.0, horizontalWidth: 10.0), // 10.0 - 20.0
        createTick('B', 25.0, horizontalWidth: 11.0), // 19.5 - 30.5
        createTick('C', 40.0, horizontalWidth: 10.0), // 30.0 - 40.0
      ];

      final report = drawStrategy.collides(ticks, AxisOrientation.bottom);

      expect(report.ticksCollide, isTrue);
    });

    test('ticks collide - last tick too large', () {
      final drawStrategy = BaseTickDrawStrategyImpl(
        chartContext,
        graphicsFactory,
        minimumPaddingBetweenLabelsPx: 0,
        labelAnchor: TickLabelAnchor.inside,
      );

      final ticks = [
        createTick('A', 10.0, horizontalWidth: 10.0), // 10.0 - 20.0
        createTick('B', 25.0, horizontalWidth: 10.0), // 20.0 - 30.0
        createTick('C', 40.0, horizontalWidth: 11.0), // 29.0 - 40.0
      ];

      final report = drawStrategy.collides(ticks, AxisOrientation.bottom);

      expect(report.ticksCollide, isTrue);
    });
  });

  group('collision detection - unsorted ticks', () {
    test('ticks do not collide', () {
      final drawStrategy = BaseTickDrawStrategyImpl(
        chartContext,
        graphicsFactory,
        minimumPaddingBetweenLabelsPx: 0,
        labelAnchor: TickLabelAnchor.inside,
      );

      final ticks = [
        createTick('C', 40.0, horizontalWidth: 10.0), // 30.0 - 40.0
        createTick('B', 25.0, horizontalWidth: 10.0), // 20.0 - 30.0
        createTick('A', 10.0, horizontalWidth: 10.0), // 10.0 - 20.0
      ];

      final report = drawStrategy.collides(ticks, AxisOrientation.bottom);

      expect(report.ticksCollide, isFalse);
    });

    test('ticks collide - tick B is too large', () {
      final drawStrategy = BaseTickDrawStrategyImpl(
        chartContext,
        graphicsFactory,
        minimumPaddingBetweenLabelsPx: 0,
        labelAnchor: TickLabelAnchor.inside,
      );

      final ticks = [
        createTick('A', 10.0, horizontalWidth: 10.0), // 10.0 - 20.0
        createTick('C', 40.0, horizontalWidth: 10.0), // 30.0 - 40.0
        createTick('B', 25.0, horizontalWidth: 11.0), // 19.5 - 30.5
      ];

      final report = drawStrategy.collides(ticks, AxisOrientation.bottom);

      expect(report.ticksCollide, isTrue);
    });
  });

  group('collision detection - corner cases', () {
    test('null ticks do not collide', () {
      final drawStrategy = BaseTickDrawStrategyImpl(
        chartContext,
        graphicsFactory,
      );

      final report = drawStrategy.collides(null, AxisOrientation.left);

      expect(report.ticksCollide, isFalse);
    });

    test('empty tick list do not collide', () {
      final drawStrategy = BaseTickDrawStrategyImpl(
        chartContext,
        graphicsFactory,
      );

      final report = drawStrategy.collides([], AxisOrientation.left);

      expect(report.ticksCollide, isFalse);
    });

    test('single tick does not collide', () {
      final drawStrategy = BaseTickDrawStrategyImpl(
        chartContext,
        graphicsFactory,
      );

      final report = drawStrategy.collides([
        createTick('A', 10.0, horizontalWidth: 10.0),
      ], AxisOrientation.bottom);

      expect(report.ticksCollide, isFalse);
    });
  });
  group('Draw Label', () {
    void setUpLabel(String text, {double? width}) {
      graphicsFactory.textElements[text] = FakeTextElement(
        text,
        TextDirection.ltr,
        width,
        15.0,
      );
    }

    late BaseTickDrawStrategyImpl drawStrategy;
    late List<Tick> ticks;

    setUp(() {
      drawStrategy = BaseTickDrawStrategyImpl(chartContext, graphicsFactory);

      ticks = [
        createTick(
          'This label \nspans \n multiple lines!!!',
          0.0,
          horizontalWidth: 100.0,
          verticalWidth: 15.0,
        ), // 10.0 - 20.0
        createTick(
          'A',
          20.0,
          horizontalWidth: 10.0,
          verticalWidth: 15.0,
        ), // 30.0 - 40.0
      ];

      setUpLabel('This label', width: 30.0);
      setUpLabel('spans', width: 10.0);
      setUpLabel('multiple lines!!!', width: 60.0);
      setUpLabel('A', width: 10.0);
    });

    test('measureHorizontallyDrawnTicks', () {
      final offset = drawStrategy.labelOffsetFromAxisPx(collision: false);
      final sizes = drawStrategy.measureHorizontallyDrawnTicks(ticks, 250, 500);

      // Text-Height * numLines + paddingBetweenLines + offset.
      expect(sizes.preferredHeight, 15 * 3 + 4 + offset);
      expect(sizes.preferredWidth, 250);
    });

    test('measureVerticallyDrawnTicks', () {
      final offset = drawStrategy.labelOffsetFromAxisPx(collision: false);
      final sizes = drawStrategy.measureVerticallyDrawnTicks(ticks, 250, 500);

      // Width of the longest line + offset.
      expect(sizes.preferredWidth, 60.0 + offset);
      expect(sizes.preferredHeight, 500);
    });

    test('measureVerticallyDrawnTicks - negative labelOffsetFromAxisPx', () {
      final offset = -500;
      drawStrategy = BaseTickDrawStrategyImpl(
        chartContext,
        graphicsFactory,
        labelOffsetFromAxisPx: offset,
      );
      final sizes = drawStrategy.measureVerticallyDrawnTicks(ticks, 250, 500);

      expect(sizes.preferredWidth, 0);
      expect(sizes.preferredHeight, 500);
    });

    test('Draw multiline label', () {
      final chartCanvas = MockChartCanvas();
      final axisBounds = Rectangle<int>(0, 0, 1000, 1000);

      drawStrategy.drawLabel(
        chartCanvas,
        ticks.first,
        orientation: AxisOrientation.bottom,
        axisBounds: axisBounds,
        drawAreaBounds: null,
      );

      // The y-coordinate should increase by the line's height + padding.
      final labelLine1 = chartCanvas.drawTextCalls[0].textElement;
      expect(labelLine1.text, 'This label');

      final labelLine2 = chartCanvas.drawTextCalls[1].textElement;
      expect(labelLine2.text, 'spans');

      final labelLine3 = chartCanvas.drawTextCalls[2].textElement;
      expect(labelLine3.text, 'multiple lines!!!');
    });

    test('Draw single line label', () {
      final chartCanvas = MockChartCanvas();
      final axisBounds = Rectangle<int>(0, 0, 1000, 1000);

      drawStrategy.drawLabel(
        chartCanvas,
        ticks[1],
        orientation: AxisOrientation.top,
        axisBounds: axisBounds,
        drawAreaBounds: null,
      );

      final labelLine = chartCanvas.drawTextCalls.single.textElement;
      expect(labelLine.text, 'A');
    });
  });

  group('Draw Label with collision', () {
    const collisionRotationDegrees = 45;

    void setUpLabel(String text, {double? width}) {
      graphicsFactory.textElements[text] = FakeTextElement(
        text,
        TextDirection.ltr,
        width,
        15.0,
      );
    }

    late BaseTickDrawStrategyImpl drawStrategy;
    late List<Tick> ticks;

    setUp(() {
      drawStrategy = BaseTickDrawStrategyImpl(
        chartContext,
        graphicsFactory,
        labelCollisionRotation: collisionRotationDegrees,
      );

      ticks = [
        createTick(
          'This label \nspans \n multiple lines!!!',
          0.0,
          horizontalWidth: 100.0,
          verticalWidth: 15.0,
          collision: true,
        ), // 10.0 - 20.0
        createTick(
          'A',
          20.0,
          horizontalWidth: 10.0,
          verticalWidth: 15.0,
          collision: true,
        ), // 30.0 - 40.0
      ];

      setUpLabel('This label', width: 30.0);
      setUpLabel('spans', width: 10.0);
      setUpLabel('multiple lines!!!', width: 60.0);
      setUpLabel('A', width: 10.0);
    });

    test('measureHorizontallyDrawnTicks', () {
      final offset = drawStrategy.labelOffsetFromAxisPx(collision: true);
      final sizes = drawStrategy.measureHorizontallyDrawnTicks(
        ticks,
        250,
        500,
        collision: true,
      );

      // Text-Height * numLines + paddingBetweenLines + offset.
      var baseHeight = (15 * 3 + 4);
      var heightAdjustedForAngle = drawStrategy.calculateHeightForRotatedLabel(
        collisionRotationDegrees,
        baseHeight.toDouble(),
        60 /* width of longest label */,
      );

      expect(sizes.preferredHeight, (heightAdjustedForAngle + offset).ceil());
      expect(sizes.preferredWidth, 250);
    });

    test('measureVerticallyDrawnTicks', () {
      final offset = drawStrategy.labelOffsetFromAxisPx(collision: true);
      final sizes = drawStrategy.measureVerticallyDrawnTicks(
        ticks,
        250,
        500,
        collision: true,
      );

      // Width of the longest line + offset.
      expect(sizes.preferredWidth, 60.0 + offset);
      expect(sizes.preferredHeight, 500);
    });

    test('measureVerticallyDrawnTicks - negativate labelOffsetFromAxisPx', () {
      final offset = -500;
      drawStrategy = BaseTickDrawStrategyImpl(
        chartContext,
        graphicsFactory,
        labelCollisionRotation: 45,
        labelCollisionOffsetFromAxisPx: offset,
      );
      final sizes = drawStrategy.measureVerticallyDrawnTicks(
        ticks,
        250,
        500,
        collision: true,
      );

      expect(sizes.preferredWidth, 0);
      expect(sizes.preferredHeight, 500);
    });

    test('Draw multiline label', () {
      final chartCanvas = MockChartCanvas();
      final axisBounds = Rectangle<int>(0, 0, 1000, 1000);

      drawStrategy.drawLabel(
        chartCanvas,
        ticks.first,
        orientation: AxisOrientation.bottom,
        axisBounds: axisBounds,
        drawAreaBounds: null,
        collision: true,
      );

      // The y-coordinate should increase by the line's height + padding.
      final labelLine1 = chartCanvas.drawTextCalls[0].textElement;
      expect(labelLine1.text, 'This label');

      final labelLine2 = chartCanvas.drawTextCalls[1].textElement;
      expect(labelLine2.text, 'spans');

      final labelLine3 = chartCanvas.drawTextCalls[2].textElement;
      expect(labelLine3.text, 'multiple lines!!!');
    });

    test('Draw single line label', () {
      final chartCanvas = MockChartCanvas();
      final axisBounds = Rectangle<int>(0, 0, 1000, 1000);

      drawStrategy.drawLabel(
        chartCanvas,
        ticks[1],
        orientation: AxisOrientation.top,
        axisBounds: axisBounds,
        drawAreaBounds: null,
        collision: true,
      );

      final labelLine = chartCanvas.drawTextCalls.single.textElement;
      expect(labelLine.text, 'A');
    });
  });

  group('Adjust width of labels based on size', () {
    void setUpLabel(String text, {double? width}) {
      graphicsFactory.textElements[text] = FakeTextElement(
        text,
        TextDirection.ltr,
        width,
        15.0,
      );
    }

    late BaseTickDrawStrategyImpl drawStrategy;
    late List<Tick> ticks;

    setUp(() {
      ticks = [
        createTick(
          'This label is long',
          0.0,
          horizontalWidth: 50.0,
          verticalWidth: 15.0,
        ),
        createTick('Test', 0.0, horizontalWidth: 10.0, verticalWidth: 15.0),
      ];

      setUpLabel('This label is long', width: 50.0);
      setUpLabel('Test', width: 10.0);
    });

    test('Sets max width for vertical labels', () {
      drawStrategy = BaseTickDrawStrategyImpl(
        chartContext,
        graphicsFactory,
        labelOffsetFromTickPx: 0,
        labelOffsetFromAxisPx: 0,
      );

      drawStrategy.updateTickWidth(ticks, 25, 500, AxisOrientation.left);
      expect(ticks.first.textElement!.maxWidth, 25);
      expect(
        ticks.first.textElement!.maxWidthStrategy,
        MaxWidthStrategy.ellipsize,
      );
      expect(ticks.last.textElement!.maxWidth, 25);
      expect(
        ticks.last.textElement!.maxWidthStrategy,
        MaxWidthStrategy.ellipsize,
      );
    });

    test(
      'Sets max width for vertical labels that are parallel to the axis ',
      () {
        drawStrategy = BaseTickDrawStrategyImpl(
          chartContext,
          graphicsFactory,
          labelOffsetFromTickPx: 0,
          labelOffsetFromAxisPx: 0,
          labelRotation: 90,
        );

        drawStrategy.updateTickWidth(ticks, 25, 500, AxisOrientation.left);
        expect(ticks.first.textElement!.maxWidth, null);
        expect(ticks.first.textElement!.maxWidthStrategy, null);
        expect(ticks.last.textElement!.maxWidth, null);
        expect(ticks.last.textElement!.maxWidthStrategy, null);
      },
    );

    test('Sets max width for vertical labels that are angled', () {
      drawStrategy = BaseTickDrawStrategyImpl(
        chartContext,
        graphicsFactory,
        labelOffsetFromTickPx: 0,
        labelOffsetFromAxisPx: 0,
        labelRotation: 45,
      );

      drawStrategy.updateTickWidth(ticks, 25, 500, AxisOrientation.left);
      expect(ticks.first.textElement!.maxWidth, 35);
      expect(
        ticks.first.textElement!.maxWidthStrategy,
        MaxWidthStrategy.ellipsize,
      );
      expect(ticks.last.textElement!.maxWidth, 35);
      expect(
        ticks.last.textElement!.maxWidthStrategy,
        MaxWidthStrategy.ellipsize,
      );
    });

    test('Sets max width for horizontal labels', () {
      drawStrategy = BaseTickDrawStrategyImpl(
        chartContext,
        graphicsFactory,
        labelOffsetFromTickPx: 0,
        labelOffsetFromAxisPx: 0,
        // 90 degrees makes the labels directly perpendicular to the axis.
        labelRotation: 90,
      );

      drawStrategy.updateTickWidth(ticks, 500, 25, AxisOrientation.bottom);
      expect(ticks.first.textElement!.maxWidth, 25);
      expect(
        ticks.first.textElement!.maxWidthStrategy,
        MaxWidthStrategy.ellipsize,
      );
      expect(ticks.last.textElement!.maxWidth, 25);
      expect(
        ticks.last.textElement!.maxWidthStrategy,
        MaxWidthStrategy.ellipsize,
      );
    });

    test(
      'Sets max width for horizontal labels that are parallel to the axis',
      () {
        drawStrategy = BaseTickDrawStrategyImpl(
          chartContext,
          graphicsFactory,
          labelOffsetFromTickPx: 0,
          labelOffsetFromAxisPx: 0,
        );

        drawStrategy.updateTickWidth(ticks, 500, 25, AxisOrientation.bottom);
        expect(ticks.first.textElement!.maxWidth, null);
        expect(ticks.first.textElement!.maxWidthStrategy, null);
        expect(ticks.last.textElement!.maxWidth, null);
        expect(ticks.last.textElement!.maxWidthStrategy, null);
      },
    );

    test('Sets max width for horizontal labels that are angled', () {
      drawStrategy = BaseTickDrawStrategyImpl(
        chartContext,
        graphicsFactory,
        labelOffsetFromTickPx: 0,
        labelOffsetFromAxisPx: 0,
        labelRotation: 45,
      );

      drawStrategy.updateTickWidth(ticks, 500, 25, AxisOrientation.bottom);
      expect(ticks.first.textElement!.maxWidth, 35);
      expect(
        ticks.first.textElement!.maxWidthStrategy,
        MaxWidthStrategy.ellipsize,
      );
      expect(ticks.last.textElement!.maxWidth, 35);
      expect(
        ticks.last.textElement!.maxWidthStrategy,
        MaxWidthStrategy.ellipsize,
      );
    });
  });
}
