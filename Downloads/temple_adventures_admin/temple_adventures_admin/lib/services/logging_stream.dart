import 'dart:async';

LogStreams logStreams = LogStreams();

class LogEvent {
  dynamic message;
  DateTime? time;
  Object? error;
  StackTrace? stackTrace;

  LogEvent(
    this.message, {
    this.time,
    this.error,
    this.stackTrace,
  });
}

/// A workaround for dart only code snippets contained in the data models to enable logging.
class LogStreams {
  StreamController<LogEvent> warningStreamController = StreamController<LogEvent>.broadcast();
  StreamController<LogEvent> errorStreamController = StreamController<LogEvent>.broadcast();

  void w(LogEvent event) => warningStreamController.add(event);

  void e(LogEvent event) => errorStreamController.add(event);
}
