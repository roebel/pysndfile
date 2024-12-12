pysndfile intro
===================

pysndfile is a python package providing *PySndfile*, a
`Cython <http://cython.org/>`__ wrapper class around
`libsndfile <http://www.mega-nerd.com/libsndfile/>`__. PySndfile
provides methods for reading and writing a large variety of soundfile
formats on a variety of plattforms. PySndfile provides a rather complete
access to the different sound file manipulation options that are
available in libsndfile.

Due to the use of libsndfile nearly all sound file formats, (besides mp3
and derived formats) can be read and written with PySndfile.

The interface has been designed such that a rather large subset of the
functionality of libsndfile can be used, notably the reading and writing
of strings into soundfile formats that support these, and a number of
sf_commands that allow to control the way libsndfile reads and writes
the samples. One of the most important ones is the use of the clipping
command.

Transparent soundfile io with libsndfile
----------------------------------------

PySndfile has been developed in the `analysis synthesis team at
IRCAM <http://anasynth.ircam.fr/home/english>`__ mainly for research on
sound analysis and sound transformation. In this context it is essential
that the reading and writing of soundfile data is transparent.

The use of the clipping mode of libsndfile is important here because
reading and writing sound data should not change the audio samples. By
default, when clipping is off, libsndfile uses slightly different
scaling factors when reading pcm format into float samples, or when
writing float samples into pcm format. Therefore whenever a complete
read/write cycle is applied to a sound file then the audio samples may
be modified even when no processing is applied.

More precisely this will happen if

-  the sound files contains pcm format,
-  *and* the data is read into float or double,
-  *and* the audio data comes close to the maximum range such that the
   difference in scaling leads to modification.

To avoid this problem PySndfile sets clipping by default to on. If you
don't like this you can set it to off individually using the PySndfile
method set_auto_clipping(False).

Implementation
--------------

The implementation is based on a slightly modified version of the header
sndfile.hh that is distributed with libsndfile. The only modification is
the addition of a methode querying the seekable state of the open
Sndfile.

Installation
------------

via Anaconda channel roebel
~~~~~~~~~~~~~~~~~~~~~~~~~~~

Precompiled packages are available for `Anaconda
python3 <https://anaconda.org/roebel/pysndfile>`__ under Linux (x86_64)
and Mac OS X (> 10.9). For these systems you can install pysndfile
simply by means of

.. code:: bash

   conda install -c roebel pysndfile

Unfortunately, I don't have a windows machine and therefore I cannot
provide any packages for Windows.

compile with conda build recipe
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

You can use the conda recipe
`here <https://github.com/roebel/conda_packages>`__. This build recipe
wil automatically download and compile libsndfile building pysndfile.

via pypi
~~~~~~~~

::

   pip install pysndfile

should install pysndfile and python dependencies. Note, that pip cannot
install libsndfile for you as it is not provided via pypi. To install
libsndfile you should be able to use the software manager of your
system. This will however only work if your software manager installs
libsndfile such that the compiler used by the setup.py script will find
it. The setup.py script will search for the dynamic library libsndfile,
as well as the include file sndfile.h, in a few standard locations,
(/usr, /usr/local, and for anaconda envrinments as well in the
exec_prefix directory of the python executable you are using). If
libsndfile is not found you may either adapt the setup.cfg file or set
the environment variable SNDFILE_INSTALL_DIR, to inform the build_ext
sub command about the location to use.

compile from sources
~~~~~~~~~~~~~~~~~~~~

Note that for compiling from sources you need to install requirements
listed in requirements.txt file before starting the compilation.
Moreover you need to install libsndfile as described in the previous
section.

If the libsndfile (header and library) is not installed in the default
compiler search path you have to specify the library and include
directories to be added to this search paths. For this you can either
set the environment variable SNDFILE_INSTALL_DIR to the installation
path or specify sndfile_libdir and sndfile_incdir in the setup.cfg file.

self-contained extension
~~~~~~~~~~~~~~~~~~~~~~~~

Both when installing from pypi or building a wheel from source (or
sdist) the extension will need the libsndfile shared library, which must
be available at runtime.

Since version 1.4.7, it is possible to integrate libsndfile into the
extension, removing this requirement. This will greatly increase the
size of the extension, but can be useful to avoid conflicts between
different libsndfile versions or to build a self-contained wheel.

To do this, the installed libsndfile must include static libraries for
itself and its dependencies. Then define the PYSNDFILE_USE_STATIC
environment variable (either without a value or to anything except 0)
before installing or building as usual. The dependencies will be
searched using pkg-config if available, or by looking for possible
dependencies in the same directory as libsndfile itself.

In some installations of libsndfile though, the pkg-config information
is incorrect (usually a missing or misspelled dependency), which will
lead to an error when building/installing or importing. In this case,
also define the PYSNDFILE_IGNORE_PKG_CONFIG environment variable and
build/install again.

Windows
^^^^^^^

An experimental support for using pysndfile under windows has been added
since version 1.3.4. For further comments see
`here <https://github.com/roebel/pysndfile/issues/3>`__ as well as
`build
scripts <https://gist.github.com/sveinse/97411b95d36a6b8c430d4d381b620ecb>`__
provided by sveinse. Note, that I do not have any windows machine and
cannot provide any help in making this work.

Documentation
-------------

Please see the developer documentation
`here <https://pysndfile.readthedocs.io/en/latest/modules.html>`__.

