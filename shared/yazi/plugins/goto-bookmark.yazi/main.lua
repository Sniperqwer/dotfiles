--- @since 26.1.22
--- @sync entry

local function notify(content, level)
	ya.notify {
		title   = "Bookmark",
		content = content,
		level   = level or "warn",
		timeout = 2,
	}
end

local function entry(self, job)
	local key = job and job.args and job.args[1]
	if not key then
		notify("No bookmark key given")
		return
	end

	local path = os.getenv("HOME") .. "/.config/yazi/local.lua"
	local ok, bookmarks = pcall(dofile, path)
	if not ok or type(bookmarks) ~= "table" then
		notify("No bookmarks configured")
		return
	end

	local target = bookmarks[key]
	if not target then
		notify("No bookmark for: " .. key)
		return
	end

	ya.emit("cd", { target })
end

return { entry = entry }
