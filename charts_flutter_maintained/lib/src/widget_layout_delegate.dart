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

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:charts_common_maintained/charts_common_maintained.dart'
    as common show BehaviorPosition, InsideJustification, OutsideJustification;

import 'behaviors/chart_behavior.dart' show BuildableBehavior;

/// Layout delegate that layout chart widget with [BuildableBehavior] widgets.
class WidgetLayoutDelegate extends MultiChildLayoutDelegate {
  /// ID of the common chart widget.
  final String chartID;

  /// Directionality of the widget.
  final isRTL;

  /// ID and [BuildableBehavior] of the widgets for calculating offset.
  final Map<String, BuildableBehavior> idAndBehavior;

  WidgetLayoutDelegate(this.chartID, this.idAndBehavior, this.isRTL);

  @override
  void performLayout(Size size) {
    // TODO: Change this to a layout manager that supports more
    // than one buildable behavior that changes chart size. Remove assert when
    // this is possible.
    assert(idAndBehavior.keys.isEmpty || idAndBehavior.keys.length == 1);

    // Size available for the chart widget.
    var availableWidth = size.width;
    var availableHeight = size.height;
    var chartOffset = Offset.zero;

    // Measure the first buildable behavior.
    final behaviorID =
        idAndBehavior.keys.isNotEmpty ? idAndBehavior.keys.first : null;
    var behaviorSize = Size.zero;
    if (behaviorID != null) {
      if (hasChild(behaviorID)) {
        final leftPosition =
            isRTL ? common.BehaviorPosition.end : common.BehaviorPosition.start;
        final rightPosition =
            isRTL ? common.BehaviorPosition.start : common.BehaviorPosition.end;
        final behaviorPosition = idAndBehavior[behaviorID]!.position;

        behaviorSize = layoutChild(behaviorID, BoxConstraints.loose(size));
        if (behaviorPosition == common.BehaviorPosition.top) {
          chartOffset = Offset(0.0, behaviorSize.height);
          availableHeight -= behaviorSize.height;
        } else if (behaviorPosition == common.BehaviorPosition.bottom) {
          availableHeight -= behaviorSize.height;
        } else if (behaviorPosition == leftPosition) {
          chartOffset = Offset(behaviorSize.width, 0.0);
          availableWidth -= behaviorSize.width;
        } else if (behaviorPosition == rightPosition) {
          availableWidth -= behaviorSize.width;
        }
      }
    }

    // Layout chart.
    final chartSize = Size(availableWidth, availableHeight);
    if (hasChild(chartID)) {
      layoutChild(chartID, BoxConstraints.tight(chartSize));
      positionChild(chartID, chartOffset);
    }

    // Position buildable behavior.
    if (behaviorID != null) {
      // TODO: Unable to relayout with new smaller width.
      // In the delegate, all children are required to have layout called
      // exactly once.
      final behaviorOffset = _getBehaviorOffset(idAndBehavior[behaviorID]!,
          behaviorSize: behaviorSize, chartSize: chartSize, isRTL: isRTL);

      positionChild(behaviorID, behaviorOffset);
    }
  }

  @override
  bool shouldRelayout(MultiChildLayoutDelegate oldDelegate) {
    // TODO: Deep equality check because the instance will not be
    // the same on each build, even if the buildable behavior has not changed.
    return idAndBehavior != (oldDelegate as WidgetLayoutDelegate).idAndBehavior;
  }

  // Calculate buildable behavior's offset.
  Offset _getBehaviorOffset(BuildableBehavior behavior,
      {required Size behaviorSize,
      required Size chartSize,
      required bool isRTL}) {
    late Offset behaviorOffset;

    final behaviorPosition = behavior.position;
    final outsideJustification = behavior.outsideJustification;
    final insideJustification = behavior.insideJustification;

    if (behaviorPosition == common.BehaviorPosition.top ||
        behaviorPosition == common.BehaviorPosition.bottom) {
      final heightOffset = behaviorPosition == common.BehaviorPosition.bottom
          ? chartSize.height
          : 0.0;

      final horizontalJustification =
          getOutsideJustification(outsideJustification, isRTL);

      behaviorOffset = switch (horizontalJustification) {
        _HorizontalJustification.leftDrawArea =>
          Offset(behavior.drawAreaBounds!.left.toDouble(), heightOffset),
        _HorizontalJustification.left => Offset(0.0, heightOffset),
        _HorizontalJustification.rightDrawArea => Offset(
            behavior.drawAreaBounds!.right - behaviorSize.width, heightOffset),
        _HorizontalJustification.right =>
          Offset(chartSize.width - behaviorSize.width, heightOffset),
      };
    } else if (behaviorPosition == common.BehaviorPosition.start ||
        behaviorPosition == common.BehaviorPosition.end) {
      final widthOffset =
          (isRTL && behaviorPosition == common.BehaviorPosition.start) ||
                  (!isRTL && behaviorPosition == common.BehaviorPosition.end)
              ? chartSize.width
              : 0.0;

      behaviorOffset = switch (outsideJustification) {
        common.OutsideJustification.startDrawArea ||
        common.OutsideJustification.middleDrawArea =>
          Offset(widthOffset, behavior.drawAreaBounds!.top.toDouble()),
        common.OutsideJustification.start ||
        common.OutsideJustification.middle =>
          Offset(widthOffset, 0.0),
        common.OutsideJustification.endDrawArea => Offset(
            widthOffset,
            behavior.drawAreaBounds!.bottom - behaviorSize.height),
        common.OutsideJustification.end =>
          Offset(widthOffset, chartSize.height - behaviorSize.height),
      };
    } else if (behaviorPosition == common.BehaviorPosition.inside) {
      var rightOffset = Offset(chartSize.width - behaviorSize.width, 0.0);

      behaviorOffset = switch (insideJustification) {
        common.InsideJustification.topStart =>
          isRTL ? rightOffset : Offset.zero,
        common.InsideJustification.topEnd =>
          isRTL ? Offset.zero : rightOffset,
      };
    }

    return behaviorOffset;
  }

  _HorizontalJustification getOutsideJustification(
          common.OutsideJustification justification, bool isRTL) =>
      switch (justification) {
        common.OutsideJustification.startDrawArea ||
        common.OutsideJustification.middleDrawArea =>
          isRTL
              ? _HorizontalJustification.rightDrawArea
              : _HorizontalJustification.leftDrawArea,
        common.OutsideJustification.start ||
        common.OutsideJustification.middle =>
          isRTL
              ? _HorizontalJustification.right
              : _HorizontalJustification.left,
        common.OutsideJustification.endDrawArea => isRTL
            ? _HorizontalJustification.leftDrawArea
            : _HorizontalJustification.rightDrawArea,
        common.OutsideJustification.end => isRTL
            ? _HorizontalJustification.left
            : _HorizontalJustification.right,
      };
}

enum _HorizontalJustification {
  leftDrawArea,
  left,
  rightDrawArea,
  right,
}
