#PySndfile#

This project provides a python extension to libsndfile [http://www.mega-nerd.com/libsndfile/](http://www.mega-nerd.com/libsndfile/). 

The goal of this extension is to be able use libsndfile to read and write sound files from within python. 

pysndfile has been created because reading of various sound file formats into python is not very well supported as soon as the sound file does not contain aifc or wav format. scikits.audiolab (see below) seems to be the only other extension that exists by today.

In contrast to scikits.audiolab pysndfile has restricted scope as it does not support playing and recording of sound. The focus is here exclusively on reading and writing sndfiles using libsndfile. 

Due to the use of libsndfile nearly all sound file formats can be handled with pysndfile.

The implementation is based on a slightly modified version of the header sndfile.hh that is distributed with libsndfile. The only modification is the addition of a methode querying the seekable state of the open Sndfile.

###Credits:###

Erik de Castro Lopo: for libsndfile [http://www.mega-nerd.com/libsndfile/](http://www.mega-nerd.com/libsndfile/)

David Cournapeau: for a few ideas I gathered from scikits.audiolab [http://cournape.github.io/audiolab/](http://cournape.github.io/audiolab/).
