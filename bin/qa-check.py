#!/usr/bin/env python3
"""Pemeriksa dokumen QA (qa-agent-workflow).

Memegang aturan yang tidak boleh bergantung pada ingatan agen: setiap AC punya
test case dan bukti, hasil AC dan rekomendasi konsisten dengan hasil test case,
test case gagal punya draft bug, draft bug lengkap, dan rekomendasi rilis tidak
lebih optimis daripada hasil regresi. Aturan lengkap: skills/_shared/report-format.md.

Pemakaian:
  qa-check.py validasi <qa-validasi.md>
  qa-check.py report   <qa.md> [--final]
  qa-check.py bug      <bug-N.md>
  qa-check.py signoff  <vX.Y.Z-qa.md>
  qa-check.py ticket   <folder docs/tickets/KODE> [--final]
Exit: 0 lolos, 1 ada pelanggaran, 2 salah pakai. Hanya pustaka standar.
"""
import re
import sys
from pathlib import Path

PLACEHOLDER = re.compile(r"<(?!https?:|mailto:)[A-Za-z][^<>\n]*>")
EMPTY = {"", "-", "—"}
TC_KINDS = ("normal", "batas", "gagal", "regresi")
RESULTS = ("Lulus", "Gagal", "Tertahan")
SEVERITIES = ("S1", "S2", "S3", "S4")
BUG_REF = re.compile(r"\bbug-(\d+)\b")


class Doc:
    """Markdown QA: judul, kepala `- Kunci: nilai`, bagian `## Nama`."""

    def __init__(self, path):
        self.path = Path(path)
        try:
            self.text = self.path.read_text(encoding="utf-8")
        except OSError as e:
            raise Usage(f"tidak bisa membaca {path}: {e}")
        self.head, self.sections, cur = {}, {}, None
        in_code = False
        for line in self.text.splitlines():
            if line.lstrip().startswith("```"):
                in_code = not in_code
            if in_code:
                if cur is not None:
                    self.sections[cur].append(line)
                continue
            m = re.match(r"^##\s+(.+?)\s*$", line)
            if m:
                cur = m.group(1)
                self.sections.setdefault(cur, [])
                continue
            if cur is None:
                h = re.match(r"^\s*-\s+([^:]+?):\s*(.*?)\s*$", line)
                if h:
                    self.head[h.group(1).strip()] = h.group(2).strip()
            else:
                self.sections[cur].append(line)

    def section(self, name):
        return self.sections.get(name)

    def body(self, name):
        lines = self.sections.get(name)
        return "\n".join(lines).strip() if lines is not None else None

    def table(self, name):
        """Baris tabel pertama di bagian `name` sebagai list of dict (kunci = judul kolom)."""
        rows, header = [], None
        for line in self.sections.get(name) or []:
            s = line.strip()
            if not s.startswith("|"):
                if header is not None:
                    break
                continue
            cells = [c.strip() for c in s.strip("|").split("|")]
            if header is None:
                header = cells
            elif all(re.fullmatch(r":?-{3,}:?", c) for c in cells if c):
                continue
            else:
                rows.append(dict(zip(header, cells + [""] * (len(header) - len(cells)))))
        return rows

    def bold(self, label):
        m = re.search(r"\*\*" + re.escape(label) + r":\s*(.+?)\s*\*\*", self.text)
        return m.group(1).strip() if m else None


class Usage(Exception):
    pass


class Result:
    def __init__(self, path):
        self.path, self.errors, self.warnings = str(path), [], []

    def err(self, msg):
        self.errors.append(msg)

    def warn(self, msg):
        self.warnings.append(msg)


def missing(v):
    return v is None or v.strip() in EMPTY


def need_head(doc, res, *keys):
    for k in keys:
        v = doc.head.get(k)
        if missing(v):
            res.err(f"kepala '{k}' wajib diisi")
        elif PLACEHOLDER.search(v):
            res.err(f"kepala '{k}' masih placeholder template: {v}")


def need_sections(doc, res, *names):
    for n in names:
        if doc.section(n) is None:
            res.err(f"bagian '## {n}' tidak ada")


