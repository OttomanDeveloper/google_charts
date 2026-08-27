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
import 'package:charts_common_maintained/src/chart/common/behavior/selection/select_nearest.dart';
import 'package:charts_common_maintained/src/chart/common/behavior/selection/selection_trigger.dart';
import 'package:charts_common_maintained/src/chart/common/datum_details.dart';
import 'package:charts_common_maintained/src/chart/common/processed_series.dart';
import 'package:charts_common_maintained/src/chart/common/series_datum.dart';
import 'package:charts_common_maintained/src/chart/common/selection_model/selection_model.dart';
import 'package:charts_common_maintained/src/common/gesture_listener.dart';
import 'package:charts_common_maintained/src/data/series.dart';

import 'package:mockito/mockito.dart';
import 'package:test/test.dart';

class MockChart extends Mock implements BaseChart<String> {
  MockChart(this.selectionModels);

  final Map<SelectionModelType, MutableSelectionModel<String>> selectionModels;
  GestureListener? lastListener;
  bool pointWithinRendererResult = false;
  List<DatumDetails<String>> nearestDetails = <DatumDetails<String>>[];
  List<MutableSeries<String>> currentSeries = <MutableSeries<String>>[];

  @override
  MutableSelectionModel<String> getSelectionModel(SelectionModelType type) =>
      selectionModels[type]!;

  @override
  bool pointWithinRenderer(Point<double> point) => pointWithinRendererResult;

  @override
  List<MutableSeries<String>> get currentSeriesList => currentSeries;

  @override
  List<DatumDetails<String>> getNearestDatumDetailPerSeries(
    Point<double> point,
    bool selectOverlappingPoints,
  ) => nearestDetails;

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

class MockSelectionModel extends Mock implements MutableSelectionModel<String> {
  int updateSelectionCallCount = 0;

