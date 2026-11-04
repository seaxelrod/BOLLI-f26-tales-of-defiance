#!/usr/bin/env bash


pdftk A=DMC_Week1_NotesFromUnderground_without_popups.pdf B=DMC_Week1_NotesFromUnderground.pdf cat A1-3 B3 A4-12 B12 A13-end output DMC_Week1_NotesFromUnderground_merge.pdf 
