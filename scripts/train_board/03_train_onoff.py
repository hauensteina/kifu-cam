#!/usr/bin/env python

# /********************************************************************
# Filename: train_onoff.py
# Author: AHN
# Creation Date: Mar 5, 2018
# **********************************************************************/
#
# Build and train model to distinguis on and off board (I=In, O=Off)
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

import matplotlib as mpl
mpl.use('Agg') # This makes matplotlib work without a display
from matplotlib import pyplot as plt

# Look for modules in our pylib folder
SCRIPTPATH = os.path.dirname(os.path.realpath(__file__))
sys.path.append( SCRIPTPATH + '/..')

import ahnutil as ut
from IOModelConv import IOModelConv


import tensorflow as tf
from tensorflow.keras import backend as K

# Limit GPU memory usage to 5GB
gpus = tf.config.experimental.list_physical_devices('GPU')
tf.config.experimental.set_virtual_device_configuration(
    gpus[0],
    [tf.config.experimental.VirtualDeviceConfiguration(memory_limit=5*1024)])

BATCH_SIZE=128

#---------------------------
def usage(printmsg=False):
    name = os.path.basename(__file__)
    msg = '''
    Name:
      %s --  Build and train two class model to tell inner board intersections from edge board intersections.
    Synopsis:
      %s --resolution <n> --epochs <n> --rate <learning_rate>
    Description:
      Build a NN model with Keras, train on the data in the train subfolder.
      Intersection crops are taken *before* zoom in, but after dewarp with phi and theta.
    Example:
      %s --resolution 23 --epochs 10 --rate 0.001
    ''' % (name,name,name)
    if printmsg:
        print(msg)
        exit(1)
    else:
        return msg


# Get metadata from the image filenames
#-----------------------------------------
def get_meta_from_fnames( path):
    batches = ut.get_batches(path, shuffle=False, batch_size=1)
    train_batches = batches['train_batches']
    valid_batches = batches['valid_batches']

    train_classes=[]
    for idx,fname in enumerate(train_batches.filenames):
        if '/I_' in fname:
            train_classes.append(0)
        elif '/O_' in fname:
            train_classes.append(1)
        else:
            print( 'ERROR: Bad filename %s' % fname)
            exit(1)
    train_classes_hot = ut.onehot(train_classes)

    valid_classes=[]
    for idx,fname in enumerate(valid_batches.filenames):
        if '/I_' in fname:
            valid_classes.append(0)
        elif '/O_' in fname:
            valid_classes.append(1)
        else:
            print( 'ERROR: Bad filename %s' % fname)
            exit(1)
    valid_classes_hot = ut.onehot(valid_classes)

    res = {
        'train_classes':train_classes,
        'train_classes_hot':train_classes_hot,
        'train_filenames':train_batches.filenames,
        'valid_classes':valid_classes,
        'valid_classes_hot':valid_classes_hot,
        'valid_filenames':valid_batches.filenames
    }
    return res


#-----------
def main():
    if len(sys.argv) == 1:
        usage(True)

    parser = argparse.ArgumentParser(usage=usage())
    parser.add_argument( "--resolution", required=True, type=int)
    parser.add_argument( "--epochs", required=True, type=int)
    parser.add_argument( "--rate", required=True, type=float)
    args = parser.parse_args()

    # Model
    model = IOModelConv( width=args.resolution, height=args.resolution, rate=args.rate, classify=True)
    modelfname = 'nn_io.h5'
    if os.path.exists( modelfname):
        model.model = km.load_model( modelfname)

    # Data Augmentation
    gen=kp.ImageDataGenerator( rotation_range=5,
                               width_shift_range=0.2,
                               height_shift_range=0.2,
                               horizontal_flip=True,
                               vertical_flip=True,
                               channel_shift_range=0.2)

    # Images
    save_to_dir='augmented_samples'
    if not os.path.exists( save_to_dir): save_to_dir = None
    images = ut.get_data( SCRIPTPATH, (args.resolution,args.resolution), color_mode='rgb', gen=gen, save_to_dir=save_to_dir)
    meta   = get_meta_from_fnames( SCRIPTPATH)
    ut.dumb_normalize( images['train_data'])
    ut.dumb_normalize( images['valid_data'])

    # Train
    model.model.fit( images['train_data'], meta['train_classes_hot'],
                     batch_size=BATCH_SIZE, epochs=args.epochs,
                     validation_data=(images['valid_data'], meta['valid_classes_hot']))
    ut.dump_n_best_and_worst( 5, model.model, images, meta, 'train')
    ut.dump_n_best_and_worst( 5, model.model, images, meta, 'valid')

    # Save weights and model
    if os.path.exists( modelfname):
        try:
            shutil.rmtree( modelfname + '.bak')
            shutil.move( modelfname, modelfname + '.bak')
        except:
            pass
    model.model.save( modelfname, save_format='h5')

    # Convert convolutional layers for iOS CoreML
    #model = IOModelConv( width=350, height=466, classify=False)
    #model.model.load_weights( wfname, by_name=True)
    #coreml_model = coremltools.converters.keras.convert( model.model)
    classmodel = km.load_model( modelfname)
    model = IOModelConv( width=350, height=466, classify=False)
    model.model.set_weights( classmodel.get_weights())
    convname = 'nn_io_conv_only.h5'
    model.model.save( convname, save_format='h5')

    coreml_model = coremltools.converters.tensorflow.convert( convname,
                                                              #input_names=['image'],
                                                              #image_input_names='image',
                                                              #class_labels = ['b', 'e', 'w'],
                                                              #predicted_feature_name='bew'
                                                              #image_scale = 1/128.0,
                                                              #red_bias = -1,
                                                              #green_bias = -1,
                                                              #blue_bias = -1
    )
    coreml_model.author = 'ahn'
    coreml_model.license = 'MIT'
    coreml_model.short_description = 'Boardness feature'
    #coreml_model.input_description['image'] = 'A 23x23 pixel Image'
    #coreml_model.output_description['output1'] = 'A feature map for boardness'
    coreml_model.save("nn_io.mlmodel")

if __name__ == '__main__':
    main()
