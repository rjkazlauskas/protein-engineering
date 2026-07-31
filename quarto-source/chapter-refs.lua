-- Run citeproc separately for each chapter instead of once for the whole
-- book.
--
-- Quarto/pandoc books render every chapter into a single combined
-- document for PDF output, so a single whole-document citeproc pass
-- numbers citations continuously across chapters (chapter 2 continuing
-- from wherever chapter 1 left off) and fills every chapter's
-- bibliography div with the complete book-wide reference list, rather
-- than that chapter's own list starting at 1.
--
-- This filter splits the document into chapters (each top-level Header)
-- and runs `pandoc.utils.citeproc()` on each chapter's blocks
-- independently, so each chapter gets its own citation numbering and its
-- own scoped bibliography. Quarto's automatic citeproc pass must be
-- disabled (`citeproc: false` in _quarto.yml) so it doesn't run a second,
-- whole-document pass afterward and undo this.
--
-- Must run `at: post-quarto` (see _quarto.yml): `@fig-x`/`@tbl-x`/
-- `@eq-x`/`@sec-x` crossref labels parse as ordinary Cite nodes until
-- Quarto's own crossref filter resolves them into numbered links. If
-- this filter's citeproc() call runs before that resolution, citeproc
-- treats every crossref label in the document as an unresolved
-- bibliographic citation and logs a "citation X not found" warning for
-- each one (harmless — the crossref itself still resolves correctly
-- afterward — but it drowns out real warnings in the render log).
-- Running after Quarto's own filters means only genuine `[@citekey]`
-- citations are still Cite nodes by the time this runs.
--
-- Each chapter's qmd file marks where its bibliography goes with
-- `::: {#chapter-bibliography} :::` rather than pandoc's usual
-- `::: {#refs} :::`. That's deliberate: for HTML book output, Quarto has
-- a separate, hardcoded post-render step (bookBibliographyPostRender)
-- that detects any `::: {#refs} :::` div (by scanning the raw qmd source
-- for that literal pattern, before any filters run), merges every
-- chapter's citations into one book-wide bibliography, injects it into
-- whichever chapter's page happened to contain the first such div, and
-- hides the `#refs` div on every other page. That is the opposite of
-- what per-chapter bibliographies need, and there is no metadata switch
-- to turn it off. Using a differently-named id avoids that detection.
-- This filter renames the div to `refs` internally (citeproc only
-- recognizes that exact id) just before calling citeproc, so citeproc
-- still finds and fills it.

local function split_into_chapters(blocks)
  local chapters = {}
  local current = {}
  for _, b in ipairs(blocks) do
    if b.t == "Header" and b.level == 1 and #current > 0 then
      table.insert(chapters, current)
      current = {}
    end
    table.insert(current, b)
  end
  if #current > 0 then
    table.insert(chapters, current)
  end
  return chapters
end

local function use_refs_id(blocks)
  for _, b in ipairs(blocks) do
    if b.t == "Div" and b.identifier == "chapter-bibliography" then
      b.identifier = "refs"
    end
  end
end

function Pandoc(doc)
  local chapters = split_into_chapters(doc.blocks)
  local new_blocks = pandoc.Blocks({})
  for _, chapter_blocks in ipairs(chapters) do
    use_refs_id(chapter_blocks)
    local chapter_doc = pandoc.Pandoc(pandoc.Blocks(chapter_blocks), doc.meta)
    chapter_doc = pandoc.utils.citeproc(chapter_doc)
    for _, b in ipairs(chapter_doc.blocks) do
      new_blocks:insert(b)
    end
  end
  doc.blocks = new_blocks
  return doc
end
