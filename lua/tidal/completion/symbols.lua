local M = {}

local symbols = {}
local buf_ns = nil

local param_patterns = {
  sound = { "s%s*=", "sound%s*=" },
  note = { "n%s*=", "note%s*=" },
}

local function extract_param_value(line, param_name)
  for _, pat in ipairs(param_patterns[param_name] or {}) do
    local _, _, val = line:find(pat .. '%s+"([^"]+)"')
    if val then return val end
  end
  local _, _, val = line:find(param_name .. '%s+"([^"]+)"')
  return val
end

local function parse_let_line(line)
  line = line:gsub("%-%-.*$", "")
  local _, _, name, rest = line:find("let%s+(%w+)%s*=%s*(.*)")
  if not name then
    _, _, name, rest = line:find("^(%w+)%s*=%s*(.*)")
  end
  if not name or not rest then return nil end

  local info = { name = name, raw = rest }
  local sound_val = extract_param_value(rest, "sound")
  if sound_val then
    info.type = "sound"
    info.bank = sound_val:match("^([%w_%-]+)")
  end
  local note_val = extract_param_value(rest, "note") or extract_param_value(rest, "n")
  if note_val then
    info.type = info.type and (info.type .. "_note") or "note"
    info.notes = note_val
  end
  return info
end

local function parse_p_line(line)
  line = line:gsub("%-%-.*$", "")
  local _, _, name, rest = line:find('p%s+"([^"]+)"%s+$%s*(.*)')
  if not name then
    _, _, name, rest = line:find("p%s+(%w+)%s+%$%s*(.*)")
  end
  if not name or not rest then return nil end
  local info = { name = name, raw = rest }
  local sound_val = extract_param_value(rest, "sound") or extract_param_value(rest, "s")
  if sound_val then
    info.type = "sound"
    info.bank = sound_val:match("^([%w_%-]+)")
  end
  return info
end

local function parse_d_line(line)
  line = line:gsub("%-%-.*$", "")
  local _, _, num, rest = line:find("^d(%d+)%s+%$%s*(.*)")
  if not num then return nil end
  local info = { name = "d" .. num, raw = rest }
  local sound_val = extract_param_value(rest, "sound") or extract_param_value(rest, "s")
  if sound_val then
    info.type = "sound"
    info.bank = sound_val:match("^([%w_%-]+)")
  end
  return info
end

function M.scan_buffer(buf)
  symbols = {}
  if not vim.api.nvim_buf_is_valid(buf) then return end

  local lines = vim.api.nvim_buf_get_lines(buf, 0, -1, false)
  local in_let = false
  local let_acc = ""

  for _, line in ipairs(lines) do
    if line:match("^%s*let%s") and not line:match("^%s*let%s+in") then
      in_let = true
      let_acc = line
    elseif in_let then
      let_acc = let_acc .. " " .. line
      if line:match("in%s*$") or line:match("^%s*in%s") then
        in_let = false
        local current = ""
        for part in let_acc:gmatch("[^,]+") do
          if not part:match("^%s*in") then
            local info = parse_let_line(part)
            if info then
              symbols[info.name] = info
            end
          end
        end
        let_acc = ""
      end
    end

    local info = parse_p_line(line)
    if info then
      symbols[info.name] = info
    end

    info = parse_d_line(line)
    if info then
      symbols[info.name] = info
    end
  end
end

function M.get_symbol(name)
  return symbols[name]
end

function M.get_all_symbols()
  local result = {}
  for name, info in pairs(symbols) do
    table.insert(result, { word = name, menu = "pat", info = info.type or "pattern" })
  end
  table.sort(result, function(a, b) return a.word < b.word end)
  return result
end

function M.get_symbol_names()
  local names = {}
  for name in pairs(symbols) do
    table.insert(names, name)
  end
  table.sort(names)
  return names
end

function M.get_bank_for_symbol(name)
  local sym = symbols[name]
  if sym and sym.bank then
    return sym.bank
  end
  return nil
end

return M
