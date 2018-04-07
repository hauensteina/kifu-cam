#!/usr/bin/env python

# /********************************************************************
# Filename: generate_training_crops.py
# Author: AHN
# Creation Date: Mar 5, 2018
# **********************************************************************/
#
# Get crops to train a two class classifier onboard/offboard.
# Crops are taken *before* perspective transform.
#

from __future__ import division, print_function
from pdb import set_trace as BP
import os,sys,re,json,copy
import numpy as np
from numpy.random import random, randint
import argparse
import matplotlib as mpl
mpl.use('Agg') # This makes matplotlib work without a display
from matplotlib import pyplot as plt

# Look for modules in our pylib folder
SCRIPTPATH = os.path.dirname(os.path.realpath(__file__))
sys.path.append( SCRIPTPATH + '/..')

import ahnutil as ut

import cv2

CROPSZ = 23

#---------------------------
def usage(printmsg=False):
    name = os.path.basename(__file__)
    msg = '''
    Name:
      %s --   Get crops to train a two class classifier in_board / edge_of_board
    Synopsis:
      %s --infolder <ifolder> --outfolder <ofolder>
    Description:
      Gets crops from inside the board vs edge of board.
    Example:
      %s --infolder ~/kc-trainingdata/andreas/phitheta --outfolder kc-inside-edge-crops
    ''' % (name,name,name)
    if printmsg:
        print(msg)
        exit(1)
    else:
        return msg

# Collect matching jpeg and sgf in a dictionary
#----------------------------------------------------
def collect_files( infolder):
    # Find images
    imgs =  ut.find( infolder, '[!.]*.jpeg')
    imgs += ut.find( infolder, '[!.]*.jpg')
    imgs += ut.find( infolder, '[!.]*.png')
    # Basenames
    basenames = [os.path.basename(f) for f in imgs]
    basenames = [os.path.splitext(f)[0] for f in basenames]
    # json files
    # jsons = []
    # if ut.find( infolder, '*_intersections.json'):
    #     jsons = [ut.find( infolder, '%s_intersections.json' % f)[0] for f in basenames]
    sgfs = []
    if ut.find( infolder, '*.sgf'):
        sgfs = [ut.find( infolder, '%s.sgf' % f)[0] for f in basenames]

    # Collect in dictionary
    files = {}
    for i,bn in enumerate( basenames):
        d = {}
        files[bn] = d
        d['img'] = imgs[i]
        #if jsons: d['json'] = jsons[i]
        if sgfs:  d['sgf']  = sgfs[i]
    # Sanity check
    for bn in files.keys():
        d = files[bn]
        if not bn in d['img']:
            print( 'ERROR: Wrong img name for key %s' % (d['img'], bn))
            exit(1)
        # elif jsons and not bn in d['json']:
        #     print( 'ERROR: Wrong json name for key %s' % (d['json'], bn))
        #     exit(1)
        elif sgfs and not bn in d['sgf']:
            print( 'ERROR: Wrong sgf name for key %s' % (d['sgf'], bn))
            exit(1)
    return files

