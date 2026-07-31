-- Use symbol footnote markers (*, †, ‡, §, ¶, ‖, then doubled) in HTML
-- output, matching the PDF, where `\renewcommand{\thefootnote}
-- {\fnsymbol{footnote}}` in layout.tex already makes footnotes symbols
-- instead of numbers. Pandoc's HTML writer always numbers footnotes
-- (1, 2, 3, ...) with no metadata option to change that, which reads as
-- though the footnote markers were reference-citation markers. This
-- filter replaces each Note element with a plain superscript symbol link
-- and builds the matching endnote list by hand, before the HTML writer
-- ever sees a Note element to auto-number.
--
-- HTML-only: PDF footnotes are left alone (layout.tex already handles
-- them), so this is only registered under `format: html:` in
-- _quarto.yml. Quarto compiles each chapter as its own separate document
-- for HTML, so numbering naturally restarts at 1 (i.e. symbol "*") for
-- every chapter with no extra bookkeeping needed here.

local symbols = { "*", "†", "‡", "§", "¶", "‖" }

local function symbol_for(n)
  local idx = ((n - 1) % #symbols) + 1
  local reps = math.floor((n - 1) / #symbols) + 1
  return symbols[idx]:rep(reps)
end

function Pandoc(doc)
  if FORMAT ~= "html" and FORMAT ~= "html4" and FORMAT ~= "html5" then
    return nil
  end

  local n = 0
  local footnotes = {}

  local wrapper = pandoc.Div(doc.blocks)
  wrapper = pandoc.walk_block(wrapper, {
    Note = function(note)
      n = n + 1
      local sym = symbol_for(n)
      local fnid = "fn-sym-" .. n
      local refid = "fnref-sym-" .. n
      table.insert(footnotes, { id = fnid, refid = refid, sym = sym, blocks = note.content })
      return pandoc.Link(
        { pandoc.Superscript({ pandoc.Str(sym) }) },
        "#" .. fnid,
        "",
        pandoc.Attr(refid, { "footnote-ref" }, { role = "doc-noteref" })
      )
    end,
  })
  doc.blocks = wrapper.content

  if n > 0 then
    local items = pandoc.Blocks({})
    for _, fn in ipairs(footnotes) do
      local blocks = fn.blocks
      local first = blocks[1]
      if first and (first.t == "Para" or first.t == "Plain") then
        first.content:insert(1, pandoc.Space())
        first.content:insert(1, pandoc.Superscript({ pandoc.Str(fn.sym) }))
      end
      local last = blocks[#blocks]
      local backlink = pandoc.Link(
        { pandoc.Str("↩︎") },
        "#" .. fn.refid,
        "",
        pandoc.Attr("", { "footnote-back" }, { role = "doc-backlink" })
      )
      if last and (last.t == "Para" or last.t == "Plain") then
        last.content:insert(backlink)
      else
        table.insert(blocks, pandoc.Para({ backlink }))
      end
      items:insert(pandoc.Div(blocks, pandoc.Attr(fn.id, {}, { role = "doc-endnote" })))
    end
    doc.blocks:insert(pandoc.HorizontalRule())
    doc.blocks:insert(pandoc.Div(
      items,
      pandoc.Attr("footnotes", { "footnotes", "footnotes-end-of-document" }, { role = "doc-endnotes" })
    ))
  end

  return doc
end
