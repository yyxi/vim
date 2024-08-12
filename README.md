## Install

```sh
git clone --depth 1 --recursive https://github.com/yyxi/vim.git ~/.vim
~/.vim/manage install
```

## Keys

|                    | Vim
|                 ---|---
| \\f                | file finder
| \\b                | buffer finder
| \\w                | choose window
| \s                 | show all the symbols in the current buffer
| \S                 | show all the symbols in the workspace
| \a                 | show the list of available code actions
| \a                 | show the list of available code actions in the visual selection
| xr                 | renames all references to the symbol under the cursor
| xR                 | show the references for the symbol under the cursor
| xd                 | show the definition for the symbols under the cursor
| xD                 | show the declaration for the symbols under the cursor
| xt                 | show the type definition for the symbols under the cursor
| xi                 | show the implementation for the symbols under the cursor
| K                  | display hover information about the symbol under the cursor
| gnn                | in normal mode, start incremental selection
| grn                | in visual mode, increment to the upper named parent
| grc                | in visual mode, increment to the upper scope
| grm                | in visual mode, decrement to the previous named node
| gc{motion}         | toggle comments
| gc{Count}c{motion} | toggle comment text with count argument
| gcc                | toggle comment for the current line
| gC{motion}         | comment region
| gCc                | comment the current line
| gs{motion}         | sort
| s                  | sneak
| zz                 | move current line to the middle of the screen
| zt                 | move current line to the top of the screen
| zb                 | move current line to the bottom of the screen
| Ctrl-e             | moves screen up one line
| Ctrl-y             | moves screen down one line
| Ctrl-u             | moves screen up ½ page
| Ctrl-d             | moves screen down ½ page
| Ctrl-b             | moves screen up one page
| Ctrl-f             | moves screen down one page

## Abbreviations

### Greek letters

#### Uppercase greek

  Abbreviations  | Character
:---------------:|:---------:
`\GA`  `\Alpha`  |     Α
`\GB`  `\Beta`   |     Β
`\GG`  `\Gamma`  |     Γ
`\GD`  `\Delta`  |     Δ
`\GE`  `\Epsilon`|     Ε
`\GZ`  `\Zeta`   |     Ζ
`\GH`  `\Eta`    |     Η
`\GTH` `\Theta`  |     Θ
`\GI`  `\Iota`   |     Ι
`\GK`  `\Kappa`  |     Κ
`\GL`  `\Lambda` |     Λ
`\GM`  `\Mu`     |     Μ
`\GN`  `\Nu`     |     Ν
`\GX`  `\Xi`     |     Ξ
`\GO`  `\Omicron`|     Ο
`\GP`  `\Pi`     |     Π
`\GR`  `\Rho`    |     Ρ
`\GS`  `\Sigma`  |     Σ
`\GT`  `\Tau`    |     Τ
`\GU`  `\Upsilon`|     Υ
`\GF`  `\Phi`    |     Φ
`\GC`  `\Chi`    |     Χ
`\GPS` `\Psi`    |     Ψ
`\GW`  `\Omega`  |     Ω

#### Lowercase greek

  Abbreviations  | Character
:---------------:|:---------:
`\ga`  `\alpha`  |     α
`\gb`  `\beta`   |     β
`\gg`  `\gamma`  |     γ
`\gd`  `\delta`  |     δ
`\ge`  `\epsilon`|     ε
`\gz`  `\zeta`   |     ζ
`\gh`  `\eta`    |     η
`\gth` `\theta`  |     θ
`\gi`  `\iota`   |     ι
`\gk`  `\kappa`  |     κ
`\gl`  `\lambda` |     λ
`\gm`  `\mu`     |     μ
`\gn`  `\nu`     |     ν
`\gx`  `\xi`     |     ξ
`\go`  `\omicron`|     ο
`\gp`  `\pi`     |     π
`\gr`  `\rho`    |     ρ
`\gs`  `\sigma`  |     σ
`\gt`  `\tau`    |     τ
`\gu`  `\upsilon`|     υ
`\gf`  `\phi`    |     φ
`\gc`  `\chi`    |     χ
`\gps` `\psi`    |     ψ
`\gw`  `\omega`  |     ω