# Rescale image and intersections to width 350
#-----------------------------------------------
def scale_350( imgfile, jsonfile):
    TARGET_WIDTH = 350
    # Read the image
    img = cv2.imread( imgfile, 1)
    # Parse json
    columns = json.load( open( jsonfile))
    # Linearize
    board_sz = len(columns)
    intersections = [0] * (board_sz * board_sz)
    for c,col in enumerate( columns):
        for r, row in enumerate( col):
            idx = board_sz * r + c
            intersections[idx] = row

    orig_height = img.shape[0]
    orig_width = img.shape[1]

    # orig_width = img.shape[1]
    # if orig_with == WIDTH:
    #     return( img, intersections)

    # Perspective transform
    #-------------------------
    # Corners
    tl = (0,0)
    tr = (orig_width-1,0)
    br = (orig_width-1, orig_height-1)
    bl = (0, orig_height-1)
    corners = np.array( [tl,tr,br,bl], dtype = "float32")

    # Target coords for transform
    scale = TARGET_WIDTH / orig_width
    target = np.array([
        (0,0),
        (TARGET_WIDTH - 1, 0),
        (TARGET_WIDTH - 1, orig_height * scale - 1),
        (0,  orig_height * scale - 1)], dtype = "float32")
    M = cv2.getPerspectiveTransform( corners, target)
    scaled_img = cv2.warpPerspective( img, M, (TARGET_WIDTH, int(orig_height * scale)))

    coords = []
    for isec in intersections:
        coords.append( [isec['x'], isec['y']])
    coords = np.array( coords)
    # Transform the intersections
    # This needs a stupid empty dimension added
    sz = len(coords)
    coords_zoomed = cv2.perspectiveTransform( coords.reshape( 1, sz, 2).astype('float32'), M)
    # And now get rid of the extra dim and back to int
    coords_zoomed = coords_zoomed.reshape(sz,2).astype('int')
    # Back to the old format
    intersections_zoomed = []
    for idx,isec in enumerate( intersections):
        intersections_zoomed.append( isec.copy())
        nnew = intersections_zoomed[-1]
        nnew['x'] = coords_zoomed[idx][0]
        nnew['y'] = coords_zoomed[idx][1]
        # Mark if off screen
        marg = int( CROPSZ / 2.0 + 1)
        if (isec['x'] < marg
            or isec['y'] < marg
            or isec['x'] > orig_width - marg
            or isec['y'] > orig_height - marg):
            nnew['off_screen'] = 1
    res = (scaled_img, intersections_zoomed)
    return res

# Save intersection crops of size rxr
#-------------------------------------------------------------------
def save_intersections( img, intersections, r, basename, folder):
    dx = int(r / 2)
    dy = int(r / 2)
    for i,isec in enumerate( intersections):
        color = isec['val'][0]
        x = isec['x']
        y = isec['y']
        hood = img[y-dy:y+dy+1, x-dx:x+dx+1]
        fname = "%s/%s_rgb_%s_hood_%03d.jpg" % (folder, color, basename, i)
        if color in ['I','O'] and not 'off_screen' in isec:
            cv2.imwrite( fname, hood)

# e.g for board size, call get_sgf_tag( sgf, "SZ")
#---------------------------------------------------
def get_sgf_tag( tag, sgf):
    m = re.search( tag + '\[[^\]]*', sgf)
    if not m: return ''
    mstr = m.group(0)
    res = mstr.split( '[')[1]
    res = res.split( ']')[0]
    return res

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

# Parse phi and theta out of the sgf file
#-------------------------------------------
def get_phi_theta( fname):
    with open( fname) as f: sgf = f.read()
    gc = get_sgf_tag( 'GC', sgf)
    gc = gc.replace( '\\','')
    phi = re.sub( r'.*#phi:([^#]*)#.*',r'\1',gc)
    theta = re.sub( r'.*#theta:([^#]*)#.*',r'\1',gc)
    return float(phi), float(theta)

# Make a Wallstedt type json file from an sgf with the
# intersection coordinates in the GC tag
#--------------------------------------------
def make_json_file( sgffile, ofname):
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
    elt = {'x':0, 'y':0, 'val':'EMPTY'}
    coltempl = [ copy.deepcopy(elt) for _ in range(boardsz) ]
    res = [ copy.deepcopy(coltempl) for _ in range(boardsz) ]
    for col in range(boardsz):
        for row in range(boardsz):
            idx = row * boardsz + col
            res[col][row]['val'] = diagram[idx]
            res[col][row]['x'] = intersections[idx][0]
            res[col][row]['y'] = intersections[idx][1]
    jstr = json.dumps( res)
    with open( ofname, 'w') as f: f.write( jstr)

