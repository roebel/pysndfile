#! /usr/bin/env python
from ez_setup import use_setuptools
use_setuptools()

import shutil
import subprocess
import re
import numpy as np
import errno

from setuptools import setup, Command
from numpy.distutils.core import Extension
from distutils.command.build_ext import build_ext

ext_modules = [Extension("_pysndfile", ["_pysndfile.pyx"],
                            libraries = ["sndfile"],
                            include_dirs=[np.get_include()],
                            language="c++")]

try :
    from Cython.Build import cythonize
    ext_modules = cythonize(ext_modules )
    CYTHONIZE_DONE = True    
except ImportError  :
    print "cythonize not available use pre_cythonized source"
    shutil.copy2("_pysndfile_precythonized.cpp", "_pysndfile.cpp")
    ext_modules[0].sources[0] =  "_pysndfile.cpp"
    
def compiler_is_clang(comp) :
    print "check for clang compiler ...",
    try:
        cc_output = subprocess.check_output(comp+['--version'],
                                            stderr = subprocess.STDOUT, shell=False)
    except OSError as ex:
        print "compiler test call failed with error {0:d} msg: {1}".format(ex.errno, ex.strerror)
        print "no"
        return False

    ret = re.search('clang', cc_output) is not None
    if ret :
        print "yes"
    else:
        print "no"
    return ret

# sub class build_ext to handle build options for specification of libsndfile
class build_ext_subclass( build_ext ):
    user_options = build_ext.user_options + [
        ("sndfile-libdir=", None, "libdir for libsndfile"),
        ("sndfile-incdir=", None, "include for libsndfile")
        ]
        
    def initialize_options(self) :
        build_ext.initialize_options(self)
        self.fcompiler = None
        self.sndfile_incdir = None
        self.sndfile_libdir = None

    def finalize_options(self) :
        build_ext.finalize_options(self)
        if self.sndfile_libdir  is not None :
            self.library_dirs.append(self.sndfile_libdir)
            self.rpath.append(self.sndfile_libdir)
        if self.sndfile_incdir  is not None :
            self.include_dirs.append(self.sndfile_incdir)
                
    def build_extensions(self):
        #c = self.compiler.compiler_type
        #print "compiler attr", self.compiler.__dict__
        #print "compiler", self.compiler.compiler
        #print "compiler is",c
        if compiler_is_clang(self.compiler.compiler):
            for e in self.extensions:
                #e.extra_compile_args.append('-stdlib=libstdc++')
                e.extra_compile_args.append('-Wno-unused-function')
            #for e in self.extensions:
            #    e.extra_link_args.append('-stdlib=libstdc++')
        build_ext.build_extensions(self)

    
setup(
    name = "pysndfile",
    version = "0.1",
    # add all python files in pysndfile dir
    packages = ["pysndfile"],
    # put extension into pysndfile dir
    ext_package = 'pysndfile',
    ext_modules = ext_modules,
    author = "A. Roebel",
    author_email = "axel.roebel@ircam.fr",
    description = "Extension modules used for accessing sndfiles io based on libsndfile/sndfile.hh",
    license = "Copyright IRCAM",
    keywords = "",
    cmdclass = {'build_ext': build_ext_subclass }, 
    )

