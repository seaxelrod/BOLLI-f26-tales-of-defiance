#/bin/bash

# custom make script for "Tales of Defiance Course"
#  Main function is to  convert .md pages to .html and .pdf
# source this file in shell to define function for each step in making
#
# Possible changes:
#  Add pandoc flag "-f markdown-blank_before_list" so that I don't need a newline before starting a list.

# =======================
# Flags and files
# =======================

export TOCFLAGS_standard="--toc --toc-depth=2"
export TOCFLAGS="$TOCFLAGS_standard"
export TOCFLAGS_beamer="--toc"

export filesToMake=(
  # in index.html
  course_web_site_instructions
  "DMC_welcome  DMC_week1_homework"
  DMC_syllabus  
  "DMC_preface DMC_preface_notes_from_underground DMC_preface_1984 DMC_preface_thematrix DMC_preface_perfectmatch"
  "DMC_week1 DMC_week1_homework"
  "DMC_week2 DMC_week2_homework"
  "DMC_week3 DMC_week3_homework"
  "DMC_week4 DMC_week4_homework"
  "DMC_week5 DMC_week5_homework"
  "DMC_notes_on_notes  DMC_preface_notes_from_underground"
  "DMC_notes_on_thematrix DMC_preface_thematrix"
  "DMC_notes_on_perfectmatch DMC_preface_perfectmatch"
  mind_control_1/DMC_cartoons
  mind_control_1/not_the_keys_of_a_piano_dialog
  materials/DMC_references_and_info
  materials/notes_from_underground/notes_from_underground_existentialist_philosphy_literature_philosophy_guy_transcript  
  mind_control_extras/DMC_notesfrumunderground_context 
  mind_control_extras/TheTriadChapter1 
  mind_control_extras/DMC_protagonists_react_to_manifesto 
  mind_control_extras/DMC_question_responses_by_characters_and_students 
  mind_control_extras/UndergroundBarbie 
  mind_control_extras/DMC_Chronology   
  mind_control_extras/PanelOfTheDefiant 
  mind_control_extras/TwoKindsOfControl 
  mind_control_extras/Foucault_timeline 

  # not in index.html
  materials/DMC_bruner_narrative_theory 
  materials/DMC_references_and_info_for_course_overall
  materials/notes_from_underground/notes_from_underground_existentialist_philosphy_literature_philosophy_guy_transcript 
  materials/notes_from_underground/NotesFromUnderground_CedarTranscript  
  materials/notes_from_underground/NotesFromUnderground_CedarViewingGuide
  materials/notes_from_underground/notes_from_underground_references_and_info
  materials/1984/1984_references_and_info
  materials/1984/1984_radford_transcript
  materials/thematrix/thematrix_references_and_info
  materials/thematrix/TheMatrix_screenplay
  mind_control_2/Class2_Outlier_to_1984_md
  mind_control_3/the_matrix_and_the_philosophers
  mind_control_3/the_matrix_and_the_philosophers_AI_summaries
  mind_control_3/the_matrix_and_the_rest_of_us
  mind_control_3/the_matrix_and_the_rest_of_us_AI_summaries
  mind_control_3/simulation_rogan_musk
  mind_control_3/simulation_rogan_musk_AI_summaries
  materials/thematrix/Behind_the_Musk_Documentary
  materials/thematrix/AlexGibneyOnMusk_summary
  materials/perfect_match/perfect_match_references_and_info
  materials/wrapup/wrapup_references_and_info
)

export filesForBeamer=(
  mind_control_3/week3_presentation
)

# ====================
# helper function
# ====================

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
      echo "Warning:  $dep does not exist"
      return 1
    fi

    # If target is NOT newer than dep, it fails
    if [[ ! "$target" -nt "$dep" ]]; then
      return 1
    fi
  done

  return 0
}

# ==========================================
#  Core Engine: Markdown to HTML
# ==========================================
_git_build_html () {
    local mode=$1
    local filebase=$2
    shift 2
    local deps=("${@/%/.md}")

    thisDir=`pwd`
    if [[ ! `basename $thisDir` == "git" ]]; then
        echo "Error: $0 must run from git directory"
        return 1
    fi

    local src="${filebase}.md"
    local out="${filebase}.html"

    # Recompile if output doesn't exist OR dependencies are newer
    if is_newer_than_all "$out" "$src" "header.html" "filters/table-pipe.lua" "filters/pandoc_markdown_dual_tables.py" "${deps[@]}"; then
        : # echo "$out is up to date."
    else
        echo "Compiling $src -> $out (HTML mode: $mode)..."
        filterDir="${thisDir}/filters"
        TIMESTAMP=`timestring` # or $(date +%s)

        # 1. Strip away all characters EXCEPT slashes
        local slashes="${filebase//[^\/]/}"
        # 2. Replace every remaining slash with "../"
        local REL_PREFIX="${slashes//\//../}"

        local mode_flags=""
        if [[ "$mode" == "toc" ]]; then
            mode_flags="--toc --toc-depth=2"
        fi

        pandoc "$src" -s \
         --lua-filter="${filterDir}/pandoc-include.lua" \
         --lua-filter="${filterDir}/table-pipe.lua" \
         -H "${thisDir}/header.html" \
         --variable header-includes="<script src=\"${REL_PREFIX}nav-sync.js?v=$TIMESTAMP\"></script>" \
         --css="${REL_PREFIX}styles.css?v=$TIMESTAMP" \
         $mode_flags \
         -o "$out"
    fi
}

