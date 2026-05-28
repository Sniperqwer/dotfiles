--- @since 26.1.22
--- @sync entry

local function notify(content, level)
	ya.notify {
		title   = "Copy content",
		content = content,
		level   = level or "warn",
		timeout = 3,
	}
end

local TEXT_EXT = {
	md=1, markdown=1, txt=1, log=1, conf=1, cfg=1, ini=1, env=1,
	toml=1, yaml=1, yml=1, json=1, jsonl=1, ndjson=1, xml=1, csv=1, tsv=1,
	lua=1, py=1, ipynb=1, js=1, mjs=1, cjs=1, ts=1, tsx=1, jsx=1,
	sh=1, zsh=1, bash=1, fish=1, ps1=1,
	go=1, rs=1, c=1, h=1, cpp=1, hpp=1, cc=1, hh=1,
	java=1, kt=1, swift=1, rb=1, php=1, sql=1,
	html=1, htm=1, css=1, scss=1, sass=1, vim=1, el=1, rst=1, tex=1, bib=1,
}

local TEXT_BASENAME = {
	gitignore=1, gitconfig=1, gitattributes=1,
	dockerfile=1, makefile=1, rakefile=1, gemfile=1,
	[".env"]=1, [".bashrc"]=1, [".zshrc"]=1, [".profile"]=1,
}

local IMG_CLASS = {
	png  = "«class PNGf»",
	jpg  = "JPEG picture",
	jpeg = "JPEG picture",
	gif  = "GIF picture",
	tif  = "TIFF picture",
	tiff = "TIFF picture",
}

local function basename_and_ext(path)
	local base = path:match("([^/]+)$") or path
	local lower = base:lower()
	local ext = lower:match("%.([^.]+)$")
	return lower, ext
end

local function as_str(s)
	return '"' .. s:gsub("\\", "\\\\"):gsub('"', '\\"') .. '"'
end

local function entry()
	local h = cx.active.current.hovered
	if not h then
		notify("No file hovered")
		return
	end

	local path = tostring(h.url)
	local base, ext = basename_and_ext(path)

	if (ext and TEXT_EXT[ext]) or TEXT_BASENAME[base] then
		local child = Command("sh"):arg({ "-c", 'pbcopy < "$1"', "sh", path }):spawn()
		if not child then
			notify("Failed to spawn pbcopy", "error")
		else
			notify("Copied text: " .. base, "info")
		end
		return
	end

	if ext and IMG_CLASS[ext] then
		local script = string.format(
			'set the clipboard to (read (POSIX file %s) as %s)',
			as_str(path), IMG_CLASS[ext]
		)
		local child = Command("osascript"):arg({ "-e", script }):spawn()
		if not child then
			notify("Failed to spawn osascript", "error")
		else
			notify("Copied image: " .. base, "info")
		end
		return
	end

	notify("Unsupported extension: " .. (ext or "(none)"))
end

return { entry = entry }
