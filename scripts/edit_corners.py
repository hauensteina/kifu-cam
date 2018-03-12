#!/usr/bin/env python

# /********************************************************************
# Filename: edit_corners.py
# Author: AHN
# Creation Date: Mar 12, 2018
# **********************************************************************/
#
# Editor to define four corners in a Goban picture and save the intersections
# to an sgf in the GC[] tag.
#

from __future__ import division, print_function
from pdb import set_trace as BP
import os,sys,re,json
import numpy as np
from numpy.random import random
import argparse
import matplotlib as mpl
# mpl.use('Agg') # This makes matplotlib work without a display
from matplotlib import pyplot as plt
from matplotlib.widgets import Slider, Button, RadioButtons, CheckButtons

# Where am I
SCRIPTPATH = os.path.dirname(os.path.realpath(__file__))
SELECTED_CORNER = 'TL'

#---------------------------
def usage(printmsg=False):
    name = os.path.basename(__file__)
    msg = '''
    Name: %s
    Synopsis: %s --fname <somepic.png>
    Description:
       Editor to define four corners in a Goban picture and save the intersections
       to an sgf in the GC[] tag.
    Example:
      %s --fname testcase_00002.png
    ''' % (name,name,name)
    if printmsg:
        print(msg)
        exit(1)
    else:
        return msg

#----------------------
def onclick( event):
    if not event.xdata: return
    if event.xdata < 1: return # The click was on the button, not the image
    print( '%s click: button=%d, x=%d, y=%d, xdata=%f, ydata=%f' %
           ('double' if event.dblclick else 'single', event.button,
            event.x, event.y, event.xdata, event.ydata))

#----------------------------
def cb_btn_reset( event):
    print( 'btn_reset')

#----------------------------
def cb_rbtn_corner( label):
    global SELECTED_CORNER
    SELECTED_CORNER = label
    print( 'rbtn_corner %s' % label)

#-----------
def main():
    global SELECTED_CORNER

    if len(sys.argv) == 1:
        usage(True)

    parser = argparse.ArgumentParser(usage=usage())
    parser.add_argument( '--fname',      required=True)
    args = parser.parse_args()
    fig = plt.figure()

    # Image
    img = mpl.image.imread( args.fname)
    ax_img = fig.add_axes( [0.07, 0.06, 0.5, 0.9] )
    ax_img.imshow( img, origin='upper')
    cid = fig.canvas.mpl_connect('button_press_event', onclick)

    # Reset button
    ax_reset = fig.add_axes( [0.70, 0.1, 0.1, 0.05] )
    btn_reset = Button( ax_reset, 'Reset')
    btn_reset.on_clicked( cb_btn_reset)

    # Radiobutton for corner
    ax_radio = fig.add_axes( [0.70, 0.5, 0.2, 0.2] )
    rbtn_corner = RadioButtons( ax_radio, ('TL', 'TR', 'BR', 'BL' ))
    rbtn_corner.on_clicked( cb_rbtn_corner)

    plt.show()


if __name__ == '__main__':
    main()
