# /********************************************************************
# Filename: ocvutil.py
# Author: AHN
# Creation Date: Apr 7, 2018
# **********************************************************************/
#
# Various utility funcs for OpenCV
#

from __future__ import division,print_function

from pdb import set_trace as BP
import os,sys,re,json
import fnmatch
import shutil
import glob
import random
import numpy as np
import cv2
import matplotlib as mpl
mpl.use('Agg') # This makes matplotlib work without a display
from matplotlib import pyplot as plt

# Distance between point and line segment
#-------------------------------------------
def dist_point_line( p, line):
    x = p[0]
    y = p[1]
    x0 = line[0]
    y0 = line[1]
    x1 = line[2]
    y1 = line[3]
    num = (y0-y1)*x + (x1-x0)*y + (x0*y1 - x1*y0)
    den = np.sqrt( (x1-x0)*(x1-x0) + (y1-y0)*(y1-y0))
    return num / den

# Convert a line in (rho, theta) representation to a line segment
#-------------------------------------------------------------------
def polar2segment( pline):
    rho = pline[0]
    theta = pline[1]
    a = np.cos( theta)
    b = np.sin( theta)
    x0 = a*rho
    y0 = b*rho
    result = [0.0] * 4
    result[0] = np.round( x0 + 1000*(-b))
    result[1] = np.round( y0 + 1000*(a))
    result[2] = np.round( x0 - 1000*(-b))
    result[3] = np.round( y0 - 1000*(a))
    return result

# Line segment to polar, with positive rho
#---------------------------------------------------
def segment2polar( line_):
    line = [line_[0][0], line_[0][1], line_[1][0], line_[1][1]]
    # Always go left to right
    if line[2] < line[0]:
        line[0], line[2] = line[2], line[0]
        line[1], line[3] = line[3], line[1]
    dx = line[2] - line[0]
    dy = line[3] - line[1]

    if abs(dx) > abs(dy): # horizontal
        if dx < 0:
            dx *= -1
            dy *= -1
    else: # vertical
        if dy > 0:
            dx *= -1
            dy *= -1

    theta = np.arctan2( dy, dx) + np.pi/2
    rho = abs( dist_point_line( (0,0), line))
    pline = [rho, theta]
    return pline

# Perform a perspective transform on a bunch of points
#-------------------------------------------------------
def perspTrans( pts, M):
    # pts needs a stupid empty dimension added
    sz = len( pts)
    pts_zoomed = cv2.perspectiveTransform( pts.reshape( 1, sz, 2).astype('float32'), M)
    # And now get rid of the extra dim and back to int
    res = pts_zoomed.reshape(sz,2).astype('float32')
    return res

# Perform an affine transform on a bunch of points
#-------------------------------------------------------
def affTrans( pts, M):
    # pts needs a stupid empty dimension added
    sz = len( pts)
    pts_trans = cv2.transform( pts.reshape( 1, sz, 2).astype('float32'), M)
    # And now get rid of the extra dim and back to int
    res = pts_trans.reshape(sz,2).astype('float32')
    return res

# Run a matrix over a bunch of line segments
#---------------------------------------------
def warp_lines( lines, M):
    if not len(lines): return
    p1s = np.array( [li[0] for li in lines], dtype='float')
    p2s = np.array( [li[1] for li in lines], dtype='float')
    if M.shape[0] == 3: # persp trans
        p1srot = perspTrans( p1s, M)
        p2srot = perspTrans( p2s, M)
    else: # affine trans
        p1srot = affTrans( p1s, M)
        p2srot = affTrans( p2s, M)

    res = []
    for idx, p1 in enumerate( p1srot):
        p2 = p2srot[idx]
        res.append( [[p1[0], p1[1]], [p2[0], p2[1]]])
    return np.array( res, dtype='float')
