import 'dart:collection';
import 'dart:math';

import 'package:collection/collection.dart';
import 'package:despresso/model/services/state/coffee_service.dart';
import 'package:despresso/model/shot.dart';
import 'package:despresso/service_locator.dart';
import 'package:despresso/ui/widgets/dashboard/colored_dashboard_item.dart';
import 'package:despresso/ui/widgets/dashboard/colorlist.dart';
import 'package:despresso/ui/widgets/legend_widget.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class ShotsPerTime extends StatefulWidget {
  const ShotsPerTime({Key? key, required this.data}) : super(key: key);
  final ColoredDashboardItem data;
  @override
  State<ShotsPerTime> createState() => _ShotsPerTimeState();
}

class _ShotsPerTimeState extends State<ShotsPerTime> {
  late CoffeeService _coffeeService;
  late List<Shot> allShots;

  late LinkedHashMap<String, LinkedHashMap<String, int>> sortedMap = LinkedHashMap();
  late LinkedHashMap<String, int> colormap = LinkedHashMap();
  int touchedIndex = -1;
  int _selectedTimeRange = 30;
  DateTime time = DateTime.now();
  var timeRanges = [
    const DropdownMenuItem(
      value: 1,
      child: Text("Day"),
    ),
    const DropdownMenuItem(
      value: 7,
      child: Text("Week"),
    ),
    const DropdownMenuItem(
      value: 30,
      child: Text("Month"),
    )
  ];

  @override
  void initState() {
    super.initState();
    _coffeeService = getIt<CoffeeService>();
    allShots = _coffeeService.shotBox.getAll();
    time = allShots.last.date;
    calcData();
    // var sortedKeys = counts.keys.toList(growable: false)..sort((k1, k2) => counts[k2]!.compareTo(counts[k1]!));
    // sortedMap = counts; // LinkedHashMap.fromIterable(sortedKeys, key: (k) => k, value: (k) => counts[k]!);
    // print(sortedMap);
  }

