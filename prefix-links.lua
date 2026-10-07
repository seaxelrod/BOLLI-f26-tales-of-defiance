-- prefix-links.lua
-- Prepend a base website URL to relative links in PDF output

local base_url = "https://seaxelrod.github.io/BOLLI-f26-tales-of-defiance/"

-- Ensure base_url ends with a trailing slash
if not base_url:match("/$") then
  base_url = base_url .. "/"
end

function Link(el)
  local target = el.target

  -- Skip:
  -- 1. Internal anchors starting with '#' (e.g. #notes)
  -- 2. Protocols like http://, https://, ftp://
  -- 3. mailto: links
  if not (target:match("^#") or target:match("^%a+://") or target:match("^mailto:")) then
    -- Strip any leading './' or '/'
    target = target:gsub("^%./", ""):gsub("^/", "")
    
    el.target = base_url .. target
  end

  return el
end
