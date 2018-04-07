# /********************************************************************
# Filename: ahnutil.py
# Author: AHN
# Creation Date: Aug 27, 2017
# **********************************************************************/
#
# Various utility funcs
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

import keras.preprocessing.image as kp
import keras.activations as ka
import keras.metrics as kmet
import keras.models as kmod
import keras.losses as klo
from keras.utils.np_utils import to_categorical
import keras

from keras import backend as K

# Custom Softmax along axis 1 (channels).
# Use as an activation
#-----------------------------------------
def softMaxAxis1(x):
    return ka.softmax(x,axis=1)
# Make sure we can save and load a model with custom activation
ka.softMaxAxis1 = softMaxAxis1

# Custom metric returns 1.0 if all rounded elements
# in y_pred match y_true, else 0.0 .
#---------------------------------------------------------
def bool_match(y_true, y_pred):
    return K.switch(K.any(y_true-y_pred.round()), K.variable(0), K.variable(1))
# Make sure we can save and load a model with custom metric
kmet.bool_match = bool_match

# Custom metric returns the fraction of correctly set bits
# in y_pred vs y_true
#---------------------------------------------------------
def bitwise_match(y_true, y_pred):
    return 1.0 - K.mean(K.abs(y_true-y_pred.round()))
kmet.bitwise_match = bitwise_match

# Custom metric returns the fraction of correctly set elements
# in y_pred vs y_true
#-------------------------------------------------------------
def element_match(y_true, y_pred):
    return 1.0 - K.mean(K.abs(K.sign(y_true-K.round(y_pred))))
kmet.element_match = element_match


# Custom loss function to optimize element_match metric
# For some reason this is a bad idea and mse works better
#-------------------------------------------------------------
def element_loss(y_true, y_pred):
    return K.mean(K.abs(K.sign(y_true-K.round(y_pred))))
klo.element_loss = element_loss

# Custom loss.
# A simple crossentropy without checking anything.
# This works even if several prob vectors where flattened into one,
# like [[1,0],[1,0]] -> [1,0,1,0]
#--------------------------------------------------
def plogq(y_true, y_pred):
    res = -K.sum(y_true * K.log(K.clip(y_pred, K.epsilon(), 1.0 - K.epsilon() )))
    return res
klo.plogq = plogq


# Return iterators to get batches of images from a folder.
# Example:
'''
    batches = get_batches('data', batch_size=2)
    nextbatch = batches['train_batches'].next() # gets two random images
'''
# [[image1,image2],[class1,class2]]
# Classes are one-hot encoded.
# If class_mode==None, just return  [image1,image2,...]
# WARNING: The images must be in *subfolders* of  path/train and path/valid.
#----------------------------------------------------------------------------
def get_batches( path,
                 gen=kp.ImageDataGenerator(),
                 shuffle=True,
                 batch_size=4,
                 class_mode='categorical',
                 target_size=(224,224),
                 color_mode='grayscale',
                 save_to_dir=None):
    train_path = path + '/' + 'train'
    valid_path = path + '/' + 'valid'
    train_batches = gen.flow_from_directory( train_path,
                                             target_size = target_size,
                                             class_mode  = class_mode,
                                             shuffle     = shuffle,
                                             batch_size  = batch_size,
                                             color_mode  = color_mode,
                                             save_to_dir = save_to_dir)
    valid_batches = gen.flow_from_directory( valid_path,
                                             target_size = target_size,
                                             class_mode  = class_mode,
                                             shuffle     = shuffle,
                                             batch_size  = batch_size,
                                             color_mode  = color_mode,
                                             save_to_dir = save_to_dir)
    res = {'train_batches':train_batches, 'valid_batches':valid_batches}
    return res

# One-hot encode a list of integers
# (1,3,2) ->
# array([[ 0.,  1.,  0.,  0.],
#        [ 0.,  0.,  0.,  1.],
#        [ 0.,  0.,  1.,  0.]])
#-------------------------------------
def onehot(x,num_classes=None):
    return to_categorical(x,num_classes)


# Get means and stds by channel(color) from array of imgs
#----------------------------------------------------------
def get_means_and_stds(images):
    # Theano
    # mean_per_channel = images.mean( axis=(0,2,3), keepdims=1)
    # std_per_channel  = images.std( axis=(0,2,3), keepdims=1)
    # Tensorflow
    mean_per_channel = images.mean( axis=(0,1,2), keepdims=1)
    std_per_channel  = images.std( axis=(0,1,2), keepdims=1)
    return mean_per_channel, std_per_channel

# Subtract supplied mean from each channel, divide by sigma
#----------------------------------------------------------
def normalize(images, mean_per_channel, std_per_channel):
    images -= mean_per_channel
    images /= std_per_channel

# Subtract 128, divide by 128 to get to a [-1,1] interval
#----------------------------------------------------------
def dumb_normalize( images):
    images -= 128.0
    images /= 128.0


