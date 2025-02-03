-- same-fragment.lua
--
-- A Lua filter that assigns the same data-fragment-index to each top-level
-- bullet item and all its sub-bullets, so they appear together in Reveal.js.

local frag_counter = 1

-- Helper function to recursively set data-fragment-index on all blocks.
local function propagate_frag(blocks, frag)
  for i, block in ipairs(blocks) do
    -- Ensure 'block.attr' is initialized
    if not block.attr then
      block.attr = pandoc.Attr("", {}, {})
    end
    block.attr.attributes["data-fragment-index"] = frag

    -- If this block contains sub-blocks (like another BulletList, Div, etc.), recurse.
    if block.t == "BulletList" or block.t == "OrderedList" then
      -- For lists, block.content is a list of list items,
      -- and each list item is a list of blocks.
      for _, listItem in ipairs(block.content) do
        propagate_frag(listItem, frag)
      end
    elseif block.content then
      -- For containers like Div, BlockQuote, etc.
      if type(block.content) == "table" then
        block.content = propagate_frag(block.content, frag)
      end
    end
  end
  return blocks
end

function BulletList(el)
  -- For each top-level list item in this bullet list,
  -- assign a new fragment index and propagate it.
  for _, listItem in ipairs(el.content) do
    local frag = tostring(frag_counter)
    frag_counter = frag_counter + 1
    propagate_frag(listItem, frag)
  end
  return el
end

return {
  { BulletList = BulletList }
}
