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
def segment2polar( line):
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

    theta = np.atan2( dy, dx) + np.pi/2
    rho = abs( dist_point_line( (0,0), line))
    pline = [rho, theta]
    return pline
