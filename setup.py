#! /usr/bin/env python
from __future__ import print_function

from ez_setup import use_setuptools
use_setuptools()

import os
import shutil
import subprocess
import re
import numpy as np

from setuptools import setup
from distutils.core import Extension
from distutils.command.build_ext import build_ext
from distutils.command.sdist import sdist 

ext_modules = [Extension("_pysndfile", ["_pysndfile.pyx"],
                            libraries = ["sndfile"],
                            include_dirs = [np.get_include()],
                            language="c++")]

try :
    from Cython.Build import cythonize
    ext_modules = cythonize(ext_modules )
except ImportError  :
    print("cythonize not available use pre_cythonized source")
    shutil.copy2("_pysndfile_precythonized.cpp", "_pysndfile.cpp")
    ext_modules[0].sources[0] =  "_pysndfile.cpp"

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
        cythonize(['_pysndfile.pyx'])
        shutil.move("setup.cfg", "setup.cfg.default")
        shutil.copy2("setup.cfg.dist", "setup.cfg")
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
        if compiler_is_clang(self.compiler.compiler):
            for e in self.extensions:
                #e.extra_compile_args.append('-stdlib=libstdc++')
                e.extra_compile_args.append('-Wno-unused-function')
            #for e in self.extensions:
            #    e.extra_link_args.append('-stdlib=libstdc++')
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
def read_long_descr():
    README_path     = os.path.join(os.path.dirname(__file__), 'README.txt')
    LONG_DESCR_path = os.path.join(os.path.dirname(__file__), 'LONG_DESCR')
    if ((not os.path.exists(LONG_DESCR_path))
        or os.path.getmtime(README_path) > os.path.getmtime(LONG_DESCR_path)):
        try :
            subprocess.check_call(["pandoc", "-f", "markdown", '-t', 'rst', '-o', LONG_DESCR_path, README_path], shell=False)
        except (OSError, subprocess.CalledProcessError) :
            print("setup.py::error:: pandoc command failed. Cannot update LONG_DESCR.txt from modified README.txt")
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
    author_email = "axel [ dot ] roebel [ at ] ircam [ dot ] fr",
    description = "pysndfile provides PySndfile, a Cython wrapper class for reading/writing soundfiles using libsndfile",
    long_description = read_long_descr(),
    license = "LGPL",
    url = "http://forge.ircam.fr/p/pysndfile",
    keywords = "soundfile,audiofile",
    cmdclass = {
        'build_ext': build_ext_subclass,
        'sdist'    : sdist_subclass,
        },
    classifiers = [
        "Topic :: Multimedia :: Sound/Audio",
        "Programming Language :: Python",
        "Programming Language :: Cython",
        "Development Status :: 4 - Beta",
        "License :: OSI Approved :: GNU Library or Lesser General Public License (LGPL)",
        "Operating System :: MacOS :: MacOS X",
        "Operating System :: POSIX :: Linux",
        "Operating System :: Microsoft :: Windows",
        ]
    )

