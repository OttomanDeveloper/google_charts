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

import 'package:charts_common_maintained/src/chart/cartesian/axis/static_tick_provider.dart';
import 'package:charts_common_maintained/src/chart/cartesian/axis/linear/linear_scale.dart';
import 'package:charts_common_maintained/src/chart/cartesian/axis/draw_strategy/base_tick_draw_strategy.dart';
import 'package:charts_common_maintained/src/common/graphics_factory.dart';
import 'package:charts_common_maintained/src/common/text_element.dart';
import 'package:charts_common_maintained/src/chart/common/chart_context.dart';
import 'package:charts_common_maintained/src/chart/cartesian/axis/scale.dart';
import 'package:charts_common_maintained/src/chart/cartesian/axis/spec/tick_spec.dart';
import 'package:charts_common_maintained/src/chart/cartesian/axis/tick_formatter.dart';
import 'package:mockito/mockito.dart';
import 'package:test/test.dart';

class MockChartContext extends Mock implements ChartContext {}

class MockGraphicsFactory extends Mock implements GraphicsFactory {}

class MockTextElement extends Mock implements TextElement {}

class MockNumericTickFormatter extends Mock implements TickFormatter<num> {}

class FakeNumericTickFormatter implements TickFormatter<num> {
  int calledTimes = 0;

  @override
  List<String> format(List<num> tickValues, Map<num, String> cache,
      {num stepSize}) {
    calledTimes += 1;

    return tickValues.map((value) => value.toString()).toList();
  }
}

class MockDrawStrategy<D> extends Mock implements BaseTickDrawStrategy<D> {}

void main() {
  ChartContext context;
  GraphicsFactory graphicsFactory;
  TickFormatter<num> formatter;
  BaseTickDrawStrategy<num> drawStrategy;
  LinearScale scale;

  setUp(() {
    context = MockChartContext();
    graphicsFactory = MockGraphicsFactory();
    formatter = MockNumericTickFormatter();
    drawStrategy = MockDrawStrategy<num>();
    scale = LinearScale()..range = ScaleOutputExtent(0, 300);

    when(graphicsFactory.createTextElement(any)).thenReturn(MockTextElement());
  });

  group('scale is extended with static tick values', () {
    test('values extend existing domain values', () {
      final tickProvider = StaticTickProvider<num>([
        TickSpec<num>(50, label: '50'),
        TickSpec<num>(75, label: '75'),
        TickSpec<num>(100, label: '100'),
      ]);

      scale.addDomain(60);
      scale.addDomain(80);

      expect(scale.dataExtent.min, equals(60));
      expect(scale.dataExtent.max, equals(80));

      tickProvider.getTicks(
          context: context,
          graphicsFactory: graphicsFactory,
          scale: scale,
          formatter: formatter,
          formatterValueCache: <num, String>{},
          tickDrawStrategy: drawStrategy,
          orientation: null);

      expect(scale.dataExtent.min, equals(50));
      expect(scale.dataExtent.max, equals(100));
    });

    test('values within data extent', () {
      final tickProvider = StaticTickProvider<num>([
        TickSpec<num>(50, label: '50'),
        TickSpec<num>(75, label: '75'),
        TickSpec<num>(100, label: '100'),
      ]);

      scale.addDomain(0);
      scale.addDomain(150);

      expect(scale.dataExtent.min, equals(0));
      expect(scale.dataExtent.max, equals(150));

      tickProvider.getTicks(
          context: context,
          graphicsFactory: graphicsFactory,
          scale: scale,
          formatter: formatter,
          formatterValueCache: <num, String>{},
          tickDrawStrategy: drawStrategy,
          orientation: null);

      expect(scale.dataExtent.min, equals(0));
      expect(scale.dataExtent.max, equals(150));
    });
  });

  group('formatter', () {
    test('is not called when all ticks have labels', () {
      final tickProvider = StaticTickProvider<num>([
        TickSpec<num>(50, label: '50'),
        TickSpec<num>(75, label: '75'),
        TickSpec<num>(100, label: '100'),
      ]);

      final fakeFormatter = FakeNumericTickFormatter();

      tickProvider.getTicks(
          context: context,
          graphicsFactory: graphicsFactory,
          scale: scale,
          formatter: fakeFormatter,
          formatterValueCache: <num, String>{},
          tickDrawStrategy: drawStrategy,
          orientation: null);

      expect(fakeFormatter.calledTimes, equals(0));
    });

    test('is called when one ticks does not have label', () {
      final tickProvider = StaticTickProvider<num>([
        TickSpec<num>(50, label: '50'),
        TickSpec<num>(75),
        TickSpec<num>(100, label: '100'),
      ]);

      final fakeFormatter = FakeNumericTickFormatter();

      tickProvider.getTicks(
          context: context,
          graphicsFactory: graphicsFactory,
          scale: scale,
          formatter: fakeFormatter,
          formatterValueCache: <num, String>{},
          tickDrawStrategy: drawStrategy,
          orientation: null);

      expect(fakeFormatter.calledTimes, equals(1));
    });

    test('is called when all ticks do not have labels', () {
      final tickProvider = StaticTickProvider<num>([
        TickSpec<num>(50),
        TickSpec<num>(75),
        TickSpec<num>(100),
      ]);

      final fakeFormatter = FakeNumericTickFormatter();

      tickProvider.getTicks(
          context: context,
          graphicsFactory: graphicsFactory,
          scale: scale,
          formatter: fakeFormatter,
          formatterValueCache: <num, String>{},
          tickDrawStrategy: drawStrategy,
          orientation: null);

      expect(fakeFormatter.calledTimes, equals(1));
    });
  });

  group('with tick increment', () {
    test('returns every Nth tick', () {
      final tickProvider = StaticTickProvider<num>([
        TickSpec<num>(50, label: '50'),
        TickSpec<num>(75, label: '75'),
        TickSpec<num>(100, label: '100'),
        TickSpec<num>(125, label: '125'),
        TickSpec<num>(150, label: '150'),
      ], tickIncrement: 2);

      final ticks = tickProvider.getTicks(
          context: context,
          graphicsFactory: graphicsFactory,
          scale: scale,
          formatter: formatter,
          formatterValueCache: <num, String>{},
          tickDrawStrategy: drawStrategy,
          orientation: null);

      expect(ticks.map((tick) => tick.value).toList(), [50, 100, 150]);
    });
  });
}
