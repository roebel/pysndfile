Changes
-------

Version_1.4.2 (2019-12-18)
~~~~~~~~~~~~~~~~~~~~~~~~~~

-  fixed PySndfile.read_frames method to properly handle reading frames
   in parts (previous fix was incomplete)

Version_1.4.1 (2019-12-18)
~~~~~~~~~~~~~~~~~~~~~~~~~~

-  extended supported commands to change compression level when writing
   flac and ogg files
-  fixed PySndfile.read_frames and sndio.read method to properly handle
   reading frames from the middle of a file

Version_1.4.0 (2019-12-17)
~~~~~~~~~~~~~~~~~~~~~~~~~~

-  Extended PySndfile class:

   -  support use as context manager
   -  added support for wve, ogg, MPC2000 sampler and RF64 wav files
   -  added support for forcing to return 2D arrays even for mono files
   -  added method to close the file and release all resources.
   -  support reading more frames than present in the file using the
      fill_value for all values positioned after the end of the file

Version_1.3.8 (2019-10-22)
~~~~~~~~~~~~~~~~~~~~~~~~~~

-  (no changes in functionality)
-  added documentation to distributed files
-  added missing licence file to distribution
-  thanks @toddrme2178 for patches.

Version_1.3.7 (2019-08-01)
~~~~~~~~~~~~~~~~~~~~~~~~~~

-  removed cython (a build requirement) from requirements.txt
-  avoid cython warning and fix language_level in the .pyx source code
-  add and support pre-release tags in the version number
-  use hashlib to calculate the README checksum.
-  fixed support for use with python 2.7 that was broken since 1.3.4

Version_1.3.6 (2019-07-27)
~~~~~~~~~~~~~~~~~~~~~~~~~~

-  fixed potential but undesired build dependency of pandoc
-  added link to explanation for using pysndfile under windows
-  fixed pandoc problem that does produce non ASCII chars in rst output.

Version_1.3.5 (2019-07-27)
~~~~~~~~~~~~~~~~~~~~~~~~~~

-  fixed two copy paste bug introduced in 1.3.4 1.3.4 did in fact not
   work at all :-(
-  added a check target to the makefile that performs a complete
   built/install/test cycle to avoid problems as in 1.3.4

Version_1.3.4 (2019-07-23)
~~~~~~~~~~~~~~~~~~~~~~~~~~

-  added support for automatic installation of requirements
-  remove precompiled cython source file and rely on pip requirements to
   provide cython so that cython compilation will always be possible.
-  added experimental support for installation on win32 (thanks to Svein
   Seldal for the contributions).
-  use expanduser for replacing ~ in filenames
-  adapted cython source code to avoid all compiler warnings due to
   deprecated numpy api
-  removed use of ez_setup.py that is no longer required.

Version_1.3.3 (2019-06-01)
~~~~~~~~~~~~~~~~~~~~~~~~~~

-  fixed missing command C_SFC_SET_SCALE_INT_FLOAT_WRITE (thanks to
   Svein Seldal for the bug report and fix)
-  better documentation of sf_string-io in sndio.read and sndio.write
-  limit size of strings to be written such that the written file can
   always be read back with libsndfile 1.0.28 (which imposes different
   constraints for different formats)
-  better error handling when number of channels exceeds channel limit
   imposed by libsndfile.
-  sndio module now exposes the dicts: fileformat_name_to_id and
   fileformat_id_to_name
-  extended sndio.read with force_2d argument that can be used to force
   the returned data array to always have 2 dimensions even for mono
   files.

Version_1.3.2 (2018-07-04)
~~~~~~~~~~~~~~~~~~~~~~~~~~

-  fixed documentation of sndio module.

Version_1.3.1 (2018-07-04)
~~~~~~~~~~~~~~~~~~~~~~~~~~

-  Extended sndio by means of adding a enw function that allows
   retrieving embed markers from sound files. Names marker labels will
   be retrieved only for aiff files.
-  removed print out in pysndfile.get_cue_mrks(self) function.
-  fixed version number in documentation.

Version_1.3.0 (2018-07-04)
~~~~~~~~~~~~~~~~~~~~~~~~~~

-  Added support for retrieving cue points from aiff and wav files.

Version_1.2.2 (2018-06-11)
~~~~~~~~~~~~~~~~~~~~~~~~~~

-  fixed c++-include file that was inadvertently scrambled.

Version_1.2.1 (2018-06-11)
~~~~~~~~~~~~~~~~~~~~~~~~~~

-  fixed formatting error in long description and README.
-  setup.py to explicitly select formatting of the long description.

Version_1.2.0 (2018-06-11)
~~~~~~~~~~~~~~~~~~~~~~~~~~

-  support reading and writing sound file strings in sndio module
-  Improved documentation of module constant mappings and PySndfile
   methods.
-  Added a new method supporting to write all strings in a dictionary to
   the sound file.

Version_1.1.1 (2018-06-10)
~~~~~~~~~~~~~~~~~~~~~~~~~~

this update is purely administrative, no code changes

-  moved project to IRCAM GitLab
-  moved doc to ReadTheDoc
-  fixed documentation.

Version_1.1.0 (2018-02-13)
~~~~~~~~~~~~~~~~~~~~~~~~~~

-  support returning extended sndfile info covering number of frames and
   number of channels from function sndio.get_info.

Version_1.0.0 (2017-07-26)
~~~~~~~~~~~~~~~~~~~~~~~~~~

-  Updated version number to 1.0.0:
-  pysndfile has now been used for quiet a while under python 3 and most
   problems seem to be fixed.
-  changed setup.py to avoid uploading outdated LONG_DESC file.

Version_0.2.15 (2017-07-26)
~~~~~~~~~~~~~~~~~~~~~~~~~~~

-  fixed get_sndfile_version function and tests script: adapted char
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
-  \_pysndfile.pyx: add constants SF_FORMAT_TYPEMASK and
   SF_FORMAT_SUBMASK, SF_FORMAT_ENDMASK to python interface Added new
   function for getting internal sf log in case of errors. Improved
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

-  setup.py: rebuild LONG_DESC only if sdist method is used.

Version 0.2.9
~~~~~~~~~~~~~

-  Added missing files to distribution.
-  force current cythonized version to be distributed.

Version 0.2.4
~~~~~~~~~~~~~

-  Compatibility with python 3 (thanks to Eduardo Moguillansky)
-  bug fix: ensure that vectors returned by read_frames function own
   their data.

