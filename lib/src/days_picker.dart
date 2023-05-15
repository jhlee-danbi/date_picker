import 'package:flutter/material.dart';

import 'days_view.dart';
import 'header.dart';

/// A scrollable grid of months to allow picking a month.
///
/// The month picker widget is rarely used directly. Instead, consider using
/// [DatePicker] which create full date picker.
///
/// See also:
///
///  * [DatePicker], which provides a Material Design date picker
///    interface.
///
class DaysPicker extends StatefulWidget {
  /// Creates a month picker.
  ///
  /// The [maxDate], [minDate], [initialDate] arguments
  /// must be non-null. The [minDate] must be after the [maxDate].
  DaysPicker({
    super.key,
    required this.initialDate,
    required this.maxDate,
    required this.minDate,
    this.onLeadingDateTap,
    this.onChange,
  }) : assert(!minDate.isAfter(maxDate), "minDate can't be after maxDate");

  /// Called when the user picks a month.
  final ValueChanged<DateTime>? onChange;

  /// The earliest date the user is permitted to pick.
  ///
  /// This date must be on or before the [maxDate].
  final DateTime minDate;

  /// The latest date the user is permitted to pick.
  ///
  /// This date must be on or after the [minDate].
  final DateTime maxDate;

  /// The date which will be displayed on first opening.
  final DateTime initialDate;

  /// Called when the user tap on the leading date.
  final VoidCallback? onLeadingDateTap;

  @override
  State<DaysPicker> createState() => _DaysPickerState();
}

class _DaysPickerState extends State<DaysPicker> {
  DateTime? _displayedMonth;
  DateTime? _selectedDate;
  final GlobalKey _pageViewKey = GlobalKey();
  late final PageController _pageController;
  double maxHeight = 52 * 6; // A 31 day month that starts on Saturday.

  @override
  void initState() {
    _displayedMonth = widget.initialDate;
    _pageController = PageController(
      initialPage: DateUtils.monthDelta(widget.minDate, widget.initialDate),
    );
    super.initState();
  }

  @override
  void didUpdateWidget(covariant DaysPicker oldWidget) {
    // there is no need to check for the displayed month because it changes via
    // page view and not the initial date.
    // but for makeing debuging easy, we will navigate to the initial date again
    // if it changes.
    if (DateUtils.dateOnly(oldWidget.initialDate) !=
        DateUtils.dateOnly(widget.initialDate)) {
      _pageController.jumpToPage(
        DateUtils.monthDelta(widget.minDate, widget.initialDate),
      );
    }
    super.didUpdateWidget(oldWidget);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Widget _buildItems(BuildContext context, int index) {
    final DateTime month =
        DateUtils.addMonthsToMonthDate(widget.minDate, index);

    return DaysView(
      key: ValueKey<DateTime>(month),
      currentDate: DateTime.now(),
      minDate: widget.minDate,
      maxDate: widget.maxDate,
      displayedMonth: month,
      selectedDate: _selectedDate,
      onChanged: (value) {
        setState(() {
          _selectedDate = value;
        });
        widget.onChange?.call(value);
      },
    );
  }

  void _handleMonthPageChanged(int monthPage) {
    final DateTime monthDate =
        DateUtils.addMonthsToMonthDate(widget.minDate, monthPage);

    setState(() {
      _displayedMonth = monthDate;
      if (isSevenRows(monthDate.year, monthDate.month, monthDate.weekday)) {
        maxHeight = 52 * 7;
      } else {
        maxHeight = 52 * 6;
      }
    });
  }

  bool isSevenRows(int year, int month, int weekday) {
    final offset = DateUtils.firstDayOffset(
        year, month, MaterialLocalizations.of(context));
    final daysCount = DateUtils.getDaysInMonth(year, month);

    // 30 & 5 => false
    // 31 & 5 => true
    // 30 & 6 => true
    // 31 & 6 => true
    if (offset == 5 && daysCount == 30) {
      return false;
    }

    if (offset >= 5 && daysCount >= 30) {
      return true;
    }

    return false;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Header(
          onDateTap: () => widget.onLeadingDateTap?.call(),
          displayedDate: MaterialLocalizations.of(context)
              .formatMonthYear(_displayedMonth!),
          onNextPage: () {
            _pageController.nextPage(
              duration: const Duration(milliseconds: 300),
              curve: Curves.ease,
            );
          },
          onPreviousPage: () {
            _pageController.previousPage(
              duration: const Duration(milliseconds: 300),
              curve: Curves.ease,
            );
          },
        ),
        const SizedBox(height: 10),
        AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          height: maxHeight,
          child: PageView.builder(
            scrollDirection: Axis.horizontal,
            key: _pageViewKey,
            controller: _pageController,
            itemCount: DateUtils.monthDelta(widget.minDate, widget.maxDate) + 1,
            itemBuilder: _buildItems,
            onPageChanged: _handleMonthPageChanged,
          ),
        ),
      ],
    );
  }
}