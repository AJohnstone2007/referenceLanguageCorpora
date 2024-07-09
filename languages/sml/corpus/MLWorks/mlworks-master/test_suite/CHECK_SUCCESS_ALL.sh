#!/bin/sh
# 
# $Log: CHECK_SUCCESS_ALL.sh,v $
# Revision 1.8  1999/02/23 12:55:14  mitchell
# [Bug #190507]
# Ignore DEPEND directories
#
# Revision 1.7  1997/11/19  17:47:07  daveb
# [Bug #30323]
#
# Revision 1.6  1997/08/13  15:35:17  jont
# [Bug #30151]
# Modify to work with installed MLWorks as well
#
# Revision 1.5  1997/01/03  10:29:36  stephenb
# [Bug #1881]
# Modified so that now knows how to skip architecture specific
# directories that aren't of interest to the architecture being
# tested.  Also changed the way OS specific directories are skipped
# to use the same mechanism.
#
# Revision 1.4  1996/12/20  17:04:24  jont
# [Bug #1879]
# Remove default setting of ARCH_OS
#
# Revision 1.3  1996/08/15  09:48:30  io
# ** No reason given. **
#
# Revision 1.2  1996/08/14  15:53:11  io
# architecture specific handling
#
# Revision 1.1  1996/05/22  15:36:35  jont
# new unit
#
# Revision 1.9  1996/01/09  12:47:19  matthew
# Renaming motif.img to gui.img
#
# Revision 1.8  1995/09/06  17:10:07  io
# use rts/bin/$ARCH/$OS/main to help multiarch testing
#
# Revision 1.7  1995/08/15  11:51:12  daveb
# Changed default SRC_DIR to /u/sml ...
#
# Revision 1.6  1995/06/16  16:45:15  daveb
# Converted this script to /bin/sh because Irix csh choked on "too many arguments"
#
# Revision 1.5  1995/03/15  14:35:13  jont
# Pass on -dir parameter
#
# Revision 1.4  1995/02/09  15:22:36  jont
# Modify to use new image directory structure
#
# Revision 1.3  1994/06/17  12:05:09  daveb
# Changed default SRC_DIR to /usr/sml ...
#
# Revision 1.2  1994/03/15  14:47:44  jont
# Change default source directory to /usr/users/sml/MLW/src
#
# Revision 1.1  1993/04/14  16:59:00  daveb
# Initial revision
#
#
# Copyright 2013 Ravenbrook Limited <http://www.ravenbrook.com/>.
# All rights reserved.
# 
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions are
# met:
# 
# 1. Redistributions of source code must retain the above copyright
#    notice, this list of conditions and the following disclaimer.
# 
# 2. Redistributions in binary form must reproduce the above copyright
#    notice, this list of conditions and the following disclaimer in the
#    documentation and/or other materials provided with the distribution.
# 
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS
# IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED
# TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A
# PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT
# HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
# SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED
# TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR
# PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF
# LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING
# NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
# SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
#

TESTDIR=.
SRCDIR=/u/sml/MLW/src
KEEP=0

ARCH_OS_DIR=""

IMAGE=guib.img

installed=""

usage='Usage: CHECK_SUCCESS_ALL \[-src \<source dir\>\] \[-dir \<architecture/OS\>\] \[-test \< test dir\>\] \[-installed\]'

while [ $# -gt 0 ]
do
  case $1 in
    -src)
      shift
      if [ "$1" != "" ]
      then
        SRCDIR=$1
        shift
      else
        echo $usage
        exit 1
      fi;;
    -dir)
      shift
      if [ "$1" != "" ]
      then
        ARCH_OS_DIR=$1
        shift
      else
        echo $usage
        exit 1
      fi;;
    -test)
      shift
      if [ "$1" != "" ]
      then
        TESTDIR=$1
        shift
      else
        echo $usage
        exit 1
      fi;;
    -installed)
      installed="-installed"
      shift;;
    *)
      echo $usage
      exit 1;;
  esac
done

if [ "$ARCH_OS_DIR" = "" ]
then
  echo "parameter -dir missing"
  exit 1
fi



#.arch: ARCH_OS_DIR gives us the ARCH we want, but what we want to know is
# the name of all the architectures whose files we don't want to test,
# since find(1) wants the names of directories to prune not to enter.
#
# The following produces arch_dirs_to_prune which contains the names
# of the architecture specific directory files to skip in find(1) format.
# For example if ARCH_OS_DIR=SPARC/Solaris, then the result will be :-
#
#   "-o name MIPS -o name I386"
#
# Note that the leading "-o" is ok since this string will come after
# any OS directories to prune, see .os.
#
# If you make any changes to the following, also make them to 
# <URI:CHECK_RESULT_ALL.sh>
#
# To include a new architecture it should only be necessary to add the
# name to the following line ...

architectures="SPARC MIPS I386"
ARCH=`dirname $ARCH_OS_DIR`
arch_dirs_to_prune=""
for a in $architectures
do
  if test $a != $ARCH
  then
    arch_dirs_to_prune=${arch_dirs_to_prune}" -o -name $a"
  fi
done


#.os: As with the ARCH case, find the names of the directories to prune
# rather than keep.  Since there are only currently two types, this is
# simple ...
case "`basename $ARCH_OS_DIR`" in
  Win95|NT) os_dir_to_prune=unix ;;
  *)        os_dir_to_prune=win32 ;;
esac


files=`find $TESTDIR -type d \( -name $os_dir_to_prune $arch_dirs_to_prune -o -name DEPEND \) -prune -o -type f -name \*.sml -print | egrep -v "^.$"`

# Re the egrep: you you know how blank lines can be generated by find
# (and hence the need for the egrep), please add a note here.

OS_NAME=`basename $ARCH_OS_DIR`

RTS_NAME=main

if [ "$OS_NAME" = "NT" -o "$OS_NAME" = "Win95" ]
then
  RTS_NAME=main.exe
  OS_TYPE=Win32
else
  OS_TYPE=Unix
fi

if [ "$installed" = "-installed" ]
then
  if [ "$OS_TYPE" = "Unix" ]
  then
    if [ ! -x $SRCDIR/bin/mlrun ]
    then
      echo Can\'t find $SRCDIR/bin/mlrun
      exit 1
    fi
  else
    if [ ! -x $SRCDIR/bin/main.exe ]
    then
      echo Can\'t find $SRCDIR/bin/main.exe
      exit 1
    fi
  fi
  if [ ! -r $SRCDIR/images/$IMAGE ]
  then
    echo Can\'t find $SRCDIR/images/$IMAGE
    exit 1
  fi
else
  if [ ! -x $SRCDIR/rts/bin/$ARCH_OS_DIR/$RTS_NAME ]
  then
    echo Can\'t find $SRCDIR/rts/bin/$ARCH_OS_DIR/$RTS_NAME
    exit 1
  fi
  if [ ! -r $SRCDIR/images/$ARCH_OS_DIR/$IMAGE ]
  then
    echo Can\'t find $SRCDIR/images/$ARCH_OS_DIR/$IMAGE
    exit 1
  fi
fi

cd $TESTDIR
set STATUS=0

for i in $files; do
  if CHECK_SUCCESS.sh -src $SRCDIR -dir $ARCH_OS_DIR $installed $i
  then
    # /bin/sh insists on a command at this point.
    dummy=0
  else
    STATUS=1
  fi
done

exit $STATUS
