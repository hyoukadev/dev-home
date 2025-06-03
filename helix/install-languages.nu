#!/usr/bin/env nu




# ✅ setup rust-lang support
rustup component add rust-analyzer
cargo install taplo-cli --locked --features lsp


# ✅ typst
cargo install --git https://github.com/Myriad-Dreamin/tinymist --locked tinymist


# ✅ lua
match $nu.os-info.name {
 "macos" => { brew install lua-language-server }
 "windows" => { winget install LuaLS.lua-language-server }
  _ => { print "❌ lua" }
}

# ✅ typescript
npm install -g typescript typescript-language-server vscode-langservers-extracted@4.8
npm install --save-dev --save-exact @biomejs/biome

# ✅ markdown
match $nu.os-info.name {
  "windows" => { winget install markdown-oxide }
  _ => { print "❌ markdown" }
}
