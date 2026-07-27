#/bin/bash

# convert .md pages to .html

pandoc home.md -s \
  --css="https://fonts.googleapis.com/css2?family=Oswald:wght@500;600&family=Open+Sans:ital,wght@0,400;0,600;1,600&display=swap" \
  --embed-resources \
  -H header.html \
  -c styles.css \
  -o home.html

pandoc week1.md -s \
  --css="https://fonts.googleapis.com/css2?family=Oswald:wght@500;600&family=Open+Sans:ital,wght@0,400;0,600;1,600&display=swap" \
  --embed-resources \
  -H header.html \
  -c styles.css \
  -o week1.htm

# test locally with

## > python3 -m http.server 8000
## open http://localhost:8000/index.html in Safari


git add .
git commit -m 'changes'
git push
