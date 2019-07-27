#
# Copyright (C) 2014 IRCAM
#
# author: Axel Roebel
# date  : 6.5.2014
#
# All rights reserved.
#
# This file is part of pysndfile.
#
# pysndfile is free software: you can redistribute it and/or modify
# it under the terms of the GNU Lesser General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# pysndfile is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU Lesser General Public License for more details.
#
# You should have received a copy of the GNU Lesser General Public License
# along with pysndfile.  If not, see <http://www.gnu.org/licenses/>.
#

# cython: embedsignature=True

import numpy as np
import warnings
import os

cimport numpy as cnp
from libcpp.string cimport string

cdef extern from "Python.h":
    ctypedef int Py_intptr_t
  
_pysndfile_version=(1,3,5)
def get_pysndfile_version():
    """
    return tuple describing the version opf pysndfile
    """
    return _pysndfile_version

    
_max_supported_string_length_tuple = (
    ("wav", 2040),
    ("wavex", 2040),
    ("aiff", 8190),
    ("caf", 16370),
    )


max_supported_string_length = dict(_max_supported_string_length_tuple)
"""dict: the maximum length of each of the string types that can be read
   from the various sound file formats in libsndfile is limited.
   we ensure these limits during writing to be able to read the strings back 
"""

cdef extern from "numpy/arrayobject.h":
    void PyArray_ENABLEFLAGS(cnp.ndarray arr, int flags)


cdef extern from "numpy/arrayobject.h":
    ctypedef Py_intptr_t npy_intp
    void *PyArray_DATA(cnp.ndarray arr)
    int PyArray_NDIM(cnp.ndarray arr)
    npy_intp* PyArray_DIMS(cnp.ndarray arr)

