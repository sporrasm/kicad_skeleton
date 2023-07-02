#!/bin/bash
set -e

help_f () {
    echo "Usage: in kicad_skeleton dir, run ./configure_kicad.sh [KICAD_VERSION] [OPTIONS]"
    echo "Options:"
    echo "-b        backup existing files, if they exist"
    echo "-h        show this help"
    echo "-o        overwrite existing configuration"
    echo "-u        update to most recent footprints/symbols from KiCad official repos"
}

kicad_ver=$1
shift 1
backup=0
overwrite=0
update=0

while getopts 'bhou' option; do
    case "$option" in
        b) backup=1;;
        h) help_f; exit 0;;
        o) overwrite=1;;
        u) update=1;;
        \?) help_f; exit 0;;
    esac
done

if (( $(echo "$kicad_ver > 6.99" | bc -l ) )); then
    libext="*.kicad_sym"
else
    libext="*.lib"
fi
fpext="*.pretty*"

if pgrep -x "kicad" > /dev/null
then
    echo "Important: You should not have KiCad running, while updating the configuration!"
    exit 1
fi

# Try to find the default libraries shipped with KiCad
install_dir="/usr/share/kicad"
if [ -d $install_dir ]; then
    for dir in `ls $install_dir`; do
        fpfiles=(`find ${install_dir}/${dir} -maxdepth 1 -name $fpext -type d`)
        libfiles=(`find ${install_dir}/${dir} -maxdepth 1 -name $libext -type f`)
        if [ ${#fpfiles[@]} -gt 0 ]; then
            fpdir=${install_dir}/${dir}
        fi
        if [ ${#libfiles[@]} -gt 0 ]; then
            symdir=${install_dir}/${dir}
        fi
    done
else
    echo "KiCad installation not found in $install_dir. Is KiCad installed?"
    exit 1
fi

if [ -z $fpdir ]; then
    echo "KiCad footprint libs not found in $install_dir."
    echo "Using libraries from kicad_official"
    fpdir="`pwd`/kicad_official/kicad_footprints"
else
    echo "Kicad foorprint libraries found under $fpdir"
    if [ $update -eq 1 ]; then
        echo "Update flag given, using most recent footprints in kicad_official"
        fpdir="`pwd`/kicad_official/kicad_footprints"
    fi
fi
if [ -z $symdir ]; then
    echo "KiCad symbol libs not found in $install_dir."
    echo "Using libraries from kicad_official"
    symdir="`pwd`/kicad_official/kicad_symbols"
else
    echo "Kicad foorprint libraries found under $symdir"
    if [ $update -eq 1 ]; then
        echo "Update flag given, using most recent symbols in kicad_official"
        symdir="`pwd`/kicad_official/kicad_symbols"
    fi
fi
KICAD_SYMBOL_DIR=$symdir
KICAD_FOOTPRINT_DIR=$fpdir
KICAD_MAJOR_VER=${kicad_ver:0:1}
echo "$KICAD_MAJOR_VER"
# Add default libs to configuration files
kicad_conf_path="${HOME}/.config/kicad/$kicad_ver"
if [ -d $kicad_conf_path ]; then
    echo "KiCad configuration directory found in $kicad_conf_path"
    if [ -f "$kicad_conf_path/kicad_common.json" ]; then
        echo "KiCad common configuration file found in $kicad_conf_path/kicad_common.json"
        echo "Adding environment variables to footprint, symbol and user libs"
        # Handling json manipulation in python is probably easier than in bash
        cmdstr="-s $KICAD_SYMBOL_DIR -f $KICAD_FOOTPRINT_DIR -v $KICAD_MAJOR_VER"
        if [ $backup -eq 1 ]; then
            cmdstr="$cmdstr -b"
        fi
        if [ $overwrite -eq 1 ]; then
            cmdstr="$cmdstr -o"
        fi
        python3 update_config.py $cmdstr
    else
        echo "KiCad configuration directory not found in $kicad_conf_path! Please run KiCad before running this script"
    fi
else
    echo "KiCad configuration directory not found in $kicad_conf_path! Please run KiCad before running this script"
fi
# Env variables configured, now update fp-lib-table and sym-lib-table to reflect changes
if [ $backup -eq 1 ]; then
    idx=0
    while [[ -f $kicad_conf_path/sym-lib-table-backup-$idx && idx -lt 100 ]]; do
        idx=$((idx + 1))
    done
    echo "Backing up $kicad_conf_path/sym-lib-table to file $kicad_conf_path/sym-lib-table-backup-$idx"
    cp $kicad_conf_path/sym-lib-table $kicad_conf_path/sym-lib-table-backup-$idx

    idx=0
    while [[ -f $kicad_conf_path/fp-lib-table-backup-$idx && idx -lt 100 ]]; do
        idx=$((idx + 1))
    done
    echo "Backing up $kicad_conf_path/fp-lib-table to file $kicad_conf_path/fp-lib-table-backup-$idx"
    cp $kicad_conf_path/fp-lib-table $kicad_conf_path/fp-lib-table-backup-$idx
fi

cp $symdir/sym-lib-table $kicad_conf_path/sym-lib-table
cp $fpdir/fp-lib-table $kicad_conf_path/fp-lib-table
        
