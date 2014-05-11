#PySndfile#

This project provides a python extension to libsndfile [http://www.mega-nerd.com/libsndfile/](http://www.mega-nerd.com/libsndfile/). The extension is written in cython.
The goal of this extension is to be able use libsndfile to read and write sound files from within python. 

pysndfile has been created because reading of various sound file formats into python is not very well supported as soon as the sound file does not contain aifc or wav format. Due to the use of libsndfile nearly all sound file formats, (besides the nonfree compression formats) can be read and written with pysndfile.

The interface has been designed such that a maximum of functionality of libsndfile can be used, notably the reading and writing of strings, and a number of sf_commands. One of the most important ones is the use of the clipping command.
The use of the  clipping command is essential when reading and writing sound data should not change the audio samples.
By default libsndfile uses slightly different scaling factors when reading pcm format into float samples, or when writing float samples into pcm format. Therefore whenever a complete read/write cycle is applied to a sound file, and if the sound files contains pcm format and the data is read into float or double and the audio data comes close to the maximum range, then the audio samples are modified even when no processing is applied. pysndfile sets clipping by default to on. If you don't like this you can set it to off individually for each sound file using the set_auto_clipping(False) function.

The implementation is based on a slightly modified version of the header sndfile.hh that is distributed with libsndfile. The only modification is the addition of a methode querying the seekable state of the open Sndfile.

###Credits:###

Erik de Castro Lopo: for libsndfile [http://www.mega-nerd.com/libsndfile/](http://www.mega-nerd.com/libsndfile/)

David Cournapeau: for a few ideas I gathered from scikits.audiolab [http://cournape.github.io/audiolab/](http://cournape.github.io/audiolab/).
