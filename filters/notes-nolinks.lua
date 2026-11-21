-- notes-nolinks.lua: keep link text in presenter notes, but drop the links.
--
-- Why: with Beamer notes on a second screen (pgfpages), hyperlinks inside
-- notes are not moved with the notes. They land on top of the slide itself,
-- so clicking a quote on the slide can open a notes link instead.
--
--   pandoc deck.md -t beamer --lua-filter=notes-nolinks.lua ...
--
-- Only ::: notes blocks are changed. Links on the slides are untouched.

return {
  {
    Div = function(div)
      if div.classes:includes("notes") then
        return div:walk({
          Link = function(link) return link.content end,
        })
      end
    end,
  },
}
