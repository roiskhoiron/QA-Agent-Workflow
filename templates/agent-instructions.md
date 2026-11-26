# QA agent workflow
- Workflow QA (repo `qa-agent-workflow`) menguji tiket dari Ready To Review sampai rekomendasi Done. Agen QA tidak menulis kode produk, tidak membuat tiket bug atau mengembalikan tiket tanpa izin, dan tidak pernah memindah tiket ke Done.
- Platform tiket dan platform dokumentasi per project, dari memory project. Belum ada → tanya user dulu. Detail: `~/.agent-workflow/qa-repo/skills/_shared/rules.md`.
- Perintah (skill flow): `validate-tiket`, `develop-tiket`, `rilis-tiket`, `branch-manager`, `audit-issue`; dipanggil dengan cara skill di agenmu (mis. `/validate-tiket` di Claude Code). Peran: `~/.agent-workflow/qa-repo/agents/<peran>.md`.
- Test case disusun tanpa membaca diff atau rencana kerja; hasil uji workflow delivery tidak dipakai sebagai bukti.
- Keputusan per project tidak ditulis agen ke file instruksi project: agen memberi blok `## Catatan agen` untuk di-commit user.
