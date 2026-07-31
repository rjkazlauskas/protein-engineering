# Protein Engineering textbook — Quarto book project

This is a working Quarto book project converted from your Markdown/LaTeX
source. It builds successfully to both HTML and PDF. Chapters 1–6 and 9 are
converted; 7 and 8 are "In revision" placeholders holding their chapter
numbers until you're ready to convert them.

**If you're picking this project back up to add or edit a chapter, read the
next section before doing anything else.**

### Hard requirements — check every one of these, every time

- Chapter markdown sources live in `/Users/romas/Documents/project_support/on_hold/Prot_Eng_Textbook/`, one folder per chapter, named by chapter number (e.g. `Prot_Eng_7_Reactivity/`). All HTML/PDF output is built here, in `Quarto_Prot_Engineer/textbook/` — never in the source chapter's own folder.
- The HTML build must be screen-reader accessible (heading structure, `fig-alt` on every figure, table header `scope`, skip link, symbol footnotes — see "Accessibility audit" below). The PDF does **not** need to be accessible (see the scope decision in that same section for why).
- Before building, always copy the current `/Users/romas/Zotero/rjk_refs.bib` over this folder's `rjk_refs.bib` — never build against a possibly-stale local copy.
- `**Summary.**` at the start of each chapter must render bold in both HTML and PDF, exactly as it's marked in the markdown. (This depends on the static-font fix under "Known book-wide fixes" — if bold ever silently stops working again, check there first.)
- Every in-text "Figure X.X" / "Table X.X" mention must render bold in both HTML and PDF, for every chapter (see `bold-figtbl-xref.lua` / `bold-caption-labels.html` / the CSS rule under "Known book-wide fixes").
- **The copyright line must be copied verbatim from the source markdown — word for word, never composed, paraphrased, or assumed from memory or from what an earlier session's copy said.** The wording after "All rights reserved." varies (some chapters say "Last revised: <Month Year>", chapter 9's has said both "Last revised: March 2026." and, after the source was edited later, "Last updated July 2026." — these are genuinely different strings, not equivalent phrasings) and it changes over time as the author edits the source. Whatever the *current* source file literally says is what belongs in the qmd and in the rendered output, in both HTML and PDF — nothing more, nothing less, nothing reworded. This has actually broken once already: chapter 9's qmd went stale after the source was updated post-conversion and the copyright line wasn't re-synced. Every session that touches a chapter — not just new conversions — must re-check this line against the current source with:
  ```bash
  for n in 1 2 3 4 5 6 9; do
    diff <(grep -m1 '^©' ../../Prot_Eng_${n}_*/*.md) <(grep -m1 '^©' chapter${n}.qmd) && echo "chapter $n: OK"
  done
  ```
  Any diff output means the qmd is stale and must be updated to match the source exactly, not edited to something that "looks right."
- **Check for stray literal `$` in the rendered HTML/PDF text.** All math is written in markdown enclosed in `$...$`/`$$...$$`; correctly-processed math never leaves a literal `$` in the output — any `$` that survives into rendered text/PDF means a math-mode escaping error (unmatched `$`, a `$` meant literally but not escaped as `\$`, etc.) and must be flagged for correction, not silently fixed by guessing. Check with (adjust the file list to whatever was just built):
  ```bash
  grep -o '\$' _book/chapterN.html
  pdftotext -layout _book/Protein-Engineering.pdf - | grep -n '\$'
  ```
  A hit doesn't automatically mean an error — a legitimate use would be a literal dollar amount (e.g. "$50") — but every hit needs to be looked at and reported.

## Adding a new chapter

Read this whole section before starting work on a new chapter. It captures
conventions and hard-won bug fixes from converting chapter 9
(`../Prot_Eng_9_Intro_Dir_Evol/9_Intro_Dir_Evol.md` → `chapter9.qmd`) so the
same mistakes don't get repeated. The "Conversion history" section further
down has the detailed log of what was fixed for chapters 1–6 and 9 if you
need the full story behind any of the points below.

Each standalone chapter source lives in its own sibling folder, e.g.
`../Prot_Eng_7_Reactivity/7_engineering_faster_enzymes.md`,
`../Prot_Eng_8_Selectivity/8_Engineering_selectivity.md`,
`../Prot_Eng_10_Mult_Subs/10_Mult_Subs.md` — each with its own
`figures/`, `figures_original/`, `filters.lua`, and `makefile` for the
standalone pandoc/LaTeX build. That standalone build is a *separate* pipeline
from this Quarto book; converting a chapter means porting its content here,
not touching its own build.

### Before starting

1. **Sync the bibliography.** Copy `/Users/romas/Zotero/rjk_refs.bib` over
   this folder's `rjk_refs.bib` — the copy here goes stale between sessions.
   Then extract every citation key the new chapter uses and confirm each one
   exists in the fresh bib file *before* converting anything:
   ```bash
   grep -oE '@[a-zA-Z][a-zA-Z0-9_-]*[0-9]{4}[a-zA-Z0-9]*' NEW_CHAPTER_SOURCE.md | sort -u
   ```
   Check each key with `grep -q "^@[a-zA-Z]*{$key,"` against the bib file.
2. **Read the entire source file, not just a page of it.** If the file is
   long enough that Read paginates it, explicitly fetch every remaining page
   (`offset=`) — do not let a truncated read stand in for the ending. A
   truncated read caused a fabricated final sentence in chapter 9 that had to
   be caught and fixed after the fact by diffing against source.
