"""Tests of scripts/model_diagrams.py and a strict syntax check of the Mermaid in docs/domain/*-model.md.

Run: python3 -m unittest discover -s scripts/tests
The grammar rules below are the subset of Mermaid's erDiagram / classDiagram grammar that the generator relies on
(mermaid.js.org syntax pages); a Mermaid CLI is not available (no Node), so this is the render check.
"""
import pathlib
import re
import sys
import tempfile
import unittest

ROOT = pathlib.Path(__file__).resolve().parents[2]
sys.path.insert(0, str(ROOT / "scripts"))
import model_diagrams as md  # noqa: E402

MAX_TEXT = 50000          # mermaid maxTextSize default; GitHub renders with the defaults
MAX_EDGES = 500           # mermaid maxEdges default

ER_ENTITY = re.compile(r"^    ([A-Za-z_][\w-]*) \{$")
ER_ATTR = re.compile(r'^        ([A-Za-z_][\w\-\[\]()]*) ([A-Za-z_][\w-]*)(?: (?:PK|FK|UK)(?:,(?:PK|FK|UK))*)?(?: "[^"{}]*")?$')
ER_REL = re.compile(r'^    ([A-Za-z_][\w-]*) (\|\||\|o)--o\{ ([A-Za-z_][\w-]*) : "[^"]*"$')
CL_CLASS = re.compile(r"^    class ([A-Za-z_]\w*) \{$")
CL_STEREO = re.compile(r"^        <<(enumeration|record|interface|abstract)>>$")
CL_MEMBER = re.compile(r"^        [+]?[A-Za-z_][\w~,.\[\]() ]*$")
CL_EDGE = re.compile(r'^    ([A-Za-z_]\w*) (-->|<\|\.\.|<\|--)(?: "\*")? ([A-Za-z_]\w*)(?: : [A-Za-z_]\w*)?$')


def mermaid_blocks(text):
    return re.findall(r"```mermaid\n(.*?)\n```", text, re.S)


def check_er(block):
    lines = block.split("\n")
    assert lines[0] == "erDiagram", lines[0]
    entities, i, rels = set(), 1, []
    while i < len(lines):
        m = ER_ENTITY.match(lines[i])
        if m:
            entities.add(m.group(1))
            i += 1
            while lines[i] != "    }":
                assert ER_ATTR.match(lines[i]), f"bad attribute: {lines[i]!r}"
                i += 1
            i += 1
            continue
        r = ER_REL.match(lines[i])
        assert r, f"bad ER line: {lines[i]!r}"
        rels.append(r)
        i += 1
    for r in rels:
        assert r.group(1) in entities and r.group(3) in entities, f"undeclared entity in {r.group(0)!r}"
    assert len(rels) <= MAX_EDGES


def check_class(block):
    lines = block.split("\n")
    assert lines[0] == "classDiagram", lines[0]
    classes, edges, i = set(), [], 1
    while i < len(lines):
        m = CL_CLASS.match(lines[i])
        if m:
            assert m.group(1) not in classes, f"duplicate class {m.group(1)}"
            classes.add(m.group(1))
            i += 1
            while lines[i] != "    }":
                assert CL_STEREO.match(lines[i]) or CL_MEMBER.match(lines[i]), f"bad member: {lines[i]!r}"
                i += 1
            i += 1
            continue
        e = CL_EDGE.match(lines[i])
        assert e, f"bad class line: {lines[i]!r}"
        edges.append(e)
        i += 1
    for e in edges:
        assert e.group(1) in classes and e.group(3) in classes, f"undeclared class in {e.group(0)!r}"
    assert len(edges) <= MAX_EDGES


