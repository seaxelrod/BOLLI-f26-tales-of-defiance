---
title: "README"
---

```bash

pandoc home.md -s \
  --css="https://fonts.googleapis.com/css2?family=Oswald:wght@500;600&family=Open+Sans:ital,wght@0,400;0,600;1,600&display=swap" \
  -c styles.css \
  -o home.html

pandoc week1.md -s \
  --css="https://fonts.googleapis.com/css2?family=Oswald:wght@500;600&family=Open+Sans:ital,wght@0,400;0,600;1,600&display=swap" \
  -c styles.css \
  -o week1.html
```
