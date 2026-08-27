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

import 'package:charts_common_maintained/src/chart/common/base_chart.dart';
import 'package:charts_common_maintained/src/chart/common/behavior/selection/lock_selection.dart';
import 'package:charts_common_maintained/src/chart/common/selection_model/selection_model.dart';
import 'package:charts_common_maintained/src/common/gesture_listener.dart';

import 'package:mockito/mockito.dart';
import 'package:test/test.dart';

class MockChart extends Mock implements BaseChart {
  MockChart(this.selectionModels);

  final Map<SelectionModelType, MutableSelectionModel> selectionModels;
  bool pointWithinRendererResult = false;
  GestureListener? lastListener;

  @override
  MutableSelectionModel getSelectionModel(SelectionModelType type) =>
      selectionModels[type]!;

  @override
  bool pointWithinRenderer(Point<double> point) => pointWithinRendererResult;

  @override
  GestureListener addGestureListener(GestureListener listener) {
    lastListener = listener;
    return listener;
  }

  @override
  void removeGestureListener(GestureListener listener) {
    expect(listener, equals(lastListener));
    lastListener = null;
  }
}

class MockSelectionModel extends Mock implements MutableSelectionModel {
  @override
  bool locked = false;

  @override
  bool hasAnySelection = false;
  int clearSelectionCalls = 0;

  @override
  bool clearSelection({bool notifyListeners = true}) {
    clearSelectionCalls++;
    return true;
  }
}

void main() {
  late MockChart _chart;
  late MockSelectionModel _hoverSelectionModel;
  late MockSelectionModel _clickSelectionModel;

  LockSelection _makeLockSelectionBehavior(
    SelectionModelType selectionModelType,
  ) {
    LockSelection behavior = LockSelection(
      selectionModelType: selectionModelType,
    );

    behavior.attachTo(_chart);

    return behavior;
  }

  void _setupChart({required Point<double> forPoint, bool? isWithinRenderer}) {
    if (isWithinRenderer != null) {
      _chart.pointWithinRendererResult = isWithinRenderer;
    }
  }

  setUp(() {
    _hoverSelectionModel = MockSelectionModel();
    _clickSelectionModel = MockSelectionModel();

    _chart = MockChart({
      SelectionModelType.info: _hoverSelectionModel,
      SelectionModelType.action: _clickSelectionModel,
    });
  });

  group('LockSelection trigger handling', () {
    test('can lock model with a selection', () {
      // Setup chart matches point with single domain single series.
      _makeLockSelectionBehavior(SelectionModelType.info);
      Point<double> point = Point(100.0, 100.0);
      _setupChart(forPoint: point, isWithinRenderer: true);

      _hoverSelectionModel.hasAnySelection = true;

      // Act
      _chart.lastListener!.onTapTest(point);
      _chart.lastListener!.onTap!(point);

      // Validate

      expect(_hoverSelectionModel.locked, equals(true));
      verifyNoMoreInteractions(_hoverSelectionModel);
      verifyNoMoreInteractions(_clickSelectionModel);
    });

    test('can lock and unlock model', () {
      // Setup chart matches point with single domain single series.
      _makeLockSelectionBehavior(SelectionModelType.info);
      Point<double> point = Point(100.0, 100.0);
      _setupChart(forPoint: point, isWithinRenderer: true);

      _hoverSelectionModel.hasAnySelection = true;

      // Act
      _chart.lastListener!.onTapTest(point);
      _chart.lastListener!.onTap!(point);

      // Validate

      expect(_hoverSelectionModel.locked, equals(true));

      // Act
      _chart.lastListener!.onTapTest(point);
      _chart.lastListener!.onTap!(point);

      // Validate
      expect(_hoverSelectionModel.clearSelectionCalls, equals(1));
      expect(_hoverSelectionModel.locked, equals(false));
      verifyNoMoreInteractions(_hoverSelectionModel);
      verifyNoMoreInteractions(_clickSelectionModel);
    });

    test('does not lock model with empty selection', () {
      // Setup chart matches point with single domain single series.
      _makeLockSelectionBehavior(SelectionModelType.info);
      Point<double> point = Point(100.0, 100.0);
      _setupChart(forPoint: point, isWithinRenderer: true);

      _hoverSelectionModel.hasAnySelection = false;

      // Act
      _chart.lastListener!.onTapTest(point);
      _chart.lastListener!.onTap!(point);

      // Validate

      expect(_hoverSelectionModel.locked, equals(false));
      verifyNoMoreInteractions(_hoverSelectionModel);
      verifyNoMoreInteractions(_clickSelectionModel);
    });
  });

  group('Cleanup', () {
    test('detach removes listener', () {
      // Setup
      final behavior = _makeLockSelectionBehavior(SelectionModelType.info);
      Point<double> point = Point(100.0, 100.0);
      _setupChart(forPoint: point, isWithinRenderer: true);
      expect(_chart.lastListener, isNotNull);

      // Act
      behavior.removeFrom(_chart);

      // Validate
      expect(_chart.lastListener, isNull);
    });
  });
}
