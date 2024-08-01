# multichar-surround.nvim

A simple surround plugin which can edit multiple characters at once.

![output](https://github.com/user-attachments/assets/7874268a-50bc-4f6d-aac4-a06fd34c378a)

# Concept

There are already so many [great plugins](#other-surround-plugins) for surrounding text in vim/neovim, so do we really need another? Not necessarily, but I've found the existing solutions to be a bit cumbersome when working with larger clusters of surrounding characters. So, I wrote a helper function for my own convenience, which I've decided to repackage as its own plugin in case anyone else finds it useful.

**I recommend using one of the [existing plugins](#other-surround-plugins)** for single character edits. I use [mini.surround](https://github.com/echasnovski/mini.surround).

# Installation / Setup

1. Install the plugin with your favorite plugin manager.

2. All it does is expose one function, which you can map to whatever key you'd like. In this example, I use shift+s (S):

```lua
vim.keymap.set("v", "S", require("multichar-surround").do_surround)
```

The following does both of the above steps if you're using [lazy.nvim](https://github.com/folke/lazy.nvim)

```lua
{
    "cz875/multichar-surround.nvim",
    config = function()
        vim.keymap.set("v", "S", require("multichar-surround").do_surround))
    end
}
```

To learn about configuration options, try `:help multichar-surround-configuration` in Neovim with the plugin installed.

# Other surround plugins

- [tpope/vim-surround](https://github.com/tpope/vim-surround)
- [machakann/vim-sandwich](https://github.com/machakann/vim-sandwich)
- [kylechui/nvim-surround](https://github.com/kylechui/nvim-surround)
- [echasnovski/mini.surround](https://github.com/echasnovski/mini.surround/)
