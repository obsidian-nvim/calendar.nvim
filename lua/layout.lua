--- TODO: from telescope
---
--- Cursor layout dynamically positioned below the cursor if possible.
--- If there is no place below the cursor it will be placed above.
---
--- <pre>
--- ┌──────────────────────────────────────────────────┐
--- │                                                  │
--- │   █                                              │
--- │   ┌──────────────┐┌─────────────────────┐        │
--- │   │    Prompt    ││      Preview        │        │
--- │   ├──────────────┤│      Preview        │        │
--- │   │    Result    ││      Preview        │        │
--- │   │    Result    ││      Preview        │        │
--- │   └──────────────┘└─────────────────────┘        │
--- │                                         █        │
--- │                                                  │
--- │                                                  │
--- │                                                  │
--- │                                                  │
--- │                                                  │
--- └──────────────────────────────────────────────────┘
--- </pre>
---@eval { ["description"] = require("telescope.pickers.layout_strategies")._format("cursor") }
layout_strategies.cursor = make_documented_layout(
	"cursor",
	vim.tbl_extend("error", {
		width = shared_options.width,
		height = shared_options.height,
		scroll_speed = shared_options.scroll_speed,
	}, {
		preview_width = { "Change the width of Telescope's preview window", "See |resolver.resolve_width()|" },
		preview_cutoff = "When columns are less than this value, the preview will be disabled",
	}),
	function(self, max_columns, max_lines, layout_config)
		local initial_options = p_window.get_initial_window_options(self)
		local preview = initial_options.preview
		local results = initial_options.results
		local prompt = initial_options.prompt
		local winid = self.original_win_id

		local height_opt = layout_config.height
		local height = resolve.resolve_height(height_opt)(self, max_columns, max_lines)

		local width_opt = layout_config.width
		local width = resolve.resolve_width(width_opt)(self, max_columns, max_lines)

		local bs = get_border_size(self)

		local h_space
		-- Cap over/undersized height
		height, h_space = calc_size_and_spacing(height, max_lines, bs, 2, 3, 0)

		prompt.height = 1
		results.height = height - prompt.height - h_space
		preview.height = height - 2 * bs

		local w_space
		if self.previewer and max_columns >= layout_config.preview_cutoff then
			-- Cap over/undersized width (with preview)
			width, w_space = calc_size_and_spacing(width, max_columns, bs, 2, 4, 0)

			preview.width =
				resolve.resolve_width(vim.F.if_nil(layout_config.preview_width, 2 / 3))(self, width, max_lines)
			prompt.width = width - preview.width - w_space
			results.width = prompt.width
		else
			-- Cap over/undersized width (without preview)
			width, w_space = calc_size_and_spacing(width, max_columns, bs, 1, 2, 0)

			preview.width = 0
			prompt.width = width - w_space
			results.width = prompt.width
		end

		local position = vim.api.nvim_win_get_position(winid)
		local winbar = (function()
			if vim.fn.exists("&winbar") == 1 then
				return vim.wo[winid].winbar == "" and 0 or 1
			end
			return 0
		end)()
		local top_left = {
			line = vim.api.nvim_win_call(winid, vim.fn.winline) + position[1] + bs + winbar,
			col = vim.api.nvim_win_call(winid, vim.fn.wincol) + position[2],
		}
		local bot_right = {
			line = top_left.line + height - 1,
			col = top_left.col + width - 1,
		}

		if bot_right.line > max_lines then
			-- position above current line
			top_left.line = top_left.line - height - 1
		end
		if bot_right.col >= max_columns then
			-- cap to the right of the screen
			top_left.col = max_columns - width
		end

		prompt.line = top_left.line + 1
		results.line = prompt.line + bs + 1
		preview.line = prompt.line

		prompt.col = top_left.col + 1
		results.col = prompt.col
		preview.col = results.col + (bs * 2) + results.width

		return {
			preview = self.previewer and preview.width > 0 and preview,
			results = results,
			prompt = prompt,
		}
	end
)