### Shapes

  Abbreviations  | Character
:---------------:|:---------:
   `\box`        |     □
   `\bbox`       |     ■
   `\sbox`       |     ▫
   `\sbbox`      |     ▪
   `\square`     |     □
   `\bsquare`    |     ■
   `\ssquare`    |     ▫
   `\sbsquare`   |     ▪
   `\diamond`    |     ◇
   `\bdiamond`   |     ◆
   `\lozenge`    |     ◊
   `\circle`     |     ○
   `\bcircle`    |     ●
   `\dcircle`    |     ◌
   `\triangle`   |     △
   `\btriangle`  |     ▲
   `\skull`      |     ☠
   `\danger`     |     ☡
   `\radiation`  |     ☢
   `\biohazard`  |     ☣
   `\yinyang`    |     ☯
   `\frownie`    |     ☹
   `\smiley`     |     ☺
   `\blacksmiley`|     ☻
   `\sun`        |     ☼
   `\rightmoon`  |     ☽
   `\leftmoon`   |     ☾
   `\female`     |     ♀
   `\male`       |     ♂

### Miscellaneous

  Abbreviations  | Character
:---------------:|:---------:
`\dagger`        |     †
`\ddager`        |     ‡
`\prime`         |     ′
`\second`        |     ″
`\third`         |     ‴
`\fourth`        |     ⁗
`\euro`          |     €

### Math symbols

  Abbreviations  | Character
:---------------:|:---------:
`\pm`            |     ±
`\mp`            |     ∓
`\sum`           |     ∑
`\prod`          |     ∏
`\coprod`        |     ∐
`\qed`           |     ∎
`\ast`           |     ∗
`times`          |     ×
`\div`           |     ÷
`\bullet`        |     •
`\o` `\comp` `\circ`|     ∘
`\.` `\cdot`     |     ∙
`\:`             |     ∶
`\::`            |     ∷
`\sqrt`          |     √
`\sqrt3`         |     ∛
`\sqrt4`         |     ∜
`\inf`           |     ∞
`\propto`        |     ∝
`\pitchfork`     |     ⋔
`\all` `\forall` |     ∀
`\ex` `\exists`  |     ∃
`\nex` `\nexists`|     ∄

#### Brackets

  Abbreviations  | Character
:---------------:|:---------:
  `\lceil`       |     ⌈
  `\rceil`       |     ⌉
  `\lfloor`      |     ⌊
  `\rfloor`      |     ⌋
  `\langle`      |     ⟨
  `\rangle`      |     ⟩
  `\llens`       |     ⦇
  `\rlens`       |     ⦈
  `\[[`          |     ⟦
  `\]]`          |     ⟧

#### Set theory

  Abbreviations  | Character
:---------------:|:---------:
  `\empty` `\emptyset`|     ∅
  `\in`          |     ∈
  `\notin`       |     ∉
  `\cap` `\inters`|     ∩
  `\cup` `\union`|     ∪
  `\subset`      |     ⊂
  `\supset`      |     ⊃
  `\nsubset`     |     ⊄
  `\nsupset`     |     ⊅
  `\subseteq`    |     ⊆
  `\supseteq`    |     ⊇
  `\nsubseteq`   |     ⊈
  `\nsupseteq`   |     ⊉

#### Lattices

  Abbreviations  | Character
:---------------:|:---------:
  `\sqsubset`    |     ⊏
  `\sqsupset`    |     ⊐
  `\sqsubseteq`  |     ⊑
  `\sqsupseteq`  |     ⊒
  `\sqcap`       |     ⊓
  `\sqcup`       |     ⊔

#### Logic

  Abbreviations  | Character
:---------------:|:---------:
  `\land` `\and` |     ∧
  `\lor` `\or`   |     ∨
  `\lnot` `\not` `\neg`|     ¬
  `\top`         |     ⊤
  `\bot`         |     ⊥
  `\multimap` `\-o`|     ⊸
  `\multimapinv` `\invmultimap`|     ⟜
  `\parr` `\invamp`|     ⅋
  `\therefore`   |     ∴
  `\because`     |     ∵

