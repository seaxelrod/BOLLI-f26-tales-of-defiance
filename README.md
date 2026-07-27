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

### note initially started repository with underscores rather than dashes, but changed it with

```bash
git remote set-url origin https://github.com/seaxelrod/BOLLI-f26-tales-of-defiance.git

```


# Link Local Folder and Push
```bash
git branch -M main
git remote add origin https://github.com/YOUR-USERNAME/YOUR-REPO-NAME.git
git push -u origin main
```

# convert .md pages to .html
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
