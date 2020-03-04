#!/bin/bash

DIR="../minishell"

OUTPUT_DIR="output"
FILES_DIR="files"
OK=$'\033[38;5;46m'
OPT=$'\033[38;5;11m'
FAIL=$'\033[38;5;9m'
RESET=$'\033[0m'

function print_color() {
	echo "$2$1$RESET"
}

function cat_files {
	echo ""
}

function read_test {
	while IFS= read -r line
	do
		echo "$line" | bash 2>> "$OUTPUT_DIR/$1_err_bash"  >> "$OUTPUT_DIR/$1_bash"
		echo "$line" | ./minishell 2>> "$OUTPUT_DIR/$1_err_minishell" >> "$OUTPUT_DIR/$1_minishell" || return 1
	done < "test/$1"
	return 0
}

function check_std_output {
	echo -en "Standar output\t: "
	DIFF=$(diff $OUTPUT_DIR/$1_bash $OUTPUT_DIR/$1_minishell)
	if [ "$DIFF" = "" ]
	then
		print_color "[OK]" $OK
		rm -rf "$OUTPUT_DIR/$1_bash"
		rm -rf "$OUTPUT_DIR/$1_minishell" 
	else
		print_color "[KO]" $FAIL
	fi
}

function check_err_output {
	echo -en "Error output\t: "
	DIFF=$(diff $OUTPUT_DIR/$1_err_bash $OUTPUT_DIR/$1_err_minishell)
	if [ "$DIFF" = "" ]
	then
		print_color "[OK]" $OK
		rm -rf "$OUTPUT_DIR/$1_err_bash"
		rm -rf "$OUTPUT_DIR/$1_err_minishell" 
	else
		print_color "[KO]" $OPT
	fi
}

function lauch_test {
	if [ -z "$1" ]; then
		return 1
	fi
	echo -e "\n"$1 | tr a-z A-Z
	echo -en "Execution\t: "
	read_test "$1"
	ERROR=$?
	if [ "$ERROR" = "1" ]; then
		print_color "[FAILURE]" $FAIL
	else
		print_color "[OK]" $OK
	fi
	check_std_output $1
	check_err_output $1
}

make -C $DIR
rm -rf minishell "$OUTPUT_DIR"
mkdir -p "$OUTPUT_DIR"
ln -s "$DIR/minishell" minishell
lauch_test echo
lauch_test argument
lauch_test multi_cmd