#### Calculus

  Abbreviations  | Character
:---------------:|:---------:
  `\grad` `\nabla`|     ∇
  `\partial`     |     𝜕
  `\inc` `\increment`|     ∆
  `\int`         |     ∫
  `\iint`        |     ∬
  `\iiint`       |     ∭
  `\oint`        |     ∮
  `\oiint`       |     ∯
  `\oiiint`      |     ∰

#### Equalities

  Abbreviations  | Character
:---------------:|:---------:
`\sim`  `\~`     |     ∼
`\nsim` `\~n`    |     ≁
`\simeq`  `\=~`  |     ≃
`\nsimeq` `\=~n` |     ≄
`\cong` `\iso` `\==~` | ≅
`\ncong` `\niso` `\==~n` | ≇
`\approx`  `\~2` |     ≈
`\napprox` `\~2n`|     ≉
`\neq` `\=n` `\!=` `\/=` | ≠
`\equiv` `\===`  |     ≡
`\nequiv` `\===n`|     ≢
`\Equiv`         |     ≣

#### Inequalities
  Abbreviations  | Character
:---------------:|:---------:
`\leq` `\<=`     |     ≤
`\nleq` `\<=n`   |     ≰
`\geq` `\>=`     |     ≥
`\ngeq` `\>=n`   |     ≱
`\ll` `\<<`      |     «
`\lll`           |     ⋘
`\gg` `\>>`      |     »
`\ggg`           |     ⋙

#### Entailment (turnstiles)
  Abbreviations  | Character
:---------------:|:---------:
`\ent` `\entails` `\vdash` `\\|-` | ⊢
`\nent` `\nentails` `\nvdash` `\\|-n` | ⊬
`\dashv` `\-\|`   |     ⊣
`\models` `\vDashh` `\\|=` | ⊨
`\nvDash` `\\|=n` |     ⊭
`\Vdash` `\\|\|-`  |     ⊩
`\nVdash` `\\|\|-n`|     ⊮
`\VDash` `\\|\|=`   |     ⊫
`\nVDash` `\\|\|=n` |     ⊯
`\Vvdash` `\\|\|\|-` |     ⊪

#### Circled operators
  Abbreviations  | Character
:---------------:|:---------:
`\oplus` `\o+`   |     ⊕
`\ominus` `\o-`  |     ⊖
`\otimes` `\ox`  |     ⊗
`\oslash` `\o/`  |     ⊘
`\odot` `\o.`    |     ⊙
`\ocirc` `\oo`   |     ⊚
`\oast` `\o*`    |     ⊛
`\oequal` `\o=`  |     ⊜

#### Boxed operators
  Abbreviations  | Character
:---------------:|:---------:
`\boxplus` `\bplus` `\b+` | ⊞
`\boxminus` `\bminus` `\b-` | ⊟
`\boxtimes` `\btimes` `\bx` | ⊠
`\boxdot` `\bdot` `\b.` | ⊡

#### Dots
  Abbreviations  | Character
:---------------:|:---------:
`\ldots` `\...`  |     …
`\cdots`         |     ⋯
`\vdots`         |     ⋮
`\iddots`        |     ⋰
`\ddots`         |     ⋱

### Arrows

#### Simple arrows
  Abbreviations  | Character
:---------------:|:---------:
`\mapsto`        |     ↦
`\to` `\arrow` `\rarrow` `\rightarrow` `\->` | →
`\larrow` `\leftarrow` `\<-` | ←
`\uarrow` `\uparrow` `\-^` `\-!` | ↑
`\darrow` `\downarrow` `\-v` | ↓
`\lrarrow` `\leftrightarrow` | ↔
`\udarrow` `\updownarrow` `\^-v` `\!-v` | ↕
`\nwarrow`       |     ↖
`\nearrow`       |     ↗
`\searrow`       |     ↘
`\swarrow`       |     ↙

