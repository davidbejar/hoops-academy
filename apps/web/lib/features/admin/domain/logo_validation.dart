import 'dart:typed_data';

/// Largest logo the API accepts (`LogoBinary.maxLength`).
const maxLogoBytes = 512 * 1024;

enum LogoProblem { empty, tooLarge, wrongType }

/// Outcome of the client-side logo check. The server re-checks everything
/// (ADR-0009: it identifies the format from the magic bytes).
class LogoCheck {
  const LogoCheck.ok(String this.mimeType) : problem = null;
  const LogoCheck.rejected(LogoProblem this.problem) : mimeType = null;

  final String? mimeType;
  final LogoProblem? problem;

  bool get isValid => problem == null;
}

/// PNG / JPEG / WebP by extension *and* magic bytes, 1 byte .. 512 KB.
LogoCheck validateLogo({required String fileName, required Uint8List bytes}) {
  if (bytes.isEmpty) return const LogoCheck.rejected(LogoProblem.empty);
  if (bytes.length > maxLogoBytes) {
    return const LogoCheck.rejected(LogoProblem.tooLarge);
  }
  final dot = fileName.lastIndexOf('.');
  final ext = dot < 0 ? '' : fileName.substring(dot + 1).toLowerCase();
  final byExtension = switch (ext) {
    'png' => 'image/png',
    'jpg' || 'jpeg' => 'image/jpeg',
    'webp' => 'image/webp',
    _ => null,
  };
  if (byExtension == null || _sniff(bytes) != byExtension) {
    return const LogoCheck.rejected(LogoProblem.wrongType);
  }
  return LogoCheck.ok(byExtension);
}

String? _sniff(Uint8List b) {
  bool starts(List<int> magic, [int offset = 0]) {
    if (b.length < offset + magic.length) return false;
    for (var i = 0; i < magic.length; i++) {
      if (b[offset + i] != magic[i]) return false;
    }
    return true;
  }

  if (starts(const [0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A])) {
    return 'image/png';
  }
  if (starts(const [0xFF, 0xD8, 0xFF])) return 'image/jpeg';
  if (starts(const [0x52, 0x49, 0x46, 0x46]) &&
      starts(const [0x57, 0x45, 0x42, 0x50], 8)) {
    return 'image/webp';
  }
  return null;
}
