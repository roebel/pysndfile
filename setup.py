#! /usr/bin/env python
# -*- coding: UTF-8 -*-
from __future__ import print_function

import os
import shutil
import subprocess
import re
import numpy as np
import hashlib
import io
from pathlib import Path
from setuptools import setup
from packaging.version import parse
from distutils.core import Extension
from distutils.command.build_ext import build_ext
from distutils.command.sdist import sdist 
import sysconfig

import os
import sys
import platform

if os.environ.get("PYSNDFILE_USE_STATIC", "0") != "0":
    from collections import namedtuple
    if os.environ.get("PYSNDFILE_IGNORE_PKG_CONFIG", "0") == "0":
        import pkgconfig

sndfile_locations = [
    os.environ.get("SNDFILE_INSTALL_DIR", None),
    sysconfig.get_config_var("exec_prefix"),
    "/usr/local",
    "/usr"
]
if sys.platform == "darwin":
    sndfile_locations.append("/opt/local")


def find_libsndfile():
    """
    search for libsndfile in a few standard locations, display error if not found
    """

    lib_dir = None
    inc_dir = None
    for dir in sndfile_locations:
        if dir is not None:

            tmp_inc_dir = Path(dir) / "include"
            tmp_lib_dir = Path(dir) / "lib"
            if (tmp_inc_dir / "sndfile.h").exists():
                if platform.system() == "Windows":
                    # static and shared libraries have the same name on windows
                    # (at least when installed through vcpkg)
                   found_lib = (tmp_lib_dir / "sndfile.lib").exists()
                elif os.environ.get("PYSNDFILE_USE_STATIC", "0") != "0":
                    # only check for the mandatory main library, others are
                    # optional
                    found_lib = (tmp_lib_dir / "libsndfile.a").exists()
                elif platform.system() == "Linux":
                    found_lib = (tmp_lib_dir / "libsndfile.so").exists()
                elif platform.system() == "Darwin":
                    found_lib = (tmp_lib_dir / "libsndfile.dylib").exists()
                else:
                    print("unsupported platform", platform.system(), file=sys.stderr)
                    exit(1)
                if found_lib:
                    inc_dir = str(tmp_inc_dir)
                    lib_dir = str(tmp_lib_dir)
                    break
    
    return lib_dir, inc_dir


def utf8_to_bytes(ss):
    try:
        return bytes(ss, encoding="UTF-8")
    except TypeError :
        return bytes(ss)

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
elif os.environ.get("PYSNDFILE_USE_STATIC", "0") != "0":
    # static libraries for libsndfile should be integrated into the exiension,
    # but their location will only be known in finalize_options
    ext_modules = [Extension("_pysndfile", ["_pysndfile.pyx"],
                             include_dirs = [np.get_include()],
                             language="c++",
                             define_macros = [("NPY_NO_DEPRECATED_API", "NPY_1_13_API_VERSION") ] )]
else:
    ext_modules = [Extension("_pysndfile", ["_pysndfile.pyx"],
                             libraries = ["sndfile"],
                             include_dirs = [np.get_include()],
                             language="c++",
                             define_macros = [("NPY_NO_DEPRECATED_API", "NPY_1_13_API_VERSION") ] )]

try :
    from Cython.Build import cythonize
    # dont adapt language level to python
    #  languge_level is hard-coded in the pyx source
    #ext_modules = cythonize(ext_modules, force=compile_for_RTD, language_level=sys.version_info[0])
    ext_modules = cythonize(ext_modules, force=compile_for_RTD, language_level=2)
except ImportError  :
    print("cannot import cythonize - to be able to cythonize the source please install cython", file=sys.stderr)
    sys.exit(1)

# check clang compiler and disable warning
def compiler_is_clang(comp) :
    print("check for clang compiler ... ", end="", file=sys.stderr)
    try:
        cc_output = subprocess.check_output(comp+['--version'],
                                            stderr = subprocess.STDOUT, shell=False)
    except OSError as ex:
        print("compiler test call failed with error {0:d} msg: {1}".format(ex.errno, ex.strerror), file=sys.stderr)
        print("no", file=sys.stderr)
        return False

    ret = re.search(b"clang", cc_output) is not None
    if ret :
        print("yes", file=sys.stderr)
    else:
        print("no", file=sys.stderr)
    return ret