cdef extern from "pysndfile.hh":
    ctypedef struct SF_FORMAT_INFO:
        int format
        char *name
        char *extension

    ctypedef cnp.int64_t sf_count_t

    struct SF_INFO:
        sf_count_t frames
        int channels
        int samplerate
        int format
        int sections
        int seekable

    cdef struct SNDFILE :
        pass

    ctypedef struct SF_CUE_POINT:
        int  indx
        unsigned int position
        int fcc_chunk
        int chunk_start
        int block_start
        unsigned int sample_offset
        char name[256]

    ctypedef struct SF_CUES:
        unsigned int cue_count
        SF_CUE_POINT cue_points[100]

    cdef int sf_command(SNDFILE *sndfile, int command, void *data, int datasize)
    cdef int sf_format_check (const SF_INFO *info)
    cdef char *sf_error_number(int errnum) 

    cdef int C_SF_FORMAT_WAV "SF_FORMAT_WAV"     # /* Microsoft WAV format (little endian default). */
    cdef int C_SF_FORMAT_AIFF "SF_FORMAT_AIFF"   # /* Apple/SGI AIFF format (big endian). */
    cdef int C_SF_FORMAT_AU "SF_FORMAT_AU"       # /* Sun/NeXT AU format (big endian). */
    cdef int C_SF_FORMAT_RAW "SF_FORMAT_RAW"     # /* RAW PCM data. */
    cdef int C_SF_FORMAT_PAF "SF_FORMAT_PAF"     # /* Ensoniq PARIS file format. */
    cdef int C_SF_FORMAT_SVX "SF_FORMAT_SVX"     # /* Amiga IFF / SVX8 / SV16 format. */
    cdef int C_SF_FORMAT_NIST "SF_FORMAT_NIST"   # /* Sphere NIST format. */
    cdef int C_SF_FORMAT_VOC "SF_FORMAT_VOC"     # /* VOC files. */
    cdef int C_SF_FORMAT_IRCAM "SF_FORMAT_IRCAM" # /* Berkeley/IRCAM/CARL */
    cdef int C_SF_FORMAT_W64 "SF_FORMAT_W64"     # /* Sonic Foundry's 64 bit RIFF/WAV */
    cdef int C_SF_FORMAT_MAT4 "SF_FORMAT_MAT4"   # /* Matlab (tm) V4.2 / GNU Octave 2.0 */
    cdef int C_SF_FORMAT_MAT5 "SF_FORMAT_MAT5"   # /* Matlab (tm) V5.0 / GNU Octave 2.1 */
    cdef int C_SF_FORMAT_PVF "SF_FORMAT_PVF"     # /* Portable Voice Format */
    cdef int C_SF_FORMAT_XI "SF_FORMAT_XI"       # /* Fasttracker 2 Extended Instrument */
    cdef int C_SF_FORMAT_HTK "SF_FORMAT_HTK"     # /* HMM Tool Kit format */
    cdef int C_SF_FORMAT_SDS "SF_FORMAT_SDS"     # /* Midi Sample Dump Standard */
    cdef int C_SF_FORMAT_AVR "SF_FORMAT_AVR"     # /* Audio Visual Research */
    cdef int C_SF_FORMAT_WAVEX "SF_FORMAT_WAVEX" # /* MS WAVE with WAVEFORMATEX */
    cdef int C_SF_FORMAT_SD2 "SF_FORMAT_SD2"     # /* Sound Designer 2 */
    cdef int C_SF_FORMAT_FLAC "SF_FORMAT_FLAC"   # /* FLAC lossless file format */
    cdef int C_SF_FORMAT_CAF "SF_FORMAT_CAF"     # /* Core Audio File format */

    #/* Subtypes from here on. */
    cdef int C_SF_FORMAT_PCM_S8 "SF_FORMAT_PCM_S8"    # /* Signed 8 bit data */
    cdef int C_SF_FORMAT_PCM_16 "SF_FORMAT_PCM_16"    # /* Signed 16 bit data */
    cdef int C_SF_FORMAT_PCM_24 "SF_FORMAT_PCM_24"    # /* Signed 24 bit data */
    cdef int C_SF_FORMAT_PCM_32 "SF_FORMAT_PCM_32"    # /* Signed 32 bit data */

    cdef int C_SF_FORMAT_PCM_U8 "SF_FORMAT_PCM_U8"    # /* Unsigned 8 bit data (WAV and RAW only) */

    cdef int C_SF_FORMAT_FLOAT "SF_FORMAT_FLOAT"      # /* 32 bit float data */
    cdef int C_SF_FORMAT_DOUBLE "SF_FORMAT_DOUBLE"    # /* 64 bit float data */

    cdef int C_SF_FORMAT_ULAW "SF_FORMAT_ULAW"            # /* U-Law encoded. */
    cdef int C_SF_FORMAT_ALAW "SF_FORMAT_ALAW"            # /* A-Law encoded. */
    cdef int C_SF_FORMAT_IMA_ADPCM "SF_FORMAT_IMA_ADPCM"  # /* IMA ADPCM. */
    cdef int C_SF_FORMAT_MS_ADPCM "SF_FORMAT_MS_ADPCM"    # /* Microsoft ADPCM. */

    cdef int C_SF_FORMAT_GSM610 "SF_FORMAT_GSM610"    # /* GSM 6.10 encoding. */
    cdef int C_SF_FORMAT_VOX_ADPCM "SF_FORMAT_VOX_ADPCM"  # /* OKI / Dialogix ADPCM */
    cdef int C_SF_FORMAT_G721_32 "SF_FORMAT_G721_32"   # /* 32kbs G721 ADPCM encoding. */
    cdef int C_SF_FORMAT_G723_24 "SF_FORMAT_G723_24"   # /* 24kbs G723 ADPCM encoding. */
    cdef int C_SF_FORMAT_G723_40 "SF_FORMAT_G723_40"   # /* 40kbs G723 ADPCM encoding. */

    cdef int C_SF_FORMAT_DWVW_12 "SF_FORMAT_DWVW_12"   # /* 12 bit Delta Width Variable Word encoding. */
    cdef int C_SF_FORMAT_DWVW_16 "SF_FORMAT_DWVW_16"   # /* 16 bit Delta Width Variable Word encoding. */
    cdef int C_SF_FORMAT_DWVW_24 "SF_FORMAT_DWVW_24"   # /* 24 bit Delta Width Variable Word encoding. */
    cdef int C_SF_FORMAT_DWVW_N "SF_FORMAT_DWVW_N"    # /* N bit Delta Width Variable Word encoding. */

    cdef int C_SF_FORMAT_DPCM_8 "SF_FORMAT_DPCM_8"    # /* 8 bit differential PCM (XI only) */
    cdef int C_SF_FORMAT_DPCM_16 "SF_FORMAT_DPCM_16"   # /* 16 bit differential PCM (XI only) */

    #    /* Endian-ness options. */
    cdef int C_SF_ENDIAN_FILE "SF_ENDIAN_FILE"   # /* Default file endian-ness. */
    cdef int C_SF_ENDIAN_LITTLE "SF_ENDIAN_LITTLE"  # /* Force little endian-ness. */
    cdef int C_SF_ENDIAN_BIG "SF_ENDIAN_BIG"   # /* Force big endian-ness. */
    cdef int C_SF_ENDIAN_CPU "SF_ENDIAN_CPU"   # /* Force CPU endian-ness. */

    cdef int C_SF_FORMAT_SUBMASK "SF_FORMAT_SUBMASK" 
    cdef int C_SF_FORMAT_TYPEMASK "SF_FORMAT_TYPEMASK" 
    cdef int C_SF_FORMAT_ENDMASK "SF_FORMAT_ENDMASK"

    # commands
    cdef int C_SFC_GET_LIB_VERSION "SFC_GET_LIB_VERSION"  
    cdef int C_SFC_GET_LOG_INFO "SFC_GET_LOG_INFO"  

    cdef int C_SFC_GET_NORM_DOUBLE "SFC_GET_NORM_DOUBLE"  
    cdef int C_SFC_GET_NORM_FLOAT "SFC_GET_NORM_FLOAT"  
    cdef int C_SFC_SET_NORM_DOUBLE "SFC_SET_NORM_DOUBLE"  
    cdef int C_SFC_SET_NORM_FLOAT "SFC_SET_NORM_FLOAT"  
    cdef int C_SFC_SET_SCALE_FLOAT_INT_READ "SFC_SET_SCALE_FLOAT_INT_READ"  
    cdef int C_SFC_SET_SCALE_INT_FLOAT_WRITE "SFC_SET_SCALE_INT_FLOAT_WRITE"

    cdef int C_SFC_GET_SIMPLE_FORMAT_COUNT "SFC_GET_SIMPLE_FORMAT_COUNT"  
    cdef int C_SFC_GET_SIMPLE_FORMAT "SFC_GET_SIMPLE_FORMAT"  

    cdef int C_SFC_GET_FORMAT_INFO "SFC_GET_FORMAT_INFO"  

    cdef int C_SFC_GET_FORMAT_MAJOR_COUNT "SFC_GET_FORMAT_MAJOR_COUNT"  
    cdef int C_SFC_GET_FORMAT_MAJOR "SFC_GET_FORMAT_MAJOR"  
    cdef int C_SFC_GET_FORMAT_SUBTYPE_COUNT "SFC_GET_FORMAT_SUBTYPE_COUNT"  
    cdef int C_SFC_GET_FORMAT_SUBTYPE "SFC_GET_FORMAT_SUBTYPE"  

    cdef int C_SFC_CALC_SIGNAL_MAX "SFC_CALC_SIGNAL_MAX"  
    cdef int C_SFC_CALC_NORM_SIGNAL_MAX "SFC_CALC_NORM_SIGNAL_MAX"  
    cdef int C_SFC_CALC_MAX_ALL_CHANNELS "SFC_CALC_MAX_ALL_CHANNELS"  
    cdef int C_SFC_CALC_NORM_MAX_ALL_CHANNELS "SFC_CALC_NORM_MAX_ALL_CHANNELS"  
    cdef int C_SFC_GET_SIGNAL_MAX "SFC_GET_SIGNAL_MAX"  
    cdef int C_SFC_GET_MAX_ALL_CHANNELS "SFC_GET_MAX_ALL_CHANNELS"  

    cdef int C_SFC_SET_ADD_PEAK_CHUNK "SFC_SET_ADD_PEAK_CHUNK"  

    cdef int C_SFC_UPDATE_HEADER_NOW "SFC_UPDATE_HEADER_NOW"  
    cdef int C_SFC_SET_UPDATE_HEADER_AUTO "SFC_SET_UPDATE_HEADER_AUTO"  

    cdef int C_SFC_FILE_TRUNCATE "SFC_FILE_TRUNCATE"  

    cdef int C_SFC_SET_RAW_START_OFFSET "SFC_SET_RAW_START_OFFSET"  

    cdef int C_SFC_SET_DITHER_ON_WRITE "SFC_SET_DITHER_ON_WRITE"  
    cdef int C_SFC_SET_DITHER_ON_READ "SFC_SET_DITHER_ON_READ"  

    cdef int C_SFC_GET_DITHER_INFO_COUNT "SFC_GET_DITHER_INFO_COUNT"  
    cdef int C_SFC_GET_DITHER_INFO "SFC_GET_DITHER_INFO"  

    cdef int C_SFC_GET_EMBED_FILE_INFO "SFC_GET_EMBED_FILE_INFO"  

    cdef int C_SFC_SET_CLIPPING "SFC_SET_CLIPPING"  
    cdef int C_SFC_GET_CLIPPING "SFC_GET_CLIPPING"  

    cdef int C_SFC_GET_CUE_COUNT "SFC_GET_CUE_COUNT"
    cdef int C_SFC_GET_CUE "SFC_GET_CUE"

    cdef int C_SFC_GET_INSTRUMENT "SFC_GET_INSTRUMENT"  
    cdef int C_SFC_SET_INSTRUMENT "SFC_SET_INSTRUMENT"  

    cdef int C_SFC_GET_LOOP_INFO "SFC_GET_LOOP_INFO"  

    cdef int C_SFC_GET_BROADCAST_INFO "SFC_GET_BROADCAST_INFO"  
    cdef int C_SFC_SET_BROADCAST_INFO "SFC_SET_BROADCAST_INFO"  

    cdef int C_SF_STR_TITLE "SF_STR_TITLE"  
    cdef int C_SF_STR_COPYRIGHT "SF_STR_COPYRIGHT"  
    cdef int C_SF_STR_SOFTWARE "SF_STR_SOFTWARE"  
    cdef int C_SF_STR_ARTIST "SF_STR_ARTIST"  
    cdef int C_SF_STR_COMMENT "SF_STR_COMMENT"  
    cdef int C_SF_STR_DATE "SF_STR_DATE"  

    # these are the only values retrieved from the header file. So we cannot
    # try to write/get strings that are not supported by the library we use.
    cdef int C_SF_STR_FIRST "SF_STR_FIRST"
    cdef int C_SF_STR_LAST  "SF_STR_LAST"
    
    cdef int C_SF_FALSE "SF_FALSE"  
    cdef int C_SF_TRUE "SF_TRUE"  

    #        /* Modes for opening files. */
    cdef int C_SFM_READ "SFM_READ"  
    cdef int C_SFM_WRITE "SFM_WRITE"  
    cdef int C_SFM_RDWR "SFM_RDWR"  

    cdef int C_SEEK_SET "SEEK_SET"  
    cdef int C_SEEK_CUR "SEEK_CUR"  
    cdef int C_SEEK_END "SEEK_END"  
    
    cdef int C_SF_ERR_NO_ERROR "SF_ERR_NO_ERROR"  
    cdef int C_SF_ERR_UNRECOGNISED_FORMAT "SF_ERR_UNRECOGNISED_FORMAT"  
    cdef int C_SF_ERR_SYSTEM "SF_ERR_SYSTEM"  
    cdef int C_SF_ERR_MALFORMED_FILE "SF_ERR_MALFORMED_FILE"  
    cdef int C_SF_ERR_UNSUPPORTED_ENCODING "SF_ERR_UNSUPPORTED_ENCODING"  
    
    cdef int C_SF_COUNT_MAX "SF_COUNT_MAX"  