class GeneratedPages(unittest.TestCase):
    def test_every_mermaid_block_is_valid_and_small(self):
        pages = sorted((ROOT / "docs/domain").glob("*-model.md"))
        self.assertEqual([p.name for p in pages], ["athlete-model.md", "core-model.md", "game-model.md"])
        for page in pages:
            text = page.read_text()
            for name in ("er", "domain", "ports"):
                self.assertIn(f"<!-- BEGIN GENERATED: {name} -->", text, page.name)
                self.assertIn(f"<!-- END GENERATED: {name} -->", text, page.name)
            blocks = mermaid_blocks(text)
            self.assertGreater(len(blocks), 3, page.name)
            for block in blocks:
                self.assertLess(len(block), MAX_TEXT, page.name)
                with self.subTest(page=page.name, head=block[:60]):
                    (check_er if block.startswith("erDiagram") else check_class)(block)


class Parser(unittest.TestCase):
    def parse(self, source, name="X.java"):
        with tempfile.TemporaryDirectory() as d:
            p = pathlib.Path(d) / name
            p.write_text(source)
            return md.parse_file(p, "")

    def test_record_components_generics_and_methods(self):
        [t] = self.parse('''package a;
/** doc // not a comment */
public record Plan(PlanId id, @NotNull List<Item> items, Map<String, Integer> m) implements Shape {
    private static final String S = "// {";
    public Plan { items = List.copyOf(items); }
    public <T> Optional<T> pick(Class<T> c, int n) { return null; }
    private void hidden() {}
}''')
        self.assertEqual([c[1] for c in t.components], ["id", "items", "m"])
        self.assertEqual(t.components[2][0], "Map<String,Integer>")
        self.assertEqual([m[0] for m in t.methods], ["pick"])
        self.assertEqual(t.methods[0][2], "Optional<T>")
        self.assertEqual(t.supers, [("implements", "Shape")])

    def test_enum_constants_and_interface_methods(self):
        e, i = self.parse("public enum E { A, B(1) { void f() {} }, C; int x; }\ninterface P { Optional<E> find(Id id); private void h() {} }")
        self.assertEqual(e.constants, ["A", "B(1)".split("(")[0], "C"])
        self.assertEqual([m[0] for m in i.methods], ["find"])

    def test_generation_is_deterministic(self):
        types = md.load_types(ROOT / "services/athlete-service/src/main/java/com/hoopsacademy/athlete", "domain")
        self.assertEqual(md.render_domain("athlete", types), md.render_domain("athlete", list(reversed(types))))


class ErDiagram(unittest.TestCase):
    CATALOG = {
        "columns": [
            {"schema": "s", "table": "parent", "column": "id", "ord": 1, "type": "uuid", "notnull": True, "pk": True, "rls": True},
            {"schema": "s", "table": "parent", "column": "tenant_id", "ord": 2, "type": "uuid", "notnull": True, "pk": False, "rls": True},
            {"schema": "s", "table": "child", "column": "id", "ord": 1, "type": "uuid", "notnull": True, "pk": True, "rls": False},
            {"schema": "s", "table": "child", "column": "parent_id", "ord": 2, "type": "uuid", "notnull": False, "pk": False, "rls": False},
            {"schema": "s", "table": "child", "column": "n", "ord": 3, "type": "numeric(5,2)", "notnull": True, "pk": False, "rls": False},
            {"schema": "x", "table": "alone", "column": "t", "ord": 1, "type": "timestamp with time zone", "notnull": False, "pk": False, "rls": False},
        ],
        "fks": [{"schema": "s", "table": "child", "rschema": "s", "rtable": "parent", "cols": ["parent_id"]}],
        "uniques": [],
    }

    def test_relationship_nullability_prefixing_and_types(self):
        out = md.render_er(self.CATALOG, {"s"})
        self.assertIn('parent |o--o{ child : "parent_id"', out)
        self.assertIn("numeric n", out)
        self.assertIn("x_alone", out)
        self.assertIn("timestamptz t", out)
        for block in mermaid_blocks(out):
            check_er(block)


if __name__ == "__main__":
    unittest.main()
