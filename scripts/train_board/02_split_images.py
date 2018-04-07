#!/usr/bin/env python

# /********************************************************************
# Filename: split_images.py
# Author: AHN
# Creation Date: Feb 15, 2018
# **********************************************************************/
#
# Divide images in a folder into train, valid, test sets
#

from __future__ import division, print_function
from pdb import set_trace as BP
import os,sys,re,json
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
      %s --  Divide images in a folder into train, valid, test sets
    Synopsis:
      %s --folder <folder> --trainpct <n> --validpct <n> --substr <substring>
    Description:
      Splits the jpg files in folder into train, valid, and test files.
      Only use files containing <substring> in the name.
    Example:
      %s --folder images --trainpct 80 --validpct 10 --substr rgb
      The remaining 10pct will be test data
    ''' % (name,name,name)
    if printmsg:
        print(msg)
        exit(1)
    else:
        return msg


#-----------
def main():
    if len(sys.argv) == 1:
        usage(True)

    parser = argparse.ArgumentParser(usage=usage())
    parser.add_argument( "--folder",      required=True)
    parser.add_argument( "--substr",      required=True)
    parser.add_argument( "--trainpct",    required=True, type=int)
    parser.add_argument( "--validpct",    required=True, type=int)
    args = parser.parse_args()
    #np.random.seed(0) # Make things reproducible
    ut.split_files( args.folder, args.trainpct, args.validpct, args.substr)


if __name__ == '__main__':
    main()
