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

import 'dart:collection' show LinkedHashMap;
import 'package:meta/meta.dart' show immutable, protected;

import 'package:charts_common_maintained/charts_common_maintained.dart'
    as common
    show AxisSpec, BaseChart, CartesianChart, NumericAxis, NumericAxisSpec;
import 'base_chart_state.dart' show BaseChartState;
import 'base_chart.dart' show BaseChart;

@immutable
abstract class CartesianChart<D> extends BaseChart<D> {
  final common.AxisSpec? domainAxis;
  final common.NumericAxisSpec? primaryMeasureAxis;
  final common.NumericAxisSpec? secondaryMeasureAxis;
  final LinkedHashMap<String, common.NumericAxisSpec>? disjointMeasureAxes;
  final bool? flipVerticalAxis;

  const CartesianChart(
    super.seriesList, {
    super.key,
    super.animate,
    super.animationDuration,
    this.domainAxis,
    this.primaryMeasureAxis,
    this.secondaryMeasureAxis,
    this.disjointMeasureAxes,
    super.defaultRenderer,
    super.customSeriesRenderers,
    super.behaviors,
    super.selectionModels,
    super.rtlSpec,
    super.defaultInteractions,
    super.layoutConfig,
    super.userManagedState,
    this.flipVerticalAxis,
  });

  @override
  void updateCommonChart(
    common.BaseChart<D> baseChart,
    BaseChart<D>? oldWidget,
    BaseChartState<D> chartState,
  ) {
    super.updateCommonChart(baseChart, oldWidget, chartState);

    final prev = oldWidget as CartesianChart?;
    final chart = baseChart as common.CartesianChart;

    if (flipVerticalAxis != null) {
      chart.flipVerticalAxisOutput = flipVerticalAxis!;
    }

    if (domainAxis != null && domainAxis != prev?.domainAxis) {
      chart.domainAxisSpec = domainAxis!;
      chartState.markChartDirty();
    }

    if (primaryMeasureAxis != prev?.primaryMeasureAxis) {
      chart.primaryMeasureAxisSpec = primaryMeasureAxis;
      chartState.markChartDirty();
    }

    if (secondaryMeasureAxis != prev?.secondaryMeasureAxis) {
      chart.secondaryMeasureAxisSpec = secondaryMeasureAxis;
      chartState.markChartDirty();
    }

    if (disjointMeasureAxes != prev?.disjointMeasureAxes) {
      chart.disjointMeasureAxisSpecs = disjointMeasureAxes;
      chartState.markChartDirty();
    }
  }

  @protected
  LinkedHashMap<String, common.NumericAxis>? createDisjointMeasureAxes() {
    if (disjointMeasureAxes != null) {
      final disjointAxes = <String, common.NumericAxis>{};

      disjointMeasureAxes!.forEach((
        String axisId,
        common.NumericAxisSpec axisSpec,
      ) {
        disjointAxes[axisId] = axisSpec.createAxis();
      });

      return LinkedHashMap<String, common.NumericAxis>.from(disjointAxes);
    } else {
      return null;
    }
  }
}
