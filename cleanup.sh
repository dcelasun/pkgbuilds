#!/bin/bash

set -e;

###############################################################
# -d Remove directories                                       #
# -f Remove forcefully                                        #
# -x Don't use ignore rules .gitignore, but do use -e options #
# -e Don't remove this even though it's in .gitignore         #
# -n Dry run                                                  #
###############################################################
git clean -dfxe .idea/