# Randomly find boardsize*boardsz offboard crops and save them to folder.
# This won't work if the board fills the image. Print a warning and return.
#----------------------------------------------------------------------------
def save_offboard_crops( img, intersections, r, basename, folder):
    boardsz = int( np.sqrt( len( intersections)) + 0.5)
    tl = intersections[0]
    tr = intersections[boardsz-1]
    br = intersections[boardsz*boardsz-1]
    bl = intersections[boardsz*boardsz - boardsz]
    cnt = np.array (
        ((tl['x'], tl['y']),
        (tr['x'], tr['y']),
        (br['x'], br['y']),
        (bl['x'], bl['y']))
        , dtype='int32' )

    dgrid = np.round( cv2.norm( (bl['x'],bl['y']), (br['x'], br['y']) ) / (boardsz - 1))
    height = img.shape[0]
    width  = img.shape[1]

    if bl['y'] - tl['y'] > height * 0.9:
        print( 'ERROR: board fills image')
        return

    outside_points = []
    marg = r // 2 + 1
    for i in range( boardsz * boardsz):
        d = 0
        while d > -dgrid: # close to board, try again
            x = randint( marg, width-marg)
            y = randint( marg, height-marg)
            d = cv2.pointPolygonTest (cnt, (x,y), measureDist=True)
        isec = {'x':x, 'y':y, 'val':'O'} # 'O' like OUT
        outside_points += [isec]
    save_intersections( img, outside_points, r, basename, folder)

# Randomly find boardsize*boardsz onboard crops and save them to folder.
#----------------------------------------------------------------------------
def save_onboard_crops( img, intersections, r, basename, folder):
    boardsz = int( np.sqrt( len( intersections)) + 0.5)
    tl = intersections[0]
    tr = intersections[boardsz-1]
    br = intersections[boardsz*boardsz-1]
    bl = intersections[boardsz*boardsz - boardsz]
    cnt = np.array (
        ((tl['x'], tl['y']),
        (tr['x'], tr['y']),
        (br['x'], br['y']),
        (bl['x'], bl['y']))
        , dtype='int32' )

    dgrid = np.round( cv2.norm( (bl['x'],bl['y']), (br['x'], br['y']) ) / (boardsz - 1))
    height = img.shape[0]
    width  = img.shape[1]

    inside_points = []
    marg = r // 2 + 1
    for i in range( boardsz * boardsz):
        d = 0
        while d <= 0: # off board, try again
            x = randint( marg, width-marg)
            y = randint( marg, height-marg)
            d = cv2.pointPolygonTest( cnt, (x,y), measureDist=True)
        isec = {'x':x, 'y':y, 'val':'I'} # 'I' like IN
        inside_points += [isec]
    save_intersections( img, inside_points, r, basename, folder)

# Randomly choose boardsize*boardsz crops and save them to folder.
#----------------------------------------------------------------------------
def save_random_crops( img, intersections, r, basename, folder):
    boardsz = int( np.sqrt( len( intersections)) + 0.5)
    height = img.shape[0]
    width  = img.shape[1]

    points = []
    marg = r // 2 + 1
    for i in range( boardsz * boardsz):
        x = randint( marg, width-marg)
        y = randint( marg, height-marg)
        isec = {'x':x, 'y':y, 'val':'O'} # 'O' like Outside, because it's probably not an intersection
        points += [isec]
    save_intersections( img, points, r, basename, folder)