  void calcData() {
    var fromTo = DateTimeRange(
        end: time.add(const Duration(seconds: 1)), start: time.subtract(Duration(days: _selectedTimeRange)));
    sortedMap.clear();
    if (_selectedTimeRange > 1) {
      for (var i = 1; i < _selectedTimeRange; i++) {
        var d = time.subtract(Duration(days: i));
        var key = "${d.day}_${d.month}_${d.year}";
        sortedMap[key] = LinkedHashMap();
      }
    }
    if (_selectedTimeRange == 1) {
      for (var i = 0; i < 24; i++) {
        var d = time.subtract(Duration(hours: i));
        var key = "${d.hour}";
        sortedMap[key] = LinkedHashMap();
      }
    }
    for (var element in allShots) {
      try {
        var d = element.date;
        if (d.isBefore(fromTo.end) && d.isAfter(fromTo.start)) {
          var key = _selectedTimeRange == 1 ? "${d.hour}" : "${d.day}_${d.month}_${d.year}";
          var key2 = element.recipe.target?.name;
          if (key2 != null) {
            if (sortedMap[key] == null) {
              sortedMap[key] = LinkedHashMap();
            }
            if (sortedMap[key]![key2] == null) {
              sortedMap[key]![key2] = 0;
            }
            sortedMap[key]![key2] = sortedMap[key]![key2]! + 1;
          }

          // sortedMap[key] = sortedMap[key]! + 1;
        }
      } catch (e) {
        debugPrint("Error");
      }
    }
    colormap.clear();
    var index = 0;
    sortedMap.entries.forEach((element) {
      element.value.forEach(
        (key, value) {
          if (colormap[key] == null) {
            colormap[key] = index % colorList.length;
            index++;
          }
        },
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    var legends = colormap.entries
        .mapIndexed((i, e) => Legend(
              e.key,
              colorList[colormap[e.key]!],
              e.value.toString(),
            ))
        .toList();
    final DateFormat formatter = DateFormat('yMMMd');
    return Container(
      color: Theme.of(context).focusColor,
      // color: yellow,
      alignment: Alignment.center,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
      child: Column(
        children: [
          Column(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  if (widget.data.title != null)
                    Text(
                      widget.data.title!,
                      textAlign: TextAlign.left,
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                  IconButton(
                      onPressed: () {
                        time = time.subtract(Duration(days: _selectedTimeRange));
                        calcData();
                        setState(() {});
                      },
                      icon: const Icon(Icons.chevron_left)),
                  DropdownButton(
                    isExpanded: false,
                    alignment: Alignment.centerLeft,
                    value: _selectedTimeRange,
                    items: timeRanges,
                    onChanged: (value) {
                      if (value != 0) {
                        _selectedTimeRange = value!;
                        calcData();
                      }
                      setState(() {});
                    },
                  ),
                  IconButton(
                      onPressed: () {
                        time = time.subtract(Duration(days: -_selectedTimeRange));
                        calcData();
                        setState(() {});
                      },
                      icon: const Icon(Icons.chevron_right)),
                  Text(formatter.format(time)),
                ],
              ),
              if (widget.data.subTitle != null)
                Row(
                  children: [
                    Text(
                      widget.data.subTitle!,
                      style: Theme.of(context).textTheme.labelSmall,
                    ),
                  ],
                ),
            ],
          ),
          const SizedBox(
            height: 10,
          ),
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Expanded(
                  child: LayoutBuilder(builder: (context, constrains) {
                    var r = min(constrains.maxWidth, constrains.maxHeight) / 2;
                    return BarChart(
                      BarChartData(
                        // pieTouchData: PieTouchData(
                        //   touchCallback: (FlTouchEvent event, pieTouchResponse) {
                        //     setState(() {
                        //       if (!event.isInterestedForInteractions ||
                        //           pieTouchResponse == null ||
                        //           pieTouchResponse.touchedSection == null) {
                        //         touchedIndex = -1;
                        //         return;
                        //       }
                        //       touchedIndex = pieTouchResponse.touchedSection!.touchedSectionIndex;
                        //       print(touchedIndex);
                        //     });
                        //   },
                        // ),
                        borderData: FlBorderData(
                          show: false,
                        ),
                        barGroups: showingSections(10),
                        // maxY: 10,

                        titlesData: FlTitlesData(
                          bottomTitles: AxisTitles(sideTitles: _bottomTitles),
                          leftTitles:
                              const AxisTitles(sideTitles: SideTitles(reservedSize: 30, showTitles: true, interval: 1)),
                          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        ),
                      ),
                    );
                  }),
                ),
                const SizedBox(
                  width: 10,
                ),
              ],
            ),
          ),
          LegendsListWidget(legends: legends, touchIndex: touchedIndex, noValues: true, horizontal: true)
        ],
      ),
    );
  }

  List<BarChartGroupData> showingSections(double radius) {
    // const shadows = [Shadow(color: Colors.black, blurRadius: 2)];
    return sortedMap.entries.mapIndexed((i, e) {
      final isTouched = i == touchedIndex;
      var color = colorList[i % colorList.length];
      // var actCol = Color.fromRGBO(color.red, color.green, color.blue, isTouched || touchedIndex == -1 ? 1 : 0.5);
      var actCol = color.withOpacity(isTouched || touchedIndex == -1 ? 1 : 0.5);

      double sum = 0;
      e.value.entries.forEach((element) {
        sum = sum + element.value;
      });
      double currentY = 0;
      print("New");
      return BarChartGroupData(
        x: i,
        barRods: [
          BarChartRodData(
            toY: sum, // isTouched ? e.value + 1 : e.value.toDouble() * 2,
            // color: isTouched ? widget.touchedBarColor : barColor,
            // width: 10,
            color: Colors.white,
            // borderSide: isTouched
            //     ? BorderSide(color: widget.touchedBarColor.darken(80))
            //     : const BorderSide(color: Colors.white, width: 0),
            // backDrawRodData: BackgroundBarChartRodData(
            //   show: true,
            //   toY: 10,
            //   // color: widget.barBackgroundColor,
            // ),
            rodStackItems: e.value.entries.mapIndexed((index, element) {
              print("${currentY} ${element.value.toDouble()} ${colormap[element.key]}");
              var bar = BarChartRodStackItem(
                currentY,
                currentY + element.value.toDouble(),
                colorList[colormap[element.key]!],
                // BorderSide(
                //   color: Colors.white,
                //   width: isTouched ? 2 : 0,
                // ),
              );
              currentY += element.value.toDouble();
              return bar;
            }).toList(),
          ),
        ],
      );
    }).toList();
  }

  SideTitles get _bottomTitles => SideTitles(
        showTitles: true,
        reservedSize: 55, //+ _selectedTimeRange == 7 ? 25 : 25,
        getTitlesWidget: (value, meta) {
          String text = '';
          String text2 = '';
          switch (_selectedTimeRange) {
            case 7:
              final DateFormat formatter = DateFormat('EEE');
              final DateFormat formatter2 = DateFormat('dd MMM');

              var d = time.subtract(Duration(days: 7 - value.toInt()));
              text = formatter.format(d);
              text2 = formatter2.format(d);

              break;
            case 30:
              final DateFormat formatter = DateFormat('dd');
              final DateFormat formatter2 = DateFormat('MMM');

              if (value.toInt() % 2 == 0) {
                var d = time.subtract(Duration(days: 30 - value.toInt()));
                text = formatter.format(d);
                if (value.toInt() % 10 == 0) text2 = formatter2.format(d);
                // text = d.day.toString();
              }

              break;
            case 1:
              if (value.toInt() % 1 == 0) {
                var d = time.subtract(Duration(hours: 23 - value.toInt()));
                text = d.hour.toString();
              }

              break;
          }

          return Column(
            children: [
              Text(text),
              Text(text2, style: Theme.of(context).textTheme.labelSmall),
            ],
          );
        },
      );
}

class AdviceResize extends StatelessWidget {
  const AdviceResize({Key? key, required this.size}) : super(key: key);

  final int size;

  @override
  Widget build(BuildContext context) {
    return Container(
        color: green,
        alignment: Alignment.center,
        child: Row(
          children: [
            Container(
              margin: const EdgeInsets.only(left: 5),
              height: double.infinity,
              width: 1,
              color: Colors.white,
            ),
            const Expanded(
                child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                Text("Users can resize widgets.",
                    maxLines: 2, style: TextStyle(color: Colors.white, fontSize: 13), textAlign: TextAlign.center),
                Text(
                    "To try resizing, hold (or long press) the line on the left"
                    " and drag it to the left.",
                    maxLines: 5,
                    style: TextStyle(color: Colors.white, fontSize: 13),
                    textAlign: TextAlign.center),
                Text("Don't forget switch to edit mode.",
                    maxLines: 3, style: TextStyle(color: Colors.white, fontSize: 13), textAlign: TextAlign.center),
              ],
            ))
          ],
        ));
  }
}