def no_placeholders(doc, res):
    in_code = False
    for i, line in enumerate(doc.text.splitlines(), 1):
        if line.lstrip().startswith("```"):
            in_code = not in_code
            continue
        if in_code:
            continue
        m = PLACEHOLDER.search(line)
        if m:
            res.err(f"baris {i}: placeholder template belum diisi: {m.group(0)}")


def check_validasi(path):
    doc, res = Doc(path), Result(path)
    need_head(doc, res, "Tiket", "Role", "PR/MR", "Validator")
    need_sections(doc, res, "Keputusan", "Acceptance criteria", "Build dan lingkungan", "Data uji")
    no_placeholders(doc, res)
    decision = doc.bold("Keputusan")
    allowed = ("Siap diuji", "Siap dengan catatan", "Belum siap")
    if decision not in allowed:
        res.err(f"keputusan harus salah satu dari {', '.join(allowed)} (ditulis **Keputusan: ...**), ditemukan: {decision}")
    acs = doc.table("Acceptance criteria")
    if not acs:
        res.err("tabel Acceptance criteria kosong")
    unmeasurable = []
    for row in acs:
        ac, t = row.get("AC", ""), row.get("Terukur", "").lower()
        if t not in ("ya", "tidak"):
            res.err(f"{ac}: kolom Terukur harus 'ya' atau 'tidak', ditemukan '{row.get('Terukur', '')}'")
        if t == "tidak":
            unmeasurable.append(ac)
        if t == "ya" and missing(row.get("Hasil yang diharapkan")):
            res.err(f"{ac}: terukur tapi hasil yang diharapkan kosong")
    if unmeasurable and decision == "Siap diuji":
        res.err(f"AC tidak terukur ({', '.join(unmeasurable)}): keputusan tidak boleh 'Siap diuji'")
    if missing(doc.head.get("Build")) and decision != "Belum siap":
        res.err("Build belum ada: keputusan harus 'Belum siap'")
    return res


