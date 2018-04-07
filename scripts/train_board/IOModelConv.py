#!/usr/bin/env python

# /********************************************************************
# Filename: IOModelConv.py
# Author: AHN
# Creation Date: Mar 5, 2018
# **********************************************************************/
#
# Model definition to distinguish on and off board (I=In, O=Off)
#

from __future__ import division, print_function
from pdb import set_trace as BP
import inspect
import os,sys,re,json, shutil
import numpy as np
from numpy.random import random
import argparse
import keras.layers as kl
import keras.models as km
import keras.optimizers as kopt
import keras.preprocessing.image as kp
import coremltools

import matplotlib as mpl
mpl.use('Agg') # This makes matplotlib work without a display
from matplotlib import pyplot as plt

# Look for modules in our pylib folder
SCRIPTPATH = os.path.dirname(os.path.realpath(__file__))
sys.path.append( SCRIPTPATH + '/..')

import ahnutil as ut


import tensorflow as tf
from keras import backend as K


# A convolutional model
#===================================================================================================
class IOModelConv:
    #------------------------------
    def __init__( self, width=None, height=None, rate=0, classify=True):
        self.width  = width
        self.height = height
        self.rate   = rate
        if classify:
            self.build_model_classify()
        else:
            self.build_model_conv()

    # The layers which are the same for classification and conv feature mode
    #--------------------------------------------------------------------------
    def make_layers( self, inputs):
        x = kl.Conv2D( 4, (3,3), activation='relu', padding='same', name='one_a')(inputs)
        #x = kl.BatchNormalization()(x)
        #x = kl.MaxPooling2D()(x)
        x = kl.Conv2D( 8, (3,3), activation='relu', padding='same', name='one_b')(x)
        #x = kl.BatchNormalization()(x)
        #x = kl.MaxPooling2D()(x)

        x = kl.Conv2D( 8, (3,3), activation='relu', padding='same', name='two_a')(x)
        #x = kl.BatchNormalization()(x)
        x = kl.Conv2D( 4, (1,1), activation='relu', padding='same', name='two_b')(x)
        #x = kl.BatchNormalization()(x)
        x = kl.Conv2D( 8, (3,3), activation='relu', padding='same', name='two_c')(x)
        #x = kl.BatchNormalization()(x)
        x = kl.MaxPooling2D()(x)

        x = kl.Conv2D( 16,(3,3), activation='relu', padding='same', name='three_a')(x)
        #x = kl.BatchNormalization()(x)
        x = kl.Conv2D( 8, (1,1), activation='relu', padding='same', name='three_b')(x)
        #x = kl.BatchNormalization()(x)
        x = kl.Conv2D( 16, (3,3), activation='relu', padding='same', name='three_c')(x)
        #x = kl.BatchNormalization()(x)
        x = kl.MaxPooling2D()(x)
        # Convolutional class layer (one channel per class)
        lastconv = kl.Conv2D( 2, (3,3), padding='same', name='lastconv')(x)
        return lastconv

    # Small crops with a classifier at the end. For training.
    #----------------------------------------------------------
    def build_model_classify( self):
        nb_colors=3
        inputs = kl.Input( shape = ( self.height, self.width, nb_colors), name = 'image')
        lastconv = self.make_layers( inputs)

        # Classification block
        x_class_pool = kl.GlobalAveragePooling2D()( lastconv)
        output = kl.Activation( 'softmax', name='class')(x_class_pool)

        self.model = km.Model( inputs=inputs, outputs=output)
        self.model.summary()
        if self.rate > 0:
            opt = kopt.Adam( self.rate)
        else:
            opt = kopt.Adam()
        self.model.compile( loss='categorical_crossentropy', optimizer=opt, metrics=['accuracy'])

    # Whole image, output a convolutional layer per class.
    #------------------------------------------------------
    def build_model_conv( self):
        nb_colors=3
        inputs = kl.Input( shape = ( self.height, self.width, nb_colors), name = 'image')
        lastconv = self.make_layers( inputs)

        # Just use highest convolutional layer as output
        self.model = km.Model( inputs=inputs, outputs=lastconv)
        self.model.summary()
