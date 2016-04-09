# phoenix.vim

phoenix.vim is a plugin inspired by rails.vim, aiming to offer the same
features (eventually).

**phoenix.vim** supports:

- Project navigation using [projectionist.vim](https://github.com/tpope/vim-projectionist) (`:Emodel` and friends)
- Jumps using `gf`
  - for example, in an Ecto model: `has_many :users`, with the cursor on `users`, `gf` brings you to `web/models/user.ex`
- Generators - run Phoenix generators from within vim `:Pgenerate`
- Preview - `:Ppreview endpoint` will open `localhost:4000/endpoint` in your browser

Check out the documentation `:h phoenix` for the full list of features!

## Installation

Use your favourite plugin manager, here we use [vim-plug](https://github.com/junegunn/vim-plug)

As this plugin relies on
[projectionist](https://github.com/tpope/vim-projectionist), you will need to
install it too.

```vim
Plug 'c-brenn/phoenix.vim'
Plug 'tpope/vim-projectionist' " required for navigation features
```

Make sure to have this plugin before projectionist in your vimrc.

## More Features To Come

The plan is to try and get feature parity with rails.vim eventually.
For now, the focus is on improving the navigation commands.

## Issues

If you run into any bugs, open an issue [in the tracker](https://github.com/c-brenn/phoenix.vim/issues)
