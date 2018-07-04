# pysndfile

pysndfile is a python package providing *PySndfile*, a [Cython](http://cython.org/) wrapper class around [libsndfile](http://www.mega-nerd.com/libsndfile/). PySndfile provides methods for reading and writing a large variety of soundfile formats on a variety of plattforms. PySndfile provides a rather complete access to the different sound file manipulation options that are available in libsndfile.

Due to the use of libsndfile nearly all sound file formats, (besides mp3 and derived formats) can be read and written with PySndfile.

The interface has been designed such that a rather large subset of the functionality of libsndfile can be used, notably the reading and writing of strings into soundfile formats that support these, and a number of sf_commands that allow to control the way libsndfile reads and writes the samples. One of the most important ones is the use of the clipping command.

## Transparent soundfile io with libsndfile

PySndfile has been developed in the  [analysis synthesis team at IRCAM](http://anasynth.ircam.fr/home/english) mainly for research on sound analysis and sound transformation. In this context it is essential that the reading and writing of soundfile data is transparent. 

The use of the clipping mode of libsndfile is important here because  reading and writing sound data should not change the audio samples. By default, when clipping is off, libsndfile uses slightly different scaling factors when reading pcm format into float samples, or when writing float samples into pcm format. Therefore whenever a complete read/write cycle is applied to a sound file then the audio samples may be modified even when no processing is applied. 

More precisely this will happen if 

 * the sound files contains pcm format, 
 * *and* the data is read into float or double,
 * *and* the audio data comes close to the maximum range such that the difference in scaling leads to modification.

To avoid this problem PySndfile sets clipping by default to on. If you don't like this you can set it to off individually using the PySndfile method set_auto_clipping(False).

## Implementation

The implementation is based on a slightly modified version of the header sndfile.hh that is distributed with libsndfile. The only modification is the addition of a methode querying the seekable state of the open Sndfile.

## Installation

### via Anaconda channel roebel

Precompiled packages are available for [Anaconda python3](https://anaconda.org/roebel/pysndfile) under
Linux (x86_64) and Mac OS X (> 10.9). For these systems you can install pysndfile
simply by means of

```bash
conda install -c roebel pysndfile
```

Unfortunately, I don't have a windows machine and therefore I cannot provide any packages for 
Windows.

### compile with conda build recipe

You can use the conda recipe [here](https://github.com/roebel/conda_packages).
This build recipe wil automatically download and compile libsndfile building pysndfile. 

### compile from sources

In case you want to manually compile
pysndfile requires availability of libsndfile [http://www.mega-nerd.com/libsndfile/](http://www.mega-nerd.com/libsndfile/).

If the libsndfile (header and library) is not installed in the default compiler search path you have to
specify the library and include directories to be added to this search paths. For this you can use either the
command line options --sndfile-libdir and --sndfile-incdir that are available for the build_ext command
or specify these two parameters in the setup.cfg file.

Besides this the setup is pretty standard. Note, that the cython source _pysndfile.pyx will be compiled with cython only if cython is installed.


## Documentation

Please see full documentation [here](https://pysndfile.readthedocs.io/)

## Changes

### Version_1.3.0 (2018-07-04)

 * Added support for retrieving cue points from aiff and wav files.

### Version_1.2.2 (2018-06-11)

 * fixed c++-include file that was inadvertently scrambled.

### Version_1.2.1 (2018-06-11)

 * fixed formatting error in long description and README.
 * setup.py to explicitly select formatting of the long description.
 
### Version_1.2.0 (2018-06-11)

 * support reading and writing sound file strings in sndio module
 * Improved documentation of module constant mappings and PySndfile methods.
 * Added a new method supporting to write all strings in a dictionary to the sound file.

### Version_1.1.1 (2018-06-10)

this update is purely administrative, no code changes
 
 * moved project to IRCAM GitLab
 * moved doc to ReadTheDoc
 * fixed documentation.

### Version_1.1.0 (2018-02-13)

 * support returning extended sndfile info covering number of frames and number of channels 
   from function sndio.get_info.
 
### Version_1.0.0 (2017-07-26)

 * Updated version number to 1.0.0:
  - pysndfile has now been used for quiet a while under python 3 and most problems seem to be fixed.
  - changed setup.py to avoid uploading outdated LONG_DESC file.
  
### Version_0.2.15 (2017-07-26)

 * fixed get_sndfile_version function and tests script:
	adapted char handling to be compatible with python 3.

### Version 0.2.14 (2017-07-26)

 * fixed filename display in warning messages due to invalid pointer:
    replaced char* by std::string

### Version 0.2.13 (2017-06-03) 

 * fixed using "~" for representing $HOME in filenames:
 * _pysndfile.pyx: replaced using cython getenv by os.environ to avoid
    type incompatibilities in python3 

### Version 0.2.12 (2017-05-11) 

 * fixed problem in sndio.read:
  Optionally return full information required to store the file using the corresponding write function
 * _pysndfile.pyx:
  add constants SF_FORMAT_TYPEMASK and SF_FORMAT_SUBMASK, SF_FORMAT_ENDMASK to python interface
  Added new function for getting internal sf log in case of errors.
  Improved consistency of variable definitions by means of retrieving them automatically from sndfile.h

### Version 0.2.11 (2015-05-17) 
    
 * setup.py: fixed problem with compilers not providing the compiler attribute (MSVC) (Thanks to Felix Hanke for reporting the problem)
 * _pysndfile.pyx: fixed problem when deriving from PySndfile using a modified list of __init__ parameters in the derived class
     (Thanks to Sam Perry for the suggestion).

### Version 0.2.10

 * setup.py: rebuild LONG_DESC only if sdist method is used.

### Version 0.2.9 

 * Added missing files to distribution.
 * force current cythonized version to be distributed.

### Version 0.2.4 
 
 * Compatibility with python 3 (thanks to Eduardo Moguillansky)
 * bug fix: ensure that vectors returned by read_frames function own their data.

## Copyright

Copyright (C) 2014-2018 IRCAM

## Author

Axel Roebel

## Credits

 * Erik de Castro Lopo: for [libsndfile](http://www.mega-nerd.com/libsndfile/)
 * David Cournapeau: for a few ideas I gathered from [scikits.audiolab](http://cournape.github.io/audiolab/).
 * The [Cython](http://cython.org) maintainers for the efficient means to write interface definitions in Cython.
