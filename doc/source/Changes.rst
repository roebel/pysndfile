Changes
-------

Version\_1.3.3 (2019-06-01)
~~~~~~~~~~~~~~~~~~~~~~~~~~~

-  fixed missing command C\_SFC\_SET\_SCALE\_INT\_FLOAT\_WRITE (thanks
   to Svein Seldal for the bug report and fix)
-  better documentation of sf\_string-io in sndio.read and sndio.write
-  limit size of strings to be written such that the written file can
   always be read back with libsndfile 1.0.28 (which imposes different
   constraints for different formats)
-  better error handling when number of channels exceeds channel limit
   imposed by libsndfile.
-  sndio module now exposes the dicts: fileformat\_name\_to\_id and
   fileformat\_id\_to\_name
-  extended sndio.read with force\_2d argument that can be used to force
   the returned data array to always have 2 dimensions even for mono
   files.

Version\_1.3.2 (2018-07-04)
~~~~~~~~~~~~~~~~~~~~~~~~~~~

-  fixed documentation of sndio module.

Version\_1.3.1 (2018-07-04)
~~~~~~~~~~~~~~~~~~~~~~~~~~~

-  Extended sndio by means of adding a enw function that allows
   retrieving embed markers from sound files. Names marker labels will
   be retrieved only for aiff files.
-  removed print out in pysndfile.get\_cue\_mrks(self) function.
-  fixed version number in documentation.

Version\_1.3.0 (2018-07-04)
~~~~~~~~~~~~~~~~~~~~~~~~~~~

-  Added support for retrieving cue points from aiff and wav files.

Version\_1.2.2 (2018-06-11)
~~~~~~~~~~~~~~~~~~~~~~~~~~~

-  fixed c++-include file that was inadvertently scrambled.

Version\_1.2.1 (2018-06-11)
~~~~~~~~~~~~~~~~~~~~~~~~~~~

-  fixed formatting error in long description and README.
-  setup.py to explicitly select formatting of the long description.

Version\_1.2.0 (2018-06-11)
~~~~~~~~~~~~~~~~~~~~~~~~~~~

-  support reading and writing sound file strings in sndio module
-  Improved documentation of module constant mappings and PySndfile
   methods.
-  Added a new method supporting to write all strings in a dictionary to
   the sound file.

Version\_1.1.1 (2018-06-10)
~~~~~~~~~~~~~~~~~~~~~~~~~~~

this update is purely administrative, no code changes

-  moved project to IRCAM GitLab
-  moved doc to ReadTheDoc
-  fixed documentation.

Version\_1.1.0 (2018-02-13)
~~~~~~~~~~~~~~~~~~~~~~~~~~~

-  support returning extended sndfile info covering number of frames and
   number of channels from function sndio.get\_info.

Version\_1.0.0 (2017-07-26)
~~~~~~~~~~~~~~~~~~~~~~~~~~~

-  Updated version number to 1.0.0:
-  pysndfile has now been used for quiet a while under python 3 and most
   problems seem to be fixed.
-  changed setup.py to avoid uploading outdated LONG\_DESC file.

Version\_0.2.15 (2017-07-26)
~~~~~~~~~~~~~~~~~~~~~~~~~~~~

-  fixed get\_sndfile\_version function and tests script: adapted char
   handling to be compatible with python 3.

Version 0.2.14 (2017-07-26)
~~~~~~~~~~~~~~~~~~~~~~~~~~~

-  fixed filename display in warning messages due to invalid pointer:
   replaced char\* by std::string

Version 0.2.13 (2017-06-03)
~~~~~~~~~~~~~~~~~~~~~~~~~~~

-  fixed using "~" for representing $HOME in filenames:
-  \_pysndfile.pyx: replaced using cython getenv by os.environ to avoid
   type incompatibilities in python3

Version 0.2.12 (2017-05-11)
~~~~~~~~~~~~~~~~~~~~~~~~~~~

-  fixed problem in sndio.read: Optionally return full information
   required to store the file using the corresponding write function
-  \_pysndfile.pyx: add constants SF\_FORMAT\_TYPEMASK and
   SF\_FORMAT\_SUBMASK, SF\_FORMAT\_ENDMASK to python interface Added
   new function for getting internal sf log in case of errors. Improved
   consistency of variable definitions by means of retrieving them
   automatically from sndfile.h

Version 0.2.11 (2015-05-17)
~~~~~~~~~~~~~~~~~~~~~~~~~~~

-  setup.py: fixed problem with compilers not providing the compiler
   attribute (MSVC) (Thanks to Felix Hanke for reporting the problem)
-  \_pysndfile.pyx: fixed problem when deriving from PySndfile using a
   modified list of **init** parameters in the derived class (Thanks to
   Sam Perry for the suggestion).

Version 0.2.10
~~~~~~~~~~~~~~

-  setup.py: rebuild LONG\_DESC only if sdist method is used.

Version 0.2.9
~~~~~~~~~~~~~

-  Added missing files to distribution.
-  force current cythonized version to be distributed.

Version 0.2.4
~~~~~~~~~~~~~

-  Compatibility with python 3 (thanks to Eduardo Moguillansky)
-  bug fix: ensure that vectors returned by read\_frames function own
   their data.

