part of 'cron_bloc.dart';

/// Events accepted by [CronBloc].
sealed class CronEvent {
  const CronEvent();
}

/// The expression was edited, or replaced by an example.
class CronExpressionChanged extends CronEvent {
  const CronExpressionChanged(this.expression);

  final String expression;
}

/// The cursor moved to [offset] in the expression, or left it (`null`).
class CronCursorMoved extends CronEvent {
  const CronCursorMoved(this.offset);

  final int? offset;
}

/// Requests a random expression, like crontab.guru's "random".
class CronRequested extends CronEvent {
  const CronRequested();
}

/// Clears the expression.
class CronCleared extends CronEvent {
  const CronCleared();
}

/// Recomputes the next runs from now: the page adds it when it is shown
/// again, so runs computed a while ago do not linger in the past.
class CronRefreshed extends CronEvent {
  const CronRefreshed();
}
