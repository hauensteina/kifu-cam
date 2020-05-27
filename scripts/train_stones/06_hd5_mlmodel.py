#!/usr/bin/env python

# /********************************************************************
# Filename: hd5_mlmodel
# Author: AHN
# Creation Date: Jul 19, 2019
# **********************************************************************/
#
# Convert an hd5 model to coreml mlmodel usable in xcode
#

from __future__ import division, print_function
from pdb import set_trace as BP
import inspect
import os,sys,re,json, shutil
import numpy as np
from numpy.random import random
import argparse
import tensorflow.keras.layers as kl
import tensorflow.keras.models as km
import tensorflow.keras.optimizers as kopt
import tensorflow.keras.preprocessing.image as kp
import coremltools

# Look for modules in our pylib folder
SCRIPTPATH = os.path.dirname(os.path.realpath(__file__))
sys.path.append( SCRIPTPATH + '/..')

import ahnutil as ut


import tensorflow as tf
from tensorflow.keras import backend as K
from tensorflow.keras.callbacks import ModelCheckpoint

# Limit GPU memory usage to 5GB
gpus = tf.config.experimental.list_physical_devices('GPU')
tf.config.experimental.set_virtual_device_configuration(
    gpus[0],
    [tf.config.experimental.VirtualDeviceConfiguration(memory_limit=5*1024)])

args = None

#---------------------------
def usage(printmsg=False):
    name = os.path.basename(__file__)
    msg = '''
    Name:
      %s --  Convert an hd5 model to mlmodel usable in xcode
    Synopsis:
      %s --file <file.hd5>
    Description:
      Ouput goes to nn_bew.mlmodel
    Example:
      %s --file model-improvement-06-1.00.hd5
    ''' % (name,name,name)
    if printmsg:
        print(msg)
        exit(1)
    else:
        return msg

#-----------
def main():
    global args
    if len(sys.argv) == 1:
        usage(True)

    parser = argparse.ArgumentParser(usage=usage())
    parser.add_argument( "--file", required=True)
    args = parser.parse_args()

    model = km.load_model( args.file)

        # Convert for iOS CoreML
    coreml_model = coremltools.converters.tensorflow.convert( args.file,
                                                              #input_names=['image'],
                                                              #image_input_names='image',
                                                              class_labels = ['b', 'e', 'w'],
                                                              predicted_feature_name='bew'
                                                              #image_scale = 1/128.0,
                                                              #red_bias = -1,
                                                              #green_bias = -1,
                                                              #blue_bias = -1
    )
    # Convert for iOS CoreML
    coreml_model = coremltools.converters.keras.convert( model,
                                                         #input_names=['image'],
                                                         #image_input_names='image',
                                                         class_labels = ['b', 'e', 'w'],
                                                         predicted_feature_name='bew'
                                                         #image_scale = 1/128.0,
                                                         #red_bias = -1,
                                                         #green_bias = -1,
                                                         #blue_bias = -1
    )

    coreml_model.author = 'ahn'
    coreml_model.license = 'MIT'
    coreml_model.short_description = 'Classify go stones and intersections'
    #coreml_model.input_description['image'] = 'A 23x23 pixel Image'
    coreml_model.output_description['output1'] = 'A one-hot vector for classes black empty white'
    coreml_model.save('nn_bew.mlmodel')

    print( 'Output is in nn_bew.mlmodel')

if __name__ == '__main__':
    main()
