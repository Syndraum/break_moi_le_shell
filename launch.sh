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

# 			print_color(string, color, option)
function	print_color() {
	echo $3 "$2$1$RESET"
}

# 			cat_files(shell_name)
function	cat_files {
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

#			try_test(test_name)
function	try_test {
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

#			create_tmp_file(test_name)
function	create_tmp_file {
	if [ $ZSH -eq 1 -o $ALL -eq 1 ]; then
		touch "$OUTPUT_DIR/tmp_err_zsh" "$OUTPUT_DIR/tmp_zsh"
		touch "$OUTPUT_DIR/$1_err_zsh" "$OUTPUT_DIR/$1_zsh"
	fi
	if [ $ZSH -ne 1 -o $ALL -eq 1 ]; then
		touch "$OUTPUT_DIR/tmp_err_bash" "$OUTPUT_DIR/tmp_bash"
		touch "$OUTPUT_DIR/$1_err_bash" "$OUTPUT_DIR/$1_bash"
	fi
	touch "$OUTPUT_DIR/tmp_err_minishell" "$OUTPUT_DIR/tmp_minishell"
	touch "$OUTPUT_DIR/$1_err_minishell" "$OUTPUT_DIR/$1_minishell"
}

#			cpy_tmp_file(test_name)
function	cpy_tmp_file {
	if [ $ZSH -eq 1 -o $ALL -eq 1 ]; then
		cat "$OUTPUT_DIR/tmp_err_zsh" >> "$OUTPUT_DIR/$1_err_zsh"
		cat "$OUTPUT_DIR/tmp_zsh" >> "$OUTPUT_DIR/$1_zsh"
	fi
	if [ $ZSH -ne 1 -o $ALL -eq 1 ]; then
		cat "$OUTPUT_DIR/tmp_err_bash" >> "$OUTPUT_DIR/$1_err_bash"
		cat "$OUTPUT_DIR/tmp_bash" >> "$OUTPUT_DIR/$1_bash"
	fi
	cat "$OUTPUT_DIR/tmp_err_minishell" >> "$OUTPUT_DIR/$1_err_minishell"
	cat "$OUTPUT_DIR/tmp_minishell" >> "$OUTPUT_DIR/$1_minishell"
}

#			echo_log(message, shell)
function	echo_log {
	echo "-=x=-=x=-=x=-=x=☆(・ω・)★-=x=-=x=-=x=-=x=-" >> log
	echo -n COMMAND : "\"$line;echo \$?\"" >> log
	if [ -n "$2" ]; then
		echo " ($2)" >> log
	else
		echo "" >> log
	fi
	echo $1 >> log
	echo "" >> log
}

#			read_test(test_name)
function	read_test {
	RET=0
	ERROR_OUTPUT=0
	BASH_ERROR_OUTPUT=0
	ZSH_ERROR_OUTPUT=0
	create_tmp_file $1
	while IFS= read -r line
	do
		ERROR_READ=0
		if [ $ZSH -eq 1 -o $ALL -eq 1 ]; then
			echo "$line;echo \$?" | zsh 2> "$OUTPUT_DIR/tmp_err_zsh"  > "$OUTPUT_DIR/tmp_zsh"
			cat_files zsh
		fi
		if [ $ZSH -ne 1 -o $ALL -eq 1 ]; then
			echo "$line;echo \$?" | bash 2> "$OUTPUT_DIR/tmp_err_bash"  > "$OUTPUT_DIR/tmp_bash"
			cat_files bash
		fi
		(echo "$line;echo \$?" | ./minishell 2> "$OUTPUT_DIR/tmp_err_minishell"  > "$OUTPUT_DIR/tmp_minishell") 2>> /dev/null || ERROR_READ=1
		cat_files minishell
		cpy_tmp_file $1
		if [ $ZSH -eq 1 -o $ALL -eq 1 ]; then
			ZSH_DIFF=$(diff $OUTPUT_DIR/tmp_zsh $OUTPUT_DIR/tmp_minishell)
		fi
		if [ $ZSH -ne 1 -o $ALL -eq 1 ]; then
			BASH_DIFF=$(diff $OUTPUT_DIR/tmp_bash $OUTPUT_DIR/tmp_minishell)
		fi
		if [ "$ERROR_READ" = "1" ];then
			RET=1
			echo_log "SEGFAULT"
		elif [ -n "$BASH_DIFF" ]; then
			echo_log "$BASH_DIFF" bash
		elif [ -n "$ZSH_DIFF" ]; then
			echo_log "$ZSH_DIFF" zsh
		fi
		NBLINE_MINISHELL=$(wc -l < $OUTPUT_DIR/tmp_err_minishell)
		if [ $ZSH -ne 1 -o $ALL -eq 1 ]; then
			NBLINE_BASH=$(wc -l < $OUTPUT_DIR/tmp_err_bash)
			if [ $NBLINE_BASH -gt 0 -a $NBLINE_MINISHELL -eq 0 ];then
				ERROR_OUTPUT=1
				BASH_ERROR_OUTPUT=1
				echo_log "ERROR OUTPUT : $(diff $OUTPUT_DIR/tmp_err_bash $OUTPUT_DIR/tmp_err_minishell)" bash
			fi
		fi
		if [ $ZSH -eq 1 -o $ALL -eq 1 ]; then
			NBLINE_ZSH=$(wc -l < $OUTPUT_DIR/tmp_err_zsh)
			if [ $NBLINE_ZSH -gt 0 -a $NBLINE_MINISHELL -eq 0 ];then
				ZSH_ERROR_OUTPUT=1
				echo_log "ERROR OUTPUT : $(diff $OUTPUT_DIR/tmp_err_zsh $OUTPUT_DIR/tmp_err_minishell)" zsh
			fi
		fi
	done < "test/$1"
	rm -rf "$OUTPUT_DIR/tmp_err_bash" "$OUTPUT_DIR/tmp_bash" "$OUTPUT_DIR/tmp_err_zsh" "$OUTPUT_DIR/tmp_zsh" "$OUTPUT_DIR/tmp_err_minishell" "$OUTPUT_DIR/tmp_minishell"
	return "$RET"
}

#			cmp_stdout_shell(shell, test_name)
function	cmp_stdout_shell {
	DIFF=$(diff $OUTPUT_DIR/$2_$1 $OUTPUT_DIR/$2_minishell)
	UPPER=$1
	UPPER=${UPPER^^}
	if [ "$DIFF" = "" ];then
		if [ $ALL -eq 1 ];then
			print_color "[$UPPER]" $OK -n
		else
			print_color "[OK]" $OK -n
		fi 
	else
		if [ $ALL -eq 1 ];then
			print_color "[$UPPER]" $FAIL -n
		else
			print_color "[KO]" $FAIL -n
		fi
		DEL_FILE=0;
	fi
}

#			check_std_output(test_name)
function	check_std_output {
	DEL_FILE=1
	echo -en "Standar output\t: "
	if [ $ZSH -ne 1 -o $ALL -eq 1 ]; then
		cmp_stdout_shell bash $1
	fi
	if [ $ZSH -eq 1 -o $ALL -eq 1 ]; then
		cmp_stdout_shell zsh $1
	fi
	echo ''
	if [ $DEL_FILE -eq 1 -a $OUTPUT -eq 0 ]; then
		rm -rf "$OUTPUT_DIR/$1_bash"
		rm -rf "$OUTPUT_DIR/$1_zsh"
		rm -rf "$OUTPUT_DIR/$1_minishell"
	fi
}

#			check_err_output()
function	check_err_output {
	echo -en "Error output\t: "
	if [ $ALL -eq 1 ];then
		if [ $BASH_ERROR_OUTPUT -ne 1 ]; then
			print_color "[BASH]" $OK -n
		else
			print_color "[BASH]" $FAIL -n
		fi
		if [ $ZSH_ERROR_OUTPUT -ne 1 ]; then
			print_color "[ZSH]" $OK -n
		else
			print_color "[ZSH]" $FAIL -n
		fi
		echo ''
	elif [ $BASH_ERROR_OUTPUT -ne 1 -a $ZSH_ERROR_OUTPUT -ne 1 ]; then
		print_color "[OK]" $OK
	else
		print_color "[KO]" $FAIL
	fi
}

#			check_file_output()
function	check_file_output {
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

#			lauch_try_segfault(test_name)
function	lauch_try_segfault {
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

#			lauch_test(test_name)
function	lauch_test {
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

rm -rf minishell log "$OUTPUT_DIR" "$FILES_OUT_DIR"
ALL=0
OUTPUT=0
ZSH=0
for i in "$@"
do
	if [ "$i" = "-a" ]; then
		ALL=1
	elif [ "$i" = "-o" ];then
		OUTPUT=1;
	elif [ "$i" = "-z" ]; then
		ZSH=1;
	else
		echo "Error argument not valid : $i"
		exit
	fi
done
make -C $DIR
ln -s "$DIR/minishell" minishell
mkdir -p "$OUTPUT_DIR" "$FILES_OUT_DIR" "$FILES_OUT_DIR"/minishell "$FILES_OUT_DIR"/tmp
if [ $ZSH -eq 1 -o $ALL -eq 1 ]; then
	mkdir "$FILES_OUT_DIR"/zsh
fi
if [ $ZSH -ne 1 -o $ALL -eq 1 ]; then
	mkdir "$FILES_OUT_DIR"/bash
fi
lauch_test echo
lauch_test argument
lauch_test multi_cmd
lauch_test cd_and_pwd
lauch_test executable
lauch_test output_redirection
lauch_test input_redirection
lauch_test pipe
lauch_try_segfault try_segfault
