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
SELECTED_BEW = 'Black'
CORNER_COORDS = { 'TL': [0.0, 0.0], 'TR': [0.0, 0.0], 'BR': [0.0, 0.0], 'BL': [0.0, 0.0] }
AX_IMAGE = None
FIG = None
IMG = None
BOARDSZ = 19
NEW_INTERSECTIONS=[]
INTERSECTIONS=[]
DIAGRAM = []

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

# Get list of intersection coords from sgf GC tag
#--------------------------------------------------
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
    intersections = re.sub( '#.*','',intersections)
    intersections = '{' + intersections + '}'
    intersections = json.loads( intersections)
    intersections = intersections[ 'intersections']
    return (intersections, diagram)

# Read sgf, replace intersections, write back
#-----------------------------------------------
def isecs2sgf( sgffile, intersections):
    sgf  = open( sgffile).read()
    gc = get_sgf_tag( 'GC', sgf)
    phi = re.sub( r'.*#phi:([^#]*)#.*',r'\1',gc)
    theta = re.sub( r'.*#theta:([^#]*)#.*',r'\1',gc)

    tstr = json.dumps( intersections)
    tstr = re.sub( '\[','(',tstr)
    tstr = re.sub( '\]',')',tstr)
    tstr = 'GC[intersections:' + tstr + '#' + 'phi:%.2f#' % float(phi) + 'theta:%.2f#' % float(theta) + ']'
    res = sgf
    res = re.sub( '(GC\[[^\]]*\])', '', res)
    res = re.sub( '(SZ\[[^\]]*\])', r'\1' + tstr, res)
    res = re.sub( r'\s*','', res)
    open( sgffile, 'w').write( res)

#----------------------
def onclick( event):
    global SELECTED_CORNER
    if not event.xdata: return
    if event.xdata < 1: return # The click was on a button, not the image

    if SELECTED_CORNER:
        handle_corner_click( event)
    else:
        handle_bew_click( event)

# Image click in corner mode
#--------------------------------
def handle_corner_click( event):
    global SELECTED_CORNER
    global CORNER_COORDS
    global AX_IMAGE
    global FIG

    CORNER_COORDS[SELECTED_CORNER][0] = event.xdata
    CORNER_COORDS[SELECTED_CORNER][1] = event.ydata

    s = 15
    r = s / 2.0
    col = 'r'
    if SELECTED_CORNER == 'TR': col = 'm'
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

# Find closest intersection to x,y
#-------------------------------------
def closest_isec( x, y, isecs):
    mind = 1E9
    minidx = -1
    for idx, isec in enumerate(isecs):
        d = (x-isec[0])*(x-isec[0]) + (y-isec[1])*(y-isec[1])
        if d < mind:
            mind = d
            minidx = idx
    return (isecs[minidx][0], isecs[minidx][1])

# Image click in Black White Empty mode
#----------------------------------------
def handle_bew_click( event):
    # Find closest intersection
    x,y = closest_isec( event.xdata, event.ydata, NEW_INTERSECTIONS)
    # Draw color on intersection
    if SELECTED_BEW == 'Black': col = 'g'
    elif SELECTED_BEW == 'Empty': col = 'b'
    elif SELECTED_BEW == 'White': col = 'r'
    s = 5
    ell = patches.Ellipse( (x, y), s, s, edgecolor=col, facecolor=col)
    AX_IMAGE.add_patch( ell)
    FIG.canvas.draw()

# Mark Black, White, Empty on the screen
#--------------------------------------------
def paint_diagram( diagram, intersections):
    for idx,bew in enumerate(diagram):
        isec = intersections[idx]
        if bew == 'BLACK':
            col = 'g'
        elif bew == 'EMPTY':
            col = 'b'
        elif bew == 'WHITE':
            col = 'r'
        s = 5
        ell = patches.Ellipse( (isec[0], isec[1]), s, s, edgecolor=col, facecolor=col)
        AX_IMAGE.add_patch( ell)
    FIG.canvas.draw()

#----------------------------
def cb_btn_reset( event):
    CORNER_COORDS = { 'TL': [0.0, 0.0], 'TR': [0.0, 0.0], 'BR': [0.0, 0.0], 'BL': [0.0, 0.0] }
    AX_IMAGE.cla()
    AX_IMAGE.imshow( IMG, origin='upper')
    FIG.canvas.draw()

# Write the sgf back, with the intersections swapped out
#----------------------------------------------------------
def cb_btn_save( event):
    isecs2sgf( SGF_FILE, np.round(NEW_INTERSECTIONS).tolist())
    print( 'saved')

# Compute intersections from corners
#-------------------------------------
def cb_btn_done( event):
    global NEW_INTERSECTIONS

    if CORNER_COORDS['TL'][0] == 0.0: # didn't mark corners
        CORNER_COORDS['TL'] = INTERSECTIONS[0]
        CORNER_COORDS['TR'] = INTERSECTIONS[BOARDSZ-1]
        CORNER_COORDS['BR'] = INTERSECTIONS[BOARDSZ*BOARDSZ-1]
        CORNER_COORDS['BL'] = INTERSECTIONS[BOARDSZ*BOARDSZ-BOARDSZ]

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
    NEW_INTERSECTIONS = intersections.tolist()

    # Show
    AX_IMAGE.cla()
    AX_IMAGE.imshow( IMG, origin='upper')
    #draw_intersections( intersections, 5, 'r')
    paint_diagram( DIAGRAM, INTERSECTIONS)

# Draw circles on intersections
#-----------------------------------------------
def draw_intersections( intersections, r, col):
    for isec in intersections:
        ell = patches.Ellipse( isec, r, r, edgecolor=col, facecolor='none')
        AX_IMAGE.add_patch( ell)
    FIG.canvas.draw()

# Choose corner
#----------------------------
def cb_rbtn_corner_bew( label):
    global SELECTED_CORNER
    global SELECTED_BEW
    if label in ('Black', 'Empty', 'White'):
        SELECTED_CORNER = ''
        SELECTED_BEW = label
        print( 'rbtn_bew %s' % label)
    else:
        SELECTED_BEW = ''
        SELECTED_CORNER = label
        print( 'rbtn_corner %s' % label)

#-----------
def main():
    global SELECTED_CORNER
    global AX_IMAGE
    global CORNER_COORDS
    global FIG
    global IMG
    global SGF_FILE
    global INTERSECTIONS
    global DIAGRAM

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
    SGF_FILE = os.path.splitext(args.fname)[0]+'.sgf'
    INTERSECTIONS, DIAGRAM = get_isec_coords( SGF_FILE)
    draw_intersections( INTERSECTIONS, 5, 'g')

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

    # Radiobutton for corner and Black Empty White
    ax_radio = FIG.add_axes( [0.70, 0.5, 0.2, 0.2] )
    rbtn_corner_bew = RadioButtons( ax_radio, ('TL', 'TR', 'BR', 'BL', 'Black', 'Empty', 'White' ))
    rbtn_corner_bew.on_clicked( cb_rbtn_corner_bew)

    plt.show()


if __name__ == '__main__':
    main()
