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
    show ArcRendererConfig, PieChart;
import 'base_chart.dart' show BaseChart;
import 'base_chart_state.dart' show BaseChartState;

class PieChart<D> extends BaseChart<D> {
  const PieChart(
    super.seriesList, {
    super.key,
    super.animate,
    super.animationDuration,
    common.ArcRendererConfig<D>? super.defaultRenderer,
    super.behaviors,
    super.selectionModels,
    super.rtlSpec,
    super.layoutConfig,
    super.defaultInteractions,
  });

  @override
  common.PieChart<D> createCommonChart(BaseChartState chartState) =>
      common.PieChart<D>(layoutConfig: layoutConfig?.commonLayoutConfig);
}
