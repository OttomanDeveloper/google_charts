# charts_flutter_maintained

[![pub package](https://img.shields.io/pub/v/charts_flutter_maintained.svg)](https://pub.dev/packages/charts_flutter_maintained)

Material Design charting library for Flutter. Community-maintained fork of [google/charts](https://github.com/google/charts).

## Features

- Bar charts (grouped, stacked, horizontal, vertical, with labels)
- Line charts (with area, stacked, segments, nulls, animation)
- Pie / Donut charts (with labels, gauge)
- Scatter plot charts (with shapes, comparison points, bucketing)
- Time series charts (with annotations, confidence intervals)
- Combo charts (line + bar, scatter + line)
- Legend support (series and datum legends, custom layouts)
- Interactive behaviors (selection, zoom/pan, sliders, tooltips)
- Accessibility support
- RTL layout support

## Getting Started

Add the dependency:

```yaml
dependencies:
  charts_flutter_maintained: ^1.0.0
```

### Simple Bar Chart

```dart
import 'package:charts_flutter_maintained/charts_flutter_maintained.dart' as charts;

charts.BarChart(
  [
    charts.Series<OrdinalSales, String>(
      id: 'Sales',
      domainFn: (sales, _) => sales.year,
      measureFn: (sales, _) => sales.sales,
      data: [
        OrdinalSales('2021', 5),
        OrdinalSales('2022', 25),
        OrdinalSales('2023', 100),
        OrdinalSales('2024', 75),
      ],
    ),
  ],
)
```

## Examples

See the [example app](example) for a full gallery of chart types and configurations.

## Requirements

- Dart SDK >= 3.0.0
- Flutter >= 3.10.0

## License

Apache 2.0 — see [LICENSE](LICENSE) for details.
