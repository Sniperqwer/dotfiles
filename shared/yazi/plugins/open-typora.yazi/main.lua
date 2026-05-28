--- @since 26.1.22
--- @sync entry

local function notify(content, level)
	ya.notify {
		title   = "Typora",
		content = content,
		level   = level or "warn",
		timeout = 3,
	}
end

local function entry()
	local h = cx.active.current.hovered
	if not h then
		notify("No file hovered")
		return
	end

	local path = tostring(h.url)
	local lower = path:lower()
	if not (lower:match("%.md$") or lower:match("%.markdown$")) then
		notify("Not a markdown file")
		return
	end

	local child, err = Command("open")
		:arg({ "-a", "Typora", path })
		:spawn()

	if not child then
		notify("Failed to launch Typora: " .. tostring(err), "error")
	end
end

return { entry = entry }
