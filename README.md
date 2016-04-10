# phoenix.vim

phoenix.vim is a plugin inspired by rails.vim, aiming to offer the same
features (eventually).

**phoenix.vim** supports:

| Feature | Description |
| ------- | ------------|
| Projectionist Navigation | Navigation using [Projectionist][projectionist] - `:Emodel` and friends |
| Jumps | Use the word under the cursor to jump to files with `gf`. For example, in an Ecto model: `has_many :users`, with the cursor on `users`, `gf` brings you to `web/models/user.ex` |
| Generators | Run Phoenix generators from within vim `:Pgenerate model Foo foos bar:string`
| Server | `:Pserver` runs `mix phoenix.server` - in a `term` for Neovim users or with [dispatch][dispatch] for Vim users|
| Preview | `:Ppreview` endpoints in your browser

Check out the documentation `:h phoenix` for the full list of features!

## Installation

Use your favourite plugin manager, here we use [vim-plug][vim-plug]

As this plugin relies on [Projectionist][projectionist], you will need to
install it too.

```vim
Plug 'c-brenn/phoenix.vim'
Plug 'tpope/vim-projectionist' " required for some navigation features
```

Make sure to have this plugin before projectionist in your vimrc.

## Documentation

Check out `:h phoenix` to find out more.

## More Features To Come

The plan is to try and get feature parity with rails.vim eventually.
For now, the focus is on improving the navigation commands.

## Issues

If you run into any bugs, open an issue [in the tracker][issues]

[projectionist]: https://github.com/tpope/vim-projectionist
[dispatch]: https://github.com/tpope/vim-dispatch
[vim-plug]: https://github.com/junegunn/vim-plug
[issues]:  https://github.com/c-brenn/phoenix.vim/issues
