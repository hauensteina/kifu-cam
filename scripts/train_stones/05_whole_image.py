#!/usr/bin/env python

# /********************************************************************
# Filename: whole_image.py
# Author: AHN
# Creation Date: Mar 2, 2018
# **********************************************************************/
#
# Run the model trained on small intersection crops on whole images
#

from __future__ import division, print_function
from pdb import set_trace as BP
import inspect
import os,sys,re,json
import numpy as np
from numpy.random import random
import argparse
import tensorflow.keras.layers as kl
import tensorflow.keras.models as km
import tensorflow.keras.optimizers as kopt
import tensorflow.keras.preprocessing.image as kp
import tensorflow as tf
import coremltools
import cv2

import matplotlib as mpl
mpl.use('Agg') # This makes matplotlib work without a display
from matplotlib import pyplot as plt

# Look for modules in our pylib folder
SCRIPTPATH = os.path.dirname(os.path.realpath(__file__))
sys.path.append( SCRIPTPATH + '/..')

import ahnutil as ut

# Limit GPU memory usage to 5GB
gpus = tf.config.experimental.list_physical_devices('GPU')
tf.config.experimental.set_virtual_device_configuration(
    gpus[0],
    [tf.config.experimental.VirtualDeviceConfiguration(memory_limit=5*1024)])

BATCH_SIZE=32

#---------------------------
def usage(printmsg=False):
    name = os.path.basename(__file__)
    msg = '''
    Name:
      %s --  Run the model trained on small intersection crops on whole images
    Synopsis:
      %s --image <image>
    Description:
      Run bew model on a big image
    Example:
      %s --image ~/kc-trainingdata/andreas/s3_2020-05-21/F7CCB0F8-20200414-161402.png
    ''' % (name,name,name)
    if printmsg:
        print(msg)
        exit(1)
    else:
        return msg

# The model
#===================================================================================================
class BEWModel:
    #------------------------------
    def __init__(self):
        self.build_model()

    #-----------------------
    def build_model(self):
        nb_colors=3
        inputs = kl.Input( shape = ( None, None, nb_colors), name = 'image')

        x = kl.Conv2D( 2, (3,3), activation='relu', padding='same', name='one_a')(inputs)
        x = kl.BatchNormalization()(x)
        x = kl.MaxPooling2D()(x)
        x = kl.Conv2D( 4, (3,3), activation='relu', padding='same', name='one_b')(x)
        x = kl.BatchNormalization()(x)
        x = kl.MaxPooling2D()(x)

        x = kl.Conv2D( 8, (3,3), activation='relu', padding='same', name='two_a')(x)
        x = kl.BatchNormalization()(x)
        x = kl.Conv2D( 4, (1,1), activation='relu', padding='same', name='two_b')(x)
        x = kl.BatchNormalization()(x)
        x = kl.Conv2D( 8, (3,3), activation='relu', padding='same', name='two_c')(x)
        x = kl.BatchNormalization()(x)
        x = kl.MaxPooling2D()(x)

        x = kl.Conv2D( 16,(3,3), activation='relu', padding='same', name='three_a')(x)
        x = kl.BatchNormalization()(x)
        x = kl.Conv2D( 8, (1,1), activation='relu', padding='same', name='three_b')(x)
        x = kl.BatchNormalization()(x)
        x = kl.Conv2D( 16, (3,3), activation='relu', padding='same', name='three_c')(x)
        x = kl.BatchNormalization()(x)
        x = kl.MaxPooling2D()(x)

        # Classification block
        lastconv = kl.Conv2D( 3, (1,1), padding='same', name='lastconv')(x)
        #x_class_pool = kl.GlobalAveragePooling2D()( x_class_conv)
        #output = kl.Activation( 'softmax', name='class')(x_class_pool)

        # Model not compiled because we do prediction only
        self.model = km.Model( inputs=inputs, outputs=lastconv)
        self.model.summary()

#===================================================================================================

#-----------
def main():
    if len(sys.argv) == 1:
        usage(True)

    parser = argparse.ArgumentParser( usage=usage())
    parser.add_argument( "--image", required=True)
    args = parser.parse_args()
    tt = cv2.imread( args.image, 1)
    BP()
    # arr[...,::-1] reverses the order of the innermost dimension, thus bgr to rgb.
    img = cv2.imread( args.image, 1)[...,::-1].astype(np.float32)
    img /= 255.0 # float images need values in [0,1]
    #plt.figure(); plt.imshow( img); plt.savefig( 'tt.jpg')
    #exit(0)
    #img = cv2.imread( args.image, 1).astype(np.float32)
    model = BEWModel()
    model.model.load_weights( 'nn_bew.weights', by_name=True)
    ut.visualize_channels( model.model, 'lastconv', [0,1,2], img, 'viz.jpg')

if __name__ == '__main__':
    main()
