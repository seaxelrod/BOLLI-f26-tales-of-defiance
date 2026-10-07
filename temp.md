---
title: "temp"
---

% This requires XeLaTeX or LuaLaTeX as --pdf-engine
% and the newunicodechar package to be installed
\usepackage{newunicodechar}
% Use a font which has the glyph
\newfontfamily\cjkfont{Noto Serif CJK TC}
\newunicodechar{中}{{\cjkfont 中}} % Yes this works!
\newunicodechar{文}{{\cjkfont 文}}