def check_report(path, final=False):
    doc, res = Doc(path), Result(path)
    need_head(doc, res, "Tiket", "Role", "Build", "Lingkungan", "Penguji")
    if doc.head.get("Test case disusun tanpa diff", "").lower() != "ya":
        res.err("kepala 'Test case disusun tanpa diff: ya' wajib (aturan independensi)")
    need_sections(doc, res, "Rekomendasi", "Acceptance criteria", "Test case", "Uji eksploratif", "Bug")
    no_placeholders(doc, res)
    base = doc.path.parent

    acs = {r.get("AC", ""): r for r in doc.table("Acceptance criteria") if r.get("AC")}
    tcs = doc.table("Test case")
    bugs = {r.get("Bug", ""): r for r in doc.table("Bug") if r.get("Bug")}
    if not acs:
        res.err("tabel Acceptance criteria kosong")
    if not tcs:
        res.err("tabel Test case kosong")

    by_ac = {ac: [] for ac in acs}
    kinds = set()
    for row in tcs:
        tc, ac = row.get("TC", "?"), row.get("AC", "")
        kind, result, proof = row.get("Jenis", "").lower(), row.get("Hasil", ""), row.get("Bukti", "")
        kinds.add(kind)
        if kind not in TC_KINDS:
            res.err(f"{tc}: Jenis harus salah satu dari {', '.join(TC_KINDS)}, ditemukan '{row.get('Jenis', '')}'")
        if result not in RESULTS:
            res.err(f"{tc}: Hasil harus Lulus, Gagal, atau Tertahan, ditemukan '{result}'")
        for a in [a.strip() for a in ac.split(",") if a.strip()] or [""]:
            if a not in acs:
                res.err(f"{tc}: AC '{a}' tidak ada di tabel Acceptance criteria")
            else:
                by_ac[a].append(row)
        if result == "Tertahan":
            if "alasan:" not in proof.lower():
                res.err(f"{tc}: Tertahan wajib menulis 'alasan: ...' di kolom Bukti")
        elif result in ("Lulus", "Gagal"):
            if missing(proof):
                res.err(f"{tc}: {result} wajib punya bukti")
            local = re.sub(r"https?://\S+", "", proof)
            for p in re.findall(r"[\w./-]+\.(?:png|jpe?g|gif|webp|mp4|mov|txt|log|json|zip|har)\b", local):
                if not (base / p).exists():
                    res.err(f"{tc}: berkas bukti tidak ditemukan: {p}")
        if result == "Gagal":
            refs = BUG_REF.findall(proof)
            if not refs:
                res.err(f"{tc}: Gagal wajib menyebut draft bug (mis. bug-1) di kolom Bukti")
            for n in refs:
                name = f"bug-{n}"
                if name not in bugs:
                    res.err(f"{tc}: {name} tidak ada di tabel Bug")
                if not (base / f"{name}.md").exists():
                    res.err(f"{tc}: berkas {name}.md tidak ditemukan di {base}")

    derived = {}
    for ac, rows in by_ac.items():
        if not any(r.get("Jenis", "").lower() == "normal" for r in rows):
            res.err(f"{ac}: tidak punya test case berjenis normal")
        results = [r.get("Hasil", "") for r in rows]
        derived[ac] = "Gagal" if "Gagal" in results else "Lulus" if "Lulus" in results else "Tertahan"
        written = acs[ac].get("Hasil", "")
        if written != derived[ac]:
            res.err(f"{ac}: hasil tertulis '{written}', seharusnya '{derived[ac]}' menurut test case-nya")
    if tcs and not kinds & {"batas", "gagal"}:
        res.warn("tidak ada test case berjenis batas atau gagal")

    severe = []
    for name, row in bugs.items():
        sev = row.get("Keparahan", "").split()[0] if row.get("Keparahan") else ""
        if sev not in SEVERITIES:
            res.err(f"{name}: Keparahan harus S1-S4, ditemukan '{row.get('Keparahan', '')}'")
        if sev in ("S1", "S2"):
            severe.append(name)
        if not (base / f"{name}.md").exists():
            res.err(f"{name}: berkas {name}.md tidak ditemukan di {base}")

    values = list(derived.values())
    expected = "Gagal" if "Gagal" in values else "Lolos" if values and all(v == "Lulus" for v in values) else "Tertahan"
    rec = doc.bold("Rekomendasi")
    if rec not in ("Lolos", "Gagal", "Tertahan"):
        res.err(f"rekomendasi harus Lolos, Gagal, atau Tertahan (ditulis **Rekomendasi: ...**), ditemukan: {rec}")
    elif rec != expected and not (rec == "Gagal" and severe):
        res.err(f"rekomendasi tertulis '{rec}', seharusnya '{expected}' menurut hasil AC")
    if rec == "Lolos" and severe:
        res.err(f"ada bug S1/S2 ({', '.join(severe)}): rekomendasi tidak boleh Lolos")

    explo = doc.body("Uji eksploratif") or ""
    if doc.section("Uji eksploratif") is not None and not re.search(r"Batas waktu:\s*\d+\s*menit", explo):
        res.err("Uji eksploratif wajib menulis 'Batas waktu: <n> menit'")

    if final:
        review = doc.body("Review") or ""
        if not re.search(r"Reviewer:.+Lolos review", review):
            res.err("laporan final wajib punya '## Review' dengan 'Reviewer: <Nama> (<Label>) — Lolos review'")
        m = re.search(r"Reviewer:\s*(.+?)\s*(?:\(|—|-)", review)
        tester = doc.head.get("Penguji", "")
        if m and tester and m.group(1).strip() and m.group(1).strip() in tester:
            res.err("Reviewer tidak boleh sama dengan Penguji")
    return res


def check_bug(path):
    doc, res = Doc(path), Result(path)
    need_head(doc, res, "Tiket", "TC", "Keparahan", "Build", "Lingkungan")
    sev = (doc.head.get("Keparahan") or "").split()
    if sev and sev[0] not in SEVERITIES:
        res.err(f"Keparahan harus S1-S4, ditemukan '{doc.head.get('Keparahan')}'")
    need_sections(doc, res, "Langkah", "Hasil", "Harapan", "Bukti")
    no_placeholders(doc, res)
    for name in ("Hasil", "Harapan", "Bukti"):
        if doc.section(name) is not None and not doc.body(name):
            res.err(f"bagian '## {name}' kosong")
    steps = doc.body("Langkah")
    if steps is not None and not re.search(r"^\s*1\.\s+\S", steps, re.M):
        res.err("bagian '## Langkah' wajib berupa daftar bernomor (1. ...)")
    return res