# Save a normalized image for inspection.
# Example: dsi( images['valid'][0], 'tt.jpg')
#------------------------------------------------------------------
def dsi( img_, fname):
    img = img_.astype(np.float32)
    img += 1.0; img /= 2.0 # denormalize from [-1,1] into [0,1]
    plt.figure(); plt.imshow(img); plt.savefig(fname) # render and save
    plt.close()

# Get all images below a folder into one huge numpy array
# WARNING: The images must be in *subfolders* of path/train and path/valid.
#---------------------------------------------------------------------------
def get_data( path, target_size=(224,224), color_mode='grayscale', gen=kp.ImageDataGenerator(), save_to_dir=None):
    batches = get_batches(path,
                          gen=gen,
                          shuffle=False,
                          batch_size=1,
                          class_mode=None,
                          target_size=target_size,
                          color_mode=color_mode,
                          save_to_dir=save_to_dir)

    train_data =  np.concatenate( [batches['train_batches'].next() for i in range(batches['train_batches'].samples)])
    valid_data =  np.concatenate( [batches['valid_batches'].next() for i in range(batches['valid_batches'].samples)])
    res = {'train_data':train_data.astype(float), 'valid_data':valid_data.astype(float)}
    return res

# Get arrays with meta info matching the order of the images
# returned by get_data().
# We take the class from a json file, not a folder name.
# Example:
# images = get_data(....)
# image = images['train'][42]
# meta =  get_meta(...)
# one_hot_class_for_image = meta['train_classes_hot'][42]
#----------------------------------------------------------
def get_meta(path):
    batches = get_batches(path, shuffle=False, batch_size=1)
    train_batches = batches['train_batches']
    valid_batches = batches['valid_batches']

    train_classes=[]
    for idx,fname in enumerate(train_batches.filenames):
        jf = path + '/train/' + os.path.splitext(fname)[0]+'.json'
        j  = json.load(open(jf, 'r'))
        train_classes.append(int(j['class']))
    train_classes_hot = onehot(train_classes)

    valid_classes=[]
    for idx,fname in enumerate(valid_batches.filenames):
        jf =  path + '/valid/' + os.path.splitext(fname)[0]+'.json'
        j = json.load(open(jf, 'r'))
        valid_classes.append(int(j['class']))
    valid_classes_hot = onehot(valid_classes)

    res = {
        'train_classes':train_classes,
        'train_classes_hot':train_classes_hot,
        'train_filenames':train_batches.filenames,
        'valid_classes':valid_classes,
        'valid_classes_hot':valid_classes_hot,
        'valid_filenames':valid_batches.filenames
    }
    return res

# Get arrays with expected output matching the order of the images
# returned by get_data().
# Returns the value found for key in each json file.
# Example:
# images = get_data(....)
# image = images['train'][42]
# meta =  get_output_by_key(...)
# meta_for_image = meta['train_output'][42]
#----------------------------------------------------------
def get_output_by_key(path,key):
    batches = get_batches(path, shuffle=False, batch_size=1)
    train_batches = batches['train_batches']
    valid_batches = batches['valid_batches']

    train_output=[]
    for idx,fname in enumerate(train_batches.filenames):
        jf = path + '/train/' + os.path.splitext(fname)[0]+'.json'
        j  = json.load(open(jf, 'r'))
        train_output.append(j[key])

    valid_output=[]
    for idx,fname in enumerate(valid_batches.filenames):
        jf =  path + '/valid/' + os.path.splitext(fname)[0]+'.json'
        j = json.load(open(jf, 'r'))
        valid_output.append(j[key])

    res = {
        'train_output':np.array(train_output),
        'train_filenames':train_batches.filenames,
        'valid_output':np.array(valid_output),
        'valid_filenames':valid_batches.filenames
    }
    return res

# Convert keras NN input into something you can feed to
# plt.imshow()
#------------------
def to_plot(img):
    if keras.backend.image_data_format() != 'channels_first':
        return np.rollaxis(img, 0, 1).astype(np.uint8)
    else:
        return np.rollaxis(img, 0, 3).astype(np.uint8)

# Feed one input to a model and return the result after some intermediate level
#----------------------------------------------------------------------------------
def get_output_of_layer( model, layer_name, input_data):
    intermediate_model = kmod.Model( inputs=model.input,
                                     outputs=model.get_layer(layer_name).output)
    res = intermediate_model.predict( [input_data], batch_size=1 )
    return res