IF UNAME_SYSNAME == "Windows":
    include "sndfile_win32.pxi"
ELSE:
    include "sndfile_linux.pxi"

# these two come with more recent versions of libsndfile
# to not break compilation they are defined outside sndfile.h
cdef int C_SF_STR_ALBUM = 0x07
cdef int C_SF_STR_LICENSE = 0x08
cdef int C_SF_STR_TRACKNUMBER = 0x09
cdef int C_SF_STR_GENRE = 0x10


SF_MAX_CHANNELS  = 1024
"""int: maximum number if channels supported by libsndfile 1.0.28.
"""

SF_FORMAT_SUBMASK  = C_SF_FORMAT_SUBMASK
"""int: format submask to retrieve encoding from format integer.
"""

SF_FORMAT_TYPEMASK = C_SF_FORMAT_TYPEMASK
"""int: format typemask to retrieve major file format from format integer.
"""

SF_FORMAT_ENDMASK  = C_SF_FORMAT_ENDMASK
"""int: endienness mask to retrieve endienness from format integer.
"""

_encoding_id_tuple = (
    ('pcms8' , C_SF_FORMAT_PCM_S8),
    ('pcm16' , C_SF_FORMAT_PCM_16),
    ('pcm24' , C_SF_FORMAT_PCM_24),
    ('pcm32' , C_SF_FORMAT_PCM_32),
    ('pcmu8' , C_SF_FORMAT_PCM_U8),

    ('float32' , C_SF_FORMAT_FLOAT),
    ('float64' , C_SF_FORMAT_DOUBLE),

    ('ulaw'      , C_SF_FORMAT_ULAW),
    ('alaw'      , C_SF_FORMAT_ALAW),
    ('ima_adpcm' , C_SF_FORMAT_IMA_ADPCM),
    ('ms_adpcm'  , C_SF_FORMAT_MS_ADPCM),

    ('gsm610'    , C_SF_FORMAT_GSM610),
    ('vox_adpcm' , C_SF_FORMAT_VOX_ADPCM),

    ('g721_32'   , C_SF_FORMAT_G721_32),
    ('g723_24'   , C_SF_FORMAT_G723_24),
    ('g723_40'   , C_SF_FORMAT_G723_40),

    ('dww12' , C_SF_FORMAT_DWVW_12),
    ('dww16' , C_SF_FORMAT_DWVW_16),
    ('dww24' , C_SF_FORMAT_DWVW_24),
    ('dwwN'  , C_SF_FORMAT_DWVW_N),

    ('dpcm8' , C_SF_FORMAT_DPCM_8),
    ('dpcm16', C_SF_FORMAT_DPCM_16)
    )

encoding_name_to_id = dict(_encoding_id_tuple)
"""dict: mapping of pysndfile's encoding names to libsndfile's encoding ids.
"""
encoding_id_to_name = dict([(id, enc) for enc, id in _encoding_id_tuple])
"""dict: mapping of libsndfile's encoding ids to pysndfile's encoding names.
"""

_fileformat_id_tuple = (
    ('wav' , C_SF_FORMAT_WAV),
    ('aiff' , C_SF_FORMAT_AIFF),
    ('au'   , C_SF_FORMAT_AU),
    ('raw'  , C_SF_FORMAT_RAW),
    ('paf'  , C_SF_FORMAT_PAF),
    ('svx'  , C_SF_FORMAT_SVX),
    ('nist' , C_SF_FORMAT_NIST),
    ('voc'  , C_SF_FORMAT_VOC),
    ('ircam', C_SF_FORMAT_IRCAM),
    ('wav64', C_SF_FORMAT_W64),
    ('mat4' , C_SF_FORMAT_MAT4),
    ('mat5' , C_SF_FORMAT_MAT5),
    ('pvf'  , C_SF_FORMAT_PVF),
    ('xi'   , C_SF_FORMAT_XI),
    ('htk'  , C_SF_FORMAT_HTK),
    ('sds'  , C_SF_FORMAT_SDS),
    ('avr'  , C_SF_FORMAT_AVR),
    ('wavex', C_SF_FORMAT_WAVEX),
    ('sd2'  , C_SF_FORMAT_SD2),
    ('flac' , C_SF_FORMAT_FLAC),
    ('caf'  , C_SF_FORMAT_CAF),
    )


#: mapping of pysndfile's major fileformat names to libsndfile's major fileformat ids.
fileformat_name_to_id = dict (_fileformat_id_tuple)

