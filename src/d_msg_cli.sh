#!/bin/sh
. /usr/lib/libsh
while getopts gi: arg ; do
	case $arg in 
		g) DMSG_GUI=1 ;;
		i) DMSG_ICON=$OPTARG ;;
	esac
done
shift $((OPTIND - 1 ))
operator=$1
title="$2"
msg="$3"
shift 3
d_msg $operator "$title" "$msg" $@