git_makehtml () {
    _git_build_html "toc" "$@"
}

git_makehtml_notoc () {
    _git_build_html "notoc" "$@"
}

# ==========================================
#  Core Engine: Markdown to LaTeX/PDF
# ==========================================
_git_build_latex () {
    local mode=$1
    local filebase=$2
    shift 2  # shift off mode and filebase to leave only the dependencies
    local deps=("${@/%/.md}")

    thisDir=`pwd`
    if [[ ! `basename $thisDir` == "git" ]]; then
        echo "Error: $0 must run from git directory"
        return 1
    fi

    local src="${filebase}.md"
    local out=""
    
    # Set output filename based on mode
    if [[ "$mode" == "beamer" ]]; then
        out="${filebase}_beamer.pdf"
    elif [[ "$mode" == "beamer_withnotes" ]]; then
        out="${filebase}_beamer_withnotes.pdf"
    elif [[ "$mode" == "beamer_onlynotes" ]]; then
        out="${filebase}_beamer_onlynotes.pdf"
    else
        out="${filebase}.pdf"
    fi

    # Recompile if output doesn't exist OR dependencies are newer
    if is_newer_than_all "$out" "$src" "header.tex" "filters/prefix-links.lua" "filters/table-pipe.lua" "filters/pandoc_markdown_dual_tables.py" "${deps[@]}"; then
        : # echo "$out is up to date."
    else
        echo "Compiling $src -> $out ($mode)..."
        filterDir="${thisDir}/filters"
        dir=$(dirname "$filebase")
        src_file=$(basename "$src")
        out_file=$(basename "$out")

        # Set flags based on mode
        local format_flags=""
        local notes_flags=()
        
        if [[ "$mode" == *"beamer"* ]]; then
            # Beamer handles its own margins and geometry
            format_flags="-t beamer -V theme:metropolis $TOCFLAGS_beamer"
            
            # Dynamically inject note options for specific builds
            if [[ "$mode" == "beamer_withnotes" ]]; then
                notes_flags=(-V header-includes='\usepackage{pgfpages}' -V header-includes='\setbeameroption{show notes on second screen=right}')
            elif [[ "$mode" == "beamer_onlynotes" ]]; then
                notes_flags=(-V header-includes='\setbeameroption{show only notes}')
            fi
        else
            # Standard article geometry and TOC
            format_flags="$TOCFLAGS -V geometry:margin=1in"
        fi

        (cd "$dir"
         pandoc $format_flags "${notes_flags[@]}" --pdf-engine=xelatex -s "$src_file" \
         -V monofont="Courier New" \
         -M doc_dir="$dir" \
         --include-in-header="${thisDir}/header.tex" \
         --lua-filter="${filterDir}/pandoc-include.lua" \
         --lua-filter="${filterDir}/toc-if-headings.lua" \
         --lua-filter="${filterDir}/table-pipe.lua" \
         --lua-filter="${filterDir}/prefix-links.lua" \
         --lua-filter="${filterDir}/straighten-quotes.lua" \
         --math-method=mathjax \
         -V colorlinks=true -V linkcolor=blue -V urlcolor=blue -V toccolor=blue \
         -o "$out_file"
        )
    fi
}

git_makepdf () {
    _git_build_latex "article" "$@"
}

git_makebeamer () {
    _git_build_latex "beamer" "$@"
}

git_makebeamer_withnotes () {
    _git_build_latex "beamer_withnotes" "$@"
}

git_makebeamer_onlynotes () {
    _git_build_latex "beamer_onlynotes" "$@"
}

# ==================================
# iterating through arrays
# ===================================

git_makehtml_all () {
    for fileArgs in "${filesToMake[@]}"
    do
        # Unquoted fileArgs allows Bash to split "base dep1 dep2" into separate arguments
        git_makehtml $fileArgs || return 1
    done
}

git_makepdf_all () {
    for fileArgs in "${filesToMake[@]}"
    do
        git_makepdf $fileArgs || return 1
    done
}

git_makebeamer_all () {
    for fileArgs in "${filesForBeamer[@]}"
    do
        git_makebeamer_withnotes $fileArgs || return 1
        git_makebeamer $fileArgs || return 1
        git_makebeamer_onlynotes $fileArgs || return 1
    done
}