3. **Check which chapter number the new content actually is.** The
   `chapters:` list in `_quarto.yml` currently runs
   `index, 1, 2, 3, 4, 5, 6, 7, 8, 9`, with 7 and 8 as `# In revision`
   placeholders. A placeholder still *consumes* its chapter number in
   Quarto's book numbering (it is **not** marked `{.unnumbered}`) —
   replacing `chapter7.qmd`'s placeholder text in place keeps it as chapter
   7; inserting a *new* chapterN.qmd file changes the count and shifts every
   later chapter's number. Decide up front whether you're replacing a
   placeholder or appending a new chapter at the end, and update
   `_quarto.yml`'s `chapters:` list accordingly.

### Converting the markdown

Syntax translations from the standalone pandoc-crossref source to Quarto's
native crossref syntax:

| Standalone source | Quarto qmd |
|---|---|
| `@fig:name`, `{#fig:name}` | `@fig-name`, `{#fig-name}` |
| `@tbl:name`, `{#tbl:name}` | `@tbl-name`, `{#tbl-name}` |
| `@eq:name`, `{#eq:name}` | `@eq-name`, `{#eq-name}` |
| `@sec:name`, `{#sec:name}` | `@sec-name`, `{#sec-name}` |
| `figures/foo.png` | `figures/chapterN/foo.png` |
| `::: {.tblnote}` ... `:::` | unchanged — `table-note.lua` handles it in both formats |
| `::: {#refs}` | `::: {#chapter-bibliography}` (required — see `chapter-refs.lua`'s comments for why) |
| `**Script N.n.**` | `**Code Block SN.n.**` (matches chapter 6's convention) |

**Watch for redundant crossref prefixes.** `@fig-x`/`@tbl-x` always expand to
include the word "Figure"/"Table" themselves. If the source literally writes
`Table @tbl:x` or `Fig @fig:x`, strip the literal word — otherwise it
prints doubled ("Table Table 9.3"). Search for this before converting:
```bash
grep -noE ".{15}@(fig|tbl|eq|sec):[A-Za-z_]+" SOURCE.md
```
Only lines with a literal "Figure"/"Table"/"Fig" immediately before the
match need fixing; bare references after a comma/paren are fine as-is.
(Chapters 2, 5, and 6 already have a few uncorrected instances of this bug —
not this chapter's problem to fix, but don't introduce new ones.)

**Cross-check in-text references to Supporting Information scripts/tables**
against their actual position — the chapter 9 source had "Script 9.2" in the
prose pointing at content that was actually Script 9.1, and vice versa. This
is a real, easy-to-miss authoring bug, not a formatting question — verify
each "Code Block SN.n" or "Table N.n in the supporting information" mention
actually matches by content, not just by assumed order.

### Figures

- Copy into `figures/chapterN/` (create the folder). Raster figures (PNG/JPG)
  copy across unchanged.
- Vector figures need both `.svg` (HTML) and `.pdf` (LaTeX) siblings, same
  basename — Quarto converts SVG→PDF automatically at PDF-render time using
  a bundled tool, but if the standalone source already has both, just copy
  both rather than relying on that.
- **Every figure needs a real `fig-alt` attribute** — not filename-derived,
  not omitted. Write it from actually looking at the image plus its caption,
  describing the scientific content a screen-reader user needs. This is a
  hard requirement carried over from the chapter 1–6 accessibility pass (see
  "Conversion history" below) — every existing chapter's figures have one,
  and Quarto does nothing with the old `short-alt` attribute some
  pre-Quarto source files use (it's silently inert; always use `fig-alt`).
- The book-wide caption-label bolding (`bold-caption-labels.html`) and
  in-text crossref bolding (`bold-figtbl-xref.lua` for PDF, the
  `a.quarto-xref[href^="#fig-"]`/`[href^="#tbl-"]` CSS rule for HTML) apply
  automatically to any new chapter's figures/tables — nothing extra needed
  per chapter.

### Structure to preserve per chapter

Match the existing chapters' section order exactly (see any of
`chapter1.qmd`–`chapter9.qmd` as a reference):

1. `# Title` (no numbering markup — Quarto numbers the book automatically)
2. Copyright line: `© 2023-2026 Romas Kazlauskas. All rights reserved. Last revised: <Month Year>.` — copy this verbatim from the source. If the source's copyright line does *not* include "Last revised: ...", don't add it; whatever's in the source markdown is exactly what should render, in both HTML and PDF.
3. `**Summary.**` and `**Key learning goals**` (bold, not headings)
4. Body content (`##`/`###` sections)
5. `## Glossary {-}` (definition-list syntax)
6. `## References {-}` then `::: {#chapter-bibliography}` `:::`
7. `## Supporting Information {-}` (Code Blocks, extra tables) — only if the chapter has one
8. `## Problems {-}`
9. `## Answers {-}` wrapped in:
   ````
   ```{=html}
   <details><summary>Click to show answers</summary>
   ```

   ```{=latex}
   \begingroup\color{gray}
   ```
   ...answers...
   ```{=html}
   </details>
   ```

   ```{=latex}
   \endgroup
   ```
   ````

### Known book-wide fixes — do not regress these

These were bugs discovered and fixed while adding chapter 9. They affect
*every* chapter, not just 9, so don't touch the following without
understanding why they're there first (each file has a comment explaining
the reasoning):

- **Bold text was silently broken across the entire PDF.** Root cause:
  `fonts/SourceSerif4/` only ships variable fonts, and xelatex/fontspec
  can't select a named "Bold" instance out of one automatically — every
  `\textbf` silently fell back to regular weight. Fixed by instantiating
  true static `SourceSerif4-{Regular,Bold,Italic,BoldItalic}-static.ttf`
  files with `fonttools varLib.instancer` and pointing `_quarto.yml`'s
  `mainfontoptions` at them directly. If you ever regenerate or replace
  these font files, re-run the instancer step and re-verify with:
  ```bash
  quarto render --to pdf   # then check the log for "Font shape .../b/n undefined"
  ```
  Zero such warnings is the bar. (A quick way to force-inspect the log:
  temporarily add `keep-tex: true` under `format: pdf:`, render, then run
  `xelatex -interaction=nonstopmode Protein-Engineering.tex` in this folder
  and `grep "Font shape.*undefined" Protein-Engineering.log` — remove
  `keep-tex` and the generated `.tex`/`.log`/`.aux` afterward.)
- **`table-note.lua`** gives `.tblnote` divs the small-font/tight-spacing
  treatment in both formats. Keep using `::: {.tblnote}` in new chapters,
  same as the standalone source's convention.
- **`bold-figtbl-xref.lua`** (PDF) and the CSS rule in `custom.scss` (HTML)
  bold in-text "Figure X.X"/"Table X.X" mentions. Equation/section
  crossrefs are deliberately left alone. If a new chapter introduces new
  crossref *types* beyond fig/tbl/eq/sec, these won't need updating — the
  matching is by content pattern (PDF) / href prefix (HTML), not per-chapter.
- **`bold-caption-labels.html`** bolds the "Figure X.X:"/"Table X.X:" prefix
  inside HTML captions client-side (Quarto fills in that number *after* Lua
  filters run, so no filter can do this — don't try to move this logic into
  a Lua filter, it won't see the resolved number).
- **Per-chapter bibliography scoping** (`chapter-refs.lua`) depends on every
  chapter using `::: {#chapter-bibliography}` instead of pandoc's usual
  `::: {#refs}`. Using `#refs` will silently merge the new chapter's
  citations into the book-wide bibliography and hide them from their own
  chapter page.
- **`table-header-scope.lua`** and **`symbol-footnotes.lua`** (HTML-only)
  need no per-chapter action — they apply automatically to every table and
  footnote in the book.

### Verifying before calling it done

1. Render **both formats together** with plain `quarto render` (no `--to`
   flag) — `--to html` or `--to pdf` alone wipes the *other* format's output
   from `_book/` since Quarto cleans the output-dir per format. Rendering
   without `--to` keeps both in `_book/` simultaneously, which is what you
   want for a review PDF/HTML pair.
2. Check the render log for anything beyond the known-benign warnings:
   - `Skipping SVG conversion for figures/... because output file already
     exists` — expected, harmless, appears for every already-converted
     figure.
   - `Duplicate note reference 'fn1'` — pre-existing, caused by chapter 2 and
     chapter 6 independently reusing the footnote label `fn1` (harmless,
     pandoc disambiguates). Don't introduce a *third* chapter reusing the
     same bare label like `fn1`/`fn2` — pick a chapter-specific label instead
     (e.g. `fnN-1`) to avoid adding to this pile.
   - Anything else (a real `ERROR`, a citation-not-found warning, a missing
     figure file) needs investigating before moving on.
3. **Diff the new chapter's prose against its source**, not just a visual
   skim — a visual read-through will not catch a dropped clause or a
   mistyped number. Normalize both files' crossref syntax and figure paths
   the same way, then diff:
   ```bash
   sed -E 's/@(fig|tbl|eq|sec):/@\1-/g; s/\{#(fig|tbl|eq|sec):([A-Za-z0-9_]+)/{#\1-\2/g; s#figures/#figures/chapterN/#g' \
     SOURCE.md > /tmp/src_norm.txt
   tail -n +N chapterN.qmd > /tmp/dst_norm.txt   # skip the title heading, N = its line count + 1
   diff -b /tmp/src_norm.txt /tmp/dst_norm.txt
   ```
   Every remaining diff line should be an intentional change you can name
   (fig-alt added, Table @tbl:x → @tbl-x, etc.) — if you can't explain a
   diff line, it's probably a transcription slip.
4. Spot-check the actual rendered pages (not just text extraction) for at
   least: chapter number in the running header, one figure, one table with
   a footnote, one in-text "Figure X.X" mention (bold), the reference list
   (real formatted entries, not "?"), and the Answers section (collapsed in
   HTML, gray in PDF).
5. Confirm citation counts are chapter-scoped, not book-wide — the new
   chapter's reference list should only contain sources it actually cites.
6. **Check for stray literal `$` characters** in both the rendered HTML and
   the PDF text — see "Hard requirements" at the top of this file. Any hit
   is a probable math-mode escaping error in the new chapter's source and
   needs to be flagged, not silently patched by guessing what was meant.
7. **Re-check every chapter's copyright line against its current source**,
   not just the one you're actively working on — the source markdown gets
   edited independently of this project, and a qmd only goes stale when
   nobody re-checks it. Use the diff loop under "Hard requirements" above.

### Communication preferences

- Generate a PDF for review before pushing anything to GitHub — don't push
  without being asked.
- `SendUserFile` has had a recurring zero-byte-download bug this project;
  always mention the direct local file path (`_book/Protein-Engineering.pdf`)
  as a fallback alongside sending it.

## What's in this folder

```
_quarto.yml                    Book configuration (chapters, HTML+PDF format)
index.qmd                      Book landing page / preface
chapter1.qmd .. chapter6.qmd    Converted chapters (see Conversion history below)
chapter7.qmd, chapter8.qmd      "In revision" placeholders (hold chapter numbers 7, 8)
chapter9.qmd                    Converted from 9_Intro_Dir_Evol.md
chapter-refs.lua                Pandoc filter: per-chapter citation numbering and bibliography
symbol-footnotes.lua            Pandoc filter (HTML only): footnote markers as symbols (*, †, ‡...)
table-header-scope.lua          Pandoc filter (HTML only): adds scope="col" to every table header cell
table-note.lua                  Pandoc filter (both formats): small-font/tight-spacing treatment for ::: {.tblnote} divs
bold-figtbl-xref.lua            Pandoc filter (PDF only): bolds in-text "Figure X.X"/"Table X.X" crossref mentions
bold-caption-labels.html        Client-side script (HTML, include-after-body): bolds the "Figure X.X:"/"Table X.X:" caption label
skip-link.html                  "Skip to main content" link, included at the top of every HTML page
custom.scss                     Site theme + the .tblnote and quarto-xref bold-crossref CSS rules
fonts/SourceSerif4/              Source Serif 4 font files — variable fonts as shipped, plus the
                                 static Regular/Bold/Italic/BoldItalic instances fontspec actually needs
                                 (see "Bold text was silently broken" above for why both exist)
figures/chapter1/ .. figures/chapter9/   Figures split by chapter, in web+PDF compatible formats
layout.tex                     LaTeX header, trimmed for book use
rjk_refs.bib                   Bibliography — re-sync from /Users/romas/Zotero/rjk_refs.bib before each new chapter
apa-numeric-superscript-brackets.csl   Citation style, saved locally
.github/workflows/publish.yml  Auto-builds and publishes to GitHub Pages on every push
```

## Steps to try this yourself

1. Unzip this folder into your book's GitHub repository (or into a fresh
   repository if you want to test in isolation first).
2. From Terminal, in that folder:
   ```
   git add .
   git commit -m "Add Quarto book chapter"
   git push
   ```
3. On GitHub, go to your repo → **Settings → Actions → General → Workflow
   permissions** → select **Read and write permissions** → Save. (One-time
   setup.)
4. Push triggers the build automatically. Watch progress under the
   **Actions** tab of your repo. When it finishes, your book is live at
   `https://<your-username>.github.io/<repo-name>/`.

If you want to preview locally on your Mac first (recommended), install
Quarto from quarto.org, then in this folder run `quarto preview`.

## Conversion history

Detailed log of what was found and fixed converting each chapter, kept for
reference — the "Adding a new chapter" section above is the actionable
summary; this is the full story behind each point in it.

### Chapters 1–6

- Renamed `.md` → `.qmd`, dropped the old per-chapter LaTeX page/section
  counters (Quarto numbers the whole book continuously, so those aren't
  needed anymore).
- Converted the old cross-reference syntax (`@fig:x`, `@tbl:x`, `@eq:x`)
  to Quarto's native syntax (`@fig-x`, `@tbl-x`, `@eq-x`).
- **Chapter 5 had 7 tables written as raw LaTeX** (`\begin{table}...`).
  Raw LaTeX is invisible in HTML output, so I rewrote all 7 as plain
  Markdown tables with proper captions and labels. I checked the PDF
  output page-by-page for these — they render correctly with the same
  numbering/caption style as before.
- **All EPS figures (9 in chapter 2, 18 in chapter 5) were reconverted
  using the epstool → Ghostscript → Inkscape pipeline** (same steps as
  `convert_eps.sh`: `epstool --copy --bbox` first to fix the bounding box,
  then `gs -dEPSCrop` to PDF, then Inkscape to SVG). The earlier
  direct-Ghostscript conversion left oversized bounding boxes on some
  figures (lots of blank margin); this pipeline fixes that.
- **Two of chapter 1's figures had the same oversized-bounding-box problem,
  even though they were already PDFs (not EPS)** —
  `cystathionine_methionine.pdf` and `tworoutestositagliptin.pdf` each had
  a full US-Letter page (612×792 pt) as their PDF page size, with the
  actual artwork occupying only a small region of it. Cropped both with
  `pdfcrop --margins 0` to fix. Worth checking any already-PDF figure in
  future chapters for the same issue (`gs -sDEVICE=bbox file.pdf`, compare
  to the PDF's `/MediaBox`) even when there's no `.eps` source to blame.
- **Figures are now split into `figures/chapter1/`, `figures/chapter2/`,
  `figures/chapter3/`, `figures/chapter4/`, and `figures/chapter5/`**
  instead of one flat folder, so it's clear which chapter each figure
  belongs to as more chapters are added.
- **Two of chapter 4's figures had the same oversized-bounding-box
  problem** — `1s01_His64_old.pdf` and `1s01_His64_new.pdf` each had a
  full US-Letter page as their PDF page size despite showing only a small
  crop of PDB-file text. Cropped both with `pdfcrop --margins 0`, same as
  chapter 1's fix above. Chapter 4's other 13 figures (4 of which had
  `.eps` sources) already had correctly-sized bounding boxes, so no
  reconversion was needed for those.
- **Stale-SVG bug: chapter 4's Figures 4.14–4.15 looked right in the PDF
  but were missing in the HTML.** Root cause: when I cropped
  `1s01_His64_old.pdf`/`1s01_His64_new.pdf` to fix their oversized
  bounding boxes (above), I only cropped the `.pdf` — the `.svg` next to
  it (which HTML actually displays) was left untouched, so its
  `viewBox` no longer matched the cropped PDF and the visible artwork
  ended up positioned/scaled wrong, effectively invisible at the
  figure's display width. The caption and `<img>` tag were both present
  and correct, which is what made this easy to miss without actually
  opening the HTML page and looking at the figure. Fixed by regenerating
  both `.svg`s from the already-cropped `.pdf`s with Inkscape; verified
  by opening each SVG directly and confirming it shows the right PDB
  coordinate excerpt (one labeled "HIS", one "HID", matching their
  captions).
- **Book-wide sweep for oversized/mismatched figure bounding boxes**,
  triggered by the Figure 4.14–4.15 report above. While checking whether
  the same *stale-SVG* pattern recurred elsewhere (it didn't — every
  other figure's SVG matched its PDF), I found two more, different
  instances of the *oversized-PDF* problem instead (same underlying issue
  as the chapter 1/4 fixes above, just not caught earlier because
  chapters 2 and 5 predate that check being part of the conversion
  process):
  - **Chapter 2's `met_to_ala.pdf` and `primers_met_to_ala.pdf`** were
    full uncropped US-Letter pages with their actual content occupying
    under 10% of the page area. Their `.svg` files were already correctly
    cropped (so HTML was fine), but the **PDF book** would have shown
    these two figures shrunk to a sliver of their frame — verified by
    rendering the actual book PDF page-by-page (pages 55 and 57) before
    and after the fix; both now display at a normal, legible size.
    Cropped both `.pdf`s with `pdfcrop --margins 0`; no SVG regeneration
    needed since those were already right.
  - **Chapter 5's `urea_unfold_data.pdf` and `urea_unfold_plot.pdf`**
    (the same two figures fixed for the `<embed>`/accessibility bug
    below) had the same issue — content occupying only 6–8% of an
    oversized page. Their `.svg`s (freshly generated via Inkscape) were
    already fine, but the underlying `.pdf`s were still uncropped.
    Cropped both the same way.
  - Checked every other figure PDF in the book (69 total) against its
    ink bounding box — no other instances found.
- **Chapter 3 has a wide 5-column table** (non-covalent interaction
  strengths) that the source wrapped in a raw-LaTeX `\begin{landscape}...
  \end{landscape}` block to rotate that one page sideways — kept as-is,
  since it's valid Pandoc raw LaTeX and works correctly in the PDF (I
  added the `lscape` package to `layout.tex`, which wasn't there before
  since no earlier chapter needed it; harmless no-op for the HTML build,
  where the table just renders normally, unrotated).
- Fixed one broken image-credit URL in chapter 5 that was already broken
  in the source file (a Wikipedia link with stray backslashes).
- **Chapter 6 was the least Quarto-adapted chapter converted so far**
  (closer in shape to the original chapters 2/5 than to 1/3/4), so it
  needed the full checklist:
  - A raw-LaTeX equation (`\begin{equation}\label{eq:improvement}...`)
    and a raw-LaTeX table (`\begin{table}...`, "Strategies to increase
    non-covalent interactions") were both invisible in HTML — converted
    to Quarto's native `$$...$$ {#eq-x}` and Markdown-table syntax.
  - The old print-book upside-down answers trick
    (`\rotatebox{180}{\begin{minipage}...}`) was replaced with the usual
    grayscale/collapsible treatment.
  - Three `\begin{lstlisting}...\end{lstlisting}` code blocks (one real
    Python script, two PyMOL command snippets) were converted to plain
    fenced code blocks (`` ```python `` / `` ``` ``) — raw LaTeX
    `lstlisting` environments render fine in the PDF but are silently
    dropped in HTML.
  - **Two pre-existing content bugs, unrelated to the Quarto conversion
    itself**, found and fixed while converting:
    - A citation key typo (`morinComputationalDesignEndo12011`) didn't
      match any entry in `rjk_refs.bib` — the correct key is
      `morinComputationalDesignEndo14betaxylanase2011`. Caught by the
      standard pre-render citation-key check; would otherwise have
      caused a silent "citation not found" warning and a missing
      in-text citation number.
    - Three places used a hardcoded `$^{18}$` (or, in one case, an
      unterminated `$^{18}` with no closing `$`, which would have
      corrupted math rendering for everything after it) instead of a
      real citation, referring to the Tinberg et al. paper. Replaced
      all three with `[@tinbergComputationalDesignLigandbinding2013]`
      so they render as a proper, numbered, hyperlinked citation
      matching the rest of the book instead of an inert "18".
- The CSL citation style file is now saved locally instead of fetched from
  zotero.org at build time — faster and more reliable builds.
- **Fixed a page-header bug**: `chapter2.qmd` and `chapter5.qmd` both had a
  leftover raw `\tableofcontents` LaTeX command at the very top (left over
  from the original conversion). Because it sat *inside* the chapter
  instead of in the book's actual front matter, it made the running page
  header read "Table of contents" on that chapter's first page and on
  every subsequent even-numbered page, instead of the chapter/section
  name. Removed the stray commands and let Quarto generate the table of
  contents itself (`toc: true` under the `pdf:` format) — it's now a
  proper front-matter section with correct roman-numeral page numbers, and
  page headers are correct throughout. (Chapter 1's source didn't have
  this particular leftover, but it's worth checking for on every new
  chapter — `grep -l tableofcontents *.qmd`.)
- **Your own preface**: `index.qmd` is the Preface chapter.
- **Fixed a sidebar-numbering bug you reported**: the Preface was showing
  up as "1" in the left sidebar, pushing every real chapter's number up
  by one. `index.qmd` had `numbered: false` in its YAML front matter,
  which isn't a real Quarto option — it was silently ignored. Quarto's
  actual mechanism (traced through its source) is to embed an
  `{.unnumbered}` class inside the `title:` string itself, written as a
  literal Pandoc heading: `title: "# Preface {.unnumbered}"` (the
  leading `# ` is required for Quarto to recognize and parse the
  attribute — a plain `title: "Preface {.unnumbered}"` doesn't work and
  instead prints the literal text into the title). Fixed in `index.qmd`;
  the sidebar now shows "Preface" with no number, and chapters 1–6 file
  in correctly starting from 1.
  - **While tracking this down I also found and fixed a real, unrelated
    numbering bug in the underlying PDF**: `chapter5.qmd` still had two
    leftover raw-LaTeX counter overrides from its Problems and
    Supporting Information sections (`\renewcommand{\thefigure}{P5....}`
    etc.) that were never removed during its original conversion (unlike
    chapters 1, 3, 4, and 6, which all had this fixed already). LaTeX
    counter overrides are global and don't reset between chapters, so
    once chapter 5's Problems section switched the document to "P5.1"
    style figure/table numbers, that numbering persisted into chapter 6
    for the rest of the book — chapter 6's tables and figures were
    showing as "Table P5.1" instead of "Table 6.1" in the **PDF only**
    (HTML was unaffected, since Quarto's HTML crossref numbering doesn't
    use LaTeX counters at all). Removed both leftover blocks from
    `chapter5.qmd`; verified chapter 5's own figures/tables still number
    correctly (Figure 5.1–5.24, continuous) and chapter 6's now show
    correctly as "Table 6.1", etc.
- **Per-chapter reference lists and citation numbering, in both PDF and
  HTML.** This took two separate fixes:
  - Quarto/Pandoc normally build PDF books as one combined document, so a
    single whole-document citation pass numbered citations continuously
    across chapters and dumped the *entire* book's bibliography into
    every chapter's reference list.
  - Separately, for HTML, Quarto has a hardcoded post-render step
    (`bookBibliographyPostRender`) that detects any chapter with a
    `::: {#refs} :::` div, merges *every* chapter's citations into one
    book-wide bibliography, injects it into whichever chapter's page
    happened to contain the first such div (chapter 2, in our case), and
    hides the `#refs` div — and therefore the reference list — on every
    other chapter's page (chapter 5 had no visible references at all).
    There's no metadata switch to turn this off.

  `chapter-refs.lua` (a Pandoc filter registered under both `html:` and
  `pdf:` in `_quarto.yml`) now runs citation processing separately per
  chapter, so chapter 1's reference list has only its own 33 sources,
  chapter 2's only its own 13, chapter 3's only its own 2, chapter 4's
  only its own 15, chapter 5's only its own 79, and chapter 6's only its
  own 19 — each numbered starting at 1 — matching the original textbook's
  per-chapter reference style, in both formats. To dodge Quarto's HTML
  consolidation step, each chapter's bibliography placeholder is now
  `::: {#chapter-bibliography} :::` instead of the usual `::: {#refs} :::`
  — the filter renames it internally right before handing it to citeproc.
  This is automatic for any future chapter, as long as it uses that same
  `::: {#chapter-bibliography} :::` placeholder (not `#refs`).
  - **Fixed a noisy-but-harmless warning you reported**: rendering to
    HTML logged a "Citeproc: citation fig-x not found" (or `tbl-`/`eq-`/
    `sec-`) warning for every single figure/table/equation/section
    cross-reference in the book. Cause: `chapter-refs.lua` was running
    *before* Quarto's own crossref filter had converted those `@fig-x`-
    style labels from raw citations into resolved numbered links —
    pandoc's markdown parser can't tell `@fig-x` apart from a genuine
    `@citekey` at that point, so citeproc treated every crossref label as
    an unresolved bibliographic citation. The crossrefs themselves always
    resolved correctly regardless (this was log noise, not a content
    bug), but it drowned out the log enough to hide a real warning if one
    ever showed up. Fixed by moving `chapter-refs.lua` to run after
    Quarto's own filters (`at: post-quarto` in `_quarto.yml`) — zero
    warnings now.
- **Chapter 5's answers are now grayscale, collapsible, and right-side up**,
  matching chapter 2's style. They previously used a raw-LaTeX
  `\rotatebox{180}{...}` trick (PDF-only, and printed the text upside
  down); replaced with the same `\color{gray}` (PDF) /
  `<details><summary>Click to show answers</summary>` (HTML) treatment
  used in chapter 2.
- **Footnote markers are symbols (\*, †, ‡...) in HTML too, matching the
  PDF.** `layout.tex` already made PDF footnotes symbols instead of
  numbers (`\fnsymbol{footnote}`), but Pandoc's HTML writer always numbers
  footnotes (1, 2, 3...) with no metadata switch to change that — which
  reads as though the footnote markers were reference-citation markers,
  since those are also numbered. `symbol-footnotes.lua` (HTML-only)
  replaces Pandoc's automatic footnote numbering with the same symbol
  sequence, before the HTML writer ever gets a chance to number them.
  Numbering restarts at `*` for each chapter automatically, since Quarto
  renders each chapter as its own HTML page.
- **PDF font is now Source Serif 4 instead of Minion Pro.** Minion Pro is
  a licensed Adobe font that can't be installed on GitHub's build
  servers, so the PDF build would have failed there. Source Serif 4 is
  open source (SIL Open Font License) and visually similar. The actual
  font files (plus their `OFL.txt` license) are bundled in
  `fonts/SourceSerif4/`, and the GitHub Actions workflow installs them on
  the runner before rendering. (See "Bold text was silently broken" in
  the "Adding a new chapter" section above — the variable-font files
  bundled here initially broke all bold text; static instances were added
  later to fix it.)
- **Every figure in chapters 1–6 now has real alt text** (80 figures
  total), generated from each figure plus its caption, focused on
  the scientific content a screen-reader user would need rather than
  visual appearance. Applied as Quarto's `fig-alt="..."` attribute on each
  image. Chapter 4's source already had `short-alt` text of the same
  quality/style as the rest of the book, so that was reused (renamed to
  `fig-alt`) rather than regenerated from scratch. Chapter 6's source had
  no alt text at all, so all 12 of its figures were generated from
  scratch, same as chapter 5.
  - **Important correction**: `short-alt` isn't an attribute Quarto
    actually does anything with — it's silently dropped into an inert
    `data-short-alt` attribute that no screen reader reads. The correct
    Quarto attribute is `fig-alt`. This means any `short-alt` attributes
    present in chapters 1–4 before this were never functioning for
    accessibility either — a pre-existing, silent bug. All of them (68
    total) were renamed to `fig-alt`.
  - **Accessibility scope decision: the HTML build is the accessible
    format for this book; the PDF is not being made accessible.**
    `fig-alt` doesn't reach the PDF at all — Quarto's LaTeX/PDF pipeline
    drops it, and the built PDF has no tag structure whatsoever (no
    `/StructTreeRoot`, no `/MarkInfo`), so it has no alt text and
    wouldn't pass a screen-reader accessibility check regardless. Making
    the PDF genuinely accessible (tagged PDF / PDF-UA) would need a
    different LaTeX engine (LuaLaTeX) plus experimental tagging packages
    — a much larger, separate effort. We're treating the PDF as a
    print/reference artifact and putting accessibility effort into HTML
    only.

### Accessibility audit (chapters 1–5, HTML build)

Checked against WCAG-style criteria — heading structure, table markup, link
text, color contrast, keyboard navigation, and figure/equation rendering —
by loading each chapter in a real browser and inspecting the actual DOM (not
just the source). Found and fixed four real issues, confirmed several other
things were already fine:

- **Two figures in chapter 5 were invisible to screen readers despite
  having `fig-alt` text.** `urea_unfold_data` and `urea_unfold_plot` were
  the only two figures in the whole book referenced by `.pdf` path
  instead of `.svg` in their qmd source (everywhere else, `.svg` is used
  so Quarto can pick the right format per output — SVG for HTML, PDF for
  LaTeX). Because the HTML build can't display a raw PDF as an `<img>`,
  Quarto fell back to `<embed>` — and `alt` isn't a valid attribute on
  `<embed>` per the HTML spec, so the alt text was silently ignored by
  screen readers, the same class of bug as the `short-alt` issue. Fixed
  by generating `.svg` versions with Inkscape (matching every other
  figure's pipeline) and changing the two image paths in `chapter5.qmd`
  to `.svg`. Zero `<embed>` figures remain anywhere in the book.
- **Chapter 5 skipped a heading level.** `### Key learning goals {-}` sat
  directly under the chapter's `#` title, skipping `##` — confusing for
  screen-reader users who navigate by heading level. Chapters 1–4 all use
  plain **bold text** for this line instead of a heading; chapter 5 was
  the only inconsistent one. Fixed by matching the established
  convention.
- **Two equations in chapter 5 showed "eq. ???" in HTML.** `FoldX_force_field`
  and `supercharge_GFP` used raw LaTeX `\label{}`/`\ref{}` for
  cross-referencing (which works in the PDF via native LaTeX, but pandoc
  doesn't resolve raw `\ref{}` for HTML — MathJax picked it up client-side
  and rendered an unresolvable "???" link, and also left a stray,
  keyboard-focusable-but-invisible link in the page). Converted both
  equations to Quarto's native `$$...$$ {#eq-x}` crossref syntax, which
  resolves correctly in both formats.
- **No table headers had a `scope` attribute anywhere in the book** (62
  `<th>` cells across 17 tables). Every table in the book has headers only
  in the header row (none in the first column), so `scope="col"` is
  unambiguously correct everywhere. Added `table-header-scope.lua`
  (HTML-only, registered `at: post-quarto` in `_quarto.yml` — it has to
  run after Quarto's own crossref filter, which rebuilds the first
  table's header row when it injects the numbered caption and would
  otherwise silently discard the `scope` attribute).
- **No way to skip the sidebar navigation.** Added a "Skip to main
  content" link (`skip-link.html`, via `include-before-body`) — invisible
  until it receives keyboard focus, then jumps straight to the chapter
  text.

**Checked and already fine, no changes needed:** color contrast (body text
~11.5:1, links ~8.6:1, both comfortably above the WCAG AA 4.5:1 minimum),
table caption association (`<figcaption>` + `aria-describedby`), math
equations (MathJax's invisible `<mjx-assistive-mml>` MathML), answer-key
contrast, page language (`lang="en"`), and zoom (no zoom-blocking viewport
meta).

The PDF was not checked for these same issues — only the HTML build is
being made accessible (see the scope decision above).

### Chapter 9 (this session)

- Converted `9_Intro_Dir_Evol.md` to `chapter9.qmd` following the syntax
  table above; verified line-by-line against source with the diff method
  in "Verifying before calling it done."
- Added `figures/chapter9/` (6 PNGs + one SVG/PDF pair) with `fig-alt` text
  written from the actual images.
- `chapter7.qmd`/`chapter8.qmd` added as "In revision" placeholders so
  chapter 9 lands on chapter number 9.
- Ported the standalone print-book pipeline's `.tblnote` small-font table
  footnote treatment into this Quarto project as `table-note.lua` (it
  didn't exist here before — chapter 3's existing table footnote had been
  plain, unstyled text).
- **Found and fixed a book-wide bug: bold text was silently not rendering
  anywhere in the PDF** (chapter summaries, "Key learning goals", answer
  labels, figure/table caption numbers — everything using `\textbf`).
  Root cause and fix described under "Known book-wide fixes" above. This
  was not something introduced this session — it affected chapters 1–6
  too, just unnoticed until chapter 9's "**Summary.**" was visibly not
  bold.
- **Added book-wide bolding of in-text "Figure X.X"/"Table X.X" mentions**
  (`bold-figtbl-xref.lua` for PDF, CSS + `bold-caption-labels.html` for
  HTML) — also applies to chapters 1–6, not just 9.
- **Added `fig-alt` to the Preface cover image** (`index.qmd`) — it had
  none before, the one accessibility gap left over from the chapters 1–6
  audit.
- Two content bugs in the chapter 9 source were found and fixed at your
  direction after review: the Supporting Information "Script N.n" labels
  didn't match their actual position (fixed by renumbering to match text
  flow), and the "Selected examples of site-saturation mutagenesis" table
  had placeholder/garbled data in several cells (you supplied the real
  content).
- **Ran a book-wide sweep for stray literal `$` in the rendered output**
  (the "Hard requirements" check above) and found three more pre-existing
  bugs, none from chapter 9:
  - **Chapter 3** had draft/scratch notes (an unfinished sentence, a
    placeholder equation `eq. x`) leaking into the HTML page. They were
    wrapped in `<!--- ... --->` (three dashes) instead of valid
    `<!-- ... -->` (two dashes), so pandoc wasn't recognizing it as a
    comment. Fixed the delimiter typo; content is now correctly hidden in
    both formats (confirmed it now appears only inside the actual HTML
    comment, invisible to a reader — a plain text search of the HTML
    source file will still show it there, that's expected and correct).
  - **Chapter 4's Table 4.1** (comparing the MM3 and AMBER force fields)
    was badly garbled in **both** HTML and PDF — a pandoc grid table gone
    out of column alignment (a trailing comma after a `$...$` in one cell
    shifted that row's column boundaries). Rebuilt as a plain pipe table;
    renders correctly in both formats now.
  - **Chapter 6** had two instances of `$\approx$` immediately followed by
    a digit (e.g. `$\approx$100-fold`) — this trips a pandoc heuristic
    that exists specifically to avoid misreading dollar amounts like
    "$5-$10" as math, so the closing `$` wasn't recognized and the actual
    math span ended up spanning way past where it should, leaving stray
    `$`/`$$` visible in the HTML. Fixed by adding a space
    (`$\approx$ 100-fold`) — meaning is unchanged, both formats now render
    "≈100-fold" correctly. While fixing this, also found and converted
    ~7 instances of raw LaTeX (`\textit{}`, `\textbf{}`, `\url{}`) in
    chapter 6's Problems/Answers/footnote content that were being
    **silently dropped entirely** from HTML (not just unstyled — the
    words and links were missing, e.g. "SwissDock calculations yield ,
    that is..." was missing "_association constants_", and the SwissDock
    tool URL wasn't a clickable link) — same underlying issue as the
    `lstlisting` bug documented for chapter 6's original conversion above,
    just in content added afterward that never went through that cleanup.
    Converted to native markdown (`_.._`, `**..**`, `<url>`); verified all
    the missing words/links are now present in the HTML.
  - **Not fixed — needs your action in Zotero, not something fixable
    here**: the Cheon et al. 2004 reference (cited in chapter 9) has
    corrupted text in its **title field in `rjk_refs.bib` itself** —
    `\textbraceleft\$\textbackslash beta\$\textbraceright` instead of a
    plain "β" — so it prints literally as "($\beta$/$\alpha$)₈-barrel
    protein" in the reference list, in both formats (citeproc renders
    bibliography titles as plain text, never through a math renderer, so
    any `$...$` in a title field always shows up literally like this).
    Needs correcting in the Zotero item itself; any fix to the local copy
    here would be overwritten on the next bib sync.

## Two things that need your input

**1. Two broken reference links in chapter 5.** In the "consensus
sequence" section, `\href{}{Consensus Finder}` and `\href{}{FireProt}`
have empty URLs in your original source (pre-existing, not something
introduced during conversion). Left as plain text rather than guessing the
URLs — worth a quick fix when you have the actual links handy.

**2. A few LaTeX packages (`multirow`, `movie15`, `framed`) weren't
installed in this Mac's TeX Live setup** (it's the "basic" scheme, which
doesn't include everything) — they had to be copied in from another TeX
Live install on this machine to get the PDF to build locally (`framed` was
needed once chapter 3 added a Python code listing — `listings` pulls it in
for the background shading). GitHub's build servers normally use a full
TeX Live install and should already have all three, so this is unlikely
to affect the GitHub Actions build, but flagging it in case you hit a
"file not found" error for any of them when building locally.
