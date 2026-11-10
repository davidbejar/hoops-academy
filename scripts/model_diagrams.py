#!/usr/bin/env python3
"""Generates the Mermaid model diagrams of docs/domain/<service>-model.md (WP94).

Two generators, standard library only:
  * ER diagrams from a catalog dump (JSON from pg_catalog, produced by scripts/model-diagrams.sh),
  * class diagrams from the Java sources of a service (domain packages and application ports).

Usage: model_diagrams.py render <service> <catalog.json> <java-root> <page-in> <page-out>
The generated blocks sit between marker comments in the page; everything outside them is hand-written and kept.
Output is deterministic: everything is sorted, nothing carries a timestamp.
"""
import json
import re
import sys
from pathlib import Path

MEMBER_CAP = 10
ENUM_CAP = 8
ER_COLUMN_CAP = 24

# Display order and names of the groups of flat domain packages. Classes not listed land in "Other";
# a new class therefore shows up in the next generated page without anyone editing this table.
FLAT_GROUPS = {
    "athlete": [
        ("Training plans", ["TrainingPlan", "PlanItem", "PlanAssignment", "PlanCompletion", "PlanProgress",
                            "CompletionStatus", "Translations", "LocalizedText", "ContentLocale"]),
        ("Schedules and sessions", ["TrainingSchedule", "TrainingSession", "SessionStatus", "SessionMaterialiser",
                                    "PlannedSlot", "Duration15to480"]),
        ("Attendance and absences", ["Attendance", "AttendanceEntry", "AttendanceSheet", "AttendanceStatus",
                                     "PlannedAbsence", "PlayerAvailability"]),
        ("Health and fitness", ["Injury", "InjurySeverity", "InjuryStatus", "BodyMeasurement", "PhysicalTestNorm",
                                "PhysicalTestResult", "PhysicalTestType", "NormBand", "BandResolver", "AgeAt",
                                "Gender"]),
        ("Rule violations and actors", ["Actor", "TrainingRuleViolation", "TrainingStateConflict"]),
    ],
    "game": [
        ("Match", ["Match", "MatchRoster", "MatchScore", "MatchStatus", "HomeAway", "RosterEntry", "JerseyNumber",
                   "PlayerVisibility", "SeasonClose"]),
    ],
}
IDENTIFIER_GROUP = "Identifiers"

COLLECTIONS = {"List", "Set", "Collection", "Iterable", "SortedSet", "Deque", "Queue"}
JAVA_NOISE = {"String", "int", "long", "boolean", "double", "float", "short", "byte", "char", "void", "Object",
              "Integer", "Long", "Boolean", "Double", "Instant", "LocalDate", "LocalTime", "LocalDateTime",
              "ZoneId", "UUID", "Optional", "List", "Set", "Map", "BigDecimal", "Duration", "Collection", "T"}

# ----------------------------------------------------------------------------------------------- ER diagram


def er_type(pg_type):
    t = pg_type.lower()
    t = re.sub(r"\(.*?\)", "", t)
    t = (t.replace("timestamp with time zone", "timestamptz").replace("timestamp without time zone", "timestamp")
         .replace("character varying", "varchar").replace("double precision", "float8")
         .replace("time without time zone", "time").replace("time with time zone", "timetz"))
    t = re.sub(r"[^a-z0-9_\[\]]", "_", t.strip())
    return t or "unknown"


def entity_name(schema, table, main_schemas):
    return table if schema in main_schemas else f"{schema}_{table}"