#: mapping of libsndfile's major fileformat ids to pysndfile's major fileformat names.
fileformat_id_to_name = dict ([(id, format) for format, id in _fileformat_id_tuple])


_endian_to_id_tuple = (
    ('file'   , C_SF_ENDIAN_FILE),
    ('little' , C_SF_ENDIAN_LITTLE),
    ('big'    , C_SF_ENDIAN_BIG),
    ('cpu'    , C_SF_ENDIAN_CPU)
    )

#: dict mapping of pysndfile's endian names to libsndfile's endian ids.
endian_name_to_id = dict(_endian_to_id_tuple)
#: dict mapping of libsndfile's endian ids to pysndfile's endian names.
endian_id_to_name = dict([(id, endname) for endname, id in _endian_to_id_tuple])

_commands_to_id_tuple = (
    ("SFC_GET_LIB_VERSION" , C_SFC_GET_LIB_VERSION),
    ("SFC_GET_LOG_INFO" ,     C_SFC_GET_LOG_INFO),
    
    ("SFC_GET_NORM_DOUBLE" , C_SFC_GET_NORM_DOUBLE),
    ("SFC_GET_NORM_FLOAT" , C_SFC_GET_NORM_FLOAT),
    ("SFC_SET_NORM_DOUBLE" , C_SFC_SET_NORM_DOUBLE),
    ("SFC_SET_NORM_FLOAT" , C_SFC_SET_NORM_FLOAT),
    ("SFC_SET_SCALE_FLOAT_INT_READ" , C_SFC_SET_SCALE_FLOAT_INT_READ),
    ("SFC_SET_SCALE_INT_FLOAT_WRITE" , C_SFC_SET_SCALE_INT_FLOAT_WRITE),

    ("SFC_GET_SIMPLE_FORMAT_COUNT" , C_SFC_GET_SIMPLE_FORMAT_COUNT),
    ("SFC_GET_SIMPLE_FORMAT" , C_SFC_GET_SIMPLE_FORMAT),

    ("SFC_GET_FORMAT_INFO" , C_SFC_GET_FORMAT_INFO),

    ("SFC_GET_FORMAT_MAJOR_COUNT" , C_SFC_GET_FORMAT_MAJOR_COUNT),
    ("SFC_GET_FORMAT_MAJOR" , C_SFC_GET_FORMAT_MAJOR),
    ("SFC_GET_FORMAT_SUBTYPE_COUNT" , C_SFC_GET_FORMAT_SUBTYPE_COUNT),
    ("SFC_GET_FORMAT_SUBTYPE" , C_SFC_GET_FORMAT_SUBTYPE),

    ("SFC_CALC_SIGNAL_MAX" , C_SFC_CALC_SIGNAL_MAX),
    ("SFC_CALC_NORM_SIGNAL_MAX" , C_SFC_CALC_NORM_SIGNAL_MAX),
    ("SFC_CALC_MAX_ALL_CHANNELS" , C_SFC_CALC_MAX_ALL_CHANNELS),
    ("SFC_CALC_NORM_MAX_ALL_CHANNELS" , C_SFC_CALC_NORM_MAX_ALL_CHANNELS),
    ("SFC_GET_SIGNAL_MAX" , C_SFC_GET_SIGNAL_MAX),
    ("SFC_GET_MAX_ALL_CHANNELS" , C_SFC_GET_MAX_ALL_CHANNELS),

    ("SFC_SET_ADD_PEAK_CHUNK" , C_SFC_SET_ADD_PEAK_CHUNK),

    ("SFC_UPDATE_HEADER_NOW" , C_SFC_UPDATE_HEADER_NOW),
    ("SFC_SET_UPDATE_HEADER_AUTO" , C_SFC_SET_UPDATE_HEADER_AUTO),

    ("SFC_FILE_TRUNCATE" , C_SFC_FILE_TRUNCATE),

    ("SFC_SET_RAW_START_OFFSET" , C_SFC_SET_RAW_START_OFFSET),

    ("SFC_SET_DITHER_ON_WRITE" , C_SFC_SET_DITHER_ON_WRITE),
    ("SFC_SET_DITHER_ON_READ" , C_SFC_SET_DITHER_ON_READ),

    ("SFC_GET_DITHER_INFO_COUNT" , C_SFC_GET_DITHER_INFO_COUNT),
    ("SFC_GET_DITHER_INFO" , C_SFC_GET_DITHER_INFO),

    ("SFC_GET_EMBED_FILE_INFO" , C_SFC_GET_EMBED_FILE_INFO),

    ("SFC_SET_CLIPPING" , C_SFC_SET_CLIPPING),
    ("SFC_GET_CLIPPING" , C_SFC_GET_CLIPPING),

    ("SFC_GET_INSTRUMENT" , C_SFC_GET_INSTRUMENT),
    ("SFC_SET_INSTRUMENT" , C_SFC_SET_INSTRUMENT),

    ("SFC_GET_LOOP_INFO" , C_SFC_GET_LOOP_INFO),

    ("SFC_GET_BROADCAST_INFO" , C_SFC_GET_BROADCAST_INFO),
    ("SFC_SET_BROADCAST_INFO" , C_SFC_SET_BROADCAST_INFO),
    )
    

#:dict mapping of pysndfile's commandtype names to libsndfile's commandtype ids.
commands_name_to_id = dict(_commands_to_id_tuple)
#: dict mapping of libsndfile's commandtype ids to pysndfile's commandtype names.
commands_id_to_name = dict([(id, com) for com, id in _commands_to_id_tuple])

# define these by hand so we can use here all string types known for the
# most recent libsndfile version. STrings will be filtered according to SF_STR_LAST

_stringtype_to_id_tuple = (
    ("SF_STR_TITLE", C_SF_STR_TITLE),
    ("SF_STR_COPYRIGHT", C_SF_STR_COPYRIGHT),
    ("SF_STR_SOFTWARE", C_SF_STR_SOFTWARE),
    ("SF_STR_ARTIST", C_SF_STR_ARTIST),
    ("SF_STR_COMMENT", C_SF_STR_COMMENT),
    ("SF_STR_DATE", C_SF_STR_DATE),
    ("SF_STR_ALBUM", C_SF_STR_ALBUM),
    ("SF_STR_LICENSE", C_SF_STR_LICENSE),
    ("SF_STR_TRACKNUMBER", C_SF_STR_TRACKNUMBER),
    ("SF_STR_GENRE", C_SF_STR_GENRE),
    )

#: dict mapping of pysndfile's stringtype nams to libsndfile's stringtype ids.
stringtype_name_to_id = dict(_stringtype_to_id_tuple[:C_SF_STR_LAST+1])

#: dict mapping of libsndfile's stringtype ids to pysndfile's stringtype names.
stringtype_id_to_name = dict([(id, com) for com, id in _stringtype_to_id_tuple[:C_SF_STR_LAST+1]])


