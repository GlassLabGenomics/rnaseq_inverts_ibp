#!/bin/bash

SOURCEDIR=$1
TARGETDIR=$2

rclone copy $SOURCEDIR googledrive:$TARGETDIR
