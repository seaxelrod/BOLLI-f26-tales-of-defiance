-- highlight.lua: turns <YELLOW>…</YELLOW>, <GREEN>…</GREEN>, <ORANGE>…</ORANGE>,
-- <RED>…</RED>, <BROWN>…</BROWN>, <PURPLE>…</PURPLE>, <TEAL>…</TEAL> (or any
-- tags defined in colors.json) into background highlights in both HTML and PDF.
--
--   pandoc story.md --lua-filter=highlight.lua -o story.html -s
--   pandoc story.md --lua-filter=highlight.lua -H header.tex -o story.pdf
--
-- PDF: needs only xcolor (already loaded by your header.tex). Each word is put
-- in its own \colorbox, and the spaces between words are filled with coloured,
-- stretchable glue, so highlights wrap across lines and justify normally.
-- No soul package, so curly quotes and dashes cause no trouble.

local default_colors = {
  yellow = "FFF176",
  green  = "A5D6A7",
  orange = "FFCC80",
  red    = "EF9A9A",
  brown  = "D7CCC8",
  purple = "E1BEE7",
  teal   = "80CBC4",
}

local function load_colors()
  local script_dir = ""
  if PANDOC_SCRIPT_FILE then
    script_dir = PANDOC_SCRIPT_FILE:match("^(.*)[/\\]") or ""
  end

  local candidates = { "colors.json" }
  if script_dir ~= "" then
    table.insert(candidates, script_dir .. "/colors.json")
    table.insert(candidates, script_dir .. "/../colors.json")
  end
  table.insert(candidates, "../colors.json")

  for _, path in ipairs(candidates) do
    local fh = io.open(path, "r")
    if fh then
      local raw = fh:read("*a")
      fh:close()
      local ok, data = pcall(pandoc.json.decode, raw)
      if ok and type(data) == "table" then
        local list = data.colors or data
        local loaded = {}
        for _, item in ipairs(list) do
          if type(item) == "table" and item.tag and (item.hex or item.bg) then
            local name = tostring(item.tag):lower()
            local hex = tostring(item.hex or item.bg):gsub("^#", ""):upper()
            loaded[name] = hex
          end
        end
        if next(loaded) ~= nil then
          return loaded
        end
      end
    end
  end

  return default_colors
end

local colors = load_colors()

-- Fallback LaTeX preamble injected via header-includes.
-- Automatically ignored by Pandoc when -H header.tex is passed on the CLI.
local function build_latex_setup()
  local lines = {}
  for name, hex in pairs(colors) do
    table.insert(lines, string.format("\\providecolor{hl%s}{HTML}{%s}", name, hex))
  end
  table.sort(lines)
  table.insert(lines, "\\providecommand{\\HLw}[2]{\\leavevmode{\\setlength{\\fboxsep}{0pt}\\colorbox{#1}{\\strut #2}}}")
  table.insert(lines, "\\providecommand{\\HLs}[1]{\\leavevmode{\\color{#1}\\leaders\\vrule height\\ht\\strutbox depth\\dp\\strutbox\\hskip 0.333em plus 0.166em minus 0.111em}}")
  return table.concat(lines, "\n") .. "\n"
end

local latex_setup = build_latex_setup()

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
  if not name or not colors[name] then return nil end
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
