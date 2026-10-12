
pandoc DMC_syllabus.md -s --filter=/Users/axelrod/.local/bin/pandoc-include.py -H header.html --css=styles.css -o DMC_syllabus.html --toc --toc-depth=2


pandoc DMC_syllabus.md -s --embed-resources --filter="/Users/axelrod/.local/bin/pandoc-include.py" -H "/Users/axelrod/writing/j26/2026f_BOLLI/2026f_mind_control/git/header.html" --css="/Users/axelrod/writing/j26/2026f_BOLLI/2026f_mind_control/git/styles.css" -o DMC_syllabus.html --toc --toc-depth=2
