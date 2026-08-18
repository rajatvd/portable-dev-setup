# Third-party components

The main project is distributed under the MIT License. The exact third-party snapshots below remain under their own licenses. A recursive source clone contains each complete license file at the listed path; offline bundles materialize the same files.

| Component | Exact commit | License file |
| --- | --- | --- |
| Oh My Zsh | `0912e05c0589d26ea20d79555487900880aad4d5` | `vendor/oh-my-zsh/LICENSE.txt` |
| Powerlevel10k | `d71edb83f9c7f045a0d528eeff3445ec3d518d71` | `vendor/powerlevel10k/LICENSE` |
| zsh-autosuggestions | `c3d4e576c9c86eac62884bd47c01f6faed043fc5` | `vendor/zsh-autosuggestions/LICENSE` |
| zsh-syntax-highlighting | `e0165eaa730dd0fa321a6a6de74f092fe87630b0` | `vendor/zsh-syntax-highlighting/COPYING.md` |
| vim-commentary | `64a654ef4a20db1727938338310209b6a63f60c9` | `vendor/nvim-plugins/vim-commentary/README.markdown` |
| vim-surround | `3d188ed2113431cf8dac77be61b842acb64433d9` | `vendor/nvim-plugins/vim-surround/README.markdown` |
| vim-fugitive | `3b753cf8c6a4dcde6edee8827d464ba9b8c4a6f0` | `vendor/nvim-plugins/vim-fugitive/README.markdown` |
| nvim-cmp | `2ffe79f1f021def8dd1fcd81deb16f1bb0d989f3` | `vendor/nvim-plugins/nvim-cmp/LICENSE` |
| cmp-nvim-lsp | `cbc7b02bb99fae35cb42f514762b89b5126651ef` | `vendor/nvim-plugins/cmp-nvim-lsp/LICENSE` |
| cmp-buffer | `b74fab3656eea9de20a9b8116afa3cfc4ec09657` | `vendor/nvim-plugins/cmp-buffer/LICENSE` |
| cmp-path | `c642487086dbd9a93160e1679a1327be111cbc25` | `vendor/nvim-plugins/cmp-path/LICENSE` |
| LuaSnip | `642b0c595e11608b4c18219e93b88d7637af27bc` | `vendor/nvim-plugins/luasnip/LICENSE` |
| cmp_luasnip | `98d9cb5c2c38532bd9bdb481067b20fea8f32e90` | `vendor/nvim-plugins/cmp_luasnip/LICENSE` |
| plenary.nvim | `74b06c6c75e4eeb3108ec01852001636d85a932b` | `vendor/nvim-plugins/plenary.nvim/LICENSE` |
| telescope.nvim | `a0bbec21143c7bc5f8bb02e0005fa0b982edc026` | `vendor/nvim-plugins/telescope.nvim/LICENSE` |
| oil.nvim | `b73018b75affd13fa38e2fc94ef753b465f770d7` | `vendor/nvim-plugins/oil.nvim/LICENSE` |
| leap.nvim | `1fc7f38b69cc4644505e3ff74ba69b1682a85dd9` | `vendor/nvim-plugins/leap.nvim/LICENSE.md` |
| which-key.nvim | `3aab2147e74890957785941f0c1ad87d0a44c15a` | `vendor/nvim-plugins/which-key.nvim/LICENSE` |
| nvim-web-devicons | `2ae6958df7ced50baac5035cec0c15799eedfbf7` | `vendor/nvim-plugins/nvim-web-devicons/LICENSE` |

The three Vim plugins state that they use the Vim license. Its complete text is retained at `licenses/VIM_LICENSE.txt`.

LuaSnip's optional jsregexp build submodules are not part of the installed or bundled runtime; LuaSnip's pure-Lua and LSP-snippet paths are used without a build step.

Source locations and pin metadata are recorded in `vendor/LOCK.tsv` and `.gitmodules`. No third-party repository history is folded into this repository's history.
