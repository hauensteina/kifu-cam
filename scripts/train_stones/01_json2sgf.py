#!/usr/bin/env python

# /********************************************************************
# Filename: json2sgf.py
# Author: AHN
# Creation Date: Feb 28, 2018
# **********************************************************************/
#
# Copy intersection coords from wallstedt format json to sgf GC tag
#

from __future__ import division, print_function
from pdb import set_trace as BP
import os,sys,re,json,shutil
import numpy as np
from numpy.random import random
import argparse
import matplotlib as mpl
mpl.use('Agg') # This makes matplotlib work without a display
from matplotlib import pyplot as plt

# Look for modules in our pylib folder
SCRIPTPATH = os.path.dirname(os.path.realpath(__file__))
sys.path.append( SCRIPTPATH + '/..')

import ahnutil as ut

#---------------------------
def usage(printmsg=False):
    name = os.path.basename(__file__)
    msg = '''
    Name:
      %s --  Copy intersection coords from wallstedt format json to sgf GC tag
    Synopsis:
      %s --folder <folder>
    Description:
      Finds all pairs (*_intersections.json, *.sgf) and cpoies the
      intersections coords into the sgf GC tag.
      The results go into a subfolder <folder>/json2sgf.
    Example:
      %s --folder ~/kc-trainingdata/andreas/mike_fixed_20180228
    ''' % (name,name,name)
    if printmsg:
        print(msg)
        exit(1)
    else:
        return msg

# Collect matching jpeg and json in a dictionary
#----------------------------------------------------
def collect_files( infolder):
    # Find images
    jsons =  ut.find( infolder, '[!.]*_intersections.json')
    # Basenames
    basenames = [os.path.basename(f) for f in jsons]
    basenames = [re.sub( '_intersections.json','',x) for x in basenames]
    sgfs  = [ut.find( infolder, '%s.sgf' % f)[0] for f in basenames]
    jpegs = [ut.find( infolder, '%s.jpeg' % f)[0] for f in basenames]
    res = zip( jsons, sgfs, jpegs)
    return res


# Read both files and return sgf with intersections in GC tag
#-------------------------------------------------------------
def fix( jsonfile, sgffile):
    jobj = json.load( open( jsonfile))
    sgf  = open( sgffile).read()
    boardsz = len(jobj)
    coords = [0] * boardsz * boardsz
    if boardsz != 19:
        print ('Size %d is not a 19x19 board. Skipping' % boardsz)
        return ''
    for c,col in enumerate( jobj):
        for r,isec in enumerate( col):
            idx = r * boardsz + c
            coords[idx] = (isec['x'],isec['y'])
    tstr = json.dumps( coords)
    tstr = re.sub( '\[','(',tstr)
    tstr = re.sub( '\]',')',tstr)
    tstr = 'GC[intersections:' + tstr + ']'
    res = sgf
    res = re.sub( '(SZ\[[^\]]*\])', r'\1' + tstr, res)
    res = re.sub( r'\s*','', res)
    return res

#-----------
def main():
    if len(sys.argv) == 1:
        usage(True)

    parser = argparse.ArgumentParser(usage=usage())
    parser.add_argument( "--folder",      required=True)
    args = parser.parse_args()

    outfolder = args.folder + '/json2sgf/'
    os.makedirs( outfolder)
    file_triples = collect_files( args.folder)
    for p in file_triples:
        newsgf = fix( p[0], p[1])
        if not newsgf: continue
        fname = outfolder + os.path.basename( p[1])
        shutil.copy( p[2], outfolder)
        with open( fname, 'w') as f:
            f.write( newsgf)

if __name__ == '__main__':
    main()
