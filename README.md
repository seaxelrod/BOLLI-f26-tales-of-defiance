---
title: "README"
---

- git reposityory name: BOLLI-f26-tales-of-defiance

# create git on local machine 
```bash
cd  /Users/axelrod/writing/j26/2026f_BOLLI/2026f_mind_control/git

git init
git add .
git commit -m "Initial commit with compiled site files"
```

# create repository BOLLI-f26-tales-of-defiance

- Go to GitHub and click the + icon in the top-right corner, then select New repository.
- Give your repository a name (e.g., course-site or bolli-course).
- Set it to Public (GitHub Pages requires a public repository unless you have a paid GitHub Pro/Enterprise account).
- Do not initialize with a README, .gitignore, or license (leave those unchecked).
- Click Create repository.

```


# Link Local Folder and Push
```bash
git branch -M main
git remote add origin https://github.com/seaxelrod/BOLLI-f26-tales-of-defiance.git
git push -u origin main
```

# see make.sh

# 20260815   conver logo to svg

```bash
> pdf2svg BOLLI_logo.pdf BOLLI_logo.svg
```

# also converted to png, but that came out fuzzy, so I delete it

```bash
> sips -s format png BOLLI_logo.pdf --out BOLLI_logo.png
> rm BOLL_logo.png
```

# 20261119 create python venv in the github repository

This uses packages need for highlighting.

-   Create once: `> python3 -m venv .venv`
-   Install once: `.venv/bin/pip install pdfplumber pypdf`
-  Run with:  `.venv/bin/python3 filters/highlight_pdf.py ...`



	
