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
import matplotlib.patches as patches
# mpl.use('Agg') # This makes matplotlib work without a display
from matplotlib import pyplot as plt
from matplotlib.widgets import Slider, Button, RadioButtons, CheckButtons

# Where am I
SCRIPTPATH = os.path.dirname(os.path.realpath(__file__))
SELECTED_CORNER = 'TL'
CORNER_COORDS = { 'TL': [0.0, 0.0], 'TR': [0.0, 0.0], 'BR': [0.0, 0.0], 'BL': [0.0, 0.0] }
AX_IMAGE = None
FIG = None
IMG = None

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
    global SELECTED_CORNER
    global CORNER_COORDS
    global AX_IMAGE
    global FIG
    if not event.xdata: return
    if event.xdata < 1: return # The click was on the button, not the image
    CORNER_COORDS[SELECTED_CORNER][0] = event.xdata
    CORNER_COORDS[SELECTED_CORNER][1] = event.ydata

    s = 15
    r = s / 2.0
    ell = patches.Ellipse( (event.xdata, event.ydata), s, s, edgecolor='r', facecolor='none')
    #rect = patches.Rectangle((event.xdata, event.ydata), s, s, linewidth=1, edgecolor='r', facecolor='none')
    #rect = patches.Rectangle((100, 100), s, s, linewidth=1, edgecolor='r', facecolor='none')
    AX_IMAGE.add_patch( ell)
    FIG.canvas.draw()
    #plt.show()
    print( '%s click: button=%d, x=%d, y=%d, xdata=%f, ydata=%f' %
           ('double' if event.dblclick else 'single', event.button,
            event.x, event.y, event.xdata, event.ydata))

#----------------------------
def cb_btn_reset( event):
    print( 'btn_reset')
    AX_IMAGE.cla()
    AX_IMAGE.imshow( IMG, origin='upper')
    FIG.canvas.draw()


#----------------------------
def cb_rbtn_corner( label):
    global SELECTED_CORNER
    SELECTED_CORNER = label
    print( 'rbtn_corner %s' % label)

#-----------
def main():
    global SELECTED_CORNER
    global AX_IMAGE
    global CORNER_COORDS
    global FIG
    global IMG

    if len(sys.argv) == 1:
        usage(True)

    parser = argparse.ArgumentParser(usage=usage())
    parser.add_argument( '--fname',      required=True)
    args = parser.parse_args()

    FIG = plt.figure()

    # Image
    IMG = mpl.image.imread( args.fname)
    AX_IMAGE = FIG.add_axes( [0.07, 0.06, 0.5, 0.9] )
    AX_IMAGE.imshow( IMG, origin='upper')
    cid = FIG.canvas.mpl_connect('button_press_event', onclick)

    # Reset button
    ax_reset = FIG.add_axes( [0.70, 0.1, 0.1, 0.05] )
    btn_reset = Button( ax_reset, 'Reset')
    btn_reset.on_clicked( cb_btn_reset)

    # Radiobutton for corner
    ax_radio = FIG.add_axes( [0.70, 0.5, 0.2, 0.2] )
    rbtn_corner = RadioButtons( ax_radio, ('TL', 'TR', 'BR', 'BL' ))
    rbtn_corner.on_clicked( cb_rbtn_corner)

    plt.show()


if __name__ == '__main__':
    main()
