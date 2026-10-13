#/bin/bash
# source this file in shell to define function for each step in making

# convert .md pages to .html

# isnewer_than_all target  file1 file2 ...
# Returns 0 (true) if $target is newer than all subsequent files passed to it.
# Returns 1 (false) if target is older, equal, missing, or any dependency is newer.
is_newer_than_all() {
  local target="$1"
  shift

  # Target must exist
  if [[ ! -e "$target" ]]; then
    return 1
  fi

  for dep in "$@"; do
    # Fail if dependency does not exist
    if [[ ! -e "$dep" ]]; then
      return 1
    fi

    # If target is NOT newer than dep, it fails
    if [[ ! "$target" -nt "$dep" ]]; then
      return 1
    fi
  done

  return 0
}

git_makehtml_noTOC () {
    filebase=$1;
    # pandoc used to have:
    # 	   --css="https://fonts.googleapis.com/css2?family=Oswald:wght@500;600&family=Open+Sans:ital,wght@0,400;0,600;1,600&display=swap" \
    pandoc $filebase.md -s \
           --filter pandoc-include  \
     	   --embed-resources \
	   -H header.html \
	   -c styles.css \
	   -o $filebase.html 
}


git_makehtml_force () {
    local filebase=$1;
    local src="$1.md"
    local out="$1.html"
    echo "Compiling $src -> $out..."
    thisDir=`pwd`;
    if [[ ! `basename $thisDir`  == "git" ]]; then
	echo "Error: git_makehtml_force $1 must run from git directory" ;
	return 1;
    fi
    # To avoid smart quotes, add flag:  -f markdown-smart 
    pandoc  "$src" -s --embed-resources \
       --filter=/Users/axelrod/.local/bin/pandoc-include  \
       -H "${thisDir}/header.html" \
       --css="${thisDir}/styles.css" \
       -o $out \
       --toc --toc-depth=2
}

git_makehtml () {
    # need -nt $2 , -nt $3, -nt $4, ...  : use  find command
    local filebase=$1;
    local src="$1.md"
    local out="$1.html"
    shift;
    local deps=("${@/%/.md}");
    echo dependencies="${deps[@]}"; 

    # Recompile if output doesn't exist OR input, header,  styles , or other dependencies are newer than output
    if is_newer_than_all $out $src "header.html" "styles.css" "${deps[@]}"; then  
        echo "$out is up to date."
    else
	git_makehtml_force $filebase || return 1
    fi
}

git_makehtml_all () {
  git_makehtml DMC_welcome DMC_week1_homework  || return 1
  git_makehtml DMC_syllabus  || return 1
  git_makehtml DMC_preface DMC_preface_notes_from_underground DMC_preface_1984 DMC_preface_thematrix DMC_preface_perfectmatch
  git_makehtml DMC_week1 DMC_week1_homework
  git_makehtml DMC_week2 DMC_week2_homework  || return 1
  git_makehtml DMC_week3 DMC_week3_homework  || return 1
  git_makehtml DMC_week4 DMC_week4_homework  || return 1
  git_makehtml DMC_week5 DMC_week5_homework  || return 1
  git_makehtml DMC_notes_on_notes DMC_preface_notes_from_underground  || return 1
  git_makehtml DMC_notes_on_1984 DMC_preface_1984  || return 1
  git_makehtml DMC_notes_on_thematrix DMC_preface_thematrix  || return 1
  git_makehtml DMC_notes_on_perfectmatch DMC_preface_perfectmatch  || return 1
  git_makehtml mind_control_1/mind_control_1  || return 1
  git_makehtml materials/notes_from_underground/notes_from_underground_existentialist_philosphy_literature_philosophy_guy_transcript  || return 1
  git_makehtml mind_control_extras/TheTriadChapter1 || return 1
  git_makehtml mind_control_extras/DMC_protagonists_react_to_manifesto || return 1
}


git_makepdf () {
    # file links don't work with this, use mdtohtmlpdf

    
    thisDir=`pwd`;
    if [[ ! `basename $thisDir`  == "git" ]]; then
	echo "Error: git_makepdf $1 must run from git directory" ;
	return 1;
    fi
    
    local filebase=$1;
    local src="$1.md"
    local out="$1.pdf"
    shift;
    local deps=("${@/%/.md}");
    echo dependencies="${deps[@]}"; 
    
    # Recompile if output doesn't exist OR input, header,  prefix, or other dependencies are newer than output
    if is_newer_than_all $out $src "header.tex" "prefix-links.lua" "${deps[@]}"; then  
        echo "$out is up to date."
    else
        echo "Compiling $src -> $out..."
	dir=$(dirname "$filebase");
	src_file=$(basename "$src");
	out_file=$(basename "$out");
	(cd $dir;
         echo -n "compile dir: "; pwd
	 pandoc --toc --toc-depth=2 -V geometry:margin=1in --pdf-engine=xelatex -s $src_file --standalone \
         --include-in-header=${thisDir}/header.tex \
         --filter /Users/axelrod/.local/bin/pandoc-include  \
	 --lua-filter=${thisDir}/prefix-links.lua \
         --math-method=mathjax  -V colorlinks=true -V linkcolor=blue -V urlcolor=blue -V toccolor=blue -o $out_file 
        )
	# url color used to be NavyBlue
    fi
}

git_makepdf_all () {
  git_makepdf DMC_welcome DMC_week1_homework  || return 1
  git_makepdf DMC_syllabus  || return 1
  git_makepdf DMC_preface DMC_preface_notes_from_underground DMC_preface_1984 DMC_preface_thematrix DMC_preface_perfectmatch
  git_makepdf DMC_week1 DMC_week1_homework
  git_makepdf DMC_week2 DMC_week2_homework  || return 1
  git_makepdf DMC_week3 DMC_week3_homework  || return 1
  git_makepdf DMC_week4 DMC_week4_homework  || return 1
  git_makepdf DMC_week5 DMC_week5_homework  || return 1
  git_makepdf DMC_notes_on_notes DMC_preface_notes_from_underground  || return 1
  git_makepdf DMC_notes_on_1984 DMC_preface_1984  || return 1
  git_makepdf DMC_notes_on_thematrix DMC_preface_thematrix  || return 1
  git_makepdf DMC_notes_on_perfectmatch DMC_preface_perfectmatch  || return 1
  git_makepdf mind_control_1/mind_control_1  || return 1
  git_makepdf materials/notes_from_underground/notes_from_underground_existentialist_philosphy_literature_philosophy_guy_transcript  || return 1
  git_makepdf mind_control_extras/TheTriadChapter1 || return 1
  git_makepdf mind_control_extras/DMC_protagonists_react_to_manifesto || return 1
}

git_make_all() {
    # after this, should be able to view files locally at: file:///Users/axelrod/Library/CloudStorage/Dropbox/sync/writing/j26/2026f_BOLLI/2026f_mind_control/git/index.html

    git_makehtml_all || return 1;
    git_makepdf_all  || return 1;
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
    git push
}
