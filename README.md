# oUF_Hankk

A rework of [oUF_Hank](https://www.wowinterface.com/downloads/info16239-oUF_Hank.html) for World of Warcraft: Midnight and Forever.

Built on [oUF](https://github.com/oUF-wow/oUF), following the structure of [oUF_Ruri](https://github.com/EKE00372/oUF_Ruri).

## Style

Keeps Hank's signature health-percentage digits and water-fill effect with some changes:

* Global Font Outline.
* Mirrored player and target layouts, with percent signs on their outer sides.
* Support all class-resource.
* Totem icons above the player frames instead bottom.
* Add bossframes power, castbars and auras, remove threat text.
* Optional arena and party frames, disable by default.
* All-in-One font support Chinese, Korean, Spanish, English and Russian.

## Features

* Config:
    * Move frames in edit mode.
    * Open the options with `/hank` or `/hankk`, take effect after a UI reload.
    * Sizes and colors can be edited in [Config.lua](oUF_Hankk/Config.lua).

* Support frames:
    * Player and pet, target and tot/tott, focus and fot/fott.
    * OptionalParty, boss, and arena frames.
    * Specialization water-fill icons for party members; skulls for bosses and arena opponents.
* Elements:
    * Show aura for target, focus, party, boss, and arena frames
    *  Threat glow for player and party.
* Forever-specific feature:
    * first-name-only display
    * colored hunter-pet happiness text.
* Retail-specific feature:
    * Grayscale debuffs cast by others on the target.
* Layout and elements adjust:
    * smaller focus frames
    * class-colored health digits
    * simplified values display
    * idle fading

## Textures

* **Digits and symbols:** redrawn in 256×256 atlas cells, with separate base, fill, and glow layers.
* **Specialization icons:** 40 icons in 256×256 cells, adapted from ToxiUI designs with custom redraws and refinements.
* **Status, faction, and class-resource icons:** redrawn at 128×128.

## Font

Hankk Sans DIN combines:

* Latin and Cyrillic from [DINish Condensed](https://github.com/playbeing/dinish).
* Chinese and Korean from [Nowar Sans Dragonflight](https://github.com/nowar-fonts/Nowar-Sans-Dragonflight), using its TC CJK font.

## Installation

Copy the `oUF_Hankk` folder into `World of Warcraft/<client>/Interface/AddOns/`. oUF is bundled; a separate installation is not required.

## Credits and License

Thanks to Hank, Gwyd, the oUF team, oUF_Ruri contributors, ToxiUI, and the font authors.

* Hankk code: [MIT](LICENSE).
* oUF: [MIT](oUF_Hankk/Libs/oUF/LICENSE.txt).
* Hankk Sans DIN: [SIL OFL 1.1](oUF_Hankk/Media/Fonts/OFL.txt).
* oUF_Ruri-derived code and textures: custom license (All rights reserved).
* ToxiUI-derived artwork: ToxiUI License Agreement (All rights reserved).
* Original oUF_Hank artwork: no explicit license found.