  @override
  bool updateSelection(
    List<SeriesDatum<String>> datumSelection,
    List<ImmutableSeries<String>> seriesList, {
    bool notifyListeners = true,
  }) {
    updateSelectionCallCount += 1;
    final namedArguments = notifyListeners
        ? <Symbol, dynamic>{}
        : <Symbol, dynamic>{#notifyListeners: false};
    return super.noSuchMethod(
          Invocation.method(#updateSelection, [
            datumSelection,
            seriesList,
          ], namedArguments),
          returnValue: true,
          returnValueForMissingStub: true,
        )
        as bool;
  }
}

void main() {
  late MockChart _chart;
  late MockSelectionModel _hoverSelectionModel;
  late MockSelectionModel _clickSelectionModel;
  late List<String> _series1Data;
  late List<String> _series2Data;
  late MutableSeries<String> _series1;
  late MutableSeries<String> _series2;
  late DatumDetails<String> _details1;
  late DatumDetails<String> _details1Series2;
  late DatumDetails<String> _details2;
  late DatumDetails<String> _details3;

  SelectNearest<String> _makeBehavior(
    SelectionModelType selectionModelType,
    SelectionTrigger eventTrigger, {
    required bool selectClosestSeries,
    SelectionMode selectionMode = SelectionMode.expandToDomain,
    int? maximumDomainDistancePx,
  }) {
    SelectNearest<String> behavior = SelectNearest<String>(
      selectionModelType: selectionModelType,
      selectionMode: selectionMode,
      selectClosestSeries: selectClosestSeries,
      eventTrigger: eventTrigger,
      maximumDomainDistancePx: maximumDomainDistancePx,
    );

    behavior.attachTo(_chart);

    return behavior;
  }

  void _setupChart({
    required Point<double> forPoint,
    bool? isWithinRenderer,
    List<DatumDetails<String>>? respondWithDetails,
    List<MutableSeries<String>>? seriesList,
  }) {
    if (isWithinRenderer != null) {
      _chart.pointWithinRendererResult = isWithinRenderer;
    }

    if (respondWithDetails != null) {
      _chart.nearestDetails = respondWithDetails;
    }

    if (seriesList != null) {
      _chart.currentSeries = seriesList;
    }
  }

  setUp(() {
    _hoverSelectionModel = MockSelectionModel();
    _clickSelectionModel = MockSelectionModel();

    _chart = MockChart({
      SelectionModelType.info: _hoverSelectionModel,
      SelectionModelType.action: _clickSelectionModel,
    });

    _series1Data = ['myDomain1', 'myDomain2', 'myDomain3'];

    _series1 = MutableSeries<String>(
      Series(
        id: 'mySeries1',
        data: ['myDatum1', 'myDatum2', 'myDatum3'],
        domainFn: (_, int? i) => _series1Data[i!],
        measureFn: (_, _) => null,
      ),
    );

    _details1 = DatumDetails(
      datum: 'myDatum1',
      domain: 'myDomain1',
      series: _series1,
      domainDistance: 10.0,
      measureDistance: 20.0,
    );
    _details2 = DatumDetails(
      datum: 'myDatum2',
      domain: 'myDomain2',
      series: _series1,
      domainDistance: 10.0,
      measureDistance: 20.0,
    );
    _details3 = DatumDetails(
      datum: 'myDatum3',
      domain: 'myDomain3',
      series: _series1,
      domainDistance: 10.0,
      measureDistance: 20.0,
    );

    _series2Data = ['myDomain1'];

    _series2 = MutableSeries<String>(
      Series(
        id: 'mySeries2',
        data: ['myDatum1s2'],
        domainFn: (_, int? i) => _series2Data[i!],
        measureFn: (_, _) => null,
      ),
    );

    _details1Series2 = DatumDetails(
      datum: 'myDatum1s2',
      domain: 'myDomain1',
      series: _series2,
      domainDistance: 10.0,
      measureDistance: 20.0,
    );
  });

  tearDown(resetMockitoState);

  group('SelectNearest trigger handling', () {
    test('single series selects detail', () {
      // Setup chart matches point with single domain single series.
      _makeBehavior(
        SelectionModelType.info,
        SelectionTrigger.hover,
        selectClosestSeries: true,
      );
      Point<double> point = Point(100.0, 100.0);
      _setupChart(
        forPoint: point,
        isWithinRenderer: true,
        respondWithDetails: [_details1],
        seriesList: [_series1],
      );

      // Act
      _chart.lastListener!.onHover!(point);

      // Validate
      expect(
        _hoverSelectionModel.updateSelectionCallCount,
        greaterThanOrEqualTo(1),
      );

      // Shouldn't be listening to anything else.
      expect(_chart.lastListener!.onTap, isNull);
      expect(_chart.lastListener!.onDragStart, isNull);
    });

    test('can listen to tap', () {
      // Setup chart matches point with single domain single series.
      _makeBehavior(
        SelectionModelType.action,
        SelectionTrigger.tap,
        selectClosestSeries: true,
      );
      Point<double> point = Point(100.0, 100.0);
      _setupChart(
        forPoint: point,
        isWithinRenderer: true,
        respondWithDetails: [_details1],
        seriesList: [_series1],
      );

      // Act
      _chart.lastListener!.onTapTest(point);
      _chart.lastListener!.onTap!(point);

      // Validate
      expect(
        _clickSelectionModel.updateSelectionCallCount,
        greaterThanOrEqualTo(1),
      );
    });

    test('can listen to drag', () {
      // Setup chart matches point with single domain single series.
      _makeBehavior(
        SelectionModelType.info,
        SelectionTrigger.pressHold,
        selectClosestSeries: true,
      );

      Point<double> startPoint = Point(100.0, 100.0);
      _setupChart(
        forPoint: startPoint,
        isWithinRenderer: true,
        respondWithDetails: [_details1],
        seriesList: [_series1],
      );

      Point<double> updatePoint1 = Point(200.0, 100.0);
      _setupChart(
        forPoint: updatePoint1,
        isWithinRenderer: true,
        respondWithDetails: [_details1],
        seriesList: [_series1],
      );

      Point<double> updatePoint2 = Point(300.0, 100.0);
      _setupChart(
        forPoint: updatePoint2,
        isWithinRenderer: true,
        respondWithDetails: [_details2],
        seriesList: [_series1],
      );

      Point<double> endPoint = Point(400.0, 100.0);
      _setupChart(
        forPoint: endPoint,
        isWithinRenderer: true,
        respondWithDetails: [_details3],
        seriesList: [_series1],
      );

      // Act
      _chart.lastListener!.onTapTest(startPoint);
      _chart.lastListener!.onDragStart!(startPoint);
      _chart.lastListener!.onDragUpdate!(updatePoint1, 1.0);
      _chart.lastListener!.onDragUpdate!(updatePoint2, 1.0);
      _chart.lastListener!.onDragEnd!(endPoint, 1.0, 0.0);

      // Validate
      // details1 was tripped 2 times (startPoint & updatePoint1)
      expect(
        _hoverSelectionModel.updateSelectionCallCount,
        greaterThanOrEqualTo(1),
      );
      // details2 was tripped for updatePoint2
      expect(
        _hoverSelectionModel.updateSelectionCallCount,
        greaterThanOrEqualTo(1),
      );
      // dragEnd deselects even though we are over details3.
      expect(_hoverSelectionModel.updateSelectionCallCount, equals(4));
    });

    test('can listen to drag after long press', () {
      // Setup chart matches point with single domain single series.
      _makeBehavior(
        SelectionModelType.info,
        SelectionTrigger.longPressHold,
        selectClosestSeries: true,
      );

      Point<double> startPoint = Point(100.0, 100.0);
      _setupChart(
        forPoint: startPoint,
        isWithinRenderer: true,
        respondWithDetails: [_details1],
        seriesList: [_series1],
      );

      Point<double> updatePoint1 = Point(200.0, 100.0);
      _setupChart(
        forPoint: updatePoint1,
        isWithinRenderer: true,
        respondWithDetails: [_details2],
        seriesList: [_series1],
      );

      Point<double> endPoint = Point(400.0, 100.0);
      _setupChart(
        forPoint: endPoint,
        isWithinRenderer: true,
        respondWithDetails: [_details3],
        seriesList: [_series1],
      );

      // Act 1
      _chart.lastListener!.onTapTest(startPoint);

      // Act 2
      // verify no interaction yet.
      _chart.lastListener!.onLongPress!(startPoint);
      _chart.lastListener!.onDragStart!(startPoint);
      _chart.lastListener!.onDragUpdate!(updatePoint1, 1.0);
      _chart.lastListener!.onDragEnd!(endPoint, 1.0, 0.0);

      // Validate
      // details1 was tripped 2 times (longPress & dragStart)
      expect(
        _hoverSelectionModel.updateSelectionCallCount,
        greaterThanOrEqualTo(1),
      );
      expect(
        _hoverSelectionModel.updateSelectionCallCount,
        greaterThanOrEqualTo(1),
      );
      // dragEnd deselects even though we are over details3.
      expect(_hoverSelectionModel.updateSelectionCallCount, equals(4));
    });

    test('no trigger before long press', () {
      // Setup chart matches point with single domain single series.
      _makeBehavior(
        SelectionModelType.info,
        SelectionTrigger.longPressHold,
        selectClosestSeries: true,
      );

      Point<double> startPoint = Point(100.0, 100.0);
      _setupChart(
        forPoint: startPoint,
        isWithinRenderer: true,
        respondWithDetails: [_details1],
        seriesList: [_series1],
      );

      Point<double> updatePoint1 = Point(200.0, 100.0);
      _setupChart(
        forPoint: updatePoint1,
        isWithinRenderer: true,
        respondWithDetails: [_details2],
        seriesList: [_series1],
      );

      Point<double> endPoint = Point(400.0, 100.0);
      _setupChart(
        forPoint: endPoint,
        isWithinRenderer: true,
        respondWithDetails: [_details3],
        seriesList: [_series1],
      );

      // Act
      _chart.lastListener!.onTapTest(startPoint);
      _chart.lastListener!.onDragStart!(startPoint);
      _chart.lastListener!.onDragUpdate!(updatePoint1, 1.0);
      _chart.lastListener!.onDragEnd!(endPoint, 1.0, 0.0);

      // Validate
      // No interaction, didn't long press first.
    });
  });

  group('Details', () {
    test('expands to domain and includes closest series', () {
      // Setup chart matches point with single domain single series.
      _makeBehavior(
        SelectionModelType.info,
        SelectionTrigger.hover,
        selectClosestSeries: true,
      );
      Point<double> point = Point(100.0, 100.0);
      _setupChart(
        forPoint: point,
        isWithinRenderer: true,
        respondWithDetails: [_details1, _details1Series2],
        seriesList: [_series1, _series2],
      );

      // Act
      _chart.lastListener!.onHover!(point);

      // Validate
      expect(
        _hoverSelectionModel.updateSelectionCallCount,
        greaterThanOrEqualTo(1),
      );
    });

    test('does not expand to domain', () {
      // Setup chart matches point with single domain single series.
      _makeBehavior(
        SelectionModelType.info,
        SelectionTrigger.hover,
        selectionMode: SelectionMode.single,
        selectClosestSeries: true,
      );
      Point<double> point = Point(100.0, 100.0);
      _setupChart(
        forPoint: point,
        isWithinRenderer: true,
        respondWithDetails: [_details1, _details1Series2],
        seriesList: [_series1, _series2],
      );

      // Act
      _chart.lastListener!.onHover!(point);

      // Validate
      expect(
        _hoverSelectionModel.updateSelectionCallCount,
        greaterThanOrEqualTo(1),
      );
    });

    test('does not include closest series', () {
      // Setup chart matches point with single domain single series.
      _makeBehavior(
        SelectionModelType.info,
        SelectionTrigger.hover,
        selectClosestSeries: false,
      );
      Point<double> point = Point(100.0, 100.0);
      _setupChart(
        forPoint: point,
        isWithinRenderer: true,
        respondWithDetails: [_details1, _details1Series2],
        seriesList: [_series1, _series2],
      );

      // Act
      _chart.lastListener!.onHover!(point);

      // Validate
      expect(
        _hoverSelectionModel.updateSelectionCallCount,
        greaterThanOrEqualTo(1),
      );
    });

    test('does not include overlay series', () {
      // Setup chart with an overlay series.
      _series2.overlaySeries = true;

      _makeBehavior(
        SelectionModelType.info,
        SelectionTrigger.hover,
        selectClosestSeries: true,
      );
      Point<double> point = Point(100.0, 100.0);
      _setupChart(
        forPoint: point,
        isWithinRenderer: true,
        respondWithDetails: [_details1, _details1Series2],
        seriesList: [_series1, _series2],
      );

      // Act
      _chart.lastListener!.onHover!(point);

      // Validate
      expect(
        _hoverSelectionModel.updateSelectionCallCount,
        greaterThanOrEqualTo(1),
      );
    });

    test('selection does not exceed maximumDomainDistancePx', () {
      // Setup chart matches point with single domain single series.
      _makeBehavior(
        SelectionModelType.info,
        SelectionTrigger.hover,
        selectClosestSeries: true,
        maximumDomainDistancePx: 1,
      );
      Point<double> point = Point(100.0, 100.0);
      _setupChart(
        forPoint: point,
        isWithinRenderer: true,
        respondWithDetails: [_details1, _details1Series2],
        seriesList: [_series1, _series2],
      );

      // Act
      _chart.lastListener!.onHover!(point);

      // Validate
      expect(_hoverSelectionModel.updateSelectionCallCount, equals(1));
    });

    test('adds overlapping points from same series if there are any', () {
      // Setup chart matches point with single domain single series.
      _makeBehavior(
        SelectionModelType.info,
        SelectionTrigger.hover,
        selectionMode: SelectionMode.selectOverlapping,
        selectClosestSeries: true,
      );
      Point<double> point = Point(100.0, 100.0);
      final series = MutableSeries<String>(
        Series(
          id: 'overlappingSeries',
          data: ['datum1', 'datum2'],
          domainFn: (_, int? i) => _series1Data[i!],
          measureFn: (_, _) => null,
        ),
      );
      // Two points covering the mouse position.
      final details1 = DatumDetails(
        datum: 'datum1',
        domain: 'myDomain1',
        series: series,
        radiusPx: 10,
        domainDistance: 4,
        relativeDistance: 5,
      );
      final details2 = DatumDetails(
        datum: 'datum2',
        domain: 'myDomain1',
        series: series,
        radiusPx: 10,
        domainDistance: 7,
        relativeDistance: 9,
      );
      _setupChart(
        forPoint: point,
        isWithinRenderer: true,
        respondWithDetails: [details1, details2],
        seriesList: [series],
      );

      // Act
      _chart.lastListener!.onHover!(point);

      // Validate
      expect(
        _hoverSelectionModel.updateSelectionCallCount,
        greaterThanOrEqualTo(1),
      );
    });
  });

  group('Cleanup', () {
    test('detach removes listener', () {
      // Setup
      SelectNearest behavior = _makeBehavior(
        SelectionModelType.info,
        SelectionTrigger.hover,
        selectClosestSeries: true,
      );
      Point<double> point = Point(100.0, 100.0);
      _setupChart(
        forPoint: point,
        isWithinRenderer: true,
        respondWithDetails: [_details1],
        seriesList: [_series1],
      );
      expect(_chart.lastListener, isNotNull);

      // Act
      behavior.removeFrom(_chart);

      // Validate
      expect(_chart.lastListener, isNull);
    });
  });
}