#### Double arrows
  Abbreviations  | Character
:---------------:|:---------:
`\To` `\Arrow` `\Rarrow` `\Rightarrow` `\=>` | ⇒
`\Larrow` `\Leftarrow` `\=<` | ⇐
`\Uarrow` `\Uparrow` `\=^` `\=!` | ⇑
`\Darrow` `\Downarrow` `\=v` | ⇓
`\Lrarrow` `\Leftrightarrow` | ⇔
`\Udarrow` `\Updownarrow` `\^=v` `\!=v` | ⇕
`\Nwarrow`       |     ⇖
`\Nearrow`       |     ⇗
`\Searrow`       |     ⇘
`\Swarrow`       |     ⇙

### Sets
  Abbreviations  | Character
:---------------:|:---------:
`\Bool` `\Bools` `\Boolean` `\Booleans` `\bb` | 𝔹
`\Ints` `\Integers` `\bz` | ℤ
`\Rats` `\Rationals` `\bq` | ℚ
`\Reals` `\br`   |     ℝ
`\Comps` `\Complex` `\Complexes` `\bc` | ℂ
`\Quats` `\Quaternions` `\bh` | ℍ
`\Primes` `\bp`  |     ℙ

### Fractions
  Abbreviations  | Character
:---------------:|:---------:
`\frac14`        |     ¼
`\frac12`        |     ½
`\frac34`        |     ¾
`\frac13`        |     ⅓
`\frac23`        |     ⅔
`\frac15`        |     ⅕
`\frac25`        |     ⅖
`\frac35`        |     ⅗
`\frac45`        |     ⅘
`\frac16`        |     ⅙
`\frac56`        |     ⅚
`\frac18`        |     ⅛
`\frac38`        |     ⅜
`\frac58`        |     ⅝
`\frac78`        |     ⅞

### Subscripts
  Abbreviations  | Character
:---------------:|:---------:
`\_a`            |     ₐ
`\_e`            |     ₑ
`\_h`            |     ₕ
`\_i`            |     ᵢ
`\_j`            |     ⱼ
`\_k`            |     ₖ
`\_l`            |     ₗ
`\_m`            |     ₘ
`\_n`            |     ₙ
`\_o`            |     ₒ
`\_p`            |     ₚ
`\_r`            |     ᵣ
`\_s`            |     ₛ
`\_t`            |     ₜ
`\_u`            |     ᵤ
`\_v`            |     ᵥ
`\_x`            |     ₓ
`\_0`            |     ₀
`\_1`            |     ₁
`\_2`            |     ₂
`\_3`            |     ₃
`\_4`            |     ₄
`\_5`            |     ₅
`\_6`            |     ₆
`\_7`            |     ₇
`\_8`            |     ₈
`\_9`            |     ₉
`\_+`            |     ₊
`\_-`            |     ₋
`\_=`            |     ₌
`\_(`            |     ₍
`\_)`            |     ₎

### Superscripts
  Abbreviations  | Character
:---------------:|:---------:
`\^a`            |     ᵃ
`\^b`            |     ᵇ
`\^c`            |     ᶜ
`\^d`            |     ᵈ
`\^e`            |     ᵉ
`\^f`            |     ᶠ
`\^g`            |     ᵍ
`\^h`            |     ʰ
`\^i`            |     ⁱ
`\^j`            |     ʲ
`\^k`            |     ᵏ
`\^l`            |     ˡ
`\^m`            |     ᵐ
`\^n`            |     ⁿ
`\^o`            |     ᵒ
`\^p`            |     ᵖ
`\^r`            |     ʳ
`\^s`            |     ˢ
`\^t`            |     ᵗ
`\^u`            |     ᵘ
`\^v`            |     ᵛ
`\^w`            |     ʷ
`\^x`            |     ˣ
`\^y`            |     ʸ
`\^z`            |     ᶻ
`\^A`            |     ᴬ
`\^B`            |     ᴮ
`\^D`            |     ᴰ
`\^E`            |     ᴱ
`\^G`            |     ᴳ
`\^H`            |     ᴴ
`\^I`            |     ᴵ
`\^J`            |     ᴶ
`\^K`            |     ᴷ
`\^L`            |     ᴸ
`\^M`            |     ᴹ
`\^N`            |     ᴺ
`\^O`            |     ᴼ
`\^P`            |     ᴾ
`\^R`            |     ᴿ
`\^T`            |     ᵀ
`\^U`            |     ᵁ
`\^V`            |     ⱽ
`\^W`            |     ᵂ
`\^0`            |     ⁰
`\^1`            |     ¹
`\^2`            |     ²
`\^3`            |     ³
`\^4`            |     ⁴
`\^5`            |     ⁵
`\^6`            |     ⁶
`\^7`            |     ⁷
`\^8`            |     ⁸
`\^9`            |     ⁹
`\^+`            |     ⁺
`\^-`            |     ⁻
`\^=`            |     ⁼
`\^(`            |     ⁽
`\^)`            |     ⁾

