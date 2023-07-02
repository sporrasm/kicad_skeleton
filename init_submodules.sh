#!/usr/bin/env bash
# Selective initialization of submodules
# Originally written by Marko Kosunen, marko.kosunen@aalto.fi, 2017,
# modified by Santeri Porrasmaa

DIR=`pwd`

SUBMODULES="\
    ./kicad_custom_libs/ \
    ./kicad_official/kicad_footprints/ \
    ./kicad_official/kicad_symbols/ \
"
git submodule sync
for mod in $SUBMODULES; do 
    git submodule update --init $mod
    cd ${mod}
    if [ -f ./init_submodules.sh ]; then
        ./init_submodules.sh
    fi
    cd ${DIR}

done
exit 0

