#!/bin/sh
#
# by Sairon Istyar, 2012
# distributed under the GPLv3 license
#

# some sane default values
cols=10
rows=40
len=8
generator='pwgen -sB1 $LEN$ $NUM$'

# load user's config if it exists and is a regular file
if [ -f ~/.gridpass ] ; then
	. ~/.gridpass 2>&1 >>/dev/null
# create it if it doesn't exist
elif [ ! -e ~/.gridpass ] ; then
cat >~/.gridpass <<EOF
cols=10
rows=40
len=8
generator='pwgen -sB1 \$LEN\$ \$NUM\$'
EOF
fi

usage() {
	echo "Usage: $0 [-c cols] [-r rows] [-l length] [filename.tex]"
	echo
	echo "Generate a LaTeX source code with a set of passwords arranged in tabular format."
	echo "If a filename is given, compile .TEX source to .PDF format. Else print LaTex source code to STDOUT."
	echo
	echo "Params:"
	echo "	-t		print title (waste of space)"
	echo "	-c [cols]	number of columns in table"
	echo "	-r [rows]	number of rows in table"
	echo "	-l [length]	password length"
	echo "	-g [prog]	use [prog] for generating passwords (in single quotes)"
	echo "			special variables are '$NUM$' (number of pws to be generated)"
	echo "			and '$LEN$' (length of one password)"
	echo "			passwords should be separated by newlines"
	exit 1
}

# parse cmdline options
tflag=0
while getopts tc:r:l:g: opt ; do
	case $opt in
		t) tflag=1;;
		c) cols="$OPTARG";;
		r) rows="$OPTARG";;
		l) len="$OPTARG";;
		g) generator="$OPTARG";;
		?) usage;;
	esac
done
shift $(($OPTIND -1))

# start with "GridPass" column
colmarks='\bf{\tiny{GridPass}}'

# define alphabetical column headings
letters="A B C D E F G H I J K L M N O P Q R S T U V W X Y Z"
# convert spaces to newlines
letters=`echo "$letters" | sed 's/\ /\n/g'`
# for future compatibility ;)
numletters=`echo "$letters" | wc -l`
# will hardly ever need more than 26 (or more in the future) columns anyway
if [ $cols -gt $numletters ] ; then
	echo "WTB moar letterz!!!1 (do U rly need that many columns?)"
	exit 2
fi

# how many pws to generate?
numpws=$(($cols * $rows))
# gotta gen 'em all
generator=$(echo "$generator" | sed 's/\$LEN\$/\$len/g;s/\$NUM\$/\$numpws/g')
pws=$(eval "$generator")
# detect errors
if [ $? -ne 0 ] ; then
	echo "Password generator exited with non-zero exit status. Aborting..."
	exit 3
fi

# LaTeX column format string
format="|c*{$cols}{|c}|"

# if given a filename, redirect source to file and then try to compile it to PDF document;
# else it will be printed to STDOUT (screen or file if redirected on cmdline)
if [ -n "$1" ] ; then
	# save STDOUT
	exec 6>&1
	# replace STDOUT with file
	exec > $1
fi

# get author's name
# first try to parse full name out of user's GECOS field in /etc/passwd
author=$(getent passwd $USER 2>/dev/null | cut -d ':' -f 5)
# if that fails, get username
if [ -z "$author" ] ; then
	author="$USER"
fi

# output LaTeX source (headers)
cat <<EOF
\documentclass{article}
\usepackage[margin=0.5in,a4paper,landscape]{geometry}
\usepackage[table,fixpdftex]{xcolor}
\title{GridPass - $numpws passwords of length $len}
\author{$author}
\begin{document}
EOF

# are we making a title?
if [ $tflag -eq 1 ] ; then
	echo '\maketitle'
fi

# LaTeX source (body)
cat <<EOF
\begin{center}
\rowcolors{1}{lightgray}{white}
\arrayrulecolor{black}
\begin{tabular}{$format}
	\hline
EOF

# table header
for i in `seq 1 $cols` ; do
	letter=`echo "$letters" | sed -n "$i"p`
	colmarks="$colmarks & \\bf{$letter}"
done
colmarks="$colmarks \\\ \\hline"
echo "	$colmarks"

# passwords
currpwnum=1
for i in `seq 1 $rows` ; do
	currline="	\\bf{$i}"
	for j in `seq 1 $cols` ; do
		currpw=$(echo "$pws" | sed -n "$currpwnum"p)
		let "currpwnum += 1"
		currline="$currline & $currpw"
	done
	currline="$currline "'\\'
	if [ $i -ne $rows ] ; then
		currline="$currline \\hline"
	fi
	echo "$currline"
done

# end table && document
cat <<EOF
	\\hline
\end{tabular}
\end{center}
\end{document}
EOF

# reset STDOUT back to normal if we were redirectiong it to file
# and compile PDF document
if [ -n "$1" ] ; then
	# restore STDOUT, close FD #6
	exec 1>&6 6>&-
	# in case something bad happens
	buildlog=$(pdflatex $1)
	# catch compiler's exitcode
	exitcode=$?
	# check whether table overflows paper
	echo "$buildlog" | grep 'too wide' >> /dev/null
	if [ $? -eq 1 ] ; then
		echo "Generation complete, you can now print ${1%tex}pdf"
	else
		echo "Horizontal space limit exceeded. Consider decreasing number of columns."
	fi
	# print buildlog if compiler exited with error status
	if [ $exitcode -ne 0 ] ; then
		echo "$buildlog"
	fi
fi