### Circled

#### Circled numbers
  Abbreviations  | Character
:---------------:|:---------:
`\(0)`           |     ⓪
`\(1)`           |     ①
`\(2)`           |     ②
`\(3)`           |     ③
`\(4)`           |     ④
`\(5)`           |     ⑤
`\(6)`           |     ⑥
`\(7)`           |     ⑦
`\(8)`           |     ⑧
`\(9)`           |     ⑨
`\(10)`          |     ⑩
`\(11)`          |     ⑪
`\(12)`          |     ⑫
`\(13)`          |     ⑬
`\(14)`          |     ⑭
`\(15)`          |     ⑮
`\(16)`          |     ⑯
`\(17)`          |     ⑰
`\(18)`          |     ⑱
`\(19)`          |     ⑲
`\(20)`          |     ⑳

#### Uppercase circled
  Abbreviations  | Character
:---------------:|:---------:
`\(A)`           |     Ⓐ
`\(B)`           |     Ⓑ
`\(C)`           |     Ⓒ
`\(D)`           |     Ⓓ
`\(E)`           |     Ⓔ
`\(F)`           |     Ⓕ
`\(G)`           |     Ⓖ
`\(H)`           |     Ⓗ
`\(I)`           |     Ⓘ
`\(J)`           |     Ⓙ
`\(K)`           |     Ⓚ
`\(L)`           |     Ⓛ
`\(M)`           |     Ⓜ
`\(N)`           |     Ⓝ
`\(O)`           |     Ⓞ
`\(P)`           |     Ⓟ
`\(Q)`           |     Ⓠ
`\(R)`           |     Ⓡ
`\(S)`           |     Ⓢ
`\(T)`           |     Ⓣ
`\(U)`           |     Ⓤ
`\(V)`           |     Ⓥ
`\(W)`           |     Ⓦ
`\(X)`           |     Ⓧ
`\(Y)`           |     Ⓨ
`\(Z)`           |     Ⓩ

#### Lowercase circled
  Abbreviations  | Character
:---------------:|:---------:
`\(a)`           |     ⓐ
`\(b)`           |     ⓑ
`\(c)`           |     ⓒ
`\(d)`           |     ⓓ
`\(e)`           |     ⓔ
`\(f)`           |     ⓕ
`\(g)`           |     ⓖ
`\(h)`           |     ⓗ
`\(i)`           |     ⓘ
`\(j)`           |     ⓙ
`\(k)`           |     ⓚ
`\(l)`           |     ⓛ
`\(m)`           |     ⓜ
`\(n)`           |     ⓝ
`\(o)`           |     ⓞ
`\(p)`           |     ⓟ
`\(q)`           |     ⓠ
`\(r)`           |     ⓡ
`\(s)`           |     ⓢ
`\(t)`           |     ⓣ
`\(u)`           |     ⓤ
`\(v)`           |     ⓥ
`\(w)`           |     ⓦ
`\(x)`           |     ⓧ
`\(y)`           |     ⓨ
`\(z)`           |     ⓩ
