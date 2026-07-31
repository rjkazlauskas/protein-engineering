-- Bold in-text "Figure X.X" / "Table X.X" cross-reference mentions in the
-- PDF (e.g. "...as shown in Figure 9.1." where the reader wrote
-- `@fig-codon_bias`). Figure/table CAPTION labels are already bold via
-- `\captionsetup{labelfont=bf}` in layout.tex -- this filter only handles
-- the separate case of a resolved crossref appearing in running prose.
--
-- Quarto's own crossref filter (which has already run by the time any
-- `at: post-quarto` filter sees the document) expands `@fig-x`/`@tbl-x` for
-- LaTeX into a literal `Str("Figure"), Str(" "), RawInline("latex",
-- "\ref{fig-x}")` run -- there is no wrapping node to target, so this looks
-- for that exact three-inline sequence and wraps it in a Strong (renders as
-- \textbf{Figure~\ref{fig-x}}). Equation/section crossrefs ("Equation",
-- "section") are deliberately left alone since only Figure/Table were asked
-- for.
--
-- LaTeX/PDF only: HTML crossrefs are already `<a class="quarto-xref">` and
-- are bolded instead with a plain CSS rule in custom.scss, since HTML fills
-- in the crossref number after Lua filters run (this filter would see only
-- an unresolved placeholder).

function Inlines(inlines)
  if not FORMAT:match("latex") then
    return nil
  end

  local out = pandoc.Inlines({})
  local i = 1
  while i <= #inlines do
    local a, b, c = inlines[i], inlines[i + 1], inlines[i + 2]
    local isLabel = a and a.t == "Str" and (a.text == "Figure" or a.text == "Table")
    -- Quarto's LaTeX crossref expansion puts a connector inline between the
    -- label and the \ref (an empty Str in practice, but check loosely for
    -- Str/Space/SoftBreak so this doesn't silently stop matching if that
    -- ever changes) before the raw \ref{fig-x}/\ref{tbl-x}.
    local isConnector = b and (b.t == "Str" or b.t == "Space" or b.t == "SoftBreak")
    local isRef = c and c.t == "RawInline" and c.format == "latex"
      and (c.text:match("^\\ref{fig%-") or c.text:match("^\\ref{tbl%-"))

    if isLabel and isConnector and isRef then
      out:insert(pandoc.Strong({ a, b, c }))
      i = i + 3
    else
      out:insert(a)
      i = i + 1
    end
  end
  return out
end
