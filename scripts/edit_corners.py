#!/usr/bin/env pythonw

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
import os,sys,re,json,copy,shutil
from io import StringIO
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
AX_STATUS = None
FIG = None
IMG = None
BOARDSZ = 19
NEW_INTERSECTIONS=[]
INTERSECTIONS=[]
DIAGRAM = []
FNAMES = []

#---------------------------
def usage(printmsg=False):
    name = os.path.basename(__file__)
    msg = '''
    Name: %s
    Synopsis: %s --run
    Description:
       Editor to define four corners in a Goban picture and save the intersections
       to an sgf in the GC[] tag.
       Goes through all png and jpg files in the current folder.
    Example:
      %s --run
    ''' % (name,name,name)
    if printmsg:
        print(msg)
        exit(1)
    else:
        return msg

#-----------
def main():
    global AX_IMAGE, AX_STATUS
    global FIG
    global FNAMES,FNUM

    if len(sys.argv) == 1:
        usage(True)

    parser = argparse.ArgumentParser(usage=usage())
    parser.add_argument( '--run', required=True, action='store_true')
    args = parser.parse_args()

    FNAMES = os.listdir('.')
    FNAMES = [f for f in FNAMES if (f.endswith('.png') or f.endswith('.jpg')) and not f.startswith('.') ]
    FNAMES = sorted(FNAMES)

    FIG = plt.figure( figsize=(9,8))

    AX_IMAGE = FIG.add_axes( [0.07, 0.06, 0.5, 0.9] )
    cid = FIG.canvas.mpl_connect('button_press_event', onclick)

    # Show button computes and shows intersections
    ax_show  = FIG.add_axes( [0.70, 0.28, 0.1, 0.05] )
    btn_show = Button( ax_show, 'Show')
    btn_show.on_clicked( cb_btn_show)

    # Clear button sets all intersections to clear
    ax_clear  = FIG.add_axes( [0.70, 0.22, 0.1, 0.05] )
    btn_clear = Button( ax_clear, 'Clear')
    btn_clear.on_clicked( cb_btn_clear)

    # Save button
    ax_save  = FIG.add_axes( [0.70, 0.16, 0.1, 0.05] )
    btn_save = Button( ax_save, 'Save')
    btn_save.on_clicked( cb_btn_save)

    # Next button
    ax_next  = FIG.add_axes( [0.70, 0.09, 0.1, 0.05] )
    btn_next = Button( ax_next, 'Next')
    btn_next.on_clicked( cb_btn_next)

    # Prev button
    ax_prev  = FIG.add_axes( [0.70, 0.03, 0.1, 0.05] )
    btn_prev = Button( ax_prev, 'Prev')
    btn_prev.on_clicked( cb_btn_prev)

    # Radiobutton for corner and Black Empty White
    ax_radio = FIG.add_axes( [0.70, 0.5, 0.2, 0.2] )
    rbtn_corner_bew = RadioButtons( ax_radio, ('TL', 'TR', 'BR', 'BL', 'Black', 'Empty', 'White' ))
    rbtn_corner_bew.on_clicked( cb_rbtn_corner_bew)

    # Status Message
    AX_STATUS = FIG.add_axes( [0.07, 0.02, 0.5, 0.05] )
    AX_STATUS.axis('off')
    #show_text( AX_STATUS, 'Status', 'red')

    FNUM=-1
    cb_btn_next()

    plt.show()


# Show next file
#-----------------------------
def cb_btn_next( event=None):
    global FNUM
    FNUM += 1
    FNUM %= len(FNAMES)
    show_next_prev()

# Show prev file
#-----------------------------
def cb_btn_prev( event=None):
    global FNUM
    FNUM -= 1
    FNUM %= len(FNAMES)
    show_next_prev()

# Display current file for the first time
#------------------------------------------
def show_next_prev():
    global IMG
    global INTERSECTIONS
    global DIAGRAM
    global SGF_FILE
    global CORNER_COORDS

    fname = FNAMES[FNUM]
    show_text( AX_STATUS, '%d/%d %s' % (FNUM+1, len(FNAMES), fname))

    # Load image
    IMG = cv2.imread( fname)
    IMG = cv2.cvtColor( IMG, cv2.COLOR_BGR2RGB)

    AX_IMAGE.cla()
    AX_IMAGE.imshow( IMG, origin='upper')

    # Sgf
    SGF_FILE = os.path.splitext( fname)[0] + '.sgf'
    INTERSECTIONS, DIAGRAM = get_isec_coords( SGF_FILE)
    CORNER_COORDS = { 'TL': [0.0, 0.0], 'TR': [0.0, 0.0], 'BR': [0.0, 0.0], 'BL': [0.0, 0.0] }
    draw_intersections( INTERSECTIONS, 5, 'g')



#===========
#=== Sgf ===
#===========

