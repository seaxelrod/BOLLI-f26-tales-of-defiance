-- prefix-links.lua
-- Prepend a base website URL to relative links in PDF output,
-- accounting for documents located in subdirectories.

local base_url = "https://seaxelrod.github.io/BOLLI-f26-tales-of-defiance/"

if not base_url:match("/$") then
  base_url = base_url .. "/"
end

local doc_dir = ""

-- Normalizes path segments to resolve "." and ".." cleanly
local function normalize_path(path)
  local segments = {}
  for seg in path:gmatch("[^/]+") do
    if seg == "." then
      -- skip current directory reference
    elseif seg == ".." then
      if #segments > 0 and segments[#segments] ~= ".." then
        table.remove(segments)
      else
        table.insert(segments, "..")
      end
    else
      table.insert(segments, seg)
    end
  end
  return table.concat(segments, "/")
end

return {
  {
    Meta = function(meta)
      -- Read doc_dir passed from Pandoc CLI (-M doc_dir=...) or environment
      local d = meta.doc_dir and pandoc.utils.stringify(meta.doc_dir) or os.getenv("DOC_DIR")
      if d and d ~= "" and d ~= "." then
        -- Strip any leading './' and trailing slashes
        doc_dir = d:gsub("^%./", ""):gsub("/+$", "")
      else
        doc_dir = ""
      end
      return meta
    end
  },
  {
    Link = function(el)
      local target = el.target

      -- Skip:
      -- 1. Internal anchors starting with '#' (e.g., #notes)
      -- 2. Protocols like http://, https://, ftp://
      -- 3. mailto: links
      if not (target:match("^#") or target:match("^%a+://") or target:match("^mailto:")) then
        -- Separate path from any query parameters or hash fragments (?page=... or #anchor)
        local path, suffix = target:match("^([^#?]*)(.*)$")

        if path:match("^/") then
          -- Root-relative link (/index.html): strip leading slash, do NOT prepend doc_dir
          path = normalize_path(path:gsub("^/", ""))
        else
          -- Subdirectory-relative link (notes.html or ../syllabus.html)
          path = path:gsub("^%./", "")
          if doc_dir ~= "" then
            path = normalize_path(doc_dir .. "/" .. path)
          else
            path = normalize_path(path)
          end
        end

        el.target = base_url .. path .. suffix
      end

      return el
    end
  }
}
