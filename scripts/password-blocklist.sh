#!/usr/bin/env bash
# Builds the realm's password blocklist (ADR-0038) from a pinned public list. Re-run only to change the source or size;
# the output is committed and copied into the Keycloak chart by scripts/sync-chart-files.sh.
#   scripts/password-blocklist.sh
#
# Source: SecLists (MIT licence, (c) Daniel Miessler), Passwords/Common-Credentials/xato-net-10-million-passwords-1000000.txt
# at commit SOURCE_COMMIT, verified against SOURCE_SHA256. The data is Mark Burnett's 10-million-password sample, which he
# released into the public domain (2015); one password per line, most common first.
#
# Output: the SIZE most common passwords the rest of the realm policy would accept (12 to 128 characters: shorter or
# longer ones are rejected anyway), lower-cased (Keycloak lower-cases both the list and the candidate) and de-duplicated,
# in frequency order. ASVS 5.0 6.2.4 asks for at least the top 3000 passwords that match the policy; the top-100k of the
# same sample holds only 488 of them, hence the top-1M source.
set -euo pipefail
cd "$(dirname "$0")/.."

SOURCE_COMMIT=48c951a3c3afba4e647bfe6944a1fbd2fdbf2ca7
SOURCE_PATH=Passwords/Common-Credentials/xato-net-10-million-passwords-1000000.txt
SOURCE_SHA256=424a3e03a17df0a2bc2b3ca749d81b04e79d59cb7aeec8876a5a3f308d0caf51
SIZE=10000
MIN_LENGTH=12   # realm passwordPolicy length(12)
MAX_LENGTH=128  # realm passwordPolicy maxLength(128)
OUT=infra/keycloak/password-blocklist/hoops-password-blocklist.txt

tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT
curl -fsSL -o "$tmp/source.txt" \
  "https://raw.githubusercontent.com/danielmiessler/SecLists/$SOURCE_COMMIT/$SOURCE_PATH"
echo "$SOURCE_SHA256  $tmp/source.txt" | shasum -a 256 -c - >/dev/null \
  || { echo "password-blocklist: checksum mismatch for $SOURCE_PATH@$SOURCE_COMMIT" >&2; exit 1; }

mkdir -p "$(dirname "$OUT")"
python3 -I - "$tmp/source.txt" "$OUT" "$SIZE" "$MIN_LENGTH" "$MAX_LENGTH" <<'PY'
import sys
source, out, size, lo, hi = sys.argv[1], sys.argv[2], int(sys.argv[3]), int(sys.argv[4]), int(sys.argv[5])
seen, kept = set(), []
with open(source, encoding="utf-8", errors="strict") as lines:
    for line in lines:
        word = line.rstrip("\r\n").lower()
        if lo <= len(word) <= hi and word.strip() == word and word not in seen:
            seen.add(word)
            kept.append(word)
            if len(kept) == size:
                break
if len(kept) < size:
    sys.exit(f"password-blocklist: only {len(kept)} passwords of {lo}..{hi} characters in the source")
with open(out, "w", encoding="utf-8", newline="\n") as f:
    f.write("\n".join(kept) + "\n")
PY
echo "password-blocklist: wrote $(wc -l < "$OUT" | tr -d ' ') passwords to $OUT"