def er_blocks(catalog, main_schemas):
    """One erDiagram per connected group of tables (FK graph); tables without any link share one diagram."""
    tables = {}
    for c in catalog["columns"]:
        tables.setdefault((c["schema"], c["table"]), []).append(c)
    fks = catalog["fks"]
    fk_cols = {}
    for fk in fks:
        for col in fk["cols"]:
            fk_cols.setdefault((fk["schema"], fk["table"]), set()).add(col)
    uk_cols = {}
    for u in catalog.get("uniques", []):
        if len(u["cols"]) == 1:
            uk_cols.setdefault((u["schema"], u["table"]), set()).add(u["cols"][0])
    parent = {t: t for t in tables}

    def find(x):
        while parent[x] != x:
            parent[x] = parent[parent[x]]
            x = parent[x]
        return x

    for fk in fks:
        a, b = (fk["schema"], fk["table"]), (fk["rschema"], fk["rtable"])
        if a in parent and b in parent:
            parent[find(a)] = find(b)
    comps = {}
    for t in tables:
        comps.setdefault(find(t), []).append(t)
    linked = [sorted(v) for v in comps.values() if len(v) > 1]
    lone = sorted(t for v in comps.values() if len(v) == 1 for t in v)
    groups = sorted(linked, key=lambda v: v[0]) + ([lone] if lone else [])
    blocks = []
    for group in groups:
        members = set(group)
        lines = ["erDiagram"]
        for key in group:
            schema, table = key
            name = entity_name(schema, table, main_schemas)
            cols = sorted(tables[key], key=lambda c: c["ord"])
            rls = any(c["rls"] for c in cols)
            lines.append(f"    {name} {{")
            important = [c for c in cols if c["pk"] or c["column"] in fk_cols.get(key, ()) or c["column"] == "tenant_id"]
            rest = [c for c in cols if c not in important]
            keep = important + rest[:max(0, ER_COLUMN_CAP - len(important))]
            keep = sorted(keep, key=lambda c: c["ord"])
            for c in keep:
                keys = []
                if c["pk"]:
                    keys.append("PK")
                if c["column"] in fk_cols.get(key, ()):
                    keys.append("FK")
                if c["column"] in uk_cols.get(key, ()) and not c["pk"]:
                    keys.append("UK")
                comment = []
                if c["column"] == "tenant_id" and rls:
                    comment.append("RLS")
                if c["notnull"] and not c["pk"]:
                    comment.append("not null")
                suffix = (" " + ",".join(keys) if keys else "") + (f' "{", ".join(comment)}"' if comment else "")
                lines.append(f"        {er_type(c['type'])} {c['column']}{suffix}")
            if len(keep) < len(cols):
                lines.append(f'        text more_columns "{len(cols) - len(keep)} more"')
            lines.append("    }")
        rels = set()
        for fk in fks:
            a, b = (fk["schema"], fk["table"]), (fk["rschema"], fk["rtable"])
            if a in members and b in members:
                nullable = any(not c["notnull"] for c in tables[a] if c["column"] in fk["cols"])
                left = "|o" if nullable else "||"
                label = ", ".join(fk["cols"])
                rels.add(f'    {entity_name(*b, main_schemas)} {left}--o{{ {entity_name(*a, main_schemas)} : "{label}"')
        lines.extend(sorted(rels))
        blocks.append((group, "\n".join(lines)))
    return blocks


def render_er(catalog, main_schemas):
    out = []
    for group, block in er_blocks(catalog, main_schemas):
        names = ", ".join(entity_name(s, t, main_schemas) for s, t in group)
        title = names if len(group) <= 4 else f"{entity_name(*group[0], main_schemas)} and {len(group) - 1} more"
        out.append(f"<details open>\n<summary>{title}</summary>\n\n```mermaid\n{block}\n```\n\n</details>\n")
    return "\n".join(out)


# --------------------------------------------------------------------------------------------- Java parsing

TOKEN = re.compile(r'"""(?:.|\n)*?"""|"(?:\\.|[^"\\\n])*"|\'(?:\\.|[^\'\\\n])*\'|//[^\n]*|/\*(?:.|\n)*?\*/')
DECL = re.compile(r"(?<![\w.@])((?:(?:public|protected|private|abstract|final|sealed|non-sealed|static|strictfp)\s+)*)"
                  r"(record|class|interface|enum)\s+(\w+)")
ANNOTATION = re.compile(r"@\w+(?:\.\w+)*(?:\s*\((?:[^()]|\([^()]*\))*\))?\s*")


def strip_source(text):
    def sub(m):
        s = m.group(0)
        if s.startswith("//") or s.startswith("/*"):
            return "\n" * s.count("\n")
        return '""' if s[0] == '"' else "''"
    return TOKEN.sub(sub, text)


def match_close(text, start, open_ch, close_ch):
    depth = 0
    for i in range(start, len(text)):
        if text[i] == open_ch:
            depth += 1
        elif text[i] == close_ch:
            depth -= 1
            if depth == 0:
                return i
    raise ValueError("unbalanced " + open_ch)


