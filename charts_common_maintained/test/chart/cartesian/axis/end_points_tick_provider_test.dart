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

import 'package:charts_common_maintained/src/chart/cartesian/axis/axis.dart';
import 'package:charts_common_maintained/src/chart/cartesian/axis/draw_strategy/base_tick_draw_strategy.dart';
import 'package:charts_common_maintained/src/common/graphics_factory.dart';
import 'package:charts_common_maintained/src/common/line_style.dart';
import 'package:charts_common_maintained/src/common/text_style.dart';
import 'package:charts_common_maintained/src/common/text_element.dart';
import 'package:charts_common_maintained/src/chart/common/chart_canvas.dart';
import 'package:charts_common_maintained/src/chart/common/chart_context.dart';
import 'package:charts_common_maintained/src/chart/cartesian/axis/collision_report.dart';
import 'package:charts_common_maintained/src/chart/cartesian/axis/end_points_tick_provider.dart';
import 'package:charts_common_maintained/src/chart/cartesian/axis/numeric_scale.dart';
import 'package:charts_common_maintained/src/chart/cartesian/axis/simple_ordinal_scale.dart';
import 'package:charts_common_maintained/src/chart/cartesian/axis/tick.dart';
import 'package:charts_common_maintained/src/chart/cartesian/axis/tick_formatter.dart';
import 'package:charts_common_maintained/src/chart/cartesian/axis/numeric_extents.dart';
import 'package:charts_common_maintained/src/chart/cartesian/axis/time/date_time_extents.dart';
import 'package:charts_common_maintained/src/chart/cartesian/axis/time/date_time_scale.dart';
import 'package:charts_common_maintained/src/chart/cartesian/axis/time/date_time_tick_formatter.dart';
import 'package:mockito/mockito.dart';
import 'package:test/test.dart';

import 'time/simple_date_time_factory.dart' show SimpleDateTimeFactory;

class MockDateTimeScale extends Mock implements DateTimeScale {
  DateTimeExtents? viewportDomainValue;
  double domainStepSizeValue = double.infinity;

  @override
  DateTimeExtents get viewportDomain => viewportDomainValue!;

  @override
  int get rangeWidth => 1000;

  @override
  double get domainStepSize => domainStepSizeValue;

  @override
  num operator [](DateTime domainValue) => 0;
}

class MockNumericScale extends Mock implements NumericScale {
  NumericExtents? viewportDomainValue;
  double domainStepSizeValue = double.infinity;

  @override
  NumericExtents get viewportDomain => viewportDomainValue!;

  @override
  int get rangeWidth => 1000;

  @override
  double get domainStepSize => domainStepSizeValue;
}

class MockOrdinalScale extends Mock implements SimpleOrdinalScale {}

/// A fake draw strategy that reports collision and alternate ticks
///
/// Reports collision when the tick count is greater than or equal to
/// [collidesAfterTickCount].
///
/// Reports alternate rendering after tick count is greater than or equal to
/// [alternateRenderingAfterTickCount].
class FakeDrawStrategy<D> extends BaseTickDrawStrategy<D> {
  final int collidesAfterTickCount;
  final int alternateRenderingAfterTickCount;

  FakeDrawStrategy(
    this.collidesAfterTickCount,
    this.alternateRenderingAfterTickCount,
  ) : super(MockChartContext(), FakeGraphicsFactory());

  @override
  CollisionReport<D> collides(
    List<Tick<D>>? ticks,
    AxisOrientation? orientation,
  ) {
    final tickList = ticks ?? <Tick<D>>[];
    final ticksCollide = tickList.length >= collidesAfterTickCount;
    final alternateTicksUsed =
        tickList.length >= alternateRenderingAfterTickCount;

    return CollisionReport(
      ticksCollide: ticksCollide,
      ticks: tickList,
      alternateTicksUsed: alternateTicksUsed,
    );
  }

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
}

/// A fake [GraphicsFactory] that returns [MockTextStyle] and [MockTextElement].
class FakeGraphicsFactory extends GraphicsFactory {
  @override
  TextStyle createTextPaint() => MockTextStyle();

  @override
  TextElement createTextElement(String text) => MockTextElement();

  @override
  LineStyle createLinePaint() => MockLinePaint();
}

class MockTextStyle extends Mock implements TextStyle {}

class MockTextElement extends Mock implements TextElement {}

class MockLinePaint extends Mock implements LineStyle {}

class MockChartContext extends Mock implements ChartContext {
  @override
  bool get chartContainerIsRtl => false;

  @override
  bool get isRtl => false;
}

