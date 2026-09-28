#/bin/bash
# source this file in shell to define function for each step in making

# convert .md pages to .html

git_makehtml_noTOC () {
    filebase=$1;
    # pandoc used to have:
    # 	   --css="https://fonts.googleapis.com/css2?family=Oswald:wght@500;600&family=Open+Sans:ital,wght@0,400;0,600;1,600&display=swap" \
    # 	   --embed-resources \
    pandoc $filebase.md -s \
           --filter pandoc-include  \
	   -H header.html \
	   -c styles.css \
	   -o $filebase.html 
}


git_makehtml_force () {
    local filebase=$1;
    local src="$1.md"
    local out="$1.html"
    echo "Compiling $src -> $out..."
    pandoc $src -s \
       --filter /Users/axelrod/.local/bin/pandoc-include  \
       -H header.html \
       -c styles.css \
       -o $out \
       --toc --toc-depth=2
}

git_makehtml () {
    local filebase=$1;
    local src="$1.md"
    local out="$1.html"
    
    # Recompile if output doesn't exist OR input, header, or styles  is newer than output
    if [ ! -f "$out" ] || [ "$src" -nt "$out" ] || [ "header.html" -nt "$out" ] || [ "styles.css" -nt "$out" ]; then
	git_makehtml_force $filebase
    else
        echo "$out is up to date."
    fi
}

git_makehtml_all () {
  git_makehtml DMC_syllabus;
  git_makehtml DMC_preface;
  git_makehtml DMC_week1;
}


git_makepdf () {
    # file links don't work with this, use mdtohtmlpdf
    
    local filebase=$1;
    local src="$1.md"
    local out="$1.pdf"
    
    # Recompile if output doesn't exist OR input is newer than output
    if [ ! -f "$out" ] || [ "$src" -nt "$out" ]; then
        echo "Compiling $src -> $out..."
	dir=$(dirname "$filebase");
	src_file=$(basename "$src");
	out_file=$(basename "$out");
	(cd $dir;
         echo -n "compile dir: "; pwd
	 pandoc --toc --toc-depth=2 -V geometry:margin=1in --pdf-engine=xelatex -s $src_file --standalone \
         --filter /Users/axelrod/.local/bin/pandoc-include  \
         --math-method=mathjax  -V colorlinks -V linkcolor=blue -V urlcolor=NavyBlue -o $out_file 
        )
    else
        echo "$out is up to date."
    fi
}

git_makelocal () {
    # after this, should be able to view files locally at: file:///Users/axelrod/Library/CloudStorage/Dropbox/sync/writing/j26/2026f_BOLLI/2026f_mind_control/git/index.html

    git_makehtml syllabus;
    git_makehtml DMC_preface;
    git_makepdf DMC_preface;
    git_makehtml week1;
    git_makehtml mind_control_1/mind_control_1;
    git_makepdf  mind_control_1/mind_control_1;  

}
    
# test locally with

git_testlocal_allowcache  () {
    # after this, should be able to view files on python server at:  http://localhost:8000/index.html 
    open http://localhost:8000/index.html   # refresh this after server runs and waits for break on next command
    python3 -m http.server 8000
}

git_testlocal  () {
python3 -c "import http.server, socketserver;
class NoCacheHandler(http.server.SimpleHTTPRequestHandler):
    def end_headers(self):
        self.send_header('Cache-Control', 'no-store, no-cache, must-revalidate')
        super().end_headers()
socketserver.TCPServer(('', 8000), NoCacheHandler).serve_forever()"
}


git_push () {
    # after this, and wait, should be able to view at: https://seaxelrod.github.io/BOLLI-f26-tales-of-defiance/
    # push all changes to git, with comment concatenation of arg (with space in between)
    # have to wait a minut or two for git to install
    if [ -z "$1" ]; then
	comment="changes";
    else
        comment="$*";
    fi
    echo "pusing with comment: '$comment'"
    git add .
    git commit -m "$comment"
    git pus
}
