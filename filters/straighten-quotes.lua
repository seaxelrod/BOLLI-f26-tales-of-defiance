-- Replaces smart quotes with straight ASCII quotes
local function straighten(text)
  text = text:gsub("‘", "'")
  text = text:gsub("’", "'")
  text = text:gsub("“", '"')
  text = text:gsub("”", '"')
  return text
end

-- Apply to inline code (`...`)
function Code(el)
  el.text = straighten(el.text)
  return el
end

-- Apply to fenced or indented code blocks
function CodeBlock(el)
  el.text = straighten(el.text)
  return el
end

-- Apply to the URL string inside links
function Link(el)
  el.target = straighten(el.target)
  return el
end