def split_top(text, sep=","):
    parts, depth, cur = [], 0, []
    for ch in text:
        if ch in "<([{":
            depth += 1
        elif ch in ">)]}":
            depth -= 1
        if ch == sep and depth == 0:
            parts.append("".join(cur).strip())
            cur = []
        else:
            cur.append(ch)
    tail = "".join(cur).strip()
    if tail:
        parts.append(tail)
    return parts


def clean_type(t):
    t = ANNOTATION.sub("", t)
    t = re.sub(r"\bfinal\s+", "", t)
    t = re.sub(r"\b(?:[a-z_]\w*\.)+(?=[A-Z])", "", t)
    t = re.sub(r"\s+", " ", t).strip()
    t = re.sub(r"\s*([<>,\[\]])\s*", r"\1", t)
    return t


def mermaid_type(t):
    t = clean_type(t).replace("?", "Any").replace("<", "~").replace(">", "~").replace(",", ",")
    t = re.sub(r"\bextends\b", "of", t)
    return t.replace(" ", "")


def type_names(t):
    return re.findall(r"[A-Z]\w*", clean_type(t))


def is_collection(t):
    return clean_type(t).split("<")[0] in COLLECTIONS or clean_type(t).endswith("[]")


class JavaType:
    def __init__(self, name, kind, package, modifiers):
        self.name, self.kind, self.package, self.modifiers = name, kind, package, modifiers
        self.components = []   # (type, name) for records
        self.fields = []       # (type, name, visibility) for classes
        self.methods = []      # (name, params, return type, static)
        self.constants = []
        self.supers = []       # (kind, type name): "extends" / "implements"

    @property
    def public(self):
        return "public" in self.modifiers


def parse_members(body, jt):
    """Walks the depth-1 statements of a class/interface/record body."""
    i, n = 0, len(body)
    header = []
    while i < n:
        ch = body[i]
        if ch == "{":
            end = match_close(body, i, "{", "}")
            add_member("".join(header), jt)
            header = []
            i = end + 1
            continue
        if ch == ";":
            add_member("".join(header), jt)
            header = []
            i += 1
            continue
        if ch == "(":
            end = match_close(body, i, "(", ")")
            header.append(body[i:end + 1])
            i = end + 1
            continue
        header.append(ch)
        i += 1


def add_member(raw, jt):
    h = ANNOTATION.sub("", raw).strip()
    if not h or re.search(r"\b(class|interface|enum|record)\s+\w+", h):
        return
    mods = set(re.findall(r"\b(public|private|protected|static|default|abstract|final)\b", h))
    visible = "private" not in mods
    if jt.kind == "interface":
        mods.add("public")
    paren = h.find("(")
    eq = h.find("=")
    if paren != -1 and (eq == -1 or paren < eq):
        head = h[:paren]
        head = re.sub(r"\b(?:public|private|protected|static|default|abstract|final|synchronized|native)\s+", "", head)
        head = re.sub(r"\s+", " ", head).strip()
        if head.startswith("<"):   # method type parameters
            head = head[match_close(head, 0, "<", ">") + 1:].strip()
        words = split_top(head, " ")
        if not words:
            return
        name = words[-1]
        if name == jt.name:   # constructor
            return
        ret = clean_type(" ".join(words[:-1])) or "void"
        params_end = match_close(h, paren, "(", ")")
        params = [clean_type(p.rsplit(" ", 1)[0]) if " " in p.strip() else p for p in split_top(h[paren + 1:params_end])]
        if visible and "public" in mods:
            jt.methods.append((name, params, ret, "static" in mods))
    else:
        decl = h[:eq] if eq != -1 else h
        words = [w for w in re.sub(r"\b(public|private|protected|static|final|volatile|transient)\b", "", decl).split()]
        if len(words) < 2:
            return
        ftype = clean_type(decl.replace(words[-1], "", 1).replace("public", "").replace("private", "")
                           .replace("protected", "").replace("static", "").replace("volatile", "")
                           .replace("transient", ""))
        if "static" not in mods:
            jt.fields.append((ftype, words[-1], "private" if "private" in mods else "visible"))