class sdist_subclass(sdist) :
    def run(self):
        # Make sure the compiled Cython files in the distribution are up-to-date
        # the cynthonized cpp file is no longer part of the distribution
        # and the long dscrption is updated anyway below
        #from Cython.Build import cythonize
        #update_long_descr()
        #cythonize(['_pysndfile.pyx'])
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


    def _define_sndfile_libraries(self, lib_dir):
        if os.environ.get("PYSNDFILE_USE_STATIC", "0") == "0":
            if self.library_dirs:
                self.library_dirs.append(lib_dir)
            else:
                self.library_dirs = [lib_dir]

            # not available on windows (crashes the build)
            if platform.system() != "Windows":
                self.rpath.append(lib_dir)
        else:
            # on linux or mac, a full path must be used for static libraries
            # because the name alone would pick the shared ones instead
            # on windows setuptools does not pass these to the linker, but on
            # the other hand most static and import libraries have the same name
            # and so cannot be installed in the same directory
            lib_path = Path(lib_dir)

            libs_added = False
            if platform.system() == "Windows":
                if self.library_dirs:
                    self.library_dirs.append(lib_dir)
                else:
                    self.library_dirs = [lib_dir]
                lib_prefix = ""
                lib_suffix = ".lib"
            else:
                lib_prefix = "lib"
                lib_suffix = ".a"

            # sometimes pkg-config or the libsndfile install are broken and
            # provide wrong information, this variable allows to bypass it
            if os.environ.get("PYSNDFILE_IGNORE_PKG_CONFIG", "0") == "0":
                old_config_path = os.environ.get("PKG_CONFIG_PATH")
                try:
                    # try to get the installed optional libraries from
                    # pkg-config
                    # known issue: lame (libmp3lame) is sometimes not mentioned
                    # in sndfile.pc despite being required and on windows its
                    # name is wrong (it should be libmp3lame-static)
                    os.environ["PKG_CONFIG_PATH"] = str(lib_path / "pkgconfig")
                    for name in \
                        pkgconfig.parse("sndfile", static = True)["libraries"]:
                        path = lib_path / (lib_prefix + name + lib_suffix)
                        if path.exists():
                            # use name only for windows (setuptools ignores
                            # link_objects)
                            if platform.system() == "Windows":
                                if self.libraries:
                                    self.libraries.append(name)
                                else:
                                    self.libraries = [name]
                            else:
                                if self.link_objects:
                                    self.link_objects.append(str(path))
                                else:
                                    self.link_objects = [str(path)]
                        else:
                            # those are probably shared objects (e.g. libm)
                            if self.libraries:
                                self.libraries.append(name)
                            else:
                                self.libraries = [name]
                    libs_added = True
                except:
                    pass
                finally:
                    if old_config_path:
                        os.environ["PKG_CONFIG_PATH"] = old_config_path
                    else:
                        os.environ.pop("PKG_CONFIG_PATH")

            if not libs_added:
                # without pkg-config into, check which optional libraries are
                # available and assume libsndfile actually uses them
                lib_name = "sndfile"
                path = str(lib_path / (lib_prefix + lib_name + lib_suffix))

                # use name only for windows (setuptools ignores link_objects)
                if platform.system() == "Windows":
                    if self.libraries:
                        self.libraries.append(lib_name)
                    else:
                        self.libraries = [lib_name]
                else:
                    if self.link_objects:
                        self.link_objects.append(path)
                    else:
                        self.link_objects = [path]

                check_libm = (platform.system() != "Windows")
                DepLib = namedtuple("DepLib",
                                    ["name", "needs_libm", "is_lame",
                                     "needs_shlw"])
                all_libs = [
                    DepLib("FLAC", check_libm, False, False),
                    DepLib("vorbisenc", False, False, False),
                    DepLib("vorbis", check_libm, False, False),
                    DepLib("ogg", False, False, False),
                    DepLib("opus", check_libm, False, False),
                    DepLib("mpg123", check_libm, False,
                           platform.system() == "Windows")
                ]
                # some windows installations have a different name for lame,
                # if both variants are present, the usual name is probably an
                # import tibrary, so prefer the altername one
                if platform.system() == "Windows":
                     all_libs.append(DepLib("libmp3lame-static", False, True,
                                            False))

                     # some installs split lame with libmp3lame depending on
                     # libmpghip
                     all_libs.append(DepLib("libmpghip-static", False, False,
                                            False))
                all_libs.append(DepLib("mp3lame", check_libm, True, False))
                add_m = False
                lame_added = False
                add_shlw = False
                for opt in all_libs:
                    path = lib_path / (lib_prefix + opt.name + lib_suffix)
                    if path.exists():
                        do_add = True
                        if opt.is_lame:
                            if lame_added:
                                do_add = False
                            else:
                                lame_added = True
                        if do_add:
                            # use name only for windows (setuptools ignores
                            # link_objects)
                            if platform.system() == "Windows":
                                self.libraries.append(opt.name)
                            else:
                                self.link_objects.append(str(path))
                            if opt.needs_libm:
                                add_m = True
                            if opt.needs_shlw:
                                add_shlw = True
                if add_m:
                    if self.libraries:
                        self.libraries.append("m")
                    else:
                        self.libraries = ["m"]
                if add_shlw:
                    if self.libraries:
                        self.libraries.append("shlwapi")
                    else:
                        self.libraries = ["shlwapi"]

    def initialize_options(self) :
        build_ext.initialize_options(self)

    def finalize_options(self) :
        build_ext.finalize_options(self)
        if not compile_for_RTD:
            auto_sndfile_libdir, auto_sndfile_incdir = find_libsndfile()
            print("build_ext::config::", ">>"*10, file=sys.stderr)
            if self.sndfile_libdir  is not None :
                print(f"build_ext::received libdir as cfg option: {self.sndfile_libdir}", file=sys.stderr)
                self._define_sndfile_libraries(self.sndfile_libdir)
            elif auto_sndfile_libdir is not None:
                print(f"build_ext::auto detected libsndfile library: {auto_sndfile_libdir}", file=sys.stderr)
                self._define_sndfile_libraries(auto_sndfile_libdir)
            else:        
                print(
f"""libsndfile library was not found in standard locations: {[ss for ss in sndfile_locations if ss]}. Please either set envvar SNDFILE_INSTALL_DIR to the directory 
containing the libsndfile install or adapt the setup.cfg file to point to the correct location""", file=sys.stderr
)
                sys.exit(1)

            if self.sndfile_incdir  is not None :
                print(f"build_ext::received include dir as cfg option: {self.sndfile_incdir}", file=sys.stderr)
                self.include_dirs.append(self.sndfile_incdir)
            elif auto_sndfile_incdir is not None:
                print(f"build_ext::auto detected libsndfile include dir: {auto_sndfile_incdir}", file=sys.stderr)
                self.include_dirs.append(auto_sndfile_incdir)
            else:
                print(
f"""libsndfile include file was not found under standard locations: {[ss for ss in sndfile_locations if ss]}. Please either set envvar SNDFILE_INSTALL_DIR to the directory 
containing the libsndfile install or adapt the setup.cfg file to point to the correct location""", file=sys.stderr
)
                sys.exit(1)
            print("build_ext::config::", "<<"*10, file=sys.stderr)


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
        _pysndfile_version_str = re.split('[()]', line)[1].replace(',','.',3).replace(',','-',1).replace('"','').replace(' ','')
        break

