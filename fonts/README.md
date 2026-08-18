# UKaiTW-MJ

A subset of **AR PL UKai TW** (文鼎PL中楷), bundled in the Mahjong iOS app for
tile faces, the 圈風 die, the launch wordmark and the share cards.

The original font is © 1999 Arphic Technology Co., Ltd., distributed under the
**Arphic Public License** (`ARPHICPL.TXT`).

## What was changed

Subset from the full 24,170-glyph TW face down to the 525 characters the app
draws — every string in its localisation catalogue, the tile and flower
characters, ASCII and punctuation — with hinting removed and the font renamed
to `UKaiTW-MJ`. That takes it from 16.8 MB to 0.27 MB. The same notice is
recorded in the font's own `name` table.

## Why this file is here

APL §2(b) requires modifications to be made Freely Available to third parties
under the same licence. The app's own repository is private, so the modified
font is published here instead. It is offered under the Arphic Public License,
exactly as received: you may copy, modify and redistribute it under those same
terms, provided `ARPHICPL.TXT` travels with it unaltered.

The font is not part of the MahjongKit library and is not referenced by any
target in `Package.swift`; it lives here purely to satisfy that obligation.