void main() {
  const dateTimeFactory = SimpleDateTimeFactory();
  late FakeGraphicsFactory graphicsFactory;
  EndPointsTickProvider tickProvider;
  late ChartContext context;

  setUp(() {
    graphicsFactory = FakeGraphicsFactory();
    context = MockChartContext();
  });

  test('dateTime_choosesEndPointTicks', () {
    final formatter = DateTimeTickFormatter(dateTimeFactory);
    final scale = MockDateTimeScale();
    tickProvider = EndPointsTickProvider<DateTime>();

    final drawStrategy = FakeDrawStrategy<DateTime>(10, 10);
    scale.viewportDomainValue = DateTimeExtents(
      start: DateTime(2018, 8, 1),
      end: DateTime(2018, 8, 11),
    );

    scale.domainStepSizeValue = 1000.0;

    final ticks = tickProvider.getTicks(
      context: context,
      graphicsFactory: graphicsFactory,
      scale: scale,
      formatter: formatter,
      formatterValueCache: <DateTime, String>{},
      tickDrawStrategy: drawStrategy,
      orientation: null,
    );

    expect(ticks, hasLength(2));
    expect(ticks[0].value, equals(DateTime(2018, 8, 1)));
    expect(ticks[1].value, equals(DateTime(2018, 8, 11)));
  });

  test('numeric_choosesEndPointTicks', () {
    final formatter = NumericTickFormatter();
    final scale = MockNumericScale();
    tickProvider = EndPointsTickProvider<num>();

    final drawStrategy = FakeDrawStrategy<num>(10, 10);
    scale.viewportDomainValue = NumericExtents(10.0, 70.0);

    scale.domainStepSizeValue = 1000.0;

    final ticks = tickProvider.getTicks(
      context: context,
      graphicsFactory: graphicsFactory,
      scale: scale,
      formatter: formatter,
      formatterValueCache: <num, String>{},
      tickDrawStrategy: drawStrategy,
      orientation: null,
    );

    expect(ticks, hasLength(2));
    expect(ticks[0].value, equals(10));
    expect(ticks[1].value, equals(70));
  });

  test('ordinal_choosesEndPointTicks', () {
    final formatter = OrdinalTickFormatter();
    final scale = SimpleOrdinalScale();
    scale.addDomain('A');
    scale.addDomain('B');
    scale.addDomain('C');
    scale.addDomain('D');
    tickProvider = EndPointsTickProvider<String>();

    final drawStrategy = FakeDrawStrategy<String>(10, 10);

    final ticks = tickProvider.getTicks(
      context: context,
      graphicsFactory: graphicsFactory,
      scale: scale,
      formatter: formatter,
      formatterValueCache: <String, String>{},
      tickDrawStrategy: drawStrategy,
      orientation: null,
    );

    expect(ticks, hasLength(2));
    expect(ticks[0].value, equals('A'));
    expect(ticks[1].value, equals('D'));
  });

  test('dateTime_emptySeriesChoosesNoTicks', () {
    final formatter = DateTimeTickFormatter(dateTimeFactory);
    final scale = MockDateTimeScale();
    tickProvider = EndPointsTickProvider<DateTime>();

    final drawStrategy = FakeDrawStrategy<DateTime>(10, 10);
    scale.viewportDomainValue = DateTimeExtents(
      start: DateTime(2018, 8, 1),
      end: DateTime(2018, 8, 11),
    );

    // An un-configured axis has no domain step size, and its scale defaults to
    // infinity.

    final ticks = tickProvider.getTicks(
      context: context,
      graphicsFactory: graphicsFactory,
      scale: scale,
      formatter: formatter,
      formatterValueCache: <DateTime, String>{},
      tickDrawStrategy: drawStrategy,
      orientation: null,
    );

    expect(ticks, hasLength(0));
  });

  test('numeric_emptySeriesChoosesNoTicks', () {
    final formatter = NumericTickFormatter();
    final scale = MockNumericScale();
    tickProvider = EndPointsTickProvider<num>();

    final drawStrategy = FakeDrawStrategy<num>(10, 10);
    scale.viewportDomainValue = NumericExtents(10.0, 70.0);

    // An un-configured axis has no domain step size, and its scale defaults to
    // infinity.

    final ticks = tickProvider.getTicks(
      context: context,
      graphicsFactory: graphicsFactory,
      scale: scale,
      formatter: formatter,
      formatterValueCache: <num, String>{},
      tickDrawStrategy: drawStrategy,
      orientation: null,
    );

    expect(ticks, hasLength(0));
  });
}
