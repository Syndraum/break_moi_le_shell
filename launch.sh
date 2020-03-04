#!/bin/bash

DIR="../minishell"
OUTPUT_DIR="output"

OK=$'\033[38;5;46m'
FAIL=$'\033[38;5;9m'
RESET=$'\033[0m'

function print_color() {
	echo "$2$1$RESET"
}

function read_test {
	while IFS= read -r line
	do
		echo "$line" | bash >> "$OUTPUT_DIR/$1_bash"
		echo "$line" | ./minishell >> "$OUTPUT_DIR/$1_minishell" || return 1
	done < "test/$1"
	return 0
}

function lauch_test {
	if [ -z "$1" ]; then
		return 1
	fi
	echo $1
	ERROR=$(read_test "$1")
	#while IFS= read -r line
	#do
	#	echo "$line" | bash >> "$OUTPUT_DIR/$1_bash"
	#	echo "$line" | ./minishell >> "$OUTPUT_DIR/$1_minishell" || (ERROR="ERROR" && break)
	#done < "test/$1"
	if [ "$ERROR" = "0" ]; then
		echo "[FAILURE]"
	fi
	DIFF=$(diff $OUTPUT_DIR/$1_bash $OUTPUT_DIR/$1_minishell)
	if [ "$DIFF" = "" ]
	then
		print_color "[OK]" $OK
		#rm -rf "$OUTPUT_DIR/$1_bash"
		#rm -rf "$OUTPUT_DIR/$1_minishell" 
	else
		echo "[KO]"
	fi
}

make -C $DIR
rm -rf minishell "$OUTPUT_DIR"
mkdir -p "$OUTPUT_DIR"
ln -s "$DIR/minishell" minishell
lauch_test echo