def check_signoff(path):
    doc, res = Doc(path), Result(path)
    need_head(doc, res, "Versi", "Build", "Tiket rilis")
    need_sections(doc, res, "Rekomendasi", "Tiket dalam rilis", "Regresi penuh", "Smoke live", "Risiko tersisa")
    no_placeholders(doc, res)
    rec = doc.bold("Rekomendasi rilis")
    allowed = ("Layak rilis", "Layak dengan risiko", "Tidak layak rilis")
    if rec not in allowed:
        res.err(f"rekomendasi rilis harus salah satu dari {', '.join(allowed)}, ditemukan: {rec}")
    blockers = []
    tickets = doc.table("Tiket dalam rilis")
    if not tickets:
        res.err("tabel Tiket dalam rilis kosong")
    for row in tickets:
        if row.get("Rekomendasi QA", "").startswith("Gagal"):
            blockers.append(f"tiket {row.get('KODE')} direkomendasikan Gagal")
    reg = doc.table("Regresi penuh")
    if not reg:
        blockers.append("regresi penuh kosong")
    for row in reg:
        if row.get("Hasil") not in RESULTS:
            res.err(f"regresi {row.get('Flow')}: Hasil harus Lulus, Gagal, atau Tertahan")
        elif row["Hasil"] != "Lulus":
            blockers.append(f"regresi {row.get('Flow')} {row['Hasil']}")
    smoke = doc.table("Smoke live")
    if not smoke:
        blockers.append("smoke live belum dijalankan")
    for row in smoke:
        if row.get("Hasil") != "Lulus":
            blockers.append(f"smoke {row.get('Flow')} {row.get('Hasil')}")
    if rec == "Layak rilis" and blockers:
        res.err("rekomendasi tidak boleh 'Layak rilis': " + "; ".join(blockers))
    if doc.section("Risiko tersisa") is not None and not doc.body("Risiko tersisa"):
        res.err("bagian '## Risiko tersisa' kosong (tulis 'Tidak ada' bila memang tidak ada)")
    if rec == "Layak dengan risiko" and re.fullmatch(r"(-\s*)?Tidak ada\.?", doc.body("Risiko tersisa") or ""):
        res.err("'Layak dengan risiko' wajib menyebut risikonya")
    return res


def check_ticket(folder, final=False):
    folder = Path(folder)
    if not folder.is_dir():
        raise Usage(f"bukan folder: {folder}")
    out = []
    if (folder / "qa-validasi.md").exists():
        out.append(check_validasi(folder / "qa-validasi.md"))
    if (folder / "qa.md").exists():
        out.append(check_report(folder / "qa.md", final))
    for b in sorted(folder.glob("bug-*.md")):
        out.append(check_bug(b))
    if not out:
        r = Result(folder)
        r.err("tidak ada qa-validasi.md, qa.md, atau bug-*.md")
        out.append(r)
    return out


def main(argv):
    args = [a for a in argv if a != "--final"]
    final = "--final" in argv
    cmds = {"validasi": check_validasi, "bug": check_bug, "signoff": check_signoff}
    if len(args) != 2 or args[0] not in (*cmds, "report", "ticket"):
        print(__doc__.split("Pemakaian:")[1].split("Exit:")[0].rstrip(), file=sys.stderr)
        return 2
    cmd, path = args
    try:
        if cmd == "ticket":
            results = check_ticket(path, final)
        elif cmd == "report":
            results = [check_report(path, final)]
        else:
            results = [cmds[cmd](path)]
    except Usage as e:
        print(f"qa-check: {e}", file=sys.stderr)
        return 2
    bad = 0
    for r in results:
        for w in r.warnings:
            print(f"{r.path}: peringatan: {w}")
        for e in r.errors:
            print(f"{r.path}: {e}")
        if r.errors:
            bad = 1
        else:
            print(f"{r.path}: ok")
    return bad


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
