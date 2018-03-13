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
import os,sys,re,json,copy
from StringIO import StringIO
import numpy as np
from numpy.random import random
import argparse
import matplotlib as mpl
import matplotlib.patches as patches
# mpl.use('Agg') # This makes matplotlib work without a display
from matplotlib import pyplot as plt
from matplotlib.widgets import Slider, Button, RadioButtons, CheckButtons
import cv2

# Where am I
SCRIPTPATH = os.path.dirname(os.path.realpath(__file__))
SELECTED_CORNER = 'TL'
CORNER_COORDS = { 'TL': [0.0, 0.0], 'TR': [0.0, 0.0], 'BR': [0.0, 0.0], 'BL': [0.0, 0.0] }
AX_IMAGE = None
FIG = None
IMG = None
BOARDSZ = 19

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

# Read and sgf file and linearize it into a list
# ['b','w','e',...]
#-------------------------------------------------
def linearize_sgf( sgf):
    boardsz = int( get_sgf_tag( 'SZ', sgf))
    if not 'KifuCam' in sgf:
        # The AW[ab][ce]... case
        match = re.search ( 'AW(\[[a-s][a-s]\])*', sgf)
        whites = match.group(0)
        whites = re.sub( 'AW', '', whites)
        whites = re.sub( '\[', 'AW[', whites)
        whites = re.findall( 'AW' + '\[[^\]]*', whites)
        match = re.search ( 'AB(\[[a-s][a-s]\])*', sgf)
        blacks = match.group(0)
        blacks = re.sub( 'AB', '', blacks)
        blacks = re.sub( '\[', 'AB[', blacks)
        blacks = re.findall( 'AB' + '\[[^\]]*', blacks)
    else:
        # The AW[ab]AW[ce]... case
        whites = re.findall( 'AW' + '\[[^\]]*', sgf)
        blacks = re.findall( 'AB' + '\[[^\]]*', sgf)

    res = ['EMPTY'] * boardsz * boardsz
    for w in whites:
        pos = w.split( '[')[1]
        col = ord( pos[0]) - ord( 'a')
        row = ord( pos[1]) - ord( 'a')
        idx = col + row * boardsz
        res[idx] = 'WHITE'

    for b in blacks:
        pos = b.split( '[')[1]
        col = ord( pos[0]) - ord( 'a')
        row = ord( pos[1]) - ord( 'a')
        idx = col + row * boardsz
        res[idx] = 'BLACK'

    return res

# e.g for board size, call get_sgf_tag( sgf, "SZ")
#---------------------------------------------------
def get_sgf_tag( tag, sgf):
    m = re.search( tag + '\[[^\]]*', sgf)
    if not m: return ''
    mstr = m.group(0)
    res = mstr.split( '[')[1]
    res = res.split( ']')[0]
    return res

# Get list of intersection coords fro sgf GC tag
#-------------------------------------------------
def get_isec_coords( sgffile):
    with open( sgffile) as f: sgf = f.read()
    sgf = sgf.replace( '\\','')
    if not 'intersections:' in sgf and not 'intersections\:' in sgf:
        print('no intersections in ' + sgffile)
        return
    boardsz = int( get_sgf_tag( 'SZ', sgf))
    diagram = linearize_sgf( sgf)
    intersections = get_sgf_tag( 'GC', sgf)
    intersections = re.sub( '\(','[',intersections)
    intersections = re.sub( '\)',']',intersections)
    intersections = re.sub( 'intersections','"intersections"',intersections)
    intersections = '{' + intersections + '}'
    intersections = json.loads( intersections)
    intersections = intersections[ 'intersections']
    elt = {'x':0, 'y':0, 'val':'EMPTY'}
    coltempl = [ copy.deepcopy(elt) for _ in range(boardsz) ]
    res = [ copy.deepcopy(coltempl) for _ in range(boardsz) ]
    for col in range(boardsz):
        for row in range(boardsz):
            idx = row * boardsz + col
            res[col][row]['val'] = diagram[idx]
            res[col][row]['x'] = intersections[idx][0]
            res[col][row]['y'] = intersections[idx][1]
    return res

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
    col = 'r'
    if SELECTED_CORNER == 'TR': col = 'g'
    elif SELECTED_CORNER == 'BR': col = 'b'
    elif SELECTED_CORNER == 'BL': col = 'c'
    ell = patches.Ellipse( (event.xdata, event.ydata), s, s, edgecolor=col, facecolor='none')
    CORNER_COORDS['SELECTED_CORNER'] = [event.xdata, event.ydata]
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
    CORNER_COORDS = { 'TL': [0.0, 0.0], 'TR': [0.0, 0.0], 'BR': [0.0, 0.0], 'BL': [0.0, 0.0] }
    AX_IMAGE.cla()
    AX_IMAGE.imshow( IMG, origin='upper')
    FIG.canvas.draw()

