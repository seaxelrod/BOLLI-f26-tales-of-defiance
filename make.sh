#/bin/bash
# source this file in shell to define steps in making

# convert .md pages to .html

git_makehtml () {

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
}
    
# test locally with

get_testlocal  () {
    open http://localhost:8000/index.html in Safari  # refresh this after server runs and waits for break on next command
    python3 -m http.server 8000
}


git_push () {
    if [ -z "$1" ]; then
	comment="changes";
    else
        comment="$*";
    fi
    echo "pusing with comment: '$comment'"
    git add .
    git commit -m "$comment"
    git push
}
