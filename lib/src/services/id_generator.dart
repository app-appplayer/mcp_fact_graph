/// Process-wide id generation.
///
/// An id built from a clock reading alone repeats when two records are made
/// in the same tick, and a store replaces a record that has the same id
/// without raising an error. The counter makes every id issued by this process
/// distinct whatever the clock does.
library;

int _sequence = 0;

/// A new id of the form `<prefix>_<microseconds>_<sequence>`.
String generateId(String prefix) {
  _sequence += 1;
  return '${prefix}_${DateTime.now().microsecondsSinceEpoch}_$_sequence';
}
