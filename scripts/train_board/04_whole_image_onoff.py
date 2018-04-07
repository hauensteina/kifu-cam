#!/usr/bin/env python

# /********************************************************************
# Filename: whole_image.py
# Author: AHN
# Creation Date: Mar 5, 2018
# **********************************************************************/
#
# Run the onoff board model trained on small intersection crops on whole images
#

from __future__ import division, print_function
from pdb import set_trace as BP
import inspect
import os,sys,re,json
import numpy as np
from numpy.random import random
import argparse
import keras.layers as kl
import keras.models as km
import keras.optimizers as kopt
import coremltools
import cv2

import matplotlib as mpl
mpl.use('Agg') # This makes matplotlib work without a display
from matplotlib import pyplot as plt

# Look for modules in our pylib folder
SCRIPTPATH = os.path.dirname(os.path.realpath(__file__))
sys.path.append( SCRIPTPATH + '/..')

import ahnutil as ut
from IOModelConv import IOModelConv

#---------------------------
def usage(printmsg=False):
    name = os.path.basename(__file__)
    msg = '''
    Name:
      %s --  Run the onoff board model trained on small intersection crops on whole images
    Synopsis:
      %s --image <image>
    Description:
      Run io model on a big image
    Example:
      %s --image ~/kc-trainingdata/andreas/20180227/testcase_00030.png
    ''' % (name,name,name)
    if printmsg:
        print(msg)
        exit(1)
    else:
        return msg

# Dump jpegs of model conv layer channels to file
#---------------------------------------------------------------------
def visualize_channels( model, layer_name, channels, img_, fname):
    img = img_.copy()
    img *= 2.0; img -= 1.0 # normalize to [-1,1] before feeding to model
    img = img.reshape( (1,) + img.shape) # Add dummy batch dimension
    channel_data = ut.get_output_of_layer( model, layer_name, img)[0]
    nplots = len( channels) + 2 # channels plus orig + overlay
    ncols = 1
    nrows = nplots // ncols
    plt.figure( edgecolor='k')
    fig = plt.gcf()
    scale = 6.0
    fig.set_size_inches( scale*ncols, scale*nrows)

    # Show input image
    plt.subplot( nrows, ncols, 1)
    ax = plt.gca()
    ax.get_xaxis().set_visible( False)
    ax.get_yaxis().set_visible( False)
    plt.imshow( img_) #  cmap='Greys')

    # Show overlay
    plt.subplot( nrows, ncols, 2)
    ax = plt.gca()
    ax.get_xaxis().set_visible( False)
    ax.get_yaxis().set_visible( False)
    plt.imshow( img_) #  orig
    data = channel_data[: ,:, 0] # onboardness
    dimg  = cv2.resize( data, (img_.shape[1], img_.shape[0]), interpolation = cv2.INTER_NEAREST)
    plt.imshow( dimg, cmap='hot', alpha=0.5)

    # Show output channels
    for idx,channel in enumerate( channels):
        data = channel_data[:,:,channel]
        # Normalization unnecessary, done automagically
        #mmin = np.min(data)
        #data -= mmin
        #mmax = np.max(data)
        #data /= mmax
        dimg  = cv2.resize( data, (img_.shape[1], img_.shape[0]), interpolation = cv2.INTER_NEAREST)
        plt.subplot( nrows, ncols, idx+3)
        ax = plt.gca()
        ax.get_xaxis().set_visible( False)
        ax.get_yaxis().set_visible( False)
        plt.imshow( dimg, cmap='hot', alpha=1.0)

    # # Channel 0 minus Channel 1
    # chan0 =  channel_data[:,:,0].astype(np.float32)
    # chan1 =  channel_data[:,:,1].astype(np.float32)
    # diff = chan0 - chan1
    # mmax = np.max(diff)
    # mmin = np.min(diff)
    # diff -= mmin
    # diff /= (mmax - mmin)
    # diff *= 255
    # diff = diff.astype(np.uint8)
    # dimg = cv2.resize( diff, (img_.shape[1], img_.shape[0]), interpolation = cv2.INTER_NEAREST)
    # plt.subplot( nrows, ncols, nrows)
    # ax = plt.gca()
    # ax.get_xaxis().set_visible( False)
    # ax.get_yaxis().set_visible( False)
    # plt.imshow( dimg, cmap='hot', alpha=1.0)


    plt.tight_layout()
    plt.savefig( fname)

#-----------
def main():
    if len(sys.argv) == 1:
        usage(True)

    parser = argparse.ArgumentParser( usage=usage())
    parser.add_argument( "--image", required=True)
    args = parser.parse_args()
    img = cv2.imread( args.image, 1)[...,::-1].astype(np.float32) # bgr to rgb
    img /= 255.0 # float images need values in [0,1]
    #plt.figure(); plt.imshow( img); plt.savefig( 'tt.jpg')
    #exit(0)
    #img = cv2.imread( args.image, 1).astype(np.float32)
    model = IOModelConv()
    model.model.load_weights( 'nn_io.weights', by_name=True)
    visualize_channels( model.model, 'lastconv', [0,1], img, 'viz.jpg')

if __name__ == '__main__':
    main()