#----------------------------
def cb_btn_save( event):
    print( 'btn_save')
    AX_IMAGE.cla()
    AX_IMAGE.imshow( IMG, origin='upper')
    FIG.canvas.draw()

# Compute intersections from corners
#-------------------------------------
def cb_btn_done( event):
    tl = CORNER_COORDS['TL']
    tr = CORNER_COORDS['TR']
    br = CORNER_COORDS['BR']
    bl = CORNER_COORDS['BL']
    src_quad = np.array( [tl,tr,br,bl]).astype('float32')
    width = IMG.shape[1]
    height = IMG.shape[0]
    marg = width / 20.0

    # Transform corners to be a square
    s = width-2*marg
    target_square = np.array( [[marg,marg], [marg+s,marg], [marg+s,marg+s], [marg,marg+s]]).astype('float32')

    # Compute the grid
    intersections_zoomed = []
    ss = s / (BOARDSZ-1.0)
    for r in range(BOARDSZ):
        for c in range(BOARDSZ):
            x = marg + c*ss
            y = marg + r*ss
            intersections_zoomed.append([x,y])

    intersections_zoomed = np.array( intersections_zoomed).astype('float32')
    # Needs extra dimension
    extra = intersections_zoomed.reshape( 1,len(intersections_zoomed), 2)
    # Transform back
    M = cv2.getPerspectiveTransform( target_square, src_quad)
    intersections = cv2.perspectiveTransform( extra, M)
    intersections = intersections.reshape( len(intersections_zoomed), 2)

    # Show
    AX_IMAGE.cla()
    AX_IMAGE.imshow( IMG, origin='upper')
    r=5
    for isec in intersections:
        ell = patches.Ellipse( isec, r, r, edgecolor='r', facecolor='none')
        AX_IMAGE.add_patch( ell)
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

    FIG = plt.figure( figsize=(12,12))

    # Image
    IMG = mpl.image.imread( args.fname)
    AX_IMAGE = FIG.add_axes( [0.07, 0.06, 0.5, 0.9] )
    AX_IMAGE.imshow( IMG, origin='upper')
    cid = FIG.canvas.mpl_connect('button_press_event', onclick)

    # Sgf
    sgffname = os.path.splitext(args.fname)[0]+'.sgf'
    intersections = get_isec_coords( sgffname)

    # Reset button
    ax_reset = FIG.add_axes( [0.70, 0.1, 0.1, 0.05] )
    btn_reset = Button( ax_reset, 'Reset')
    btn_reset.on_clicked( cb_btn_reset)

    # Save button
    ax_save  = FIG.add_axes( [0.70, 0.16, 0.1, 0.05] )
    btn_save = Button( ax_save, 'Save')
    btn_save.on_clicked( cb_btn_save)

    # Done button computes and shows intersections
    ax_done  = FIG.add_axes( [0.70, 0.22, 0.1, 0.05] )
    btn_done = Button( ax_done, 'Done')
    btn_done.on_clicked( cb_btn_done)

    # Radiobutton for corner
    ax_radio = FIG.add_axes( [0.70, 0.5, 0.2, 0.2] )
    rbtn_corner = RadioButtons( ax_radio, ('TL', 'TR', 'BR', 'BL' ))
    rbtn_corner.on_clicked( cb_rbtn_corner)

    plt.show()


if __name__ == '__main__':
    main()
