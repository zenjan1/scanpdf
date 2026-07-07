import 'package:scanpdf/core/utils/date_format.dart';

extension DateTimeExtension on DateTime {
  String get formatted => DateFormatUtil.formatDateTime(this);
  String get formattedDate => DateFormatUtil.formatDate(this);
  String get formattedTime => DateFormatUtil.formatTime(this);
  String get relative => DateFormatUtil.formatRelative(this);
}
