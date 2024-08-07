# multichar-surround.nvim

A simple Neovim surround plugin for editing multiple characters at once

![output](https://github.com/user-attachments/assets/7874268a-50bc-4f6d-aac4-a06fd34c378a)

# Concept

There are already so many [great plugins](#other-surround-plugins) for surrounding text in vim/neovim, so do we really need another? Not necessarily, but I've found the existing solutions to be a bit cumbersome when working with larger clusters of surrounding characters. So, I wrote a helper function for my own convenience, which I've decided to repackage as its own plugin in case anyone else finds it useful.

**I recommend using one of the [existing plugins](#other-surround-plugins)** for single character edits. I use [mini.surround](https://github.com/echasnovski/mini.surround).

# Installation / Setup

1. Install the plugin with your favorite plugin manager.

2. All it does is expose one function, which you can map to whatever key you'd like. In this example, I use <kbd>shift+s</kbd> (<kbd>S</kbd>):

```lua
vim.keymap.set("v", "S", function() require("multichar-surround").do_surround() end)
```

The following does both of the above steps if you're using [lazy.nvim](https://github.com/folke/lazy.nvim):

```lua
{
    "cz875/multichar-surround.nvim",
    keys = {
        { mode = { "x" }, "S", function() require("multichar-surround").do_surround() end }
    }
}
```

Once you've completed the above setup, you should be able to select some text in visual mode and edit its surrounding characters by pressing <kbd>S</kbd>.

# Configuration

You can configure the plugin by passing a table to the `setup()` function.
For example, if you wanted to redundantly override the default options with the default values:

```lua
require("multichar-surround").setup({
    -- the text to show when prompting the user for input
    prompt_text = "Edit right pair:",

    -- a list of pairs of characters for the purposes of detecting and
    -- editing surrounding pairs
    matching_pairs = {
        { "(", ")" }, { "[", "]" }, { "{", "}" }, { "<", ">" }
    },
} --[[@as MulticharSurroundOpts]])
```

In `lazy.nvim`, you can (and should) use the `opts` field:

```lua
{
    "cz875/multichar-surround.nvim",
    keys = {
        { mode = { "x" }, "S", function() require("multichar-surround").do_surround() end }
    },
    ---@type MulticharSurroundOpts
    opts = {
        -- the text to show when prompting the user for input
        prompt_text = "Edit right pair:",

        -- a list of pairs of characters for the purposes of detecting and
        -- editing surrounding pairs
        matching_pairs = {
            { "(", ")" }, { "[", "]" }, { "{", "}" }, { "<", ">" }
        },
    }
}
```

That opts table is then automatically passed into the `setup()` function.

# Contributing

Contributions are always welcome. Feel free to open an issue or submit a PR if you have problems/suggestions.

# Other surround plugins

- [tpope/vim-surround](https://github.com/tpope/vim-surround)
- [machakann/vim-sandwich](https://github.com/machakann/vim-sandwich)
- [kylechui/nvim-surround](https://github.com/kylechui/nvim-surround)
- [echasnovski/mini.surround](https://github.com/echasnovski/mini.surround/)
