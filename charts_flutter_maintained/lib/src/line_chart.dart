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

import 'package:charts_common_maintained/charts_common_maintained.dart'
    as common
    show LineChart, LineRendererConfig;
import 'behaviors/line_point_highlighter.dart' show LinePointHighlighter;
import 'behaviors/chart_behavior.dart' show ChartBehavior;
import 'base_chart_state.dart' show BaseChartState;
import 'cartesian_chart.dart' show CartesianChart;

class LineChart extends CartesianChart<num> {
  const LineChart(
    super.seriesList, {
    super.key,
    super.animate,
    super.animationDuration,
    super.domainAxis,
    super.primaryMeasureAxis,
    super.secondaryMeasureAxis,
    super.disjointMeasureAxes,
    common.LineRendererConfig<num>? super.defaultRenderer,
    super.customSeriesRenderers,
    super.behaviors,
    super.selectionModels,
    super.rtlSpec,
    super.layoutConfig,
    super.defaultInteractions,
    super.flipVerticalAxis,
    super.userManagedState,
  });

  @override
  common.LineChart createCommonChart(BaseChartState chartState) {
    // Optionally create primary and secondary measure axes if the chart was
    // configured with them. If no axes were configured, then the chart will
    // use its default types (usually a numeric axis).
    return common.LineChart(
      layoutConfig: layoutConfig?.commonLayoutConfig,
      primaryMeasureAxis: primaryMeasureAxis?.createAxis(),
      secondaryMeasureAxis: secondaryMeasureAxis?.createAxis(),
      disjointMeasureAxes: createDisjointMeasureAxes(),
    );
  }

  @override
  void addDefaultInteractions(List<ChartBehavior> behaviors) {
    super.addDefaultInteractions(behaviors);

    behaviors.add(LinePointHighlighter<num>());
  }
}
