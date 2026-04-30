import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

// Simple Mon-Sun bar chart for weekly adherence.
/// Seven values: Monday (0) … Sunday (6) for the week containing [referenceDay].
class WeekMondaySundayAdherenceChart extends StatelessWidget {
  const WeekMondaySundayAdherenceChart({
    required this.valuesMondayToSunday,
    required this.referenceDayInWeek,
    super.key,
  });

  final List<double> valuesMondayToSunday;
  final DateTime referenceDayInWeek;

  DateTime _mondayOfWeekContaining(DateTime d) {
    final cal = DateTime(d.year, d.month, d.day);
    final daysFromMonday = (cal.weekday - DateTime.monday) % 7;
    return cal.subtract(Duration(days: daysFromMonday));
  }

  DateTime _dayAtIndex(int index) =>
      _mondayOfWeekContaining(referenceDayInWeek).add(Duration(days: index));

  String _weekdayShort(BuildContext context, int index) {
    return DateFormat.E(
      Localizations.localeOf(context).toLanguageTag(),
    ).format(_dayAtIndex(index));
  }

  String _dateShort(int index) {
    final day = _dayAtIndex(index);
    return '${day.month.toString().padLeft(2, '0')}/${day.day.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    if (valuesMondayToSunday.length != 7) {
      return const SizedBox.shrink();
    }

    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'This week (Mon–Sun)',
          style: Theme.of(
            context,
          ).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 140,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: List.generate(7, (index) {
              final value = valuesMondayToSunday[index].clamp(0.0, 1.0);
              final color =
                  Color.lerp(
                    theme.colorScheme.error,
                    theme.colorScheme.secondary,
                    value,
                  ) ??
                  theme.colorScheme.secondary;

              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 2),
                  child: Column(
                    children: [
                      Expanded(
                        child: LayoutBuilder(
                          builder: (context, constraints) {
                            final trackH = constraints.maxHeight;
                            final fillH = trackH * value;
                            return Container(
                              decoration: BoxDecoration(
                                color:
                                    theme.colorScheme.surfaceContainerHighest,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Align(
                                alignment: Alignment.bottomCenter,
                                child: Container(
                                  width: 16,
                                  height: fillH.clamp(0.0, trackH),
                                  decoration: BoxDecoration(
                                    color: color,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _weekdayShort(context, index),
                        style: Theme.of(context).textTheme.labelSmall,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        _dateShort(index),
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          fontSize: 9,
                          color: Theme.of(context).hintColor,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
          ),
        ),
      ],
    );
  }
}
