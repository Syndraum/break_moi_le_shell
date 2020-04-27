#!/bin/bash

# Change project directory
DIR="../minishell"

OUTPUT_DIR="output"
FILES_IN_DIR="files/input"
FILES_OUT_DIR="files/output"
FILE_TMP_DIR="$FILES_OUT_DIR"/tmp
#COLOR
OK=$'\033[38;5;46m'
OPT=$'\033[38;5;11m'
FAIL=$'\033[38;5;9m'
RESET=$'\033[0m'

function print_color() {
	echo "$2$1$RESET"
}

function cat_files {
	echo "$FILE_TMP_DIR"/* | grep '*' 2>/dev/null >/dev/null
	ERROR_CAT=$?
	if [ "$ERROR_CAT" = "0" ]; then
		return 1;
	fi
	for file in $FILE_TMP_DIR/*
	do
		filename=$(echo $file | sed -e "s/files\/output\/tmp\///g")
		mv $file "$FILES_OUT_DIR"/"$1"/"$filename"
	done
}

function try_test {
	RET=0
	while IFS= read -r line
	do
		ERROR_TRY=0
		(echo "$line" | ./minishell 2> "/dev/null"  > "/dev/null") 2>> /dev/null || ERROR_TRY=1
		if [ "$ERROR_TRY" = "1" ];then
			RET=1
			echo "-=x=-=x=-=x=-=x=☆(・ω・)★-=x=-=x=-=x=-=x=-" >> log
			echo COMMAND : "$line" >> log
			echo "SEGFAULT" >> log
			echo "" >> log
		fi
	done < "test/$1"
	return "$RET"
}

function create_tmp_file {
	touch "$OUTPUT_DIR/tmp_err_bash" "$OUTPUT_DIR/tmp_bash"
	touch "$OUTPUT_DIR/tmp_err_minishell" "$OUTPUT_DIR/tmp_minishell"
	touch "$OUTPUT_DIR/$1_err_bash" "$OUTPUT_DIR/$1_bash"
	touch "$OUTPUT_DIR/$1_err_minishell" "$OUTPUT_DIR/$1_minishell"
}

function cpy_tmp_file {
	cat "$OUTPUT_DIR/tmp_err_bash" >> "$OUTPUT_DIR/$1_err_bash"
	cat "$OUTPUT_DIR/tmp_err_minishell" >> "$OUTPUT_DIR/$1_err_minishell"
	cat "$OUTPUT_DIR/tmp_bash" >> "$OUTPUT_DIR/$1_bash"
	cat "$OUTPUT_DIR/tmp_minishell" >> "$OUTPUT_DIR/$1_minishell"
}

function echo_log {
	echo "-=x=-=x=-=x=-=x=☆(・ω・)★-=x=-=x=-=x=-=x=-" >> log
	echo COMMAND : "\" $line;echo \$? \"" >> log
	echo $1 >> log
	echo "" >> log
}

function read_test {
	RET=0
	ERROR_OUTPUT=0
	create_tmp_file $1
	while IFS= read -r line
	do
		ERROR_READ=0
		echo "$line;echo \$?" | bash 2> "$OUTPUT_DIR/tmp_err_bash"  > "$OUTPUT_DIR/tmp_bash"
		cat_files bash
		(echo "$line;echo \$?" | ./minishell 2> "$OUTPUT_DIR/tmp_err_minishell"  > "$OUTPUT_DIR/tmp_minishell") 2>> /dev/null || ERROR_READ=1
		cat_files minishell
		cpy_tmp_file $1
		DIFF=$(diff $OUTPUT_DIR/tmp_bash $OUTPUT_DIR/tmp_minishell)
		if [ "$ERROR_READ" = "1" ];then
			RET=1
			echo_log "SEGFAULT"
		elif [ "$DIFF" != "" ]; then
			echo_log "$DIFF"
		fi
		NBLINE_BASH=$(wc -l < $OUTPUT_DIR/tmp_err_bash)
		NBLINE_MINISHELL=$(wc -l < $OUTPUT_DIR/tmp_err_minishell)
		if [ $NBLINE_BASH -gt 0 -a $NBLINE_MINISHELL -eq 0 ];then
			ERROR_OUTPUT=1
			echo_log "$(diff $OUTPUT_DIR/tmp_err_bash $OUTPUT_DIR/tmp_err_minishell)"
		fi
	done < "test/$1"
	rm -rf "$OUTPUT_DIR/tmp_err_bash" "$OUTPUT_DIR/tmp_bash" "$OUTPUT_DIR/tmp_err_minishell" "$OUTPUT_DIR/tmp_minishell"
	return "$RET"
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
	if [ $ERROR_OUTPUT -ne 1 ]; then
		print_color "[OK]" $OK
	else
		print_color "[KO]" $FAIL
	fi
}

function check_file_output {
	ERROR_FILE=0
	for file in $FILES_OUT_DIR/bash/*
	do
		filename=$(echo $file | sed -e "s/files\/output\/bash\///g")
		FIND=$(find "$FILES_OUT_DIR"/minishell -name "$filename" -type f)
		if [ -z "$FIND" ]; then
			ERROR_FILE=1
		else
			DIFF=$(diff $FILES_OUT_DIR/bash/$filename $FILES_OUT_DIR/minishell/$filename)
			if [ "$DIFF" != "" ] ; then
				ERROR_FILE=1
			else
				rm -rf "$FILES_OUT_DIR"/bash/"$filename"
				rm -rf "$FILES_OUT_DIR"/minishell/"$filename"
			fi
		fi
	done
	if [ "$ERROR_FILE" = "1" ]; then
		print_color "[FAILURE]" $FAIL
	else
		print_color "[OK]" $OK
	fi
}

function lauch_try_segfault {
	if [ -z "$1" ]; then
		return 1
	fi
	echo -e "\n"$1 | tr a-z A-Z
	echo -en "Execution\t: "
	try_test "$1"
	ERROR=$?
	if [ "$ERROR" = "1" ]; then
		print_color "[FAILURE]" $FAIL
		return 1
	else
		print_color "[OK]" $OK
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
		return 1
	else
		print_color "[OK]" $OK
	fi
	check_std_output $1
	check_err_output $1
	echo "$FILES_OUT_DIR"/bash/* | grep '*' 2>/dev/null >/dev/null
	ERROR=$?
	if [ "$ERROR" = "1" ]; then
		echo -en "File output\t: "
		check_file_output
	fi
}

make -C $DIR
rm -rf minishell log "$OUTPUT_DIR" "$FILES_OUT_DIR"
mkdir -p "$OUTPUT_DIR" "$FILES_OUT_DIR" "$FILES_OUT_DIR"/bash "$FILES_OUT_DIR"/minishell "$FILES_OUT_DIR"/tmp
ln -s "$DIR/minishell" minishell
lauch_test echo
lauch_test argument
lauch_test multi_cmd
lauch_test cd_and_pwd
lauch_test executable
lauch_test output_redirection
lauch_test input_redirection
lauch_test pipe
lauch_try_segfault try_segfault