def get_sndfile_version():
    """
    return a tuple of ints representing the version of libsndfile that is used
    """
    cdef int status
    cdef char buffer[256]

    st = sf_command(NULL, C_SFC_GET_LIB_VERSION, buffer, 256)
    version = buffer.decode("UTF-8")
    
    # Get major, minor and micro from version
    # Template: libsndfile-X.X.XpreX with preX being optional
    version = version.split('-')[1]
    prerelease = 0
    major, minor, micro = [i for i in version.split('.')]
    try:
        micro = int(micro)
    except ValueError,e:
        #print "micro is " + str(micro)
        micro, prerelease = micro.split('pre')

    return int(major), int(minor), int(micro), prerelease


def get_sndfile_encodings(major):
    """
    Return lists of available encoding for the given sndfile format.

    *Parameters*
    
    :param major: (str) sndfile format for that the list of available encodings should
             be returned. format should be specified as a string, using
             one of the strings returned by :py:func:`get_sndfile_formats`
    """

    # make major an id
    if major in fileformat_id_to_name:
        pass
    elif major in fileformat_name_to_id:
        major = fileformat_name_to_id[major]
    else:
        raise ValueError("PySndfile::File format {0} not known by PySndfile".format(str(major)))
    
    if major not in get_sndfile_formats_from_libsndfile():
        raise ValueError("PySndfile::File format {0}:{1:x} not supported by libsndfile".format(fileformat_id_to_name[major], major))

    enc = []
    for i in _get_sub_formats_for_major(major):
        # Handle the case where libsndfile supports an encoding we don't
        if i not in encoding_id_to_name:
            warnings.warn("Encoding {0:x} supported by libsndfile but not by PySndfile"
                          .format(i & C_SF_FORMAT_SUBMASK))
        else:
            enc.append(encoding_id_to_name[i & C_SF_FORMAT_SUBMASK])
    return enc

cdef _get_sub_formats_for_major(int major):
    """
    Retrieve list of subtype formats or encodings given the major format specified as int.

    internal function

    :param major: (int) major format specified as integer, the mapping from format strings to integers
                   can be retrieved from :py:data:`fileformat_name_to_id`

    :return: list of sub formats or encodings in form of integers, these integers can be converted to strings
                  by means of :py:data:`encoding_id_to_name`
    """
    cdef int nsub
    cdef int i
    cdef SF_FORMAT_INFO info
    cdef SF_INFO sfinfo

    sf_command (NULL, C_SFC_GET_FORMAT_SUBTYPE_COUNT, &nsub, sizeof(int))

    subs = []
    # create a valid sfinfo struct
    sfinfo.channels   = 1
    sfinfo.samplerate = 44100
    for i in range(nsub):
        info.format = i
        sf_command (NULL, C_SFC_GET_FORMAT_SUBTYPE, &info, sizeof (info))
        sfinfo.format = (major & C_SF_FORMAT_TYPEMASK) | info.format
        if sf_format_check(&sfinfo):
            subs.append(info.format)

    return subs

cdef get_sndfile_formats_from_libsndfile():
    """
    retrieve list of major format ids

    :return: list of strings representing all major sound formats that can be handled by the libsndfile
             library that is used by pysndfile.
    """
    cdef int nmajor
    cdef int i
    cdef SF_FORMAT_INFO info

    sf_command (NULL, C_SFC_GET_FORMAT_MAJOR_COUNT, &nmajor, sizeof(int))

    majors = []
    for i in xrange(nmajor):
        info.format = i
        sf_command (NULL, C_SFC_GET_FORMAT_MAJOR, &info, sizeof (info))
        majors.append(info.format)

    return majors

def get_sf_log():
    """
    retrieve internal log from libsndfile, notably useful in case of errors.

    :return: string representing the internal error log managed by libsndfile
    """
    cdef char buf[2048]
    sf_command (NULL, C_SFC_GET_LOG_INFO, &buf, sizeof (buf))
    return str(buf)
    
def get_sndfile_formats():
    """
    Return lists of available file formats supported by libsndfile and pysndfile.

    :return: list of strings representing all major sound formats that can be handled by the libsndfile
             library and the pysndfile interface.
    """
    fmt = []
    for i in get_sndfile_formats_from_libsndfile():
        # Handle the case where libsndfile supports a format we don't
        if not i in fileformat_id_to_name:
            warnings.warn("Format {0:x} supported by libsndfile but not "
                          "yet supported by PySndfile".format(i & C_SF_FORMAT_TYPEMASK))
        else:
            fmt.append(fileformat_id_to_name[i & C_SF_FORMAT_TYPEMASK])
    return fmt