# Return a perspective transform by angle phi
#-----------------------------------------------
def perspective_warp( rows, cols, phi):
    phi *= np.pi / 180.0
    center_x = cols / 2.0
    center_y = rows / 2.0
    a = 1.0 * rows # Distance of eye from image center
    s = 1.0 # side of orig square
    # Undistorted orig square
    # Move the square down to avoid projecting the top edge off screen
    d = (rows / 4.0) * np.cos(phi) * -1
    bl_sq = ( center_x - s/2.0, center_y + d)
    br_sq = ( center_x + s/2.0, center_y + d)
    tl_sq = ( center_x - s/2.0, center_y - s + d)
    tr_sq = ( center_x + s/2.0, center_y - s + d)
    # Distorted by angle phi
    bl_dist = ( center_x - s/2.0, center_y)
    br_dist = ( center_x + s/2.0, center_y)
    l2r = a / (s * (np.sqrt( a*a + s*s - 2 * a * s * np.cos(phi)))) # distorted distance left to right
    b2t = s * np.sin( phi) # distorted bottom to top
    tl_dist = ( center_x - l2r/2.0, center_y - b2t)
    tr_dist = ( center_x + l2r/2.0, center_y - b2t)
    src = np.array( [tl_dist, tr_dist, br_dist, bl_dist], dtype = 'float32')
    dst = np.array( [tl_sq, tr_sq, br_sq, bl_sq], dtype = 'float32')
    M = cv2.getPerspectiveTransform( src, dst)
    return M

#-----------
def main():
    if len(sys.argv) == 1:
        usage(True)

    parser = argparse.ArgumentParser(usage=usage())
    parser.add_argument( "--infolder",      required=True)
    parser.add_argument( "--outfolder",     required=True)
    args = parser.parse_args()

    os.makedirs( args.outfolder)
    files = collect_files( args.infolder)

    for i,k in enumerate( files.keys()):
        print( '%s ...' % k)
        f = files[k]
        f['json'] = os.path.dirname( f['img']) + '/%s_intersections.json' % k
        make_json_file( f['sgf'], f['json'])
        phi, theta = get_phi_theta( f['sgf'])
        img, intersections = scale_350( f['img'], f['json'])
        rows = img.shape[0]
        cols = img.shape[1]
        Ms = cv2.getRotationMatrix2D( (cols/2.0, rows/2.0), theta, 1.0)
        Mp = perspective_warp( rows, cols, phi)
        # Unwarp image
        #cv2.imwrite( 'tt1.jpg', img)
        img = cv2.warpAffine( img, Ms, (cols, rows))
        #cv2.imwrite( 'tt2.jpg', img)
        img = cv2.warpPerspective( img, Mp, (cols, rows))
        #cv2.imwrite( 'tt3.jpg', img)
        # Unwarp intersections
        isecs = np.array( [[p['x'],p['y']] for p in intersections], dtype = 'float32')
        # This needs a stupid empty dimension added
        sz = len(isecs)
        isecs_unwarped = cv2.transform( isecs.reshape( 1, sz, 2).astype('float32'), Ms)
        isecs_unwarped = cv2.perspectiveTransform( isecs_unwarped, Mp)
        isecs_unwarped = isecs_unwarped.reshape(sz,2).astype('int')
        for idx,isec in enumerate(intersections):
            isec['x'] = isecs_unwarped[idx][0]
            isec['y'] = isecs_unwarped[idx][1]

        if len(intersections) != 19*19:
            print( 'not a 19x19 board, skipping')
            continue
        boardsz = 19
        inner_isecs = []
        outer_isecs = []
        for idx, isec in enumerate( intersections):
            isec['val'] = 'I'
            if idx % boardsz == 0: isec['val'] = 'O' # left
            if idx % boardsz == boardsz-1: isec['val'] = 'O' # right
            if idx < boardsz: isec['val'] = 'O' # top
            if idx >= boardsz*boardsz - boardsz: isec['val'] = 'O' # bottom
            if isec['val'] == 'I':
            	inner_isecs.append( isec)
            else:
	            outer_isecs.append( isec)
        # Make sure same number of example for each class
        save_intersections( img, inner_isecs[:len(outer_isecs)], CROPSZ, k, args.outfolder)
        save_intersections( img, outer_isecs, CROPSZ, k, args.outfolder)

if __name__ == '__main__':
    main()