# Read an sgf file and linearize it into a list
# ['b','w','e',...]
#-------------------------------------------------
def linearize_sgf( sgf):
    boardsz = int( get_sgf_tag( 'SZ', sgf))
    if not 'KifuCam' in sgf:
        # The AW[ab][ce]... case
        match = re.search( 'AW(\[[a-s][a-s]\])*', sgf)
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
    try:
        with open( sgffile) as f: sgf = f.read()
    except:
        sgf = '(;GM[1]GN[]FF[4]CA[UTF-8]AP[KifuCam]RU[Chinese]PB[Black]PW[White]BS[0]WS[0]SZ[19] )'
    sgf = sgf.replace( '\\','')
    boardsz = int( get_sgf_tag( 'SZ', sgf))
    diagram = linearize_sgf( sgf)
    if not 'intersections:' in sgf and not 'intersections\:' in sgf:
        print('no intersections in ' + sgffile)
        intersections = [[0.0, 0.0]] * boardsz * boardsz
    else:
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
    try:
        with open( sgffile) as f: sgf = f.read()
    except:
        sgf = '(;GM[1]GN[]FF[4]CA[UTF-8]AP[KifuCam]RU[Chinese]PB[Black]PW[White]BS[0]WS[0]SZ[19] )'
    sgf = sgf.replace( '\\','')
    gc = get_sgf_tag( 'GC', sgf)
    phi = 0
    if 'phi:' in gc:
        phi = re.sub( r'.*#phi:([^#]*)#.*',r'\1',gc)
    theta = 0
    if 'theta:' in gc:
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

# Replace anything after the GC tag with the new position
#----------------------------------------------------------
def overwrite_sgf( sgffile, diagram):
    sgf  = open( sgffile).read()
    boardsz = int( get_sgf_tag( 'SZ', sgf))
    # Cut off after GC tag
    sgf = re.sub( '(.*GC\[[^\]]*\]).*', r'\1', sgf)
    moves = ''
    for i,bew in enumerate(diagram):
        row = i // boardsz
        col = i % boardsz
        ccol = chr( ord('a') + col)
        crow = chr( ord('a') + row)
        if bew == 'WHITE': tag = 'AW'
        elif bew == 'BLACK': tag = 'AB'
        else: continue
        moves += tag + "[" + ccol + crow + "]"
    sgf += moves + ')'
    open( sgffile, 'w').write( sgf)

#======================
#=== Click Handlers ===
#======================

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
    return (isecs[minidx][0], isecs[minidx][1], minidx)

# Image click in Black White Empty mode
#----------------------------------------
def handle_bew_click( event):
    # Find closest intersection
    x,y,idx = closest_isec( event.xdata, event.ydata, NEW_INTERSECTIONS)
    # Draw color on intersection
    if SELECTED_BEW == 'Black':
        col = 'g'
        DIAGRAM[idx] = 'BLACK'
    elif SELECTED_BEW == 'Empty':
        col = 'b'
        DIAGRAM[idx] = 'EMPTY'
    elif SELECTED_BEW == 'White':
        col = 'r'
        DIAGRAM[idx] = 'WHITE'
    s = 4
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
        s = 4
        ell = patches.Ellipse( (isec[0], isec[1]), s, s, edgecolor=col, facecolor=col)
        AX_IMAGE.add_patch( ell)
    FIG.canvas.draw()

# #----------------------------
# def cb_btn_reset( event):
#     CORNER_COORDS = { 'TL': [0.0, 0.0], 'TR': [0.0, 0.0], 'BR': [0.0, 0.0], 'BL': [0.0, 0.0] }
#     AX_IMAGE.cla()
#     AX_IMAGE.imshow( IMG, origin='upper')
#     FIG.canvas.draw()

# Write the sgf back, with the intersections swapped out
#----------------------------------------------------------
def cb_btn_save( event):
    isecs2sgf( SGF_FILE, np.round(NEW_INTERSECTIONS).tolist())
    overwrite_sgf( SGF_FILE, DIAGRAM)
    print( 'saved')
    sys.stdout.flush()

# Set all intersections to empty
#----------------------------------------------------------
def cb_btn_clear( event):
    for idx,d in enumerate(DIAGRAM):
        DIAGRAM[idx] = 'EMPTY'
    cb_btn_show( event)

# Compute and show intersections from corners
#------------------------------------------------
def cb_btn_show( event):
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
    paint_diagram( DIAGRAM, NEW_INTERSECTIONS)

# Draw circles on intersections
#-----------------------------------------------
def draw_intersections( intersections, r, col):
    for isec in intersections:
        ell = patches.Ellipse( isec, r, r, edgecolor=col, facecolor='none')
        AX_IMAGE.add_patch( ell)
    FIG.canvas.draw()

# Choose corner
#--------------------------------
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

#-------------------------------------------------
def show_text( ax, txt, color='black', size=10):
    ax.cla()
    ax.axis( 'off')
    ax.text( 0,0, txt,
             verticalalignment='bottom', horizontalalignment='left',
             transform = ax.transAxes,
             fontname = 'monospace', style = 'normal',
             color=color, fontsize=size)
    #FIG.canvas.draw()
    plt.pause( 0.0001)


if __name__ == '__main__':
    main()