git_make_all() {
    # after this, should be able to view files locally at: file:///Users/axelrod/Library/CloudStorage/Dropbox/sync/writing/j26/2026f_BOLLI/2026f_mind_control/git/index.html
    git_makebeamer_all || return 1;
    git_makehtml_all || return 1;
    git_makepdf_all  || return 1;
    git_make_dev     || return 1;
}

# ==================================
# cleaning
# ===================================

git_clean_html () {
    for fileArgs in "${filesToMake[@]}"; do
        local args=($fileArgs)
        local basefile="${args[0]}"
        if [ ! -f "${basefile}.md" ]; then
           echo "${basefile}.md not found, not removing .html file"
           continue
        fi
        echo "removing ${basefile}.html"
        /bin/rm -f "${basefile}.html"
    done
}

git_clean_pdf () {
    for fileArgs in "${filesToMake[@]}"; do
        local args=($fileArgs)
        local basefile="${args[0]}"
        if [ ! -f "${basefile}.md" ]; then
           echo "${basefile}.md not found, not removing .pdf file"
           continue
        fi
        echo "removing ${basefile}.pdf"
        /bin/rm -f "${basefile}.pdf"
    done
}

git_clean_beamer () {
    for fileArgs in "${filesForBeamer[@]}"; do
        local args=($fileArgs)
        local basefile="${args[0]}"
        if [ ! -f "${basefile}.md" ]; then
           echo "${basefile}.md not found, not removing Beamer PDF files"
           continue
        fi
        echo "removing ${basefile} Beamer PDFs"
        /bin/rm -f "${basefile}_beamer.pdf"
        /bin/rm -f "${basefile}_beamer_withnotes.pdf"
        /bin/rm -f "${basefile}_beamer_onlynotes.pdf"
    done
}

# ==========================
# testing locally
# ===========================

git_testlocal_allowcache  () {
    open http://localhost:8000/index.html   
    python3 -m http.server 8000
}

git_testlocal_old  () {
python3 -c "import http.server, socketserver;
class NoCacheHandler(http.server.SimpleHTTPRequestHandler):
    def end_headers(self):
        self.send_header('Cache-Control', 'no-store, no-cache, must-revalidate')
        super().end_headers()
socketserver.TCPServer(('', 8000), NoCacheHandler).serve_forever()"
}

git_testlocal () {
    python3 serve.py
}

# =======================
# git admin
# ========================

git_push () {
    if [ -z "$1" ]; then
        comment="changes";
    else
        comment="$*";
    fi
    echo "pushing with comment: '$comment'"
    git add .
    git commit -m "$comment"
    git push
}

# =======================
# display
# =======================

git_pdfpc () {
    # e.g. git_pdfpc week3_presentation_beamer.pdf
    env GST_PLUGIN_SCANNER_1_0=/usr/bin/true pdfpc  $1 &
}

# =====================
# development
# =======================

git_make_dev() {
    if is_newer_than_all index_dev.html index.html; then  
        :
    else
        echo "Creating: index_dev.html"
        fgrep -v '@@DEV@@' index.html > index_dev.html
    fi
}

funny_quote_all_search () {
    grep -rnE "\([^\)]*[“”‘’][^\)]*\)|\<[^\>]*[“”‘’][^\>]*\>" ./*.md ./*/*.md ./*/*/*.md
}

funny_quote_search () {
    echo 'In backticks: '
    grep -rnE '`[^`]*[“”‘’][^`]*`' . --include="*.md"
    echo
    echo ' In URLs: '
    grep -rnE '\([^)]*[“”‘’][^)]*\)|<[^>]*[“”‘’][^>]*>' . --include="*.md"
    echo
    echo 'In 4-space indents (code blocks)'
    grep -rnE '^ {4,}.*[“”‘’]' . --include="*.md"
    echo
}

generate_debug () {
    pandoc DMC_preface.md -s \
      --lua-filter=filters/pandoc-include.lua \
      -V header-includes='\tracinglostchars=3' \
      -o debug.tex

    echo 'Checking for Pandoc passthrough macros:'
    grep -nE '\\(passthrough|lstinline).*?[“”‘’]' debug.tex
    echo
    
    echo 'In fenced code block: '
    cat debug.tex | awk '/\\begin\{(verbatim|Highlighting)\}/{f=1} /\\end\{(verbatim|Highlighting)\}/{f=0} f && /[“”‘’]/{print "Line " NR ": " $0}' 
    echo

    echo 'In inline LaTeX macros: '
    grep -nE '(\\texttt|\\url|\\href|\\verb).*?[“”‘’]' debug.tex
    echo

    echo 'Running xelatex and extracting warning from log:'
    xelatex debug.tex >/dev/null 
    grep -C 5 "Missing character: There is no" debug.log
    echo
    
    echo 'Compiling to trap the exact line number:'
    xelatex -halt-on-error debug.tex >/dev/null
    echo
}
