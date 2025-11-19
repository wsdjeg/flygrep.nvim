# Changelog

## [1.3.0](https://github.com/wsdjeg/flygrep.nvim/compare/v1.2.0...v1.3.0) (2025-11-19)


### Features

* add ctrl-q to apply quickfix ([e695654](https://github.com/wsdjeg/flygrep.nvim/commit/e6956547f1647430fdff647c42c131a3331e61ab))
* add ignore_keys options ([3b49900](https://github.com/wsdjeg/flygrep.nvim/commit/3b499006280ca057a79458b009c680c5e8f0e82d))


### Bug Fixes

* disable F1 in insert mode ([665b5ee](https://github.com/wsdjeg/flygrep.nvim/commit/665b5eea4bbba6d47913a749259be22161d8d8cb))

## [1.2.0](https://github.com/wsdjeg/flygrep.nvim/compare/v1.1.0...v1.2.0) (2025-11-04)


### Features

* improve flygrep logger ([ca986ee](https://github.com/wsdjeg/flygrep.nvim/commit/ca986ee5a7e53129b9047b82a4115fc326cf3870))
* **mappings:** support custom mappings ([9584a79](https://github.com/wsdjeg/flygrep.nvim/commit/9584a79456bf1a3a2686f06a3ef4a5f1bcdddcff))


### Bug Fixes

* catch matchadd error ([947c98e](https://github.com/wsdjeg/flygrep.nvim/commit/947c98ec2fa66c9370a7e1c5d2a8a7833df1b36a))

## [1.1.0](https://github.com/wsdjeg/flygrep.nvim/compare/v1.0.0...v1.1.0) (2025-04-22)


### Features

* add window option ([297d0d4](https://github.com/wsdjeg/flygrep.nvim/commit/297d0d42f5371a9392c7fdce3fdca42d29d69d66))


### Bug Fixes

* avoid overriden by global 'cursorlineopt' ([5375239](https://github.com/wsdjeg/flygrep.nvim/commit/53752399c4ddcd9209d6479322c773f3a5cf180f))
* disable blink.cmp on prompt win ([5116b1d](https://github.com/wsdjeg/flygrep.nvim/commit/5116b1d9c6147718fd38fc981505a9fd281b296a))
* remove setup function from plugin ([90a9135](https://github.com/wsdjeg/flygrep.nvim/commit/90a91355bb6af207ab0642def32ce5159694c6fc))
* when enter no entry matched ([65f42d4](https://github.com/wsdjeg/flygrep.nvim/commit/65f42d4dc13c1cc861e1dbb7dd47af3d2c07781c))

## 1.0.0 (2025-03-17)


### Features

* **flygrep.nvim:** support preview win ([5949502](https://github.com/wsdjeg/flygrep.nvim/commit/59495029704f57a1e2f9c67dffc960c6abbe6630))
* **flygrep:** add `ctrl-h` to toggle hidden file ([dabcb5f](https://github.com/wsdjeg/flygrep.nvim/commit/dabcb5fb1d98ac94f2188d930238703fb25a6cfc))
* **flygrep:** make flygrep support input and cwd ([1c09cea](https://github.com/wsdjeg/flygrep.nvim/commit/1c09ceaee8c66aa600729f86196f75194baeb369))
* support runtime log via logger.nvim ([92bd3d8](https://github.com/wsdjeg/flygrep.nvim/commit/92bd3d8f035f616bc2611aea5790944f0a71de46))


### Bug Fixes

* **flygrep:** clear preview buf when text is empty ([ea0291e](https://github.com/wsdjeg/flygrep.nvim/commit/ea0291ef480a8be48d22d4c699702fe483efcdb4))
* **flygrep:** fix result count ([33cb398](https://github.com/wsdjeg/flygrep.nvim/commit/33cb39840414a23d305de7587f1d12c957baba26))
* **flygrep:** fix setup function ([d9c3108](https://github.com/wsdjeg/flygrep.nvim/commit/d9c3108f299521fa8823dff4f4d080c20f386a17))
* **flygrep:** setup cmp only when exists ([9ae3d73](https://github.com/wsdjeg/flygrep.nvim/commit/9ae3d7327f285f0cadf8bd10ff07117c590dc34d))
* **flygrep:** skip E33 when input is ~ ([99432e5](https://github.com/wsdjeg/flygrep.nvim/commit/99432e550bf1daace8a1709e006f87254d396622))


### Performance Improvements

* **flygrep:** add ctrl-j/ctrl-k ([11a97e6](https://github.com/wsdjeg/flygrep.nvim/commit/11a97e657a2695dea24ffb7eb854ad198d264146))
* **flygrep:** enable cursorline in preview win ([de5cf0b](https://github.com/wsdjeg/flygrep.nvim/commit/de5cf0b7084125b27a0d521d1c70d8df70d59a68))
* **flygrep:** improve tab/shift-tab key binding ([c1d1454](https://github.com/wsdjeg/flygrep.nvim/commit/c1d14546a187825cb0401a150a1c8b1782ffbd82))
* **flygrep:** save mouse option ([5e3a317](https://github.com/wsdjeg/flygrep.nvim/commit/5e3a317f776b4755130143d6146630f9ccde1e6b))
* **flygrep:** stop job if grep_input is empty ([5e4df21](https://github.com/wsdjeg/flygrep.nvim/commit/5e4df2168060d1e3b77b88fb60dd8dd62340801e))
* **flygrep:** update preview buf after C-p ([7c797db](https://github.com/wsdjeg/flygrep.nvim/commit/7c797db4ef72a7b883ed5651e608ab92909a5146))
* **flygrep:** update result count after ctrl-w ([630ec4f](https://github.com/wsdjeg/flygrep.nvim/commit/630ec4f64cf1301052d2046abb56c6b23ba12d9f))
