#! /usr/bin/env python
from __future__ import print_function

import os
import shutil
import subprocess
import re
import numpy as np

from setuptools import setup
from distutils.core import Extension
from distutils.command.build_ext import build_ext
from distutils.command.sdist import sdist 

import os
import sys

try : 
    pp=[pd for pd in sys.path if not os.path.exists(pd) or not os.path.samefile(pd , ".")]
    sys.path=pp
except Exception:
    pass


compile_for_RTD =  "READTHEDOCS" in os.environ

if compile_for_RTD:
    ext_modules = [Extension("_pysndfile", ["_pysndfile.pyx"],
                             define_macros=[('READTHEDOCS_ENV', '1'), ("NPY_NO_DEPRECATED_API", "NPY_1_13_API_VERSION")],
                             include_dirs = [np.get_include()],
                             language="c++")]
else:
    ext_modules = [Extension("_pysndfile", ["_pysndfile.pyx"],
                             libraries = ["sndfile"],
                             include_dirs = [np.get_include()],
                             language="c++",
                             define_macros = [("NPY_NO_DEPRECATED_API", "NPY_1_13_API_VERSION") ] )]

try :
    from Cython.Build import cythonize
    ext_modules = cythonize(ext_modules, force=compile_for_RTD )
except ImportError  :
    print("cannot import cythonize - to be able to cythonize the source please install cython")
    sys.exit(1)

# check clang compiler and disable warning
def compiler_is_clang(comp) :
    print("check for clang compiler ... ", end="")
    try:
        cc_output = subprocess.check_output(comp+['--version'],
                                            stderr = subprocess.STDOUT, shell=False)
    except OSError as ex:
        print("compiler test call failed with error {0:d} msg: {1}".format(ex.errno, ex.strerror))
        print("no")
        return False

    ret = re.search(b"clang", cc_output) is not None
    if ret :
        print("yes")
    else:
        print("no")
    return ret

class sdist_subclass(sdist) :
    def run(self):
        # Make sure the compiled Cython files in the distribution are up-to-date
        from Cython.Build import cythonize
        update_long_descr()
        cythonize(['_pysndfile.pyx'])
        shutil.move("setup.cfg", "setup.cfg.default")
        shutil.copy2("setup.cfg.dist", "setup.cfg")
        shutil.copy2("_pysndfile.cpp", "_pysndfile_precythonized.cpp")
        sdist.run(self)
        shutil.move("setup.cfg.default", "setup.cfg")

# sub class build_ext to handle build options for specification of libsndfile
class build_ext_subclass( build_ext ):
    user_options = build_ext.user_options + [
        ("sndfile-libdir=", None, "libdir for libsndfile"),
        ("sndfile-incdir=", None, "include for libsndfile")
        ]
    fcompiler = None
    sndfile_incdir = None
    sndfile_libdir = None
        
    def initialize_options(self) :
        build_ext.initialize_options(self)

    def finalize_options(self) :
        build_ext.finalize_options(self)
        if not compile_for_RTD:
            if self.sndfile_libdir  is not None :
                self.library_dirs.append(self.sndfile_libdir)
                self.rpath.append(self.sndfile_libdir)
            if self.sndfile_incdir  is not None :
                    self.include_dirs.append(self.sndfile_incdir)
                
    def build_extensions(self):
        #c = self.compiler.compiler_type
        #print("compiler attr", self.compiler.__dict__)
        #print("compiler", self.compiler.compiler)
        #print("compiler is",c)
        try :
            if compiler_is_clang(self.compiler.compiler):
                for e in self.extensions:
                    #e.extra_compile_args.append('-stdlib=libc++')
                    #e.extra_compile_args.append('-mmacosx-version-min=10.9')
                    e.extra_compile_args.append('-Wno-unused-function')
        except AttributeError :
            pass

        build_ext.build_extensions(self)

# get _pysndfile version number
for line in open("_pysndfile.pyx") :
    if "_pysndfile_version=" in line:
        _pysndfile_version_str = re.split('[()]', line)[1].replace(',','.')
        break

# Utility function to read the README file.
# Used for the long_description.  It's nice, because now 1) we have a top level
# README file and 2) it's easier to type in the README file than to put a raw
# string in below ...
def update_long_descr():
    README_path     = os.path.join(os.path.dirname(__file__), 'README.md')
    LONG_DESCR_path = os.path.join(os.path.dirname(__file__), 'LONG_DESCR')
    if ((not os.path.exists(LONG_DESCR_path))
            or os.path.getmtime(README_path) > os.path.getmtime(LONG_DESCR_path)):
        try :
            subprocess.check_call(["pandoc", "-f", "markdown", '-t', 'rst', '-o', LONG_DESCR_path, README_path], shell=False)
        except (OSError, subprocess.CalledProcessError) as ex:
            print("setup.py::error:: pandoc command failed. Cannot update LONG_DESCR.txt from modified README.md" + str(
                ex))

        # prepare inpiut for documentation
        with open(LONG_DESCR_path) as infile:
            with open(os.path.join("doc", "source", "LONG_DESCR.rst"), "w") as outfile:
                for ind, line in enumerate(infile):
                    if ind == 0:
                        # extend title and prepare underline
                        outfile.write("pysndfile intro\n==========")
                    elif line.startswith("Changes"):
                        break
                    else:
                        outfile.write(line)
            with open(os.path.join("doc", "source", "Changes.rst"), "w") as outfile:
                outfile.write(line)
                for ind, line in enumerate(infile):
                    if line.startswith("Copyright"):
                        break
                    outfile.write(line)

            with open(os.path.join("doc", "source", "GeneralInfo.rst"), "w") as outfile:
                outfile.write(line)
                for line in infile:
                    outfile.write(line)

    return open(LONG_DESCR_path).read()


with open('./requirements.txt') as f:
    install_requires = [line.strip('\n') for line in f.readlines()]


# read should not be used because it does not update LONG_DESCR if required.
def read_long_descr():
    LONG_DESCR_path = os.path.join(os.path.dirname(__file__), 'LONG_DESCR')
    return open(LONG_DESCR_path).read()

setup(
    name = "pysndfile",
    version = _pysndfile_version_str,
    # add all python files in pysndfile dir
    packages = ["pysndfile"],
    # put extension into pysndfile dir
    ext_package = 'pysndfile',
    ext_modules = ext_modules,
    author = "A. Roebel",
    author_email = "axel.dot.roebel@ircam.dot.fr",
    description = "pysndfile provides PySndfile, a Cython wrapper class for reading/writing soundfiles using libsndfile",
    long_description = update_long_descr(),
    long_description_content_type='text/x-rst',
    license = "LGPL",
    install_requires= install_requires,
    url = " https://forge-2.ircam.fr/roebel/pysndfile.git",
    keywords = "soundfile,audiofile",
    cmdclass = {
        'build_ext': build_ext_subclass,
        'sdist'    : sdist_subclass,
        },
    classifiers = [
        "Topic :: Multimedia :: Sound/Audio",
        "Programming Language :: Python",
        "Programming Language :: Cython",
        "Development Status :: 5 - Production/Stable",
        "License :: OSI Approved :: GNU Library or Lesser General Public License (LGPL)",
        "Operating System :: MacOS :: MacOS X",
        "Operating System :: POSIX :: Linux",
        "Operating System :: Microsoft :: Windows",
        ]
    )

