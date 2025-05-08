# calendar.nvim

**WIP** Calendar library for neovim

## Idea

- Like emacs's builtin calendar, `calendar-vim`, be a capable yet minimal calendar.
- Supports customizable callbacks for any app you want to build
- Flexible Layouts, ordered as planned:
  1. Center, one month popup, like orgmode(nvim)
  2. Follow Cursor [reference](https://publish.obsidian.md/kanban/Settings/Date+trigger)
  3. Side pannel, three month, like neorg's and [calendar-vim](https://github.com/nvim-telekasten/calendar-vim)
  4. _Long Term Goal_ Calendar app view [calendar.vim](https://github.com/itchyny/calendar.vim)

Three parts:

- `date`: Contains all the logic of calculating dates
  - `parser`: parse date strings
  - `writer`: outputs formatted dates
- `calendar`: Contains all the logic of operation of a calendar
  - All the views/layouts
  - custom everything by ftplugin
    - winhighlight
    - winborder
    - ...
- `actions`: customizable and provide utils for ease of defining
  - opening actions:
    - open the date under cursor
  - confirm actions:
    - insert dates
    - echo dates
    - open journal of dates

## Acknowledgements

- [nvim-orgmode/orgmode](https://github.com/nvim-orgmode/orgmode) for all the main logic