if sys.argv[1] == "get_version":
    print(parse(_pysndfile_version_str))
    sys.exit(0)

README_path       = os.path.join(os.path.dirname(__file__), 'README.md')
README_cksum_path = os.path.join(os.path.dirname(__file__), 'README.md.cksum')    

def write_readme_checksum(rdlen, rdsum):
    with open(README_cksum_path, "w") as fi:
        print("{} {}".format(rdlen, rdsum), file=fi)

def read_readme_checksum():
    try:
        with open(README_cksum_path, "r") as fi:
            rdlen, rdsum = fi.read().split()
            return rdlen, rdsum
    except IOError:
            return 0, 0

def calc_readme_checksum():

    readme = open(README_path).read()
    readme_length = len(readme)
    readme_sum    = hashlib.sha256(utf8_to_bytes(readme)).hexdigest()

    return readme_length, readme_sum
    

# Utility function to read the README file.
# Used for the long_description.  It's nice, because now 1) we have a top level
# README file and 2) it's easier to type in the README file than to put a raw
# string in below ...
def update_long_descr():
    README_path     = os.path.join(os.path.dirname(__file__), 'README.md')
    LONG_DESCR_path = os.path.join(os.path.dirname(__file__), 'LONG_DESCR')
    crdck = calc_readme_checksum()
    rrdck = read_readme_checksum()
    if ((not os.path.exists(LONG_DESCR_path)) or rrdck[1] != crdck[1]):
        if rrdck[1] != crdck[1]:
            print("readme check sum {} does not match readme {}, recalculate LONG_DESCR".format(rrdck[1], crdck[1]))
        try :
            subprocess.check_call(["pandoc", "-f", "markdown", '-t', 'rst', '--ascii', '-o', LONG_DESCR_path, README_path], shell=False)

            # pandoc version before 2.4 seems to write non ascii files even if the ascii flag is given
            # fix this to ensure LONG_DESCR is ASCII, use io.open to make this work with python 2.7
            with io.open(LONG_DESCR_path, "r", encoding="UTF-8") as fi:
                # this creates a byte stream
                inp = fi.read()
            # replace utf8 characters that are generated by pandoc to ASCII
            # and create a byte string 
            ascii_long_desc = inp.replace(u"’","'").replace(u"–","--").replace(u'“','"').replace(u'”','"')

            with open(LONG_DESCR_path, "w") as fw:
                fw.write(ascii_long_desc)
        except (OSError, subprocess.CalledProcessError) as ex:
            print("setup.py::error:: pandoc command failed. Cannot update LONG_DESCR.txt from modified README.md" + str(
                ex))

        # prepare input for documentation
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

            write_readme_checksum(crdck[0], crdck[1])
        try :
            subprocess.check_call(["pandoc", "-f", "rst", '-t', 'plain', '--ascii', '-o', 'ChangeLog', os.path.join("doc", "source", "Changes.rst")], shell=False)
        except (OSError, subprocess.CalledProcessError) as ex:
            print("setup.py::error:: pandoc command failed. Cannot update ChangeLog from modified Changes.rst" + str(ex))
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

