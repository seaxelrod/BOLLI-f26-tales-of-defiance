--  call pandoc with: --lua-filter /Users/axelrod/.local/bin/toc-if-headings.lua

local toc_depth = 3
local has_toc_headers = false

function Meta(m)
  -- Read `toc-depth` from metadata/CLI, defaulting to 3
  if m['toc-depth'] then
    local val = tonumber(pandoc.utils.stringify(m['toc-depth']))
    if val then
      toc_depth = val
    end
  end
  return m
end

function Header(el)
  -- Check if any header level falls within the TOC threshold
  if el.level <= toc_depth then
    has_toc_headers = true
  end
end

function Doc(doc)
  -- If no headers within the toc-depth exist, disable the TOC
  if not has_toc_headers then
    doc.meta.toc = false
    doc.meta['table-of-contents'] = false
  end
  return doc
end

return {
  { Meta = Meta },
  { Header = Header },
  { Doc = Doc }
}
