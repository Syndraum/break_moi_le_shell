> :warning: **Important note: still in development. Some bugs may appear**

> **Do not use it for your corrections (stupidly)**

# Installation
Clone this reposity next to your project directory
```
.
|- minishell/
|- break_minishell/
```
Change the path to your project directory if necessary in ```launch.sh```
```bash
# Change project directory 
DIR="../minishell/"
```

run the command ```bash launch.sh```
It's going to run a comparison test with bash

list options
```bash
	-o keep output files
	-z compare with zsh instead of bash
	-a comnpare with bash and zsh, ignore -z
```

you can specify a specific test to run, example :
```bash
bash launch.sh echo
```
The list of tests is in the test directory


Youn can open ```log``` file to see which command didn't work