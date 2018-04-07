#!/usr/bin/env python

# /********************************************************************
# Filename: train.py
# Author: AHN
# Creation Date: Feb 16, 2018
# **********************************************************************/
#
# Build and train threeclasses model for Go board intersections (BEW)
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

num_cores = 4

GPU=1
if GPU:
    num_GPU = 1
    num_CPU = 1
else:
    num_CPU = 1
    num_GPU = 0

config = tf.ConfigProto(intra_op_parallelism_threads=num_cores,\
        inter_op_parallelism_threads=num_cores, allow_soft_placement=True,\
        device_count = {'CPU' : num_CPU, 'GPU' : num_GPU})
session = tf.Session(config=config)
K.set_session(session)


BATCH_SIZE=1024
#BATCH_SIZE=32

#---------------------------
def usage(printmsg=False):
    name = os.path.basename(__file__)
    msg = '''
    Name:
      %s --  Build and train three classes model for Go board intersections (BEW)
    Synopsis:
      %s --resolution <n> --epochs <n> --rate <learning_rate>
    Description:
      Build a NN model with Keras, train on the data in the train subfolder.
    Example:
      %s --resolution 23 --epochs 10 --rate 0.001
    ''' % (name,name,name)
    if printmsg:
        print(msg)
        exit(1)
    else:
        return msg

# A dense model
#===================================================================================================
class BEWModelDense:
    #------------------------------
    def __init__(self, resolution, rate=0):
        self.resolution = resolution
        self.rate = rate
        self.build_model()

    #-----------------------
    def build_model(self):
        nb_colors=3
        inputs = kl.Input( shape = ( self.resolution, self.resolution, nb_colors), name='image')
        x = kl.Flatten()(inputs)
        x = kl.Dense( 4, activation='relu')(x)
        x = kl.Dense( 4, activation='relu')(x)
        #x = kl.Dense( 4, activation='relu')(x)
        #x = kl.Dense( 4, activation='relu')(x)
        #x = kl.Dense( 16, activation='relu')(x)
        #x = kl.Dense(4, activation='relu')(x)
        output = kl.Dense( 3,activation='softmax', name='class')(x)
        self.model = km.Model(inputs=inputs, outputs=output)
        self.model.summary()
        if self.rate > 0:
            opt = kopt.Adam(self.rate)
        else:
            opt = kopt.Adam()
        #opt = kopt.Adam(0.001)
        #opt = kopt.SGD(lr=0.01)
        self.model.compile( loss='categorical_crossentropy', optimizer=opt, metrics=['accuracy'])
#===================================================================================================

# A convolutional model
#===================================================================================================
class BEWModelConv:
    #------------------------------
    def __init__(self, resolution, rate=0):
        self.resolution = resolution
        self.rate = rate
        self.build_model()

    #-----------------------
    def build_model(self):
        nb_colors=3
        inputs = kl.Input( shape = ( self.resolution, self.resolution, nb_colors), name = 'image')

        x = kl.Conv2D( 2, (3,3), activation='relu', padding='same', name='one_a')(inputs)
        x = kl.MaxPooling2D()(x)
        x = kl.Conv2D( 4, (3,3), activation='relu', padding='same', name='one_b')(x)
        x = kl.MaxPooling2D()(x)

        x = kl.Conv2D( 8, (3,3), activation='relu', padding='same', name='two_a')(x)
        x = kl.Conv2D( 4, (1,1), activation='relu', padding='same', name='two_b')(x)
        x = kl.Conv2D( 8, (3,3), activation='relu', padding='same', name='two_c')(x)
        x = kl.MaxPooling2D()(x)

        x = kl.Conv2D( 16,(3,3), activation='relu', padding='same', name='three_a1')(x)
        x = kl.Conv2D( 8, (1,1), activation='relu', padding='same', name='three_b1')(x)
        x = kl.Conv2D( 16, (3,3), activation='relu', padding='same', name='three_c1')(x)
        x = kl.MaxPooling2D()(x)

        # Classification block
        x_class_conv = kl.Conv2D( 3, (1,1), padding='same', name='lastconv')(x)
        x_class_pool = kl.GlobalAveragePooling2D()( x_class_conv)
        output = kl.Activation( 'softmax', name='class')(x_class_pool)

        self.model = km.Model( inputs=inputs, outputs=output)
        self.model.summary()
        if self.rate > 0:
            opt = kopt.Adam( self.rate)
        else:
            opt = kopt.Adam()
        #opt = kopt.Adam(0.001)
        #opt = kopt.SGD(lr=0.01)
        self.model.compile( loss='categorical_crossentropy', optimizer=opt, metrics=['accuracy'])
#===================================================================================================

# Get metadata from the image filenames
#-----------------------------------------
def get_meta_from_fnames( path):
    batches = ut.get_batches(path, shuffle=False, batch_size=1)
    train_batches = batches['train_batches']
    valid_batches = batches['valid_batches']

    train_classes=[]
    for idx,fname in enumerate(train_batches.filenames):
        if '/B_' in fname:
            train_classes.append(0)
        elif '/E_' in fname:
            train_classes.append(1)
        elif '/W_' in fname:
            train_classes.append(2)
        else:
            print( 'ERROR: Bad filename %s' % fname)
            exit(1)
    train_classes_hot = ut.onehot(train_classes)

    valid_classes=[]
    for idx,fname in enumerate(valid_batches.filenames):
        if '/B_' in fname:
            valid_classes.append(0)
        elif '/E_' in fname:
            valid_classes.append(1)
        elif '/W_' in fname:
            valid_classes.append(2)
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
    model = BEWModelConv( args.resolution, args.rate)
    #model = BEWModelDense( args.resolution, args.rate)
    wfname =  'nn_bew.weights'
    if os.path.exists( wfname):
        model.model.load_weights( wfname)

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
    model.model.fit(images['train_data'], meta['train_classes_hot'],
                    batch_size=BATCH_SIZE, epochs=args.epochs,
                    validation_data=(images['valid_data'], meta['valid_classes_hot']))
    ut.dump_n_best_and_worst( 10, model.model, images, meta, 'train')
    ut.dump_n_best_and_worst( 10, model.model, images, meta, 'valid')

    # Save weights and model
    if os.path.exists( wfname):
        shutil.move( wfname, wfname + '.bak')
    model.model.save( 'nn_bew.hd5')
    model.model.save_weights( wfname)

    # Convert for iOS CoreML
    coreml_model = coremltools.converters.keras.convert( model.model,
                                                         #input_names=['image'],
                                                         #image_input_names='image',
                                                         class_labels = ['b', 'e', 'w'],
                                                         predicted_feature_name='bew'
                                                         #image_scale = 1/128.0,
                                                         #red_bias = -1,
                                                         #green_bias = -1,
                                                         #blue_bias = -1
    );

    coreml_model.author = 'ahn'
    coreml_model.license = 'MIT'
    coreml_model.short_description = 'Classify go stones and intersections'
    #coreml_model.input_description['image'] = 'A 23x23 pixel Image'
    coreml_model.output_description['output1'] = 'A one-hot vector for classes black empty white'
    coreml_model.save("nn_bew.mlmodel")

if __name__ == '__main__':
    main()