def parse_enum_constants(body):
    consts, i, n, cur = [], 0, len(body), []
    while i < n:
        ch = body[i]
        if ch in "({":
            close = match_close(body, i, ch, ")" if ch == "(" else "}")
            i = close + 1
            continue
        if ch in ",;":
            word = "".join(cur).strip()
            word = ANNOTATION.sub("", word).strip()
            if word:
                consts.append(word)
            cur = []
            if ch == ";":
                return consts, body[i + 1:]
        else:
            cur.append(ch)
        i += 1
    word = ANNOTATION.sub("", "".join(cur)).strip()
    if word:
        consts.append(word)
    return consts, ""


def parse_file(path, package):
    text = strip_source(path.read_text())
    depth_at = []
    depth = 0
    for ch in text:
        depth_at.append(depth)
        if ch == "{":
            depth += 1
        elif ch == "}":
            depth -= 1
    found = []
    for m in DECL.finditer(text):
        if depth_at[m.start()] != 0:
            continue
        # skip 'class' keyword used inside annotations/strings handled by strip_source; require declaration shape
        kind = m.group(2)
        jt = JavaType(m.group(3), kind, package, set(m.group(1).split()))
        i = m.end()
        tp = re.match(r"\s*<", text[i:])
        if tp:
            i = i + tp.end() - 1
            i = match_close(text, i, "<", ">") + 1
        if kind == "record":
            j = text.index("(", i)
            k = match_close(text, j, "(", ")")
            for comp in split_top(text[j + 1:k]):
                comp = ANNOTATION.sub("", comp).strip()
                if comp:
                    t, _, n = comp.rpartition(" ")
                    jt.components.append((clean_type(t), n))
            i = k + 1
        brace = text.index("{", i)
        clause = re.sub(r"\s+", " ", text[i:brace])
        for key in ("extends", "implements"):
            mm = re.search(rf"\b{key}\s+(.*?)(?=\b(?:extends|implements|permits)\b|$)", clause)
            if mm:
                for t in split_top(mm.group(1)):
                    jt.supers.append((key, clean_type(t).split("<")[0]))
        end = match_close(text, brace, "{", "}")
        body = text[brace + 1:end]
        if kind == "enum":
            jt.constants, body = parse_enum_constants(body)
        parse_members(body, jt)
        found.append(jt)
    return found


def load_types(root, subdir):
    base = root / subdir
    types = []
    for path in sorted(base.rglob("*.java")):
        if path.name in ("package-info.java", "module-info.java"):
            continue
        package = str(path.parent.relative_to(base)).replace("/", ".")
        types.extend(parse_file(path, "" if package == "." else package))
    return types


# --------------------------------------------------------------------------------------------- class diagram


def class_block(group_types, all_names_in_group, with_edges=True):
    lines = ["classDiagram"]
    edges = set()
    for jt in sorted(group_types, key=lambda x: x.name):
        members = []
        if jt.kind == "enum":
            consts = jt.constants
            members = [c for c in consts[:ENUM_CAP]]
            if len(consts) > ENUM_CAP:
                members.append(f"and {len(consts) - ENUM_CAP} more")
            stereo = "enumeration"
        else:
            stereo = {"record": "record", "interface": "interface"}.get(jt.kind)
            if jt.kind == "class" and "abstract" in jt.modifiers:
                stereo = "abstract"
            rows = [f"+{mermaid_type(t)} {n}" for t, n in jt.components]
            rows += [f"+{n}({','.join(mermaid_type(p) for p in ps)}) {mermaid_type(r)}"
                     for n, ps, r, static in jt.methods if not static or jt.kind != "record"]
            if jt.kind == "class":
                rows = [f"+{mermaid_type(t)} {n}" for t, n, v in jt.fields if v == "visible"] + rows
            members = rows[:MEMBER_CAP]
            if len(rows) > MEMBER_CAP:
                members.append(f"and {len(rows) - MEMBER_CAP} more")
        lines.append(f"    class {jt.name} {{")
        if stereo:
            lines.append(f"        <<{stereo}>>")
        for m in members:
            lines.append(f"        {m}")
        lines.append("    }")
        if with_edges:
            refs = [(t, n) for t, n in jt.components] + [(t, n) for t, n, v in jt.fields]
            for t, n in refs:
                for target in dict.fromkeys(type_names(t)):
                    if target in all_names_in_group and target != jt.name:
                        card = ' "*"' if is_collection(t) else ""
                        edges.add(f"    {jt.name} -->{card} {target} : {n}")
            for kind, sup in jt.supers:
                if sup in all_names_in_group and sup != jt.name:
                    arrow = "<|.." if kind == "implements" or [x for x in group_types if x.name == sup and x.kind == "interface"] else "<|--"
                    edges.add(f"    {sup} {arrow} {jt.name}")
    lines.extend(sorted(edges))
    return "\n".join(lines)


