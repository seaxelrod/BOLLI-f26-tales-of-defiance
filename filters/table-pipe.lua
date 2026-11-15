-- Dynamically get the directory where this Lua filter is located
local filter_dir = PANDOC_SCRIPT_FILE:match("(.*[/\\])") or "./"

function CodeBlock(el)
  if el.classes:includes('custom-table') then
    
    local python_script = filter_dir .. "pandoc_markdown_dual_tables.py"
    local args = {python_script}
    
    -- Loop through every attribute provided in the Markdown block
    for key, value in pairs(el.attributes) do
      
      -- Convert the markdown key into a command-line flag (e.g., row-padding -> --row-padding)
      table.insert(args, "--" .. key)
      
      -- If the value is exactly "true", treat it as a boolean flag (store_true) and omit the value string.
      -- Otherwise, pass the value alongside the flag.
      if value ~= "true" and value ~= "" then
        table.insert(args, value)
      end
      
    end
    
    local script_output = pandoc.pipe(
      'python3', 
      args, 
      el.text
    )
    
    return pandoc.read(script_output).blocks
  end
end
