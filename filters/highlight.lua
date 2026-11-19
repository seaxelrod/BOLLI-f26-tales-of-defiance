-- highlight.lua: turns <YELLOW>…</YELLOW>, <ORANGE>…</ORANGE>, <GREEN>…</GREEN>
-- into background highlights in both HTML and PDF.
--
--   pandoc story.md --lua-filter=highlight.lua -o story.html -s
--   pandoc story.md --lua-filter=highlight.lua -H header.tex -o story.pdf
--
-- PDF: needs only xcolor (already loaded by your header.tex). Each word is put
-- in its own \colorbox, and the spaces between words are filled with coloured,
-- stretchable glue, so highlights wrap across lines and justify normally.
-- No soul package, so curly quotes and dashes cause no trouble.

local colors = {
  yellow = "FFF176",
  orange = "FFCC80",
  green  = "A5D6A7",
}

-- Fallback LaTeX preamble injected via header-includes.
-- Automatically ignored by Pandoc when -H header.tex is passed on the CLI.
local latex_setup = [[
\providecolor{hlyellow}{HTML}{FFF176}
\providecolor{hlorange}{HTML}{FFCC80}
\providecolor{hlgreen}{HTML}{A5D6A7}
\providecommand{\HLw}[2]{\leavevmode{\setlength{\fboxsep}{0pt}\colorbox{#1}{\strut #2}}}
\providecommand{\HLs}[1]{\leavevmode{\color{#1}\leaders\vrule height\ht\strutbox depth\dp\strutbox\hskip 0.333em plus 0.166em minus 0.111em}}
]]

local function tag(el)
  if el.t ~= "RawInline" or not el.format:match("html") then return nil end
  local close, name = el.text:match("^<(/?)(%a+)%s*>$")
  if name and colors[name:lower()] then
    return name:lower(), close == "/"
  end
end

-- Pair up opening and closing tags within each list of inlines.
local function pair_tags(inlines)
  local out, stack = pandoc.List(), {}
  for _, el in ipairs(inlines) do
    local name, closing = tag(el)
    if name and not closing then
      table.insert(stack, { name = name, content = pandoc.List() })
    elseif name and closing and #stack > 0 and stack[#stack].name == name then
      local top = table.remove(stack)
      -- drop spaces/line breaks just inside the tags
      local function blank(x) return x and (x.t == "Space" or x.t == "SoftBreak") end
      while blank(top.content[1]) do top.content:remove(1) end
      while blank(top.content[#top.content]) do top.content:remove(#top.content) end
      local span = pandoc.Span(top.content, { class = "hl-" .. name })
      if #stack > 0 then stack[#stack].content:insert(span) else out:insert(span) end
    elseif #stack > 0 then
      stack[#stack].content:insert(el)
    else
      out:insert(el)
    end
  end
  -- Unclosed tag: keep its text, drop the highlight.
  for _, open in ipairs(stack) do out:extend(open.content) end
  return out
end

-- Let a highlight run across several paragraphs: close any tag still open at
-- the end of a paragraph and reopen it at the start of the next one.
local function span_paragraphs(blocks)
  local stack = {}
  local function open_tags()
    local l = pandoc.List()
    for _, name in ipairs(stack) do l:insert(pandoc.RawInline("html", "<" .. name .. ">")) end
    return l
  end
  for _, b in ipairs(blocks) do
    if b.t == "Para" or b.t == "Plain" then
      local content = open_tags()
      for _, el in ipairs(b.content) do
        content:insert(el)
        local name, closing = tag(el)
        if name and not closing then
          table.insert(stack, name)
        elseif name and closing and #stack > 0 and stack[#stack] == name then
          table.remove(stack)
        end
      end
      for i = #stack, 1, -1 do content:insert(pandoc.RawInline("html", "</" .. stack[i] .. ">")) end
      b.content = content
    end
  end
  return blocks
end

local function raw(s) return pandoc.RawInline("latex", s) end

-- Box every word; fill every space with coloured glue.
local boxed
boxed = function(inlines, color)
  return pandoc.Inlines(inlines):walk({
    traverse = "topdown",
    -- a highlight nested inside another keeps its own colour
    Span = function(s)
      local inner = (s.classes[1] or ""):match("^hl%-(%a+)$")
      if inner then return boxed(s.content, "hl" .. inner), false end
    end,
    Str = function(s)
      return { raw("\\HLw{" .. color .. "}{"), s, raw("}") }
    end,
    Space = function() return raw("\\HLs{" .. color .. "}") end,
    SoftBreak = function() return raw("\\HLs{" .. color .. "}") end,
    Quoted = function(q)
      local open, close = "``", "''"
      if q.quotetype == "SingleQuote" then open, close = "`", "'" end
      local out = pandoc.List({ raw("\\HLw{" .. color .. "}{" .. open .. "}") })
      out:extend(boxed(q.content, color))
      out:insert(raw("\\HLw{" .. color .. "}{" .. close .. "}"))
      return out, false
    end,
  })
end

local function Span(span)
  local name = (span.classes[1] or ""):match("^hl%-(%a+)$")
  if not name then return nil end
  if FORMAT:match("latex") or FORMAT:match("beamer") then
    -- highlight_pdf.py sets HL_PDF_PLAIN: leave the text plain, it adds
    -- real PDF highlight annotations afterwards.
    if os.getenv("HL_PDF_PLAIN") then return span.content end
    return boxed(span.content, "hl" .. name), false
  elseif FORMAT:match("html") then
    span.attributes.style = "background-color:#" .. colors[name]
    return span
  end
end

local function Pandoc(doc)
  if FORMAT:match("latex") or FORMAT:match("beamer") then
    local header = doc.meta["header-includes"]
    if not header then
      header = pandoc.MetaList{}
    elseif header.t ~= "MetaList" then
      header = pandoc.MetaList{header}
    end
    table.insert(header, pandoc.MetaBlocks{pandoc.RawBlock("latex", latex_setup)})
    doc.meta["header-includes"] = header
  end
  return doc
end

return {
  { Blocks = span_paragraphs },
  { Inlines = pair_tags },
  { traverse = "topdown", Span = Span },
  { Pandoc = Pandoc },
}