def details(title, block):
    return f"<details open>\n<summary>{title}</summary>\n\n```mermaid\n{block}\n```\n\n</details>\n"


def split_in_chunks(items, limit=28):
    return [items[i:i + limit] for i in range(0, len(items), limit)] or [[]]


def render_domain(service, types):
    domain = [t for t in types]
    groups = {}
    for jt in domain:
        if jt.package:
            key = jt.package.split(".")[0]
            groups.setdefault(f"Package {key}", []).append(jt)
    flat = [jt for jt in domain if not jt.package]
    if flat:
        spec = FLAT_GROUPS.get(service, [])
        assigned = set()
        for title, names in spec:
            members = [jt for jt in flat if jt.name in names]
            assigned.update(jt.name for jt in members)
            if members:
                groups[title] = members
        ids = [jt for jt in flat if jt.name not in assigned and jt.name.endswith("Id") and jt.kind == "record"]
        assigned.update(jt.name for jt in ids)
        if ids:
            groups[IDENTIFIER_GROUP] = ids
        other = [jt for jt in flat if jt.name not in assigned]
        if other:
            groups["Other domain types" if spec else "Domain"] = other
    out = []
    for title in sorted(groups, key=lambda t: (t.startswith("Package"), t)) if not FLAT_GROUPS.get(service) else \
            [t for t, _ in FLAT_GROUPS[service] if t in groups] + sorted(t for t in groups if t not in dict(FLAT_GROUPS[service])):
        members = sorted(groups[title], key=lambda x: x.name)
        for n, chunk in enumerate(split_in_chunks(members), 1):
            names = {jt.name for jt in chunk}
            suffix = f" ({n})" if len(split_in_chunks(members)) > 1 else ""
            out.append(details(f"{title}{suffix}", class_block(chunk, names, title != IDENTIFIER_GROUP)))
    return "\n".join(out)


def render_ports(types):
    ports = [jt for jt in types if jt.kind in ("interface", "enum")]
    groups = {}
    for jt in ports:
        key = jt.package.split(".")[0] if jt.package else "(root)"
        groups.setdefault(key, []).append(jt)
    out = []
    for key in sorted(groups):
        members = sorted(groups[key], key=lambda x: x.name)
        chunks = split_in_chunks(members, 12)
        for n, chunk in enumerate(chunks, 1):
            suffix = f" ({n}/{len(chunks)})" if len(chunks) > 1 else ""
            out.append(details(f"application {key}{suffix}", class_block(chunk, {j.name for j in chunk})))
    return "\n".join(out)


# ----------------------------------------------------------------------------------------------- the page

SECTION = "<!-- BEGIN GENERATED: {0} -->\n{1}\n<!-- END GENERATED: {0} -->"


def splice(page, name, content):
    pattern = re.compile(rf"<!-- BEGIN GENERATED: {name} -->.*?<!-- END GENERATED: {name} -->", re.S)
    block = SECTION.format(name, content.rstrip("\n"))
    if not pattern.search(page):
        raise SystemExit(f"marker pair '{name}' missing in the page")
    return pattern.sub(lambda m: block, page)


def render(service, catalog_path, java_root, page_in, page_out, main_schemas):
    catalog = json.loads(Path(catalog_path).read_text())
    root = Path(java_root)
    domain = load_types(root, "domain")
    application = load_types(root, "application")
    page = Path(page_in).read_text()
    page = splice(page, "er", render_er(catalog, main_schemas))
    page = splice(page, "domain", render_domain(service, domain))
    page = splice(page, "ports", render_ports(application))
    Path(page_out).write_text(page)


if __name__ == "__main__":
    if len(sys.argv) != 8 or sys.argv[1] != "render":
        sys.exit(__doc__)
    render(*sys.argv[2:7], set(sys.argv[7].split(",")))
