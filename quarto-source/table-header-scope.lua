-- Add scope="col" to every table header cell in HTML output. Pandoc's
-- HTML writer emits <th> elements with no scope attribute, which makes
-- screen readers fall back to guessing whether a header applies to a
-- column or row instead of being told directly (WCAG 1.3.1). Every table
-- in this book has header cells only in the header row (none in the
-- first column of the body), so scope="col" is always correct here.
--
-- Must run `at: post-quarto` (see _quarto.yml): Quarto's own crossref
-- filter reconstructs the first table's head row when it injects the
-- numbered caption, which silently discards attributes set by a filter
-- that ran before it. Running after Quarto's built-in filters avoids
-- that clobbering.
--
-- HTML-only: the scope attribute has no meaning in PDF/LaTeX output, so
-- this is only registered under `format: html:` in _quarto.yml.

function Table(tbl)
  if not quarto.doc.is_format("html") then
    return nil
  end

  for _, row in ipairs(tbl.head.rows) do
    for _, cell in ipairs(row.cells) do
      cell.attr.attributes["scope"] = "col"
    end
  end

  return tbl
end