cdef class PySndfile:
    """\
    PySndfile is a python class for reading/writing audio files.

    PySndfile is proxy for the SndfileHandle class in sndfile.hh
    Once an instance is created, it can be used to read and/or write
    data from/to numpy arrays, query the audio file meta-data, etc...

    :param filename: <string or int> name of the file to open (string), or file descriptor (integer)
    :param mode: <string> 'r' for read, 'w' for write, or 'rw' for read and write.
    :param format: <int> Required when opening a new file for writing, or to read raw audio files (without header).
                   See function :py:meth:`construct_format`.
    :param channels: <int> number of channels.
    :param samplerate: <int> sampling rate.

    :return: valid PySndfile instance. An IOError exception is thrown if any error is
        encountered in libsndfile. A ValueError exception is raised if the arguments are invalid. 

    *Notes*

      * the files will be opened with auto clipping set to True
        see the member set_autoclipping for more information.
      * the soundfile will be closed when the class is destroyed    
      * format, channels and samplerate need to be given only
        in the write modes and for raw files.
    """

    cdef SndfileHandle *thisPtr
    cdef int fd
    cdef string filename
    def __cinit__(self, filename, mode='r', int format=0,
                    int channels=0, int samplerate=0, *args, **kwrds):
        cdef int sfmode
        cdef const char*cfilename
        cdef int fh

        IF UNAME_SYSNAME == "Windows":
           cdef Py_ssize_t length
           cdef wchar_t *my_wchars

        # -1 will indicate that the file has been open from filename, not from
        # file descriptor
        self.fd = -1
        self.thisPtr = NULL

        if channels > SF_MAX_CHANNELS:
            raise ValueError( "PySndfile:: max number of channels exceeded {} > {}!".format(channels, SF_MAX_CHANNELS))
        
        # Check the mode is one of the expected values
        if mode == 'r':
            sfmode = C_SFM_READ
        elif mode == 'w':
            sfmode = C_SFM_WRITE
            if format is 0:
                raise ValueError( "PySndfile::opening for writing requires a format argument !")
        elif mode == 'rw':
            sfmode  = C_SFM_RDWR
            if format is 0:
                raise ValueError( "PySndfile::opening for writing requires a format argument !")
        else:
            raise ValueError("PySndfile::mode {0} not recognized".format(str(mode)))

        self.fd = -1
        if isinstance(filename, int):
            fh = filename
            self.thisPtr = new SndfileHandle(fh, 0, sfmode, format, channels, samplerate)
            self.filename = b""
            self.fd = filename
        else:
            filename = os.path.expanduser(filename)

            IF UNAME_SYSNAME == "Windows":
                # Need to get the wchars before filename is converted to utf-8
                my_wchars = PyUnicode_AsWideCharString(filename, &length)
            
            if isinstance(filename, unicode):
                filename = bytes(filename, "UTF-8")
            self.filename = filename

            IF UNAME_SYSNAME == "Windows":
                if length > 0:
                    self.thisPtr = new SndfileHandle(my_wchars, sfmode, format, channels, samplerate)
                    PyMem_Free(my_wchars)
                else:
                    raise RuntimeError("PySndfile::error while converting {0} into wchars".format(filename))
            ELSE:
                self.thisPtr = new SndfileHandle(self.filename.c_str(), sfmode, format, channels, samplerate)
            

        if self.thisPtr == NULL or self.thisPtr.rawHandle() == NULL:
            raise IOError("PySndfile::error while opening {0}\n\t->{1}".format(self.filename,
                                                                                   self.thisPtr.strError()))

        self.set_auto_clipping(True)

    def get_name(self):
        """
        :return: <str> filename that was used to open the underlying sndfile
        """
        return self.filename

    def __dealloc__(self):
        del self.thisPtr
            
    def command(self, command, arg=0) :
        """
        interface for passing commands via sf_command to underlying soundfile
        using sf_command(this_sndfile, command_id, NULL, arg)        

        :param command: <string or int>
              libsndfile command macro to be used. They can be specified either as string using the command macros name, or the command id.

              Supported commands are:
        
|                 SFC_SET_NORM_FLOAT
|                 SFC_SET_NORM_DOUBLE
|                 SFC_GET_NORM_FLOAT
|                 SFC_GET_NORM_DOUBLE
|                 SFC_SET_SCALE_FLOAT_INT_READ
|                 SFC_SET_SCALE_INT_FLOAT_WRITE
|                 SFC_SET_ADD_PEAK_CHUNK
|                 SFC_UPDATE_HEADER_NOW
|                 SFC_SET_UPDATE_HEADER_AUTO
|                 SFC_SET_CLIPPING (see :py:func:`pysndfile.PySndfile.set_auto_clipping`)
|                 SFC_GET_CLIPPING (see :py:func:`pysndfile.PySndfile.set_auto_clipping`)
|                 SFC_WAVEX_GET_AMBISONIC
|                 SFC_WAVEX_SET_AMBISONIC
|                 SFC_RAW_NEEDS_ENDSWAP

        :param arg: <int> additional argument of the command

        :return: <int> 1 for success or True, 0 for failure or False
        """
        if isinstance(command, str) :
            return self.thisPtr.command(commands_name_to_id[command], NULL, arg)
        # so we suppose it is an int
        return self.thisPtr.command(command, NULL, arg)
        

    def set_auto_clipping( self, arg = True) :
        """
        enable auto clipping when reading/writing samples from/to sndfile.

        auto clipping is enabled by default.
        auto clipping is required by libsndfile to properly handle scaling between sndfiles with pcm encoding and float representation of the samples in numpy.
        When auto clipping is set to on reading pcm data into a float vector and writing it back with libsndfile will reproduce 
        the original samples. If auto clipping is off, samples will be changed slightly as soon as the amplitude is close to the
        sample range because libsndfile applies slightly different scaling factors during read and write.

        :param arg: <bool> indicator of the desired clipping state

        :return: <int> 1 for success, 0 for failure
        """
        if self.thisPtr == NULL or not self.thisPtr:
            raise RuntimeError("PySndfile::error::no valid soundfilehandle")
        return self.thisPtr.command(C_SFC_SET_CLIPPING, NULL, arg);
             
    def writeSync(self):
        """
        call the operating system's function to force the writing of all
        file cache buffers to disk the file.

        No effect if file is open as read
        """
        if self.thisPtr == NULL or not self.thisPtr:
            raise RuntimeError("PySndfile::error::no valid soundfilehandle")
        self.thisPtr.writeSync()
        
                  
    def __str__( self):
        if self.thisPtr == NULL or not self.thisPtr:
            return "invalid sndfile"
        repstr = ["----------------------------------------"]
        if not self.fd == -1:
            repstr += ["File        : %d (opened by file descriptor)" % self.fd]
        else:
            repstr += ["File        : %s" % self.filename.decode("UTF-8")]
        repstr  += ["Channels    : %d" % self.thisPtr.channels()]
        repstr  += ["Sample rate : %d" % self.thisPtr.samplerate()]
        repstr  += ["Frames      : %d" % self.thisPtr.frames()]
        repstr  += ["Raw Format  : %#010x" % self.thisPtr.format()]
        repstr  += ["File format : %s" % fileformat_id_to_name[self.thisPtr.format()& C_SF_FORMAT_TYPEMASK]]
        repstr  += ["Encoding    : %s" % encoding_id_to_name[self.thisPtr.format()& C_SF_FORMAT_SUBMASK]]
        #repstr  += ["Endianness  : %s" % ]
        #repstr  += "Sections    : %d\n" % self._sfinfo.sections
        repstr  += ["Seekable    : %s\n" % self.thisPtr.seekable()]
        #repstr  += "Duration    : %s\n" % self._generate_duration_str()
        return "\n".join(repstr)

    def read_frames(self, sf_count_t nframes=-1, dtype=np.float64):
        """
        Read the given number of frames and put the data into a numpy array of
        the requested dtype.

        :param nframes: <int> number of frames to read (default = -1 -> read all).
        :param dtype: <numpy dtype> dtype of the returned array containing read data (see note).

        :return: np.array<dtype> with sound data

        *Notes*
        
          * One column per channel.

        """
        if self.thisPtr == NULL or not self.thisPtr:
            raise RuntimeError("PySndfile::error::no valid soundfilehandle")

        if nframes < 0 :
            nframes = self.thisPtr.frames()
        if dtype == np.float64:
            y = self.read_frames_double(nframes)
        elif dtype == np.float32:
            y = self.read_frames_float(nframes)
        elif dtype == np.int32:
            y = self.read_frames_int(nframes)
        elif dtype == np.int16:
            y = self.read_frames_short(nframes)
        else:
            raise RuntimeError("Sorry, dtype %s not supported" % str(dtype))

        if y.shape[1] == 1:
            y.shape = (y.shape[0],)
        return y

    cdef read_frames_double(self, sf_count_t nframes):
        cdef sf_count_t res
        cdef cnp.ndarray[cnp.float64_t, ndim=2] ty = np.empty((nframes, self.thisPtr.channels()),
                                                                dtype=np.float64, order='C')

        res = self.thisPtr.readf(<double*> PyArray_DATA(ty), nframes)
        if not res == nframes:
            raise RuntimeError("Asked %d frames, read %d" % (nframes, res))
        return ty

    cdef read_frames_float(self, sf_count_t nframes):
        cdef sf_count_t res
        # Use Fortran order to cope with interleaving
        cdef cnp.ndarray[cnp.float32_t, ndim=2] ty = np.empty((nframes, self.thisPtr.channels()),
                                                                dtype=np.float32, order='C')

        res = self.thisPtr.readf(<float*>PyArray_DATA(ty), nframes)
        if not res == nframes:
            raise RuntimeError("Asked %d frames, read %d" % (nframes, res))
        return ty

    cdef read_frames_int(self, sf_count_t nframes):
        cdef sf_count_t res
        # Use Fortran order to cope with interleaving
        cdef cnp.ndarray[cnp.int32_t, ndim=2] ty = np.empty((nframes, self.thisPtr.channels()),
                                                            dtype=np.int32, order='C')

        res = self.thisPtr.readf(<int*>PyArray_DATA(ty), nframes)
        if not res == nframes:
            raise RuntimeError("Asked %d frames, read %d" % (nframes, res))
        return ty

    cdef read_frames_short(self, sf_count_t nframes):
        cdef sf_count_t res
        # Use Fortran order to cope with interleaving
        cdef cnp.ndarray[cnp.int16_t, ndim=2] ty = np.empty((nframes, self.thisPtr.channels()),
                                                            dtype=np.short, order='C')

        res = self.thisPtr.readf(<short*>PyArray_DATA(ty), nframes)
        if not res == nframes:
            raise RuntimeError("Asked %d frames, read %d" % (nframes, res))
        return ty

    def write_frames(self, cnp.ndarray input):
        """
        write 1 or 2 dimensional array into sndfile.

        :param input: <numpy array>
               containing data to write.

        :return: int representing the number of frames that have been written

        *Notes*
          * One column per channel.
          * updates the write pointer.
          * if the input type is float, and the file encoding is an integer type,
            you should make sure the input data are normalized normalized data
            (that is in the range [-1..1] - which will corresponds to the maximum
            range allowed by the integer bitwidth).
        """
        cdef int nc
        cdef sf_count_t nframes

        if self.thisPtr == NULL or not self.thisPtr:
            raise RuntimeError("PySndfile::error::no valid soundfilehandle")
        
        # First, get the number of channels and frames from input
        if PyArray_NDIM(input) == 2:
            nc = PyArray_DIMS(input)[1]
            nframes = input.size / nc
        elif PyArray_NDIM(input) == 1:
            nc = 1
            input = input[:, None]
            nframes = input.size
        else:
            raise ValueError("PySndfile::write_frames::error cannot handle arrays of {0:d} dimensions, please restrict to  2 dimensions".format(PyArray_NDIM(input)))

        # Number of channels should be the one expected
        if not nc == self.thisPtr.channels():
            raise ValueError("Expected %d channels, got %d" %
                             (self.thisPtr.channels(), nc))

        input = np.require(input, requirements = 'C')

        if input.dtype == np.float64:
            if (self.thisPtr.format() & C_SF_FORMAT_SUBMASK) not in [C_SF_FORMAT_FLOAT, C_SF_FORMAT_DOUBLE]:
                if (np.max(np.abs(input.flat)) > 1.) :
                    warnings.warn("write_frames::warning::audio data has been clipped while writing to file {0}.".format(self.filename.decode("UTF-8")))
            res = self.thisPtr.writef(<double*>PyArray_DATA(input), nframes)
        elif input.dtype == np.float32:
            if (self.thisPtr.format() & C_SF_FORMAT_SUBMASK) not in [C_SF_FORMAT_FLOAT, C_SF_FORMAT_DOUBLE]:
                if (np.max(np.abs(input.flat)) > 1.) :
                    warnings.warn("write_frames::warning::audio data has been clipped while writing to file {0}.".format(self.filename.decode("UTF-8")))
            res = self.thisPtr.writef(<float*>PyArray_DATA(input), nframes)
        elif input.dtype == np.int32:
            res = self.thisPtr.writef(<int*>PyArray_DATA(input), nframes)
        elif input.dtype == np.short:
            res = self.thisPtr.writef(<short*>PyArray_DATA(input), nframes)
        else:
            raise RuntimeError("type of input {0} not understood".format(str(input.dtype)))

        if not(res == nframes):
            raise IOError("write_frames::error::wrote {0:d} frames, expected to write {1:d}".format(res, nframes))

        return res
    
    def format(self) :
        """
        :return: <int> raw format specification that was used to create the present PySndfile instance.
        """
        if self.thisPtr == NULL or not self.thisPtr:
            raise RuntimeError("PySndfile::error::no valid soundfilehandle")
        return self.thisPtr.format()

    def major_format_str(self) :
        """

        :return: short string representation of major format (e.g. aiff)

        see :py:func:`pysndfile.get_sndfile_formats` for a complete lst of fileformats

        """
        if self.thisPtr == NULL or not self.thisPtr:
            raise RuntimeError("PySndfile::error::no valid soundfilehandle")
        return fileformat_id_to_name[self.thisPtr.format() & C_SF_FORMAT_TYPEMASK]

    def encoding_str(self) :
        """
        :return:  string representation of encoding (e.g. pcm16)

        see :py:func:`pysndfile.get_sndfile_encodings` for a list of
        available encoding strings that are supported by a given sndfile format
        """
        if self.thisPtr == NULL or not self.thisPtr:
            raise RuntimeError("PySndfile::error::no valid soundfilehandle")
        return encoding_id_to_name[self.thisPtr.format() & C_SF_FORMAT_SUBMASK]

    def channels(self) :
        """
        :return: <int> number of channels of sndfile
        """
        if self.thisPtr == NULL or not self.thisPtr:
            raise RuntimeError("PySndfile::error::no valid soundfilehandle")
        return self.thisPtr.channels()

    def frames(self) :
        """
        :return: <int> number for frames (number of samples per channel)
        """
        if self.thisPtr == NULL or not self.thisPtr:
            raise RuntimeError("PySndfile::error::no valid soundfilehandle")
        return self.thisPtr.frames()

    def samplerate(self) :
        """
        :return: <int> samplerate
        """
        if self.thisPtr == NULL or not self.thisPtr:
            raise RuntimeError("PySndfile::error::no valid soundfilehandle")
        return self.thisPtr.samplerate()

    def seekable(self) :
        """
        :return: <bool> true for soundfiles that support seeking
        """
        if self.thisPtr == NULL or not self.thisPtr:
            raise RuntimeError("PySndfile::error::no valid soundfilehandle")
        return self.thisPtr.seekable()

    def get_strings(self) :
        """
        get all stringtypes from the sound file.
        
        see :py:data:`stringtype_name_to_id` for the list of strings that are supported
        by the libsndfile version you use.  
        
        """
        cdef const char* string_value
        if self.thisPtr == NULL or not self.thisPtr:
            raise RuntimeError("PySndfile::error::no valid soundfilehandle")

        str_dict = {}
        for ii  in xrange(C_SF_STR_FIRST, C_SF_STR_LAST):
            string_value = self.thisPtr.getString(ii)
            if string_value != NULL:
                str_dict[stringtype_id_to_name[ii]] = string_value
                
        return str_dict

    def set_string(self, stringtype_name, string) :
        """
        set one of the stringtype to the string given as argument.
        If you try to write a stringtype that is not supported by the library
        a RuntimeError will be raised
        If you try to write a string with length exceeding the length that 
        can be read by libsndfile version 1.0.28 a RuntimeError will be raised as well
        these limits are stored in the dict max_supported_string_length.        
        """
        cdef int res = 0
        
        if self.thisPtr == NULL or not self.thisPtr:
            raise RuntimeError("PySndfile::error::no valid soundfilehandle")
        if stringtype_name not in stringtype_name_to_id :
            raise RuntimeError("PySndfile::error::set_string called with an unsupported stringtype:{0}".format(stringtype_name))

        my_format = self.major_format_str()
        if my_format in max_supported_string_length :
            if len(string)> max_supported_string_length[my_format]:
                raise RuntimeError("pysndfile::set_string::your string to be written into {} has length {} exceeding the length of strings ({}) supported for reading in libsndfile 1.0.28".format(stringtype_name, len(string), max_supported_string_length[my_format]))
        res = self.thisPtr.setString(stringtype_name_to_id[stringtype_name], string)
        if res :
            raise RuntimeError("PySndfile::error::setting string of type {0}\nerror messge is:{1}".format(stringtype_name, sf_error_number(res)))

    def set_strings(self, sf_strings_dict) :
        """
        set all strings provided as key value pairs in sf_strings_dict.
        If you try to write a stringtype that is not  supported by the library
        a RuntimeError will be raised.
        If you try to write a string with length exceeding the length that 
        can be read by libsndfile version 1.0.28 a RuntimeError will be raised as well
        these limits are stored in the dict max_supported_string_length.
        """
        for kk in sf_strings_dict:
            self.set_string(kk, sf_strings_dict[kk])

    def get_cue_count(self):
        """
        get number of cue markers.


        """
        # get number of cue mrks that are present in the file

        res = self.thisPtr.get_cue_count()
        return res

    def get_cue_mrks(self) :
        """
        get all cue markers.

        Gets list of tuple of positions and related names of embedded markers for aiff and wav files,
        due to a limited support of cue names in libsndfile cue names are not retrieved for wav files.

        """
        # get number of cue mrks that are present in the file
        cdef SF_CUES sf_cues

        res = self.thisPtr.command(C_SFC_GET_CUE, &sf_cues, sizeof(sf_cues))
        if res == 0:
            return []

        mrks = []
        for ii in range(sf_cues.cue_count):
            mrks.append((sf_cues.cue_points[ii].sample_offset, sf_cues.cue_points[ii].name.decode("ASCII")))

        return mrks


    def error(self) :
        """
        report error numbers related to the current sound file
        """
        if self.thisPtr == NULL or not self.thisPtr:
            raise RuntimeError("PySndfile::error::no valid soundfilehandle")
        return self.thisPtr.error()
    def strError(self) :            
        """
        report error strings related  to the current sound file
        """
        if self.thisPtr == NULL or not self.thisPtr:
            raise RuntimeError("PySndfile::error::no valid soundfilehandle")
        return self.thisPtr.strError()

    def seek(self, sf_count_t offset, int whence=C_SEEK_SET, mode='rw'):
        """
        Seek into audio file: similar to python seek function, taking only in
        account audio data.

        :param offset: <int>
                the number of frames (eg two samples for stereo files) to move
                relatively to position set by whence.
        :param whence: <int>
                only 0 (beginning), 1 (current) and 2 (end of the file) are
                valid.
        :param mode:  <string>
                If set to 'rw', both read and write pointers are updated. If
                'r' is given, only read pointer is updated, if 'w', only the
                write one is (this may of course make sense only if you open
                the file in a certain mode).

        :return: <int>  the number of frames from the beginning of the file

        *Notes*

           * Offset relative to audio data: meta-data are ignored.

           * if an invalid seek is given (beyond or before the file), an IOError is
             raised; note that this is different from the seek method of a File object.
             
        """

        if self.thisPtr == NULL or not self.thisPtr:
            raise RuntimeError("PySndfile::error::no valid soundfilehandle")

        cdef sf_count_t pos
        if mode == 'rw':
            # Update both read and write pointers
            pos = self.thisPtr.seek(offset, whence)
        elif mode == 'r':
            whence = whence | C_SFM_READ
            pos = self.thisPtr.seek(offset, whence)
        elif mode == 'w':
            whence = whence | C_SFM_WRITE
            pos = self.thisPtr.seek(offset, whence)
        else:
            raise ValueError("mode should be one of 'r', 'w' or 'rw' only")

        if pos == -1:
            msg = "libsndfile error during seek:: {0}".format(self.thisPtr.strError())
            raise IOError(msg)
        return pos

    def rewind(self, mode="rw") :
        """\
        rewind read/write/read and write position given by mode to start of file
        """
        cdef sf_count_t pos
        cdef int whence = C_SEEK_SET     

        if self.thisPtr == NULL or not self.thisPtr:
            raise RuntimeError("PySndfile::error::no valid soundfilehandle")
       
        if mode == 'rw':
            # Update both read and write pointers
            pos = self.thisPtr.seek(0, whence)
        elif mode == 'r':
            whence = whence | C_SFM_READ
            pos = self.thisPtr.seek(0, whence)
        elif mode == 'w':
            whence = whence | C_SFM_WRITE
            pos = self.thisPtr.seek(0, whence)
        else:
            raise ValueError("mode should be one of 'r', 'w' or 'rw' only")

        if pos == -1:
            msg = "libsndfile error while rewinding:: {0}".format(self.thisPtr.strError())
            raise IOError(msg)
        return pos            

cdef _construct_format(major, encoding) :
    """
    construct a format specification for libsndfile from major format string and encoding string
    """
    cdef int major_id = fileformat_name_to_id[major]
    cdef int enc_id   = encoding_name_to_id[encoding]
    return  major_id | enc_id

def construct_format(major, encoding) :
    """
    construct a format specification for libsndfile from major format string and encoding string
    """
    return  _construct_format(major, encoding)

