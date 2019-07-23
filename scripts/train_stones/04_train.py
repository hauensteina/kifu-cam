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

# Look for modules in our pylib folder
SCRIPTPATH = os.path.dirname(os.path.realpath(__file__))
sys.path.append( SCRIPTPATH + '/..')

import ahnutil as ut


import tensorflow as tf
from keras import backend as K
from keras.callbacks import ModelCheckpoint

num_cores = 4
GPU=1

if GPU:
    config = tf.ConfigProto()
    config.gpu_options.allow_growth = True
    session = tf.Session( config=config)
    K.set_session( session)
else:
    num_CPU = 1
    num_GPU = 0
    config = tf.ConfigProto( intra_op_parallelism_threads=num_cores,\
                             inter_op_parallelism_threads=num_cores, allow_soft_placement=True,\
                             device_count = {'CPU' : num_CPU, 'GPU' : num_GPU})
    session = tf.Session( config=config)
    K.set_session( session)

BATCH_SIZE=128
#BATCH_SIZE=32
args = None

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
      %s --resolution 23 --epochs 100 --rate 0
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

        x = kl.Conv2D( 4, (3,3), activation='relu', padding='same', name='one_a')(inputs)
        x = kl.BatchNormalization(axis=-1)(x) # -1 for tf back end, 1 for theano
        x = kl.MaxPooling2D()(x)
        x = kl.Conv2D( 8, (3,3), activation='relu', padding='same', name='one_b')(x)
        x = kl.BatchNormalization(axis=-1)(x)
        x = kl.MaxPooling2D()(x)

        x = kl.Conv2D( 16, (3,3), activation='relu', padding='same', name='two_a')(x)
        x = kl.BatchNormalization(axis=-1)(x)
        x = kl.Conv2D( 8, (1,1), activation='relu', padding='same', name='two_b')(x)
        x = kl.BatchNormalization(axis=-1)(x)
        x = kl.Conv2D( 16, (3,3), activation='relu', padding='same', name='two_c')(x)
        x = kl.BatchNormalization(axis=-1)(x)
        x = kl.MaxPooling2D()(x)

        x = kl.Conv2D( 32,(3,3), activation='relu', padding='same', name='three_a1')(x)
        x = kl.BatchNormalization(axis=-1)(x)
        x = kl.Conv2D( 16, (1,1), activation='relu', padding='same', name='three_b1')(x)
        x = kl.BatchNormalization(axis=-1)(x)
        x = kl.Conv2D( 32, (3,3), activation='relu', padding='same', name='three_c1')(x)
        x = kl.BatchNormalization(axis=-1)(x)
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

# Generate training batches on the fly
#===================================================================================================
class Generator:
    #--------------------------------------
    def __init__( self, data_directory):
        self.datadir = data_directory #  + '/all_files'
        # Data Augmentation
        self.gen = kp.ImageDataGenerator( rotation_range=5,
                                          width_shift_range=0.2,
                                          height_shift_range=0.2,
                                          horizontal_flip=True,
                                          vertical_flip=True,
                                          channel_shift_range=0.1)
                                          #channel_shift_range=0.2)
        self.get_one_batch_iter = self.gen.flow_from_directory( self.datadir,
                                                           target_size = (args.resolution, args.resolution),
                                                           class_mode  = None,
                                                           shuffle     = True,
                                                           batch_size  = BATCH_SIZE,
                                                           color_mode  = 'rgb',
                                                           save_to_dir = None)
        self.class_vectors = { 'B':np.array([1,0,0]), 'E':np.array([0,1,0]), 'W':np.array([0,0,1]) }


    #--------------------
    def nsamples( self):
        return len(self.get_one_batch_iter.filenames)

    #-----------------------
    def generate( self):
        while 1:
            batch = self.get_one_batch_iter.next()
            ut.dumb_normalize( batch)
            idx = self.get_one_batch_iter.batch_index - 1 # starts at 1
            #idxs = [ self.get_one_batch_iter.index_array[i] for i in range( idx*BATCH_SIZE, (idx+1)*BATCH_SIZE) ]
            idxs = [ self.get_one_batch_iter.index_array[i] for i in range( idx*BATCH_SIZE, idx*BATCH_SIZE + len(batch)) ]
            fnames = [ self.get_one_batch_iter.filenames[i] for i in idxs ]
            classes = [ os.path.split(fname)[-1][0] for fname in fnames ]
            labels = [ self.class_vectors[c] for c in classes ]
            if len(batch) != len(labels):
                BP()
                tt=42
            yield np.array(batch), np.array(labels)

#=======================================================================================================

#-----------
def main():
    global args
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


    train_generator = Generator( 'train')
    valid_generator = Generator( 'valid')
    STEPS_PER_EPOCH = int( train_generator.nsamples() / BATCH_SIZE)
    # checkpoint
    filepath="model-improvement-{epoch:02d}-{val_acc:.2f}.hd5"
    checkpoint = ModelCheckpoint( filepath, monitor='val_acc', verbose=1, save_best_only=True, save_weights_only=False, mode='max')
    callbacks_list = [checkpoint]

    model.model.fit_generator( train_generator.generate(),
                               steps_per_epoch=STEPS_PER_EPOCH, epochs=args.epochs,
                               validation_data = valid_generator.generate(),
                               validation_steps=int(STEPS_PER_EPOCH/10),
                               callbacks=callbacks_list)

    # Dump easiest, hardest, worst samples
    #classnum = {'B':0,'E':1,'W':2}
    #ut.dump_n_best_worst_folder( 10, model.model, 'valid', args.resolution, lambda fname: classnum[os.path.split(fname)[-1][0]] )

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
