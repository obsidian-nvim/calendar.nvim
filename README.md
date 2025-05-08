# calendar.nvim

Calendar library for neovim

## Idea

- Like emacs's builtin calendar, `calendar-vim`, be a capable yet minimal calendar.
- Supports customizable callbacks for any app you want to build
- Flexible Layouts, ordered as planned:
  1. Center, one month popup, like orgmode(nvim)
  2. Follow Cursor [reference](https://publish.obsidian.md/kanban/Settings/Date+trigger)
  3. Side pannel, three month, like neorg's and [calendar-vim](https://github.com/nvim-telekasten/calendar-vim)
  4. _Long Term Goal_ Calendar app view [calendar.vim](https://github.com/itchyny/calendar.vim)

Three parts:

- `ui`
- `date_parser`
- `actions`

## Acknowledgements

- [nvim-orgmode/orgmode](https://github.com/nvim-orgmode/orgmode) for all the main logic
