-- Render a small-font note directly below a table, flush against it with
-- no blank-line gap. Wrap the note in a fenced div right after the
-- captioned table:
--   ::: {.tblnote}
--   ^a^ Data from ...
--   :::
--
-- HTML: the div is left in place with its .tblnote class; custom.scss
-- styles it (font-size: .85em; margin-top: -0.8em).
-- LaTeX/PDF: the div is unwrapped and its contents wrapped in
-- \footnotesize with a negative \vspace, since a plain paragraph after a
-- longtable (these are non-float tables) would otherwise print at full
-- size with normal paragraph spacing below the table.
--
-- Ported from the standalone chapter's filters.lua so chapters converted
-- into this Quarto book keep the same table-note styling.

function Div(el)
  if not el.classes:includes("tblnote") then
    return nil
  end

  if FORMAT:match("latex") then
    el.content:insert(1, pandoc.RawBlock("latex",
      "\\vspace{-0.9em}\\begingroup\\footnotesize\\setlength{\\parindent}{0pt}"))
    el.content:insert(pandoc.RawBlock("latex", "\\par\\endgroup"))
    return el.content   -- unwrap: emit contents without the div wrapper
  end

  return el             -- HTML: leave the div for CSS to style
end
