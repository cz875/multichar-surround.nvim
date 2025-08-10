### multichar-surround.nvim

A simple Neovim surround plugin for editing multiple characters at once

### Concept

There are already so many [great plugins](#other-surround-plugins) for surrounding text in vim/neovim, so why write another? Other plugins are mature, fully featured, and work great for single-character edits, but I've always a convenient way to edit multiple surrounding characters at a time. So, I wrote a helper function for my own convenience, which I've decided to repackage as its own plugin in case anyone else finds it useful.

**I recommend using one of the [existing plugins](#other-surround-plugins) for single character edits** I use [mini.surround](https://github.com/echasnovski/mini.surround).

### Usage

This is a very simple plugin which provides just one lua function intended to
be called by a keymap in visual mode. For example:

```lua
vim.keymap.set("x", "S", function()
    require("multichar-surround").do_surround()
end)
```

With this keymap, upon typing "S" in visual mode, you should be prompted on the
command line:

```
Enter right pair:
```

If the function detects matching pairs of characters at both ends of your
visual selection, then they will be automatically filled into the prompt for
editing.

That is, if you select the text:

```lua
({ "Hello World!" })
```

then you should see the following after triggering `do_surround`:

```
Enter right pair:" })
```

which you can edit as necessary:

```
Enter right pair:']
```

and hit enter (<CR>) to apply the changes to the buffer:

```lua
['Hello world']
```

### Installation / Setup

1. Install the plugin with your favorite plugin manager.

2. All it does is expose one function, which you can map to whatever key you'd like. In this example, I use <kbd>shift+s</kbd> (<kbd>S</kbd>):

```lua
vim.keymap.set("x", "S", function() require("multichar-surround").do_surround() end)
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

### Configuration

You can configure the plugin by passing a table to the `setup()` function.
The default config is as follows:

```lua
require("multichar-surround").setup({
    -- the text to show when prompting the user for input
    prompt_text = "Edit right pair:",

    -- the highlight group to use for detected balanced pairs
    hl_group = "MatchParen",

    -- a list of pairs of mirrored characters to be used in
    -- detection/insertion of balanced pairs
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

        -- the highlight group to use for detected balanced pairs
        hl_group = "MatchParen",

        -- a list of pairs of mirrored characters to be used in
        -- detection/insertion of balanced pairs
        matching_pairs = {
            { "(", ")" }, { "[", "]" }, { "{", "}" }, { "<", ">" }
        },
    }
}
```

That opts table is then automatically passed into the `setup()` function.

### Contributing

Contributions are always welcome. Feel free to open an issue or submit a PR if you have problems/suggestions.

### Other surround plugins

- [tpope/vim-surround](https://github.com/tpope/vim-surround)
- [machakann/vim-sandwich](https://github.com/machakann/vim-sandwich)
- [kylechui/nvim-surround](https://github.com/kylechui/nvim-surround)
- [echasnovski/mini.surround](https://github.com/echasnovski/mini.surround/)
