import json
import argparse
import os
import shutil
import pdb

def parse_paths(**kwargs):
    ver=kwargs.get('version_kicad') 
    symdir=kwargs.get('symbol_dir') 
    fpdir=kwargs.get('footprint_dir') 
    symvar=f'KICAD{ver}_SYMBOL_DIR' 
    fpvar=f'KICAD{ver}_FOOTPRINT_DIR'
    userdir='${HOME}/kicad_skeleton/kicad_custom_libs'
    uservar='KICAD_USER_LIBS'
    if symdir is None:
        raise ValueError("Symbol dir not given!")
    if fpdir is None:
        raise ValueError("Footprint dir not given!")
    paths = {
            symvar : symdir,
            fpvar: fpdir,
            uservar: userdir
            }

    return paths

def upd_conf(paths,**kwargs):
    ver=kwargs.get('version_kicad')
    conffile=os.path.join(os.environ['HOME'], '.config/kicad', '%d.0' % ver, 'kicad_common.json')
    backup=kwargs.get('backup')
    overwrite=kwargs.get('overwrite')
    if backup:
        backup_path=os.path.join(os.path.dirname(conffile), 'kicad_common.backup')
        idx=0
        while os.path.isfile(backup_path) and idx<100:
            backup_path=os.path.join(os.path.dirname(conffile), 'kicad_common_%d.backup' % idx)
            idx+=1
        shutil.copy(conffile, backup_path)
    with open(conffile, 'r') as f:
        conf=json.load(f)
    for k, v in paths.items():
        if k in conf['environment']['vars'].keys():
            if overwrite:
                print('Key %s already specified in configuration file. Overwriting.' % k)
                conf['environment']['vars'].update({'%s' % k: v})
            else:
                print('Key %s already specified in configuration file! Specify -o to overwrite!' % k)
    with open(conffile, 'w') as f:
        json.dump(conf, f, indent=2) 

parser=argparse.ArgumentParser(description='Python utility to update KiCad configuration files',
                               formatter_class=argparse.ArgumentDefaultsHelpFormatter)
parser.add_argument('-s', '--symbol-dir', action='store', help='Abs. path to symbol lib directory')
parser.add_argument('-f', '--footprint-dir', action='store', help='Abs. path to footprint lib directory')
parser.add_argument('-v', '--version-kicad', action='store', help='KiCad major version', type=int, default=6)
parser.add_argument('-b', '--backup', action='store_true', help='Backup exisiting files?')
parser.add_argument('-o', '--overwrite', action='store_true', help='Overwrite exisiting entries in conf. files?')

args=parser.parse_args()
config=vars(args)
paths=parse_paths(**config)
upd_conf(paths, **config)
