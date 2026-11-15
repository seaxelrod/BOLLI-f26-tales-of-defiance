-- Helper function to convert Pandoc AST elements to plain text
local stringify = pandoc.utils.stringify

-- This function intercepts every Paragraph in the document
function Para(el)
  local text = stringify(el)
  
  -- Check if the paragraph starts with exactly "!include "
  if text:match("^!include%s+") then
    
    -- Extract the filename by removing the "!include " prefix
    local filename = text:gsub("^!include%s+", "")
    -- Trim any accidental trailing whitespace
    filename = filename:match("^%s*(.-)%s*$")
    
    -- Attempt to open and read the target file
    local file = io.open(filename, 'r')
    if file then
      local content = file:read('*a')
      file:close()
      
      -- Parse the included file's text as Markdown into Pandoc AST blocks
      local doc = pandoc.read(content, 'markdown')
      
      -- Replace the !include paragraph with the contents of the file
      return doc.blocks
    else
      -- If the file doesn't exist, print a warning to the console 
      -- and leave the !include text unmodified in the output document.
      io.stderr:write("Warning: pandoc-include.lua could not find '" .. filename .. "'\n")
      return el
    end
  end
end