# Dump jpegs of model conv layer channels to file
#---------------------------------------------------------------------
def visualize_channels( model, layer_name, channels, img_, fname):
    img = img_.copy()
    img *= 2.0; img -= 1.0 # normalize to [-1,1] before feeding to model
    img = img.reshape( (1,) + img.shape) # Add dummy batch dimension
    channel_data = get_output_of_layer( model, layer_name, img)[0]
    nplots = len( channels) + 1 # channels plus orig
    ncols = 1
    nrows = nplots // ncols
    plt.figure( edgecolor='k')
    fig = plt.gcf()
    scale = 6.0
    fig.set_size_inches( scale*ncols, scale*nrows)

    # Show input image
    plt.subplot( nrows,ncols,1)
    ax = plt.gca()
    ax.get_xaxis().set_visible( False)
    ax.get_yaxis().set_visible( False)
    plt.imshow( img_) #  cmap='Greys')

    # Show output channels
    for idx,channel in enumerate( channels):
        data = channel_data[:,:,channel]
        # Normalization unnecessary, done automagically
        #mmin = np.min(data)
        #data -= mmin
        #mmax = np.max(data)
        #data /= mmax
        dimg  = cv2.resize( data, (img_.shape[1], img_.shape[0]), interpolation = cv2.INTER_NEAREST)
        plt.subplot( nrows, ncols, idx+2)
        ax = plt.gca()
        ax.get_xaxis().set_visible( False)
        ax.get_yaxis().set_visible( False)
        plt.imshow( dimg, cmap='binary', alpha=1.0)

    plt.tight_layout()
    plt.savefig( fname)

# Get the n indexes who predicted the wrong class,
# sorted descending by confidence
# Example:
# n_worst_results( 10, preds, meta['valid_classes'])
#----------------------------------------------------
def n_worst_results( n, preds, true_classes):
    pred_classes = [np.argmax(x) for x in preds]
    pred_confidences = [np.max(x) for x in preds]
    bad_indexes = [idx for idx,c in enumerate(true_classes) if c != pred_classes[idx]]
    bad_true_classes = np.array(true_classes)[bad_indexes]
    bad_pred_classes = np.array(pred_classes)[bad_indexes]
    sorted_indexes = sorted( bad_indexes, key=lambda idx: -pred_confidences[idx])
    worst_preds = np.array(pred_classes)[sorted_indexes]
    return sorted_indexes[:n], worst_preds

# Get the n indexes who predicted the correct class,
# sorted descending by confidence
# Example:
# n_worst_results( 10, preds, meta['valid_classes'])
#----------------------------------------------------
def n_best_results( n, preds, true_classes):
    pred_classes = [np.argmax(x) for x in preds]
    pred_confidences = [np.max(x) for x in preds]
    good_indexes = [idx for idx,c in enumerate(true_classes) if c == pred_classes[idx]]
    good_true_classes = np.array(true_classes)[good_indexes]
    good_pred_classes = np.array(pred_classes)[good_indexes]
    sorted_indexes = sorted( good_indexes, key=lambda idx: -pred_confidences[idx])
    # The easiest ones and the hardest ones
    return (sorted_indexes[:n], sorted_indexes[-n:])


# Save best and worst images for inspection
#-----------------------------------------------------------------------
def dump_n_best_and_worst( n, model, images, meta, sset='valid'):
    preds = model.predict(images['%s_data' % sset], batch_size=8)
    worst_indexes, worst_preds = n_worst_results( n, preds, meta['%s_classes' % sset])
    easiest_indexes, hardest_indexes = n_best_results( n, preds, meta['%s_classes' % sset])

    for i,idx in enumerate( worst_indexes):
        dsi( images['%s_data' % sset][idx],
             'worst_%s_%02d_%d' % (sset,i,worst_preds[i]) + os.path.basename( meta['%s_filenames' % sset][idx]))

    for i,idx in enumerate( easiest_indexes):
        dsi( images['%s_data' % sset][idx],
             'easiest_%s_%02d_' % (sset,i) + os.path.basename( meta['%s_filenames' % sset][idx]))

    for i,idx in enumerate( hardest_indexes):
        dsi( images['%s_data' % sset][idx],
             'hardest_%s_%02d_' % (sset,i) + os.path.basename( meta['%s_filenames' % sset][idx]))


# Randomly split the jpg files in a folder into
# train, valid, test
#-------------------------------------------------
def split_files( folder, trainpct, validpct, substr=''):
    files = glob.glob( folder + '/*.jpg')
    files = [os.path.basename(f) for f in files];
    files = [f for f in files if substr in f];
    random.shuffle( files)
    ntrain = int( round( len( files) * (trainpct / 100.0)))
    nvalid = int( round( len( files) * (validpct / 100.0)))
    trainfiles = files[:ntrain]
    validfiles = files[ntrain:ntrain+nvalid]
    testfiles  = files[ntrain+nvalid:]

    os.makedirs( 'test/all_files')
    os.makedirs( 'train/all_files')
    os.makedirs( 'valid/all_files')

    for f in trainfiles:
        shutil.copy2( folder + '/' + f, 'train/all_files/' + f)
    for f in validfiles:
        shutil.copy2( folder + '/' + f, 'valid/all_files/' + f)
    for f in testfiles:
        shutil.copy2( folder + '/' + f, 'test/all_files/' + f)

# Return list of files matching filterstr
# Example: fing( '/tmp', '*.jpg')
#-------------------------------------------
def find( folder, filterstr):
    matches = []
    for root, dirnames, filenames in os.walk( folder):
        for filename in fnmatch.filter( filenames, filterstr):
            matches.append( os.path.join( root, filename))
    return matches
