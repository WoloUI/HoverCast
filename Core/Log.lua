local HC = _G.HoverCast
if not HC then HC = {}; _G.HoverCast = HC end

-- Prints to chat with the addon's coloured prefix.
function HC.Log(msg)
  if DEFAULT_CHAT_FRAME then
    DEFAULT_CHAT_FRAME:AddMessage("|cff66ccff[HoverCast]|r " .. tostring(msg))
  end
end

-- Wraps fn in a pcall. Returns (ok, result) and logs the error on failure.
function HC.safe(fn, ...)
  local ok, res = pcall(fn, ...)
  if not ok then HC.Log("error: " .. tostring(res)) end
  return ok, res
end
