/// Spreadsheet formula-injection guard (OWASP CSV injection, CWE-1236).
///
/// A text value that Excel, LibreOffice or Sheets could read as a formula
/// (it starts with `=`, `+`, `-`, `@`, TAB or CR) gets a leading apostrophe,
/// which makes the spreadsheet show it as text. Numbers written as numbers
/// are not text and never pass through here.
library;

const _triggers = {'=', '+', '-', '@', '\t', '\r'};

String guardFormula(String value) =>
    value.isNotEmpty && _triggers.contains(value[0]) ? "'$value" : value;
