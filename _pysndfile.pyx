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
# cython: language_level=2

import numpy as np
import warnings
import os
from dataclasses import dataclass
from typing import List

cimport numpy as cnp
from libcpp.string cimport string

cdef extern from "Python.h":
    ctypedef int Py_intptr_t
  
_pysndfile_version=(1, 5, 3)
def get_pysndfile_version():
    """
    return tuple describing the version of pysndfile
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

cdef extern from *:
    """
    #ifdef _WIN32
    #include <Windows.h>
    #define ENABLE_SNDFILE_WINDOWS_PROTOTYPES 1
    #endif
    """

from libc.stddef cimport wchar_t, size_t
ctypedef const wchar_t *LPCWSTR

cdef extern from "Python.h":
    wchar_t* PyUnicode_AsWideCharString(object, Py_ssize_t *) except NULL
    void PyMem_Free(void *p)

from libc.stdint cimport uint32_t, int16_t, uint64_t, int32_t, INT16_MIN, INT16_MAX, INT32_MIN, INT32_MAX
from libc.stdlib cimport free, malloc, calloc
from libc.string cimport strcpy, memchr, memset
from libc.limits cimport CHAR_MIN, CHAR_MAX
from libc.math cimport pow

# not in sndfile.h, but nested structs are not supported by Cython
cdef struct loop_t:
    int mode
    uint32_t start
    uint32_t end
    uint32_t count

cdef extern from "pysndfile.hh":
    ctypedef struct SF_FORMAT_INFO:
        int format
        char *name
        char *extension

    ctypedef cnp.int64_t sf_count_t

    struct SF_INFO:
        sf_count_t frames
        int samplerate
        int channels
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

    ctypedef struct SF_DITHER_INFO:
        int type
        double level
        const char* name

    ctypedef struct SF_EMBED_FILE_INFO:
        sf_count_t offset
        sf_count_t length

    ctypedef struct SF_INSTRUMENT:
        int gain
        char basenote
        char detune
        char velocity_lo
        char velocity_hi
        char key_lo
        char key_hi
        int loop_count
        loop_t loops[16]

    ctypedef struct SF_LOOP_INFO:
        short time_sig_num
        short time_sig_den
        int loop_mode
        int num_beats
        float bpm
        int root_key
        int future[6]

    # this matches the definition starting with libsndfile 1.0.29, but the
    # members that were not defined in 1.0.28 can't be used, while the old
    # definition would have a wrong size for the reserved member when using a
    # more recent version
    ctypedef struct SF_BROADCAST_INFO:
        char description[256]
        char originator[32]
        char originator_reference[32]
        char origination_date[10]
        char origination_time[8]
        uint32_t time_reference_low
        uint32_t time_reference_high
        short version
        char umid[64]
        int16_t loudness_value         # added in 1.0.29, offset 414
        int16_t loudness_range         # added in 1.0.29, offset 416
        int16_t max_true_peak_level    # added in 1.0.29, offset 418
        int16_t max_momentary_loudness # added in 1.0.29, offset 420
        int16_t max_shortterm_loudness # added in 1.0.29, offset 422
        char reserved[180]
        uint32_t coding_history_size
        char coding_history[256]

    ctypedef struct SF_CART_TIMER:
        char usage[4]
        int32_t value

    ctypedef struct SF_CART_INFO:
        char version[4]
        char title[64]
        char artist[64]
        char cut_id[64]
        char client_id[64]
        char category[64]
        char classification[64]
        char out_cue[64]
        char start_date[10]
        char start_time[8]
        char end_date[10]
        char end_time[8]
        char producer_app_id[64]
        char producer_app_version[64]
        char user_def[64]
        int32_t level_reference
        SF_CART_TIMER post_timers[8]
        char reserved[276]
        char url[1024]
        uint32_t tag_text_size
        char tag_text[256]

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
    cdef int C_SF_FORMAT_WVE "SF_FORMAT_WVE"     # /* Psion WVE format */
    cdef int C_SF_FORMAT_OGG "SF_FORMAT_OGG"     # /* Xiph OGG container */
    cdef int C_SF_FORMAT_MPCK "SF_FORMAT_MPC2K"  # /* Akai MPC 2000 sampler */
    cdef int C_SF_FORMAT_RF64 "SF_FORMAT_RF64"   # /* RF64 WAV file */

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

    cdef int C_SF_FORMAT_VORBIS "SF_FORMAT_VORBIS"    # /* Xiph Vorbis encoding. */

    cdef int C_SF_FORMAT_ALAC_16 "SF_FORMAT_ALAC_16" # /* Apple Lossless Audio Codec (16 bit). */
    cdef int C_SF_FORMAT_ALAC_20 "SF_FORMAT_ALAC_20" # /* Apple Lossless Audio Codec (20 bit). */
    cdef int C_SF_FORMAT_ALAC_24 "SF_FORMAT_ALAC_24" # /* Apple Lossless Audio Codec (24 bit). */
    cdef int C_SF_FORMAT_ALAC_32 "SF_FORMAT_ALAC_32" # /* Apple Lossless Audio Codec (32 bit). */


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
    cdef int C_SFC_GET_CURRENT_SF_INFO "SFC_GET_CURRENT_SF_INFO"

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
    cdef int C_SFC_SET_ADD_HEADER_PAD_CHUNK "SFC_SET_ADD_HEADER_PAD_CHUNK"

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
    cdef int C_SFC_SET_CUE "SFC_SET_CUE"

    cdef int C_SFC_GET_INSTRUMENT "SFC_GET_INSTRUMENT"  
    cdef int C_SFC_SET_INSTRUMENT "SFC_SET_INSTRUMENT"  

    cdef int C_SFC_GET_LOOP_INFO "SFC_GET_LOOP_INFO"  

    cdef int C_SFC_GET_BROADCAST_INFO "SFC_GET_BROADCAST_INFO"  
    cdef int C_SFC_SET_BROADCAST_INFO "SFC_SET_BROADCAST_INFO"  

    cdef int C_SFC_GET_CHANNEL_MAP_INFO "SFC_GET_CHANNEL_MAP_INFO"
    cdef int C_SFC_SET_CHANNEL_MAP_INFO "SFC_SET_CHANNEL_MAP_INFO"

    cdef int C_SFC_RAW_DATA_NEEDS_ENDSWAP "SFC_RAW_DATA_NEEDS_ENDSWAP"

    # /* Support for Wavex Ambisonics Format */
    cdef int C_SFC_WAVEX_SET_AMBISONIC "SFC_WAVEX_SET_AMBISONIC"
    cdef int C_SFC_WAVEX_GET_AMBISONIC "SFC_WAVEX_GET_AMBISONIC"

    # /*
    #  ** RF64 files can be set so that on-close, writable files that have less
    #  ** than 4GB of data in them are converted to RIFF/WAV, as per EBU
    #  ** recommendations.
    #  */
    cdef int C_SFC_RF64_AUTO_DOWNGRADE "SFC_RF64_AUTO_DOWNGRADE"

    cdef int C_SFC_SET_VBR_ENCODING_QUALITY "SFC_SET_VBR_ENCODING_QUALITY"
    cdef int C_SFC_SET_COMPRESSION_LEVEL "SFC_SET_COMPRESSION_LEVEL"

    # /* Cart Chunk support */
    cdef int C_SFC_SET_CART_INFO "SFC_SET_CART_INFO"
    cdef int C_SFC_GET_CART_INFO "SFC_GET_CART_INFO"

    # /* Following commands for testing only. */
    cdef int C_SFC_TEST_IEEE_FLOAT_REPLACE "SFC_TEST_IEEE_FLOAT_REPLACE"

    # /*
    #  ** These SFC_SET_ADD_* values are deprecated and will disappear at some
    #  ** time in the future. They are guaranteed to be here up to and
    #  ** including version 1.0.8 to avoid breakage of existing software.
    #  ** They currently do nothing and will continue to do nothing.
    #  */
    cdef int C_SFC_SET_ADD_DITHER_ON_WRITE "SFC_SET_ADD_DITHER_ON_WRITE"
    cdef int C_SFC_SET_ADD_DITHER_ON_READ "SFC_SET_ADD_DITHER_ON_READ"

    cdef int C_SF_STR_TITLE "SF_STR_TITLE"  
    cdef int C_SF_STR_COPYRIGHT "SF_STR_COPYRIGHT"  
    cdef int C_SF_STR_SOFTWARE "SF_STR_SOFTWARE"  
    cdef int C_SF_STR_ARTIST "SF_STR_ARTIST"  
    cdef int C_SF_STR_COMMENT "SF_STR_COMMENT"  
    cdef int C_SF_STR_DATE "SF_STR_DATE"  

    # these are the values retrieved from the header file. So we cannot
    # try to write/get strings that are not supported by the library we use.
    cdef int C_SF_STR_FIRST "SF_STR_FIRST"
    cdef int C_SF_STR_LAST  "SF_STR_LAST"
    
    cdef int C_SF_FALSE "SF_FALSE"  
    cdef int C_SF_TRUE "SF_TRUE"  

    #        /* Modes for opening files. */
    cdef int C_SFM_READ "SFM_READ"  
    cdef int C_SFM_WRITE "SFM_WRITE"  
    cdef int C_SFM_RDWR "SFM_RDWR"  

    cdef int C_SF_AMBISONIC_NONE "SF_AMBISONIC_NONE"
    cdef int C_SF_AMBISONIC_B_FORMAT "SF_AMBISONIC_B_FORMAT"

    cdef int C_SEEK_SET "SEEK_SET"  
    cdef int C_SEEK_CUR "SEEK_CUR"  
    cdef int C_SEEK_END "SEEK_END"  
    
    cdef int C_SF_ERR_NO_ERROR "SF_ERR_NO_ERROR"  
    cdef int C_SF_ERR_UNRECOGNISED_FORMAT "SF_ERR_UNRECOGNISED_FORMAT"  
    cdef int C_SF_ERR_SYSTEM "SF_ERR_SYSTEM"  
    cdef int C_SF_ERR_MALFORMED_FILE "SF_ERR_MALFORMED_FILE"  
    cdef int C_SF_ERR_UNSUPPORTED_ENCODING "SF_ERR_UNSUPPORTED_ENCODING"  
    
    cdef int C_SF_COUNT_MAX "SF_COUNT_MAX"  

    cdef int C_SF_LOOP_NONE "SF_LOOP_NONE"
    cdef int C_SF_LOOP_FORWARD "SF_LOOP_FORWARD"
    cdef int C_SF_LOOP_BACKWARD "SF_LOOP_BACKWARD"
    cdef int C_SF_LOOP_ALTERNATING "SF_LOOP_ALTERNATING"

    cdef int C_SF_CHANNEL_MAP_INVALID "SF_CHANNEL_MAP_INVALID"
    cdef int C_SF_CHANNEL_MAP_MONO "SF_CHANNEL_MAP_MONO"
    cdef int C_SF_CHANNEL_MAP_LEFT "SF_CHANNEL_MAP_LEFT" # /* Apple calls this 'Left' */
    cdef int C_SF_CHANNEL_MAP_RIGHT "SF_CHANNEL_MAP_RIGHT" # /* Apple calls this 'Right' */
    cdef int C_SF_CHANNEL_MAP_CENTER "SF_CHANNEL_MAP_CENTER" # /* Apple calls this 'Center' */
    cdef int C_SF_CHANNEL_MAP_FRONT_LEFT "SF_CHANNEL_MAP_FRONT_LEFT"
    cdef int C_SF_CHANNEL_MAP_FRONT_RIGHT "SF_CHANNEL_MAP_FRONT_RIGHT"
    cdef int C_SF_CHANNEL_MAP_FRONT_CENTER "SF_CHANNEL_MAP_FRONT_CENTER"
    cdef int C_SF_CHANNEL_MAP_REAR_CENTER "SF_CHANNEL_MAP_REAR_CENTER" # /* Apple calls this 'Center Surround', Msft calls this 'Back Center' */
    cdef int C_SF_CHANNEL_MAP_REAR_LEFT "SF_CHANNEL_MAP_REAR_LEFT" # /* Apple calls this 'Left Surround', Msft calls this 'Back Left' */
    cdef int C_SF_CHANNEL_MAP_REAR_RIGHT "SF_CHANNEL_MAP_REAR_RIGHT" # /* Apple calls this 'Right Surround', Msft calls this 'Back Right' */
    cdef int C_SF_CHANNEL_MAP_LFE "SF_CHANNEL_MAP_LFE" # /* Apple calls this 'LFEScreen', Msft calls this 'Low Frequency'  */
    cdef int C_SF_CHANNEL_MAP_FRONT_LEFT_OF_CENTER "SF_CHANNEL_MAP_FRONT_LEFT_OF_CENTER" # /* Apple calls this 'Left Center' */
    cdef int C_SF_CHANNEL_MAP_FRONT_RIGHT_OF_CENTER "SF_CHANNEL_MAP_FRONT_RIGHT_OF_CENTER" # /* Apple calls this 'Right Center */
    cdef int C_SF_CHANNEL_MAP_SIDE_LEFT "SF_CHANNEL_MAP_SIDE_LEFT" # /* Apple calls this 'Left Surround Direct' */
    cdef int C_SF_CHANNEL_MAP_SIDE_RIGHT "SF_CHANNEL_MAP_SIDE_RIGHT" # /* Apple calls this 'Right Surround Direct' */
    cdef int C_SF_CHANNEL_MAP_TOP_CENTER "SF_CHANNEL_MAP_TOP_CENTER" # /* Apple calls this 'Top Center Surround' */
    cdef int C_SF_CHANNEL_MAP_TOP_FRONT_LEFT "SF_CHANNEL_MAP_TOP_FRONT_LEFT" # /* Apple calls this 'Vertical Height Left' */
    cdef int C_SF_CHANNEL_MAP_TOP_FRONT_RIGHT "SF_CHANNEL_MAP_TOP_FRONT_RIGHT" # /* Apple calls this 'Vertical Height Right' */
    cdef int C_SF_CHANNEL_MAP_TOP_FRONT_CENTER "SF_CHANNEL_MAP_TOP_FRONT_CENTER" # /* Apple calls this 'Vertical Height Center' */
    cdef int C_SF_CHANNEL_MAP_TOP_REAR_LEFT "SF_CHANNEL_MAP_TOP_REAR_LEFT" # /* Apple and MS call this 'Top Back Left' */
    cdef int C_SF_CHANNEL_MAP_TOP_REAR_RIGHT "SF_CHANNEL_MAP_TOP_REAR_RIGHT" # /* Apple and MS call this 'Top Back Right' */
    cdef int C_SF_CHANNEL_MAP_TOP_REAR_CENTER "SF_CHANNEL_MAP_TOP_REAR_CENTER" # /* Apple and MS call this 'Top Back Center' */
    cdef int C_SF_CHANNEL_MAP_AMBISONIC_B_W "SF_CHANNEL_MAP_AMBISONIC_B_W"
    cdef int C_SF_CHANNEL_MAP_AMBISONIC_B_X "SF_CHANNEL_MAP_AMBISONIC_B_X"
    cdef int C_SF_CHANNEL_MAP_AMBISONIC_B_Y "SF_CHANNEL_MAP_AMBISONIC_B_Y"
    cdef int C_SF_CHANNEL_MAP_AMBISONIC_B_Z "SF_CHANNEL_MAP_AMBISONIC_B_Z"

    cdef cppclass SndfileHandle :
        SndfileHandle(const char *path, int mode, int format, int channels, int samplerate)
        SndfileHandle(const int fh, int close_desc, int mode, int format, int channels, int samplerate)

        # will only be used (and defined) on Windows, it is just a declaration
        # on other platforms
        SndfileHandle(LPCWSTR path, int mode, int format, int channels, int samplerate)
        sf_count_t frames()
        int format()
        int channels()
        int samplerate()
        int seekable()
        int error()
        char* strError()
        int command (int cmd, void *data, int datasize)
        int get_cue_count()
        sf_count_t seek (sf_count_t frames, int whence)
        void writeSync () 
        sf_count_t readf (short *ptr, sf_count_t items) 
        sf_count_t readf (int *ptr, sf_count_t items) 
        sf_count_t readf (float *ptr, sf_count_t items) 
        sf_count_t readf (double *ptr, sf_count_t items)
        sf_count_t writef (const short *ptr, sf_count_t items) 
        sf_count_t writef (const int *ptr, sf_count_t items) 
        sf_count_t writef (const float *ptr, sf_count_t items) 
        sf_count_t writef (const double *ptr, sf_count_t items)
        SNDFILE* rawHandle()
        int setString (int str_type, const char* str)
        const char* getString (int str_type)

# the following are defined with more recent versions of libsndfile (more recent
# than 1.0.28)
# to not break compilation they are defined outside sndfile.h

# formats
cdef int C_SF_FORMAT_MPEG = 0x230000 # should be "SF_FORMAT_MPEG" /* MPEG-1/2 audio stream */

# encodings
cdef int C_SF_FORMAT_NMS_ADPCM_16 = 0x0022 # should be "SF_FORMAT_NMS_ADPCM_16" /* 16kbs NMS G721-variant encoding. */
cdef int C_SF_FORMAT_NMS_ADPCM_24 = 0x0023 # should be "SF_FORMAT_NMS_ADPCM_24" /* 24kbs NMS G721-variant encoding. */
cdef int C_SF_FORMAT_NMS_ADPCM_32 = 0x0024 # should be "SF_FORMAT_NMS_ADPCM_32" /* 32kbs NMS G721-variant encoding. */

cdef int C_SF_FORMAT_OPUS = 0x0064 # should be "SF_FORMAT_OPUS" /* Xiph/Skype Opus encoding. */
cdef int C_SF_FORMAT_MPEG_LAYER_I = 0x0080 # should be "SF_FORMAT_MPEG_LAYER_I" /* MPEG-1 Audio Layer I */
cdef int C_SF_FORMAT_MPEG_LAYER_II = 0x0081 # should be "SF_FORMAT_MPEG_LAYER_II" /* MPEG-1 Audio Layer II */
cdef int C_SF_FORMAT_MPEG_LAYER_III = 0x0082 # should be "SF_FORMAT_MPEG_LAYER_III" /* MPEG-2 Audio Layer III */

# Ogg format commands
cdef int C_SFC_SET_OGG_PAGE_LATENCY_MS = 0x1302 # should be "SFC_SET_OGG_PAGE_LATENCY_MS"
cdef int C_SFC_SET_OGG_PAGE_LATENCY = 0x1303 # should be "SFC_SET_OGG_PAGE_LATENCY"
cdef int C_SFC_GET_OGG_STREAM_SERIALNO = 0x1306 # should be "SFC_GET_OGG_STREAM_SERIALNO"

# MPEG bitrate commands
cdef int C_SFC_GET_BITRATE_MODE = 0x1304 # should be "SFC_GET_BITRATE_MODE"
cdef int C_SFC_SET_BITRATE_MODE = 0x1305 # should be "SFC_SET_BITRATE_MODE"

# Opus files original samplerate metadata
cdef int C_SFC_SET_ORIGINAL_SAMPLERATE = 0x1500 # should be "SFC_SET_ORIGINAL_SAMPLERATE"
cdef int C_SFC_GET_ORIGINAL_SAMPLERATE = 0x1501 # should be "SFC_GET_ORIGINAL_SAMPLERATE"

# string types
cdef int C_SF_STR_ALBUM = 0x07
cdef int C_SF_STR_LICENSE = 0x08
cdef int C_SF_STR_TRACKNUMBER = 0x09
cdef int C_SF_STR_GENRE = 0x10

# Bitrate mode values (for use with SFC_GET/SET_BITRATE_MODE)
cdef int C_SF_BITRATE_MODE_CONSTANT = 0 # should be "SF_BITRATE_MODE_CONSTANT"
cdef int C_SF_BITRATE_MODE_AVERAGE = 1 # should be "SF_BITRATE_MODE_AVERAGE"
cdef int C_SF_BITRATE_MODE_VARIABLE = 2 # should "SF_BITRATE_MODE_VARIABLE"

# end of constants defined outside sndfile.h for compatibilty

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

    ('nms_adpcm_16', C_SF_FORMAT_NMS_ADPCM_16),
    ('nms_adpcm_24', C_SF_FORMAT_NMS_ADPCM_24),
    ('nms_adpcm_32', C_SF_FORMAT_NMS_ADPCM_32),

    ('g721_32'   , C_SF_FORMAT_G721_32),
    ('g723_24'   , C_SF_FORMAT_G723_24),
    ('g723_40'   , C_SF_FORMAT_G723_40),

    ('dww12' , C_SF_FORMAT_DWVW_12),
    ('dww16' , C_SF_FORMAT_DWVW_16),
    ('dww24' , C_SF_FORMAT_DWVW_24),
    ('dwwN'  , C_SF_FORMAT_DWVW_N),

    ('dpcm8' , C_SF_FORMAT_DPCM_8),
    ('dpcm16', C_SF_FORMAT_DPCM_16),

    ('vorbis', C_SF_FORMAT_VORBIS),
    ('opus', C_SF_FORMAT_OPUS),

    ('alac16', C_SF_FORMAT_ALAC_16),
    ('alac20', C_SF_FORMAT_ALAC_20),
    ('alac24', C_SF_FORMAT_ALAC_24),
    ('alac32', C_SF_FORMAT_ALAC_32),

    ('mpeg1', C_SF_FORMAT_MPEG_LAYER_I),
    ('mpeg2', C_SF_FORMAT_MPEG_LAYER_II),
    ('mp3', C_SF_FORMAT_MPEG_LAYER_III)
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
    ('wve'  , C_SF_FORMAT_WVE),
    ('ogg'  , C_SF_FORMAT_OGG),
    ('mpck'  , C_SF_FORMAT_MPCK),
    ('rf64'  , C_SF_FORMAT_RF64),
    ('mpeg'  , C_SF_FORMAT_MPEG)
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
    ("SFC_GET_CURRENT_SF_INFO", C_SFC_GET_CURRENT_SF_INFO),
    
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
    ("SFC_SET_ADD_HEADER_PAD_CHUNK", C_SFC_SET_ADD_HEADER_PAD_CHUNK),

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

    ("SFC_GET_CUE_COUNT", C_SFC_GET_CUE_COUNT),
    ("SFC_GET_CUE", C_SFC_GET_CUE),
    ("SFC_SET_CUE", C_SFC_SET_CUE),

    ("SFC_GET_INSTRUMENT" , C_SFC_GET_INSTRUMENT),
    ("SFC_SET_INSTRUMENT" , C_SFC_SET_INSTRUMENT),

    ("SFC_GET_LOOP_INFO", C_SFC_GET_LOOP_INFO),

    ("SFC_GET_BROADCAST_INFO", C_SFC_GET_BROADCAST_INFO),
    ("SFC_SET_BROADCAST_INFO", C_SFC_SET_BROADCAST_INFO),

    ("SFC_GET_CHANNEL_MAP_INFO", C_SFC_GET_CHANNEL_MAP_INFO),
    ("SFC_SET_CHANNEL_MAP_INFO", C_SFC_SET_CHANNEL_MAP_INFO),

    ("SFC_RAW_DATA_NEEDS_ENDSWAP", C_SFC_RAW_DATA_NEEDS_ENDSWAP),

    ("SFC_WAVEX_SET_AMBISONIC", C_SFC_WAVEX_SET_AMBISONIC),
    ("SFC_WAVEX_GET_AMBISONIC", C_SFC_WAVEX_GET_AMBISONIC),
    ("SFC_RF64_AUTO_DOWNGRADE", C_SFC_RF64_AUTO_DOWNGRADE),

    ("SFC_SET_VBR_ENCODING_QUALITY", C_SFC_SET_VBR_ENCODING_QUALITY),
    ("SFC_SET_COMPRESSION_LEVEL", C_SFC_SET_COMPRESSION_LEVEL),

    ("SFC_SET_CART_INFO", C_SFC_SET_CART_INFO),
    ("SFC_GET_CART_INFO", C_SFC_GET_CART_INFO),

    ("SFC_SET_OGG_PAGE_LATENCY_MS", C_SFC_SET_OGG_PAGE_LATENCY_MS),
    ("SFC_SET_OGG_PAGE_LATENCY", C_SFC_SET_OGG_PAGE_LATENCY),
    ("SFC_GET_OGG_STREAM_SERIALNO", C_SFC_GET_OGG_STREAM_SERIALNO),

    ("SFC_GET_BITRATE_MODE", C_SFC_GET_BITRATE_MODE),
    ("SFC_SET_BITRATE_MODE", C_SFC_SET_BITRATE_MODE),

    ("SFC_SET_ORIGINAL_SAMPLERATE", C_SFC_SET_ORIGINAL_SAMPLERATE),
    ("SFC_GET_ORIGINAL_SAMPLERATE", C_SFC_GET_ORIGINAL_SAMPLERATE),

    ("SFC_TEST_IEEE_FLOAT_REPLACE", C_SFC_TEST_IEEE_FLOAT_REPLACE),

    ("SFC_SET_ADD_DITHER_ON_WRITE", C_SFC_SET_ADD_DITHER_ON_WRITE),
    ("SFC_SET_ADD_DITHER_ON_READ", C_SFC_SET_ADD_DITHER_ON_READ)
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

# loop modes for instrument
_loop_to_id_tuple = (
    ("SF_LOOP_NONE", C_SF_LOOP_NONE),
    ("SF_LOOP_FORWARD", C_SF_LOOP_FORWARD),
    ("SF_LOOP_BACKWARD", C_SF_LOOP_BACKWARD),
    ("SF_LOOP_ALTERNATING", C_SF_LOOP_ALTERNATING)
    )

loop_name_to_id = dict(_loop_to_id_tuple)
"""dict: mapping of instrument loop names to libsndfile's loop mode ids.

   these names are used in the :py:attr:`SfInstrument.mode` attrbute of the
   :py:attr:`SfInstrument.loop` list in the :py:class:`SfInstrument` object
   passed to the SFC_SET_INSTRUMENT command or returned by the
   SFC_GET_INSTRUMENT, and in the :py:attr:`SfLoopInfo.loop_mode` attribute
   returned by the SFC_GET_LOOP_INFO command
   command
"""
loop_id_to_name = dict([(id, name) for name, id in _loop_to_id_tuple])
"""dict: mapping of libsndfile's instsrument loop mode ids to loop mode names.

   these names are used in the :py:attr:`SfInstrument.mode` attrbute of the
   :py:attr:`SfInstrument.loop` in the :py:class:`SfInstrument` object passed
   to the SFC_SET_INSTRUMENT command or returned by the SFC_GET_INSTRUMENT
   command
"""

_channel_map_to_id_tuple = (
    ("SF_CHANNEL_MAP_INVALID", C_SF_CHANNEL_MAP_INVALID),
    ("SF_CHANNEL_MAP_MONO", C_SF_CHANNEL_MAP_MONO),
    ("SF_CHANNEL_MAP_LEFT", C_SF_CHANNEL_MAP_LEFT),
    ("SF_CHANNEL_MAP_RIGHT", C_SF_CHANNEL_MAP_RIGHT),
    ("SF_CHANNEL_MAP_CENTER", C_SF_CHANNEL_MAP_CENTER),
    ("SF_CHANNEL_MAP_FRONT_LEFT", C_SF_CHANNEL_MAP_FRONT_LEFT),
    ("SF_CHANNEL_MAP_FRONT_RIGHT", C_SF_CHANNEL_MAP_FRONT_RIGHT),
    ("SF_CHANNEL_MAP_FRONT_CENTER", C_SF_CHANNEL_MAP_FRONT_CENTER),
    ("SF_CHANNEL_MAP_REAR_CENTER", C_SF_CHANNEL_MAP_REAR_CENTER),
    ("SF_CHANNEL_MAP_REAR_LEFT", C_SF_CHANNEL_MAP_REAR_LEFT),
    ("SF_CHANNEL_MAP_REAR_RIGHT", C_SF_CHANNEL_MAP_REAR_RIGHT),
    ("SF_CHANNEL_MAP_LFE", C_SF_CHANNEL_MAP_LFE),
    ("SF_CHANNEL_MAP_FRONT_LEFT_OF_CENTER", C_SF_CHANNEL_MAP_FRONT_LEFT_OF_CENTER),
    ("SF_CHANNEL_MAP_FRONT_RIGHT_OF_CENTER", C_SF_CHANNEL_MAP_FRONT_RIGHT_OF_CENTER),
    ("SF_CHANNEL_MAP_SIDE_LEFT", C_SF_CHANNEL_MAP_SIDE_LEFT),
    ("SF_CHANNEL_MAP_SIDE_RIGHT", C_SF_CHANNEL_MAP_SIDE_RIGHT),
    ("SF_CHANNEL_MAP_TOP_CENTER", C_SF_CHANNEL_MAP_TOP_CENTER),
    ("SF_CHANNEL_MAP_TOP_FRONT_LEFT", C_SF_CHANNEL_MAP_TOP_FRONT_LEFT),
    ("SF_CHANNEL_MAP_TOP_FRONT_RIGHT", C_SF_CHANNEL_MAP_TOP_FRONT_RIGHT),
    ("SF_CHANNEL_MAP_TOP_FRONT_CENTER", C_SF_CHANNEL_MAP_TOP_FRONT_CENTER),
    ("SF_CHANNEL_MAP_TOP_REAR_LEFT", C_SF_CHANNEL_MAP_TOP_REAR_LEFT),
    ("SF_CHANNEL_MAP_TOP_REAR_RIGHT", C_SF_CHANNEL_MAP_TOP_REAR_RIGHT),
    ("SF_CHANNEL_MAP_TOP_REAR_CENTER", C_SF_CHANNEL_MAP_TOP_REAR_CENTER),
    ("SF_CHANNEL_MAP_AMBISONIC_B_W", C_SF_CHANNEL_MAP_AMBISONIC_B_W),
    ("SF_CHANNEL_MAP_AMBISONIC_B_X", C_SF_CHANNEL_MAP_AMBISONIC_B_X),
    ("SF_CHANNEL_MAP_AMBISONIC_B_Y", C_SF_CHANNEL_MAP_AMBISONIC_B_Y),
    ("SF_CHANNEL_MAP_AMBISONIC_B_Z", C_SF_CHANNEL_MAP_AMBISONIC_B_Z)
    )

channel_map_name_to_id = dict(_channel_map_to_id_tuple)
"""dict: mapping of channel map names to libsndfile's channel map values.

   these names are passed to the SFC_SET_CHANNEL_MAP_INFO command and returned
   by the SFC_GET_CHANNEL_MAP_INFO command
"""
channel_map_id_to_name = dict([(id, name) for name, id in _channel_map_to_id_tuple])
"""dict: mapping of libsndfile's channel map values to channel map names.

   these names are passed to the SFC_SET_CHANNEL_MAP_INFO command and returned
   by the SFC_GET_CHANNEL_MAP_INFO command
"""

_ambisonic_to_id_tuple = (
    ("SF_AMBISONIC_NONE", C_SF_AMBISONIC_NONE),
    ("SF_AMBISONIC_B_FORMAT", C_SF_AMBISONIC_B_FORMAT)
    )

ambisonic_name_to_id = dict(_ambisonic_to_id_tuple)
"""dict: mapping of ambisonic format names to libsndfile's ambisonic format ids.

   these names are passed to the SFC_WAVEX_SET_AMBISONIC command and returned
   by the SFC_WAVEX_GET_AMBISONIC command
"""
ambisonic_id_to_name = dict([(id, name) for name, id in _ambisonic_to_id_tuple])
"""dict: mapping of libsndfile's ambisonic format ids to ambisonic format names.

   these names are passed to the SFC_WAVEX_SET_AMBISONIC command and returned
   by the SFC_WAVEX_GET_AMBISONIC command
"""

_bitrate_mode_to_id_tuple = (
    ("SF_BITRATE_MODE_CONSTANT", C_SF_BITRATE_MODE_CONSTANT),
    ("SF_BITRATE_MODE_AVERAGE", C_SF_BITRATE_MODE_AVERAGE),
    ("SF_BITRATE_MODE_VARIABLE", C_SF_BITRATE_MODE_VARIABLE)
    )

bitrate_mode_name_to_id = dict(_bitrate_mode_to_id_tuple)
"""dict: mapping of bitrate mode names to libsndfile's bitrate mode ids.

   these names are passed to the SFC_SET_BITRATE_MODE command and returned by
   the SFC_GET_BITRATE_MODE command
"""
bitrate_mode_id_to_name = dict([(id, name) for name, id in _bitrate_mode_to_id_tuple])
"""dict: mapping of libsndfile's bitrate mode ids to bitrate mode names.
"""

@dataclass
class SfInfo:
    """Description of the current file's format.

    Returned by the SFC_GET_CURRENT_SF_INFO command (see the libsndfile
    documentation for sf_open and the SF_INFO structure for more information)
    """
    frames: int
    samplerate: int
    channels: int
    format: int
    sections: int
    seekable: int

@dataclass
class SfFormatInfo:
    """Information about supported file formats.

    Returned by the SFC_GET_SIMPLE_FORMAT, SFC_GET_FORMAT_MAJOR,
    SFC_GET_FORMAT_SUBTYPE and SFC_GET_FORMAT_INFO commands (see the
    libsndfile documentation for these commands and the SF_FORMAT_INFO struct
    for more information)
    """
    format: int
    name: str
    extension: str

@dataclass
class SfDitherInfo:
    """Dither information.

    Passed to the SFC_SET_DITHER_ON_WRITE and SFC_SET_DITHER_ON_READ commands
    and returned by the SFC_GET_DITHER_INFO (see the libsndfile documentation
    for these commands and the SF_DITHER_INFO struct for more
    information)
    """
    type: int
    level: float
    name: str

@dataclass
class SfEmbedFileInfo:
    """Information about an embedded file.

    Returned by the SFC_GET_EMBED_FILE_INFO command (see the libsndfile
    documentation for this command and the SF_EMBED_FILE_INFO struct for more
    information)
    """
    offset: int
    length: int

@dataclass
class SfCuePoint:
    """Cue marker information.

    A list of these is passed to the SFC_SET_CUE command and returned by the
    SFC_SET_CUE command (see the libsndfile documentation for these commands
    and the SF_CUE_POINT struct for more information)
    """
    indx: int
    position: int
    fcc_chunk: int
    chunk_start: int
    block_start: int
    sample_offset: int
    name: str

@dataclass
class SfInstrumentLoop:
    """Information about a loop of an instrument.

    The :py:attr:`mode` value is one of the keys in :py:data:`loop_name_to_id`.
    A list of these is in :py:attr:`SfInstrument.loops` attribute (see the
    libsndfile documentation for the SFC_GET_INSTRUMENT and SFC_SET_INSTRUMENT
    commands and the anonymous nested struct in the SF_INSTRUMENT struct for
    more information)
    """
    mode: str
    start: int
    end: int
    count: int

@dataclass
class SfInstrument:
    """Instrument information.

    Passed to the SFC_SET_INSTRUMENT command and returned by the
    SFC_GET_INSTRUMENT command (see the libsndfile documentation for these
    commands and the SF_INSTRUMENT struct for more information)
    """
    gain: int
    basenote: int
    detune: int
    velocity_lo: int
    velocity_hi: int
    key_lo: int
    key_hi: int
    loops: List[SfInstrumentLoop]

@dataclass
class SfLoopInfo:
    """Loop information.

    The :py:attr:`loop_mode` value is one of the keys in
    :py:data:`loop_name_to_id`.
    Returned by the SFC_GET_LOOP_INFO command (see the libsndfile documentation
    for this command and the SF_LOOP_INFO struct for more information)
    """
    time_sig_num: int
    time_seg_den: int
    loop_mode: str
    num_beats: int
    bpm: float
    root_key: int
    future: List[int]

@dataclass
class SfBroadcastInfo:
    """Broadcast (EBU) information.

    Passed to the SFC_SET_BROADCAST_INFO command and returned by the
    SFC_GET_BROADCAST_INFO command (see the libsndfile documentation for these
    commands and the SF_BROADCAST_INFO struct for more information)
    """
    description: str
    originator: str
    originator_reference: str
    origination_date: str
    origination_time: str
    time_reference: int
    version: int
    umid: bytes
    loudness_value: int
    loudness_range: int
    max_true_peak_level: int
    max_momentary_loudness: int
    max_shortterm_loudness: int
    coding_history: str

@dataclass
class SfCartTimer:
    """Timer information in a :py:SfCartInfo.

    A list of these is in the :py:attr:`SfCartInfo.post_timers` attribute
    """
    usage: str
    value: int

@dataclass
class SfCartInfo:
    """Traffic data information (Cart chunk, see http://www.cartchunk.org/).

    Passed to the SFC_SET_CART_INFO command and returned by the
    SFC_GET_CART_INFO command (see the libsndfile documentation for this command
    and the SF_CART_INFO struct for more information)
    """
    version: str
    title: str
    artist: str
    cut_id: str
    client_id: str
    category: str
    classification: str
    out_cue: str
    start_date: str
    start_time: str
    end_date: str
    end_time: str
    producer_app_id: str
    producer_app_version: str
    user_def: str
    level_reference: int
    post_timers: List[SfCartTimer]
    url: str
    tag_text: str

def _raise_command_retcode_error(ret, command):
    """Format and raise a :py:class:`RuntimeError` from a retcode.

    :param ret: retcode returned by sf_command
    :type ret: int
    :param command: the id of the command
    :type command: int
    :return: not applicable
    :raises RuntimeError: always
    """
    raise RuntimeError("PySndfile::error:: command {0} failed with error {1}".format(commands_id_to_name[command], sf_error_number(ret)))

def _check_command_retcode(ret, command):
    """Checks a retcode.

    :param ret: retcode returned by sf_command
    :type ret: int
    :param command: the id of the command
    :type command: int
    :return: None
    :rtype: None
    :raises RuntimeError: if ret indicates failure
    """
    if ret != C_SF_ERR_NO_ERROR:
        _raise_command_retcode_error(ret, command)

def _check_command_retval(ret, command, failure):
    """Checks a return value against a failure code.

    :param ret: return value sf_command
    :type ret: int
    :param command: the id of the command
    :type command: int
    :param failure: value that indicates failure
    :type failure: int
    :return: ret
    :rtype: int
    :raises RuntimeError: if ret is equal to failure
    """
    if ret == failure:
        raise RuntimeError("PySndfile::error:: command {0} failed".format(commands_id_to_name[command]))
    return ret

# special case for some commands that can return a mix of boolean and codes
def _check_command_hybrid_retval(ret, command):
    """Checks return value as both a boolean and retcode.

    :param ret: return value of sf_command
    :type ret: int
    :param command: the id of the command
    :type command: int
    :return: None
    :rtype: None
    :raises RuntimeError: if ret is false or not true and indicates failure
    """
    _check_command_retval(ret, command, C_SF_FALSE)
    if ret != C_SF_TRUE:
        _raise_command_retcode_error(ret, command)

def _check_char_range(value, command, field):
    """Checks that a python value fits in a C char variable.

    :param value: python value
    :type value: int
    :param command: the id of the command
    :type command: int
    :param field: the name of the python attribute
    :type field: str
    :return: value
    :rtype: int
    :raises RuntimeError: if value is outside the representable range of char
    """
    if value < CHAR_MIN or value > CHAR_MAX:
        raise RuntimeError("PySndfile::error:: command {0} argument {1} value {2} is out of range".format(commands_id_to_name[command], field, value))
    return value

def _check_int16_range(value, command, field):
    """Checks that a python value fits in a C int16_t variable.

    :param value: python value
    :type value: int
    :param command: the id of the command
    :type command: int
    :param field: the name of the python attribute
    :type field: str
    :return: value
    :rtype: int
    :raises RuntimeError: if value is outside the representable range of int16_t
    """
    if value < INT16_MIN or value > INT16_MAX:
        raise RuntimeError("PySndfile::error:: command {0} argument {1} value {2} is out of range {3}-{4}".format(commands_id_to_name[command], field, value, INT16_MIN, INT16_MAX))
    return value

def _check_int32_range(value, command, field):
    """Checks that a python value fits in a C int32_t variable.

    :param value: python value
    :type value: int
    :param command: the id of the command
    :type command: int
    :param field: the name of the python attribute
    :type field: str
    :return: value
    :rtype: int
    :raises RuntimeError: if value is outside the representable range of int32_t
    """
    if value < INT32_MIN or value > INT32_MAX:
        raise RuntimeError("PySndfile::error:: command {0} argument {1} value {2} is out of range {3}-{4}".format(commands_id_to_name[command], field, value, INT32_MIN, INT32_MAX))
    return value

cdef int _assign_string_field(char* dst, value, int max_length, command, field):
    """Copy a string to a null-terminated C char array

    :param dst: destination character array
    :type dst: char*
    :param value: string to be copied
    :type value: str or convertible to str
    :param max_length: maximum length of destination string (not including 0)
    :type max_length: int
    :param command: the id of the command
    :type command: int
    :param field: name of the struct member (for error message)
    :type field: str
    :return: the length of the string
    :raises RuntimeError: if the value length exceeds max_length
    """
    cdef int length
    if value:
        tmp_str = value.encode("UTF-8")
        length = len(tmp_str)
        if length > max_length:
            raise RuntimeError("PySndfile::error:: {0} is too long ({1}) in {2}, maximum length is {3}".format(field, length, commands_id_to_name[command], max_length))
        strcpy(dst, tmp_str)
        return length
    else:
        dst[0] = 0;
        return 0

cdef str _read_from_char_field(char* src, int size):
    """Create a string from a character array (assumes UTF-8 encoding)

    :param src: C characted array (terminating 0 is not required)
    :type src: char*
    :param size: size of source character array
    :type size: int
    :returns: unicode string (the src character array is interpreted as UTF-8)
    :rtype: str
    """
    cdef char* zero = <char*>memchr(src, 0, size)
    if zero:
        size = zero - src
    return src[:size].decode("UTF-8")

cdef int _assign_char_field(char* dst, value, int max_length, command, field):
    """Copy a string to a character array (only 0-terminated if it fits)

    :param dst: destination C character array
    :type dst: char*
    :param value: string to be copied
    :type value: str
    :param max_length: size of dst
    :type max_length: int
    :param command: the id of the command
    :type command: int
    :param field: name of the struct member (for error message)
    :returns: length of UTF-8 encoded value
    :rtype: int
    """
    cdef int length
    if value:
        tmp_str = value.encode("UTF-8")
        length = len(tmp_str)
        if length > max_length:
            raise RuntimeError("PySndfile::error:: {0} is too long ({1}) in {2}, maximum length is {3}".format(field, length, commands_id_to_name[command], max_length))
        for si in range(length):
            dst[si] = tmp_str[si]
    else:
        length = 0
    if length < max_length:
        dst[length] = 0
    return length

# some members of SF_BROADCAST_INFO were not defined in libsndfile 1.0.28
# they latter were (1.0.29) introduced in the first bytes of the reserved member
cdef int16_t _read_new_broadcast_member(SF_BROADCAST_INFO* info,
                                        int offset):
    """Read a member of broadcast info that was not defined in version 1.0.28

    :param info: source struct
    :type info: :c:struct:`SF_BROADCAST_INFO`*
    :param offset: offset of value in info
    :type offset: int
    :returns: value at offset info info
    :rtype: 16-bit signed integer
    """
    return (<int16_t*>(<char*>info + offset))[0]

cdef void _write_new_broadcast_member(SF_BROADCAST_INFO* info, int offset,
                                      int16_t value):
    """Write to a member of broadcast info that was not defined in version 1.0.28

    :param info: destination struct
    :type info: SF_BROADCAST_INFO*
    :param offset: offset of value in info
    :type offset: int
    :param value: value to be written into info
    :type value: int
    :returns: None
    :rtype: None
    """
    (<int16_t*>(<char*>info + offset))[0] = value

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

# a convoluted way to have Windows-specific code for file names, now that the
# Cython IF construct is deprecated and slated for removal
cdef extern from *:
    """
    #ifdef _WIN32
    #define PySndfile_filename_type wchar_t*
    #define PySndfile_convert_filename(self_filename, filename) PyUnicode_AsWideCharString((filename), NULL)
    #define PySndfile_free_filename(filename) PyMem_Free(filename)
    #else
    #define PySndfile_filename_type const char*
    #define PySndfile_convert_filename(self_filename, filename) (self_filename.c_str())
    #define PySndfile_free_filename(filename)
    #endif
    """

    ctypedef char* filename_type "PySndfile_filename_type"
    cdef filename_type convert_filename "PySndfile_convert_filename" (const string& self_filename, object filename)
    cdef void free_filename "PySndfile_free_filename" (filename_type filename)
    
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

        cdef filename_type filename_for_ctor

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

            if isinstance(filename, unicode):
                tmp_filename = bytes(filename, "UTF-8")
            else:
                tmp_filename = filename
            self.filename = tmp_filename

            # on Windows, the original filename must be converted to wchar_t,
            # not the one converted to utf-8
            filename_for_ctor = convert_filename(self.filename, filename)

            # this should only happen on Windows
            if filename_for_ctor == NULL:
                raise RuntimeError("PySndfile::error while converting {0} into wchars".format(filename))

            self.thisPtr = new SndfileHandle(filename_for_ctor, sfmode, format, channels, samplerate)
            free_filename(filename_for_ctor)
            

        if self.thisPtr == NULL or self.thisPtr.rawHandle() == NULL:
            raise IOError("PySndfile::error while opening {0}\n\t->{1}".format(self.filename,
                                                                                   self.thisPtr.strError()))

        self.set_auto_clipping(True)

    # supoort use as context manager
    def __enter__(self):
        return self

    def __exit__(self, *args):
        self.close()

    def get_name(self):
        """
        :return: <str> filename that was used to open the underlying sndfile
        """
        return self.filename

    def __dealloc__(self):
        self.close()

    def close(self):
        """
        Closes file and deallocates internal structures
        """
        if self.thisPtr != NULL and self.thisPtr:
            del self.thisPtr
            self.thisPtr = NULL

    def command(self, command, arg=0) :
        """
        interface for passing commands via sf_command to underlying soundfile
        using sf_command(this_sndfile, command_id, NULL, arg)

        The argument (if any) and return value depend of the command, here are
        the details (refer to the libsndfile documentation for more information)

        SFC_GET_LIB_VERSION(None) -> str
        SFC_GET_LOG_INFO(None) -> str
        SFC_GET_CURRENT_SF_INFO(None) -> :py:class:`SfInfo`
        SFC_GET_NORM_DOUBLE(None) -> bool
        SFC_GET_NORM_FLOAT(None) -> bool
        SFC_SET_NORM_DOUBLE(bool) -> bool
        SFC_SET_NORM_FLOAT(bool) -> bool
        SFC_SET_SCALE_FLOAT_INT_READ(bool) -> bool
        SFC_SET_SCALE_INT_FLOAT_WRITE(bool) -> bool
        SFC_GET_SIMPLE_FORMAT_COUNT(None) -> int
        SFC_GET_SIMPLE_FORMAT(int) -> :py:class:`SfFormatInfo`
        SFC_GET_FORMAT_INFO(int) -> :py:class:`SfFormatInfo`
        SFC_GET_FORMAT_MAJOR_COUNT(None) -> int
        SFC_GET_FORMAT_MAJOR(int) -> :pt:type:`SfFormatInfo`
        SFC_GET_FORMAT_SUBTYPE_COUNT(None) -> int
        SFC_GET_FORMAT_SUBTYPE(int) -> :py:class:`SfFormatInfo`
        SFC_CALC_SIGNAL_MAX(None) -> float
        SFC_CALC_NORM_SIGNAL_MAX(None) -> float
        SFC_CALC_MAX_ALL_CHANNELS(None) -> :py:class:`numpy.ndarray(numpy.float64)`
        SFC_CALC_NORM_MAX_ALL_CHANNELS(None) -> :py:class:`numpy.ndarray(numpy.float64)`
        SFC_GET_SIGNAL_MAX(None) -> float or None
        SFC_GET_MAX_ALL_CHANNELS(None) -> :py:class:`numpy.ndarray(numpy.float64)` or None
        SFC_SET_ADD_PEAK_CHUNK(bool) -> bool
        SFC_SET_ADD_HEADER_PAD_CHUNK(bool) -> bool
        SFC_UPDATE_HEADER_NOW(None) -> None
        SFC_SET_UPDATE_HEADER_AUTO(bool) -> bool
        SFC_FILE_TRUNCATE(int) -> None
        SFC_SET_RAW_START_OFFSET(int) -> None
        SFC_SET_DITHER_ON_WRITE(:py:class:`SfDitherInfo`) -> None
        SFC_SET_DITHER_ON_READ(:py:class:`SfDitherInfo`) -> None
        SFC_GET_DITHER_INFO_COUNT(None) -> int
        SFC_GET_DITHER_INFO(None) -> :py:class:`SfDitherInfo`
        SFC_GET_EMBED_FILE_INFO(None) -> :py:class:`SfEmbedFileInfo`
        SFC_SET_CLIPPING(bool) -> bool
        SFC_GET_CLIPPING(None) -> bool
        SFC_GET_CUE_COUNT(None) -> int
        SFC_GET_CUE(None) -> [:py:class:`SfCuePoint`]
        SFC_SET_CUE([SfCuePoint]) -> None
        SFC_GET_INSTRUMENT(None) -> :py:class:`SfInstrument` or None
        SFC_SET_INSTRUMENT(:py:class:`SfInstrument`) -> None
        SFC_GET_LOOP_INFO(None) -> :py:class:`SfLoopInfo`
        SFC_GET_BROADCAST_INFO(None) -> :py:class:`SfBroadcastInfo` or None
        SFC_SET_BROADCAST_INFO(:py:class:`SfBroadcastInfo`) -> None
        SFC_GET_CHANNEL_MAP_INFO(None) -> [str]
        SFC_SET_CHANNEL_MAP_INFO([str]) -> None
        SFC_RAW_DATA_NEEDS_ENDSWAP(None) -> bool
        SFC_WAVEX_SET_AMBISONIC(str) -> None
        SFC_WAVEX_GET_AMBISONIC(None) -> str
        SFC_RF64_AUTO_DOWNGRADE(bool) -> bool
        SFC_SET_VBR_ENCODING_QUALITY(float) -> None
        SFC_SET_COMPRESSION_LEVEL(float) -> None
        SFC_SET_CART_INFO(:py:class:`SfCartInfo`) -> None
        SFC_GET_CART_INFO(None) -> :py:class:`SfCartInfo` or None
        SFC_SET_OGG_PAGE_LATENCY_MS(float) -> None
        SFC_SET_OGG_PAGE_LATENCY(float) -> None
        SFC_GET_OGG_STREAM_SERIALNO(None) -> int
        SFC_GET_BITRATE_MODE(None) -> str
        SFC_SET_BITRATE_MODE(str) -> None
        SFC_SET_ORIGINAL_SAMPLERATE(int) -> None
        SFC_GET_ORIGINAL_SAMPLERATE(None) -> int
        SFC_TEST_IEEE_FLOAT_REPLACE(bool) -> None
        SFC_SET_ADD_DITHER_ON_WRITE(None) -> None
        SFC_SET_ADD_DITHER_ON_READ(None) -> None

        :param command: libsndfile command macro to be used. They can be specified either as string using the command macros name, or the command id.
        :type command: string or int
        :param arg: argument to the command
        :type arg: depends on the command (see above)
        :returns: depends on the command (see above)
        :raises RuntimeError: if arg is invalid or if libsndfile reports failure
        """
        if isinstance(command, str) :
            return self.command(commands_name_to_id[command], arg)

        if command in [C_SFC_GET_LIB_VERSION, C_SFC_GET_SIMPLE_FORMAT_COUNT,
                       C_SFC_GET_SIMPLE_FORMAT, C_SFC_GET_FORMAT_INFO,
                       C_SFC_GET_FORMAT_MAJOR_COUNT, C_SFC_GET_FORMAT_MAJOR,
                       C_SFC_GET_FORMAT_SUBTYPE_COUNT,
                       C_SFC_GET_FORMAT_SUBTYPE]:
            null_handle = True
        else:
            if (self.thisPtr == NULL) or not self.thisPtr:
                raise RuntimeError("PySndfile::error::no valid soundfilehandle")
            null_handle = False

        if command == C_SFC_GET_LIB_VERSION or command == C_SFC_GET_LOG_INFO:
            return self._string_out_command(command, null_handle)
        if command == C_SFC_GET_CURRENT_SF_INFO:
            return self._get_current_sf_info()
        if command in [C_SFC_GET_NORM_DOUBLE, C_SFC_GET_NORM_FLOAT,
                       C_SFC_GET_CLIPPING, C_SFC_RAW_DATA_NEEDS_ENDSWAP]:
            return self.thisPtr.command(command, NULL, 0)
        if command == C_SFC_UPDATE_HEADER_NOW:
            self.thisPtr.command(command, NULL, 0)
            return None
        if command in [C_SFC_SET_NORM_DOUBLE, C_SFC_SET_NORM_FLOAT,
                       C_SFC_SET_SCALE_FLOAT_INT_READ,
                       C_SFC_SET_SCALE_INT_FLOAT_WRITE,
                       C_SFC_SET_ADD_PEAK_CHUNK, C_SFC_SET_UPDATE_HEADER_AUTO,
                       C_SFC_SET_CLIPPING, C_SFC_RF64_AUTO_DOWNGRADE,
                       C_SFC_TEST_IEEE_FLOAT_REPLACE,
                       C_SFC_SET_ADD_HEADER_PAD_CHUNK]:
            return self._bool_set_command(
                command, arg,
                command in [C_SFC_SET_ADD_PEAK_CHUNK,
                            C_SFC_SET_UPDATE_HEADER_AUTO, C_SFC_SET_CLIPPING,
                            C_SFC_RF64_AUTO_DOWNGRADE,
                            C_SFC_SET_ADD_HEADER_PAD_CHUNK],
                command == C_SFC_TEST_IEEE_FLOAT_REPLACE)
        if command in [C_SFC_GET_SIMPLE_FORMAT_COUNT,
                       C_SFC_GET_FORMAT_MAJOR_COUNT,
                       C_SFC_GET_FORMAT_SUBTYPE_COUNT,
                       C_SFC_GET_ORIGINAL_SAMPLERATE,
                       C_SFC_GET_DITHER_INFO_COUNT]:
            return self._int_get_command(
                command, null_handle, command == C_SFC_GET_ORIGINAL_SAMPLERATE)
        if command in [C_SFC_GET_SIMPLE_FORMAT, C_SFC_GET_FORMAT_MAJOR,
                       C_SFC_GET_FORMAT_SUBTYPE, C_SFC_GET_FORMAT_INFO]:
            return self._format_get_command(command, arg)
        if command in [C_SFC_CALC_SIGNAL_MAX, C_SFC_CALC_NORM_SIGNAL_MAX,
                       C_SFC_GET_SIGNAL_MAX]:
            return self._double_get_command(command,
                                            command == C_SFC_GET_SIGNAL_MAX)
        if command in [C_SFC_CALC_MAX_ALL_CHANNELS,
                       C_SFC_CALC_NORM_MAX_ALL_CHANNELS,
                       C_SFC_GET_MAX_ALL_CHANNELS]:
            return self._double_channel_get_command(
                command, command == C_SFC_GET_MAX_ALL_CHANNELS)
        if command in [C_SFC_FILE_TRUNCATE, C_SFC_SET_RAW_START_OFFSET]:
            return self._sf_count_set_command(
                command, arg, command == C_SFC_SET_RAW_START_OFFSET)
        if command == C_SFC_GET_EMBED_FILE_INFO:
            return self._embed_get_command(command)
        if command == C_SFC_GET_CUE_COUNT:
            return self._uint32_get_command(command)
        if command == C_SFC_GET_CUE:
            return self._cue_get_command(command)
        if command == C_SFC_SET_CUE:
            return self._cue_set_command(command, arg)
        if command == C_SFC_GET_INSTRUMENT:
            return self._instrument_get_command(command)
        if command == C_SFC_SET_INSTRUMENT:
            return self._instrument_set_command(command, arg)
        if command == C_SFC_GET_LOOP_INFO:
            return self._loop_get_command(command)
        if command == C_SFC_GET_BROADCAST_INFO:
            return self._broadcast_get_command(command)
        if command == C_SFC_SET_BROADCAST_INFO:
            return self._broadcast_set_command(command, arg)
        if command == C_SFC_GET_CHANNEL_MAP_INFO:
            return self._channel_map_get_command(command)
        if command == C_SFC_SET_CHANNEL_MAP_INFO:
            return self._channel_map_set_command(command, arg)
        if command == C_SFC_WAVEX_SET_AMBISONIC:
            _check_command_retval(
                self.thisPtr.command(command, NULL, ambisonic_name_to_id[arg]),
                command, C_SF_FALSE)
            return None
        if command == C_SFC_WAVEX_GET_AMBISONIC:
            return ambisonic_id_to_name[
                _check_command_retval(self.thisPtr.command(command, NULL, 0),
                                      command, C_SF_FALSE)]
        if command in [C_SFC_SET_VBR_ENCODING_QUALITY,
                       C_SFC_SET_COMPRESSION_LEVEL]:
            self._double_set_command(command, arg, [0., 1.], True)
            return None
        if command in [C_SFC_SET_OGG_PAGE_LATENCY_MS,
                       C_SFC_SET_OGG_PAGE_LATENCY]:
            self._double_set_command(command, arg, [50., 1600.], False)
            return None
        if command == C_SFC_GET_OGG_STREAM_SERIALNO:
            return self._int32_get_command(command)
        if command == C_SFC_GET_BITRATE_MODE:
            return bitrate_mode_id_to_name[
                _check_command_retval(self.thisPtr.command(command, NULL, 0),
                                      command, -1)]
        if command == C_SFC_SET_BITRATE_MODE:
            return self._bitrate_set_command(command, arg)
        if command == C_SFC_SET_CART_INFO:
            return self._cart_set_command(command, arg)
        if command == C_SFC_GET_CART_INFO:
            return self._cart_get_command(command)
        if command == C_SFC_SET_ORIGINAL_SAMPLERATE:
            return self._int_set_command(command, arg)
        if command in [C_SFC_SET_ADD_DITHER_ON_WRITE,
                       C_SFC_SET_ADD_DITHER_ON_READ]:
            _check_command_retcode(self.thisPtr.command(command, NULL, 0),
                                   command)
            return None
        # not documented but maybe implemented in 1.2.2
        if command in [C_SFC_SET_DITHER_ON_WRITE, C_SFC_SET_DITHER_ON_READ]:
            return self._dither_set_command(command, arg)
        # not documented or implemented in 1.2.2
        if command == C_SFC_GET_DITHER_INFO:
            return self._dither_get_command(command)

        raise RuntimeError("PySndfile::error::unknow command {0}".format(command))

    def set_compression_level(self, level:float):
        """
        Set the compression level for the file. The level should be between 0 and 1.
        with 1. indicating maximal compression and 0 minimal compression.

        :param level: <int> compression level

        :return: <int> 1 for success, 0 for failure
        """
        if (self.thisPtr == NULL) or not self.thisPtr:
            raise RuntimeError("PySndfile::error::no valid soundfilehandle")
        
        if level < 0 or level > 1:
            raise ValueError("PySndfile::error::compression level should be between 0 and 1")
        cdef double d_level = <double> level
        cdef double* d_ptr = &d_level
        cdef size_t d_size = sizeof(double)
        return self.thisPtr.command(C_SFC_SET_COMPRESSION_LEVEL, d_ptr, d_size)

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


    def read_frames(self, sf_count_t nframes=-1, dtype=np.float64, force_2d = False, fill_value=None, min_read=0):
        """
        Read the given number of frames and put the data into a numpy array of
        the requested dtype.

        :param nframes: number of frames to read (default = -1 -> read all).
        :type nframes: int
        :param dtype: data type of the returned array containing read data (see note).
        :type dtype: numpy.dtype
        :param force_2d: always return 2D arrays even if file is mono
        :type force_2d: bool
        :param fill_value: value to use for filling frames in case nframes is larger than the file
        :type fill_value: any tye that can be assigned to an array containing dtype
        :param min_read: when fill_value is not None and EOFError will be thrown when the number
                 of read sample frames is equal to or lower than this value
        :return: np.array<dtype> with sound data

        *Notes*
        
          * One column per channel.

        """
        if self.thisPtr == NULL or not self.thisPtr:
            raise RuntimeError("PySndfile::error::no valid soundfilehandle")

        if nframes < 0 :
            whence = C_SEEK_CUR | C_SFM_READ
            pos = self.thisPtr.seek(0, whence)
            nframes = self.thisPtr.frames() - pos
        if dtype == np.float64:
            y = self.read_frames_double(nframes, fill_value=fill_value, min_read=min_read)
        elif dtype == np.float32:
            y = self.read_frames_float(nframes, fill_value=fill_value, min_read=min_read)
        elif dtype == np.int32:
            y = self.read_frames_int(nframes, fill_value=fill_value, min_read=min_read)
        elif dtype == np.int16:
            y = self.read_frames_short(nframes, fill_value=fill_value, min_read=min_read)
        else:
            raise RuntimeError("Sorry, dtype %s not supported" % str(dtype))

        if y.shape[1] == 1 and not force_2d:
            y.shape = (y.shape[0],)
        return y

    cdef read_frames_double(self, sf_count_t nframes, fill_value=None, min_read=0):
        cdef sf_count_t res
        cdef cnp.ndarray[cnp.float64_t, ndim=2] ty = np.empty((nframes, self.thisPtr.channels()),
                                                                dtype=np.float64, order='C')

        res = self.thisPtr.readf(<double*> PyArray_DATA(ty), nframes)
        if not res == nframes:
            if fill_value is None:
                raise RuntimeError("Asked %d frames, read %d" % (nframes, res))
            elif res <= min_read:
                raise EOFError()
            else:
                ty[res:,:] = fill_value
        return ty

    cdef read_frames_float(self, sf_count_t nframes, fill_value=None, min_read=0):
        cdef sf_count_t res
        # Use C order to cope with interleaving
        cdef cnp.ndarray[cnp.float32_t, ndim=2] ty = np.empty((nframes, self.thisPtr.channels()),
                                                                dtype=np.float32, order='C')

        res = self.thisPtr.readf(<float*>PyArray_DATA(ty), nframes)
        if not res == nframes:
            if fill_value is None:
                raise RuntimeError("Asked %d frames, read %d" % (nframes, res))
            elif res <= min_read:
                raise EOFError()
            else:
                ty[res:,:] = fill_value
        return ty

    cdef read_frames_int(self, sf_count_t nframes, fill_value=None, min_read=0):
        cdef sf_count_t res
        # Use C order to cope with interleaving
        cdef cnp.ndarray[cnp.int32_t, ndim=2] ty = np.empty((nframes, self.thisPtr.channels()),
                                                            dtype=np.int32, order='C')

        res = self.thisPtr.readf(<int*>PyArray_DATA(ty), nframes)
        if not res == nframes:
            if fill_value is None:
                raise RuntimeError("Asked %d frames, read %d" % (nframes, res))
            elif res <= min_read:
                raise EOFError()
            else:
                ty[res:,:] = fill_value
        return ty

    cdef read_frames_short(self, sf_count_t nframes, fill_value=None, min_read=0):
        cdef sf_count_t res
        # Use C order to cope with interleaving
        cdef cnp.ndarray[cnp.int16_t, ndim=2] ty = np.empty((nframes, self.thisPtr.channels()),
                                                            dtype=np.short, order='C')

        res = self.thisPtr.readf(<short*>PyArray_DATA(ty), nframes)
        if res < nframes:
            if fill_value is None:
                raise RuntimeError("Asked %d frames, read %d" % (nframes, res))
            elif res <= min_read:
                raise EOFError()
            else:
                ty[res:,:] = fill_value
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
                if (input.size > 0 and np.max(np.abs(input.flat)) > 1.) :
                    warnings.warn("write_frames::warning::audio data has been clipped while writing to file {0}.".format(self.filename.decode("UTF-8")))
            res = self.thisPtr.writef(<double*>PyArray_DATA(input), nframes)
        elif input.dtype == np.float32:
            if (self.thisPtr.format() & C_SF_FORMAT_SUBMASK) not in [C_SF_FORMAT_FLOAT, C_SF_FORMAT_DOUBLE]:
                if (input.size > 0 and np.max(np.abs(input.flat)) > 1.) :
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

    def _string_out_command(self, command, null_handle):
        """Calls a libsndfile command returning a string

        :param command: the command id
        :type command: int
        :param null_handle: True if the command does not required an open file
        :type null_handle: bool
        :return: the unicode string (from a buffer interpreted as UTF-8)
        :rtype: str
        """
        # string buffer, returns string size (not needed)
        cdef char buf[2048]
        buf[0] = 0
        if null_handle:
            ret = sf_command(NULL, command, buf, sizeof(buf))
        else:
            ret = self.thisPtr.command(command, buf, sizeof(buf))
        return buf.decode("UTF-8")

    def _get_current_sf_info(self):
        """Retrieves format information about the current file

        :returns: description of the file format
        :rtype: :py:class:`SfInfo`
        """
        cdef SF_INFO info
        memset(&info, 0, sizeof(SF_INFO))
        retcode = self.thisPtr.command(C_SFC_GET_CURRENT_SF_INFO, &info,
                                       sizeof(info))
        _check_command_retcode(retcode, C_SFC_GET_CURRENT_SF_INFO)
        return SfInfo(frames = info.frames, samplerate = info.samplerate,
                      channels = info.channels, format = info.format,
                      sections = info.sections, seekable = info.seekable)

    def _bool_set_command(self, command, arg, compare_return, check_retcode):
        """Calls a libsndfile command expecting a boolean argument

        :param command: the command id
        :type command: int
        :param arg: the argument
        :type arg: bool
        :param compare_return: whether the command returns the new value
        :type compare_return: bool
        :param check_retcode: whether the command returns an error code
        :returns: previous or current value or None depending on the command
        :rtype: bool or None
        :raises RuntimeError: if arg is not a boolean, if the command failed or it if the current value is not equal to arg
        """
        if arg != C_SF_FALSE and arg != C_SF_TRUE:
            raise RuntimeError("PySndfile::error:: command {0} argument {1} should be {2} or {3}".format(commands_id_to_name[command], arg, C_SF_FALSE, C_SF_TRUE))
        cdef int tmp_arg = <int> arg
        cdef int ret = self.thisPtr.command(command, NULL, tmp_arg)
        if check_retcode:
            _check_command_retcode(ret, command)
            return None
        if compare_return and ret != tmp_arg:  
            raise RuntimeError("PySndfile::error:: command {0} failed with current value {1} while it should be set to {2}".format(commands_id_to_name[command], ret, arg))
        return ret

    def _int_get_command(self, command, null_handle, return_is_hybrid):
        """Retrieves an integer value

        :param command: the command id
        :type command: int
        :param null_handle: True if the command does not required an open file
        :type null_handle: bool
        :param return_is_hybrid: True if a SF_TRUE return value means success
        :type return_is_hybrid: bool
        :returns: the integer value
        :rtype: int
        :raises RuntimeError: if the command failed
        """
        cdef int tmp_int = 0
        cdef int ret
        if null_handle:
            ret = sf_command(NULL, command, &tmp_int, sizeof(int))
        else:
            ret = self.thisPtr.command(command, &tmp_int, sizeof(int))
        if return_is_hybrid:
            _check_command_hybrid_retval(ret, command)
        else:
            _check_command_retcode(ret, command)
        return tmp_int

    def _format_get_command(self, command, arg):
        """Retrieves information about a file format

        :param command: the command id
        :type command: int
        :param arg: index or id of the format
        :type arg: int
        :returns: :py:class:`SfFormatInfo`
        :raises RuntimeError: if the index or id is invalid
        """
        cdef SF_FORMAT_INFO tmp_info
        memset(&tmp_info, 0, sizeof(SF_FORMAT_INFO))
        tmp_info.format = <int> arg
        cdef int retcode
        retcode = sf_command(NULL, command, &tmp_info, sizeof(SF_FORMAT_INFO))
        _check_command_retcode(retcode, command)
        ret = SfFormatInfo(format = tmp_info.format, name = None,
                           extension = None)
        if tmp_info.name != NULL:
            ret.name = bytes(tmp_info.name).decode("UTF-8")
        if tmp_info.extension != NULL:
            ret.extension = bytes(tmp_info.extension).decode("UTF-8")
        return ret

    def _double_get_command(self, command, is_optional):
        """Retrieves a floating point value

        :param command: the command id
        :type command: int
        :param is_optional: if False the value is expected to exist
        :type is_optional: bool
        :returns: either the requested value or None if optional and absent
        :rtype: float or None
        :raises RuntimeError: if the command failed or if the value is missing and is_optional is False
        """
        cdef double tmp_double = 0.
        cdef int ret = self.thisPtr.command(command, &tmp_double,
                                            sizeof(double))
        if is_optional:
            if ret == C_SF_FALSE:
                return None
        else:
            _check_command_retcode(ret, command)
        return tmp_double

    def _double_channel_get_command(self, command, is_optional):
        """Retrieves values for each channel

        :param command: the command id
        :type command: int
        :param is_optional: if False the value is expected to exist
        :type is_optional: bool
        :returns: either the requested values or None if optional and absent
        :rtype: list[float] or None
        :raises RuntimeError: if the command failed or if the value is missing and is_optional is False
        """
        nc = self.thisPtr.channels()
        cdef cnp.ndarray[cnp.float64_t, ndim=1] ret = np.zeros(nc,
                                                               dtype=np.float64,
                                                               order='C')
        cdef int retcode = self.thisPtr.command(command,
                                                <double*>PyArray_DATA(ret),
                                                nc * sizeof(double))
        if is_optional:
            if retcode == C_SF_FALSE:
                return None
        else:
            _check_command_retcode(retcode, command)
        return ret

    def _double_set_command(self, command, arg, valid_range, return_is_hybrid):
        """Sets a floating point value within a range

        :param command: the command id
        :type command: int
        :param arg: the floating point value
        :type arg: float
        :param valid_range: a list of two values, minimum and maximum
        :param return_is_hybrid: True if a SF_TRUE return value means success
        :type return_is_hybrid: bool
        :returns: None
        :rtype: None
        :raises RuntimeError: if arg is not with the valid range or if libsnfile reports an error
        """
        cdef double tmp_double = arg
        if tmp_double < valid_range[0] or tmp_double > valid_range[1]:
            raise RuntimeError("PySndfile::error:: value {0} not in range {1}-{2} for command {3}".format(arg, valid_range[0], valid_range[1], commands_id_to_name[command]))

        cdef int ret = self.thisPtr.command(command, &tmp_double,
                                            sizeof(double))
        if return_is_hybrid:
            _check_command_hybrid_retval(ret, command)
        else:
            _check_command_retcode(ret, command)
        return None

    def _sf_count_set_command(self, command, arg, is_retcode):
        """sets a size value

        :param command: the command id
        :type command: int
        :param arg: a non negative integer value
        :type arg: int
        :param is_retcode: if True the command returns an error code, otherwise a non-zero value indicates an unspecified failure
        :type is_retcode: bool
        :returns: None
        :rtype: None
        :raises RuntimeError: if arg is negative or if libsndfile reports failure
        """
        if arg < 0:
            raise RuntimeError("PySndfile::error:: argument to command {0} must not be negative ({1} provided)".format(commands_id_to_name[command], arg))
        cdef sf_count_t tmp_arg = <sf_count_t> arg
        cdef int ret
        ret = self.thisPtr.command(command, &tmp_arg, sizeof(sf_count_t))
        if is_retcode:
            _check_command_retcode(ret, command)
        else:
            if ret != 0:
                raise RuntimeError("PySndfile::error:: command {0} failed".format(commands_id_to_name[command]))
            else:
                _check_command_retcode(self.thisPtr.error(), command)
        return None

    def _dither_set_command(self, command, arg):
        """Sets dither information

        :param command: the command id
        :type command: int
        :param arg: dither information
        :type arg: :py:class:`SfDitherInfo`
        :returns: None
        :rtype: None
        :raises RuntimeError: if libsndfile reports failure
        """
        cdef SF_DITHER_INFO tmp_info
        tmp_info.type = arg.type
        tmp_info.level = arg.level
        tmp_name = arg.name.encode("UTF-8")
        tmp_info.name = tmp_name
        ret = self.thisPtr.command(command, &tmp_info, sizeof(SF_DITHER_INFO))
        _check_command_retcode(ret, command)
        return None

    def _dither_get_command(self, command):
        """Retrieves dither information

        :param command: the command id
        :type command: int
        :returns: dither information
        :rtype: :py:class:`SfDitherInfo`
        :raises RuntimeError: if libsndfile reports failure
        """
        cdef SF_DITHER_INFO tmp_info
        memset(&tmp_info, 0, sizeof(SF_DITHER_INFO))
        retcode = self.thisPtr.command(command, &tmp_info,
                                       sizeof(SF_DITHER_INFO))
        _check_command_retcode(retcode, command)
        ret = SfDitherInfo(type = tmp_info.type, level = tmp_info.level,
                            name = None)
        if tmp_info.name != NULL:
            ret.name = bytes(tmp_info.name).decode("UTF-8")
        return ret

    def _embed_get_command(self, command):
        """Retrieves information about embedded files

        :param command: the command id
        :type command: int
        :returns: offset and length of embedded file
        :rtype: py:class:`SfEmbedFileInfo`
        :raises RuntimeError: if libsndfile reports failure
        """
        cdef SF_EMBED_FILE_INFO tmp_info
        memset(&tmp_info, 0, sizeof(SF_EMBED_FILE_INFO))
        retcode = self.thisPtr.command(command, &tmp_info,
                                       sizeof(SF_EMBED_FILE_INFO))
        _check_command_retcode(retcode, command)
        return SfEmbedFileInfo(offset = tmp_info.offset,
                               length = tmp_info.length)

    def _uint32_get_command(self, command):
        """Retrieves an unsigned integer value

        :param command: the command id
        :type command: int
        :returns: the unsigned value
        :rtype: int
        """
        cdef uint32_t ret = 0
        retcode = self.thisPtr.command(command, &ret, sizeof(uint32_t))
        if retcode == C_SF_FALSE:
            ret = 0
        return ret

    def _cue_get_command(self, command):
        """Retrieves cue markers

        :param command: the command id
        :type command: int
        :returns: the list of cue points
        :rtype: list[:py:class:`SfCuePoint`]
        """
        cdef SF_CUES tmp_cues
        cdef SF_CUES* cue_ptr = NULL
        cdef int cue_size
        cdef uint32_t cue_count
        retcode = self.thisPtr.command(C_SFC_GET_CUE_COUNT, &cue_count,
                                       sizeof(uint32_t))
        if retcode == C_SF_FALSE:
            return []
        ret = []
        try:
            if cue_count > 100:
                cue_size = sizeof(SF_CUES) \
                           + (cue_count - 100) * sizeof(SF_CUE_POINT)
                cue_ptr = <SF_CUES*>calloc(1, cue_size)
            else:
                memset(&tmp_cues, 0, sizeof(SF_CUES))
                cue_ptr = &tmp_cues
                cue_size = sizeof(SF_CUES)
            retcode = self.thisPtr.command(command, cue_ptr, cue_size)
            if retcode == C_SF_TRUE:
                for ci in range(cue_ptr.cue_count):
                    ret.append(SfCuePoint(
                        indx = cue_ptr.cue_points[ci].indx,
                        position = cue_ptr.cue_points[ci].position,
                        fcc_chunk = cue_ptr.cue_points[ci].fcc_chunk,
                        chunk_start = cue_ptr.cue_points[ci].chunk_start,
                        block_start = cue_ptr.cue_points[ci].block_start,
                        sample_offset = cue_ptr.cue_points[ci].sample_offset,
                        name = cue_ptr.cue_points[ci].name.decode("UTF-8")))
        finally:
            if cue_size != sizeof(SF_CUES):
                free(cue_ptr)
        return ret
            
    def _cue_set_command(self, command, arg):
        """Set cue markers

        :param command: the command id
        :type command: int
        :param arg: the list of cue points
        :type arg: list[:py:class:`SfCuePoint`]
        :returns: None
        :rtype: None
        :raises RuntimeError: if libsndfile reports failure
        """
        cdef SF_CUES tmp_cues
        cdef SF_CUES* cue_ptr = NULL
        cdef int cue_size
        tmp_cues.cue_count = len(arg)
        try:
            if tmp_cues.cue_count > 100:
                cue_size = sizeof(SF_CUES) \
                           + (tmp_cues.cue_count - 100) * sizeof(SF_CUE_POINT)
                cue_ptr = <SF_CUES*>malloc(cue_size)
                cue_ptr.cue_count = tmp_cues.cue_count
            else:
                cue_ptr = &tmp_cues
                cue_size = sizeof(SF_CUES)
            for ci in range(cue_ptr.cue_count):
                cue_ptr.cue_points[ci].indx = arg[ci].indx
                cue_ptr.cue_points[ci].position = arg[ci].position
                cue_ptr.cue_points[ci].fcc_chunk = arg[ci].fcc_chunk
                cue_ptr.cue_points[ci].chunk_start = arg[ci].chunk_start
                cue_ptr.cue_points[ci].block_start = arg[ci].block_start
                cue_ptr.cue_points[ci].sample_offset = arg[ci].sample_offset
                _assign_string_field(cue_ptr.cue_points[ci].name, arg[ci].name,
                                     255, command, "name")
            retcode = self.thisPtr.command(command, cue_ptr, cue_size)
            _check_command_retval(retcode, command, C_SF_FALSE)
        finally:
            if cue_size != sizeof(SF_CUES):
                free(cue_ptr)
        return None

    def _instrument_get_command(self, command):
        """Retrieves instrument information

        :param command: the command id
        :type command: int
        :returns: instrument information or None
        :rtype: :py:class:SfInstrument or None
        """
        cdef SF_INSTRUMENT tmp_inst
        memset(&tmp_inst, 0, sizeof(SF_INSTRUMENT))
        retcode = self.thisPtr.command(command, &tmp_inst,
                                       sizeof(SF_INSTRUMENT))
        if retcode == C_SF_TRUE:
            ret = SfInstrument(gain = tmp_inst.gain,
                               basenote = tmp_inst.basenote,
                               detune = tmp_inst.detune,
                               velocity_lo = tmp_inst.velocity_lo,
                               velocity_hi = tmp_inst.velocity_hi,
                               key_lo = tmp_inst.key_lo,
                               key_hi = tmp_inst.key_hi, loops = [])
            for li in range(tmp_inst.loop_count):
                ret.loops.append(SfInstrumentLoop(
                    mode = loop_id_to_name[tmp_inst.loops[li].mode], 
                    start = tmp_inst.loops[li].start,
                    end = tmp_inst.loops[li].end, 
                    count = tmp_inst.loops[li].count))
            return ret
        else:
            return None

    def _instrument_set_command(self, command, arg):
        """Sets instrument information

        :param command: the command id
        :type command: int
        :param arg: instrument definition
        :type arg: SfInstrument
        :returns: None
        :rtype: None
        :raises RuntimeError: if more than 16 loops are defined or if libsndfile reports failure
        """
        cdef SF_INSTRUMENT tmp_inst
        tmp_inst.loop_count = len(arg.loops)
        if tmp_inst.loop_count > 16:
            raise RuntimeError("PySndfile::error:: too many loops ({0}) in {1}, maximum is 16".format(tmp_inst.loop_count, command))
        tmp_inst.gain = arg.gain
        tmp_inst.basenote = _check_char_range(arg.basenote, command, "basenote")
        tmp_inst.detune = _check_char_range(arg.detune, command, "detune")
        tmp_inst.velocity_lo = _check_char_range(arg.velocity_lo, command,
                                                 "velocity_lo")
        tmp_inst.velocity_hi = _check_char_range(arg.velocity_hi, command,
                                                 "velocity_hi")
        tmp_inst.key_lo = _check_char_range(arg.key_lo, command, "key_lo")
        tmp_inst.key_hi = _check_char_range(arg.key_hi, command, "key_hi")
        for li in range(tmp_inst.loop_count):
            if arg.loops[li].mode not in loop_name_to_id:
                raise RuntimeError("PySndfile::error:: unknow loop mode ({0}) in {1}".format(arg.loops[li].mode, command))
            tmp_inst.loops[li].mode = loop_name_to_id[arg.loops[li].mode]
            tmp_inst.loops[li].start = arg.loops[li].start
            tmp_inst.loops[li].end = arg.loops[li].end
            tmp_inst.loops[li].count = arg.loops[li].count
        retcode = self.thisPtr.command(command, &tmp_inst,
                                       sizeof(SF_INSTRUMENT))
        _check_command_retval(retcode, command, C_SF_FALSE)
        return None
        
    def _loop_get_command(self, command):
        """Retrieves loop information

        :param command: the command id
        :type command: int
        :returns: loop information or None
        :rtype: :py:class:`SfLoopInfo` or None
        """
        cdef SF_LOOP_INFO tmp_loop
        memset(&tmp_loop, 0, sizeof(SF_LOOP_INFO))
        retcode = self.thisPtr.command(command, &tmp_loop, sizeof(SF_LOOP_INFO))
        if retcode == C_SF_TRUE:
            ret = SfLoopInfo(time_sig_num = tmp_loop.time_sig_num,
                             time_sig_den = tmp_loop.time_sig_den,
                             loop_mode = loop_id_to_name[tmp_loop.loop_mode],
                             num_beats = tmp_loop.num_beats, bpm = tmp_loop.bpm,
                             root_key = tmp_loop.root_key, future = [])
            for fi in range(6):
                ret.future.append(tmp_loop.future[fi])
            return ret
        else:
            return None

    def _broadcast_get_command(self, command):
        """Retrieves the broadcast extension chunk

        :param command: the command id
        :type command: int
        :returns: broadcast information or None
        :rtype: :py:class:`SfBroadcastInfo` or None
        """
        cdef SF_BROADCAST_INFO tmp_info
        cdef SF_BROADCAST_INFO* info_ptr = NULL
        memset(&tmp_info, 0, sizeof(SF_BROADCAST_INFO))
        retcode = self.thisPtr.command(command, &tmp_info,
                                       sizeof(SF_BROADCAST_INFO))
        if retcode != C_SF_TRUE:
            return None
        ret = SfBroadcastInfo(
            description = _read_from_char_field(tmp_info.description, 256),
            originator = _read_from_char_field(tmp_info.originator, 32),
            originator_reference = 
                _read_from_char_field(tmp_info.originator_reference, 32),
            origination_date =
                _read_from_char_field(tmp_info.origination_date, 10),
            origination_time =
                _read_from_char_field(tmp_info.origination_time, 8),
            time_reference =
                (<uint64_t>pow(2.0, 32)) * tmp_info.time_reference_high
                + tmp_info.time_reference_low,
            version = tmp_info.version,
            umid = tmp_info.umid[:64],
            loudness_value = _read_new_broadcast_member(&tmp_info, 414),
            loudness_range = _read_new_broadcast_member(&tmp_info, 416),
            max_true_peak_level = _read_new_broadcast_member(&tmp_info, 418),
            max_momentary_loudness = _read_new_broadcast_member(&tmp_info, 420),
            max_shortterm_loudness = _read_new_broadcast_member(&tmp_info, 422),
            coding_history = None)
        if tmp_info.coding_history_size < 256:
            ret.coding_history = \
                tmp_info.coding_history[:tmp_info.coding_history_size] \
                    .decode("UTF-8")
        else:
            try:
                info_size = sizeof(SF_BROADCAST_INFO) \
                            + (tmp_info.coding_history_size - 255)
                info_ptr = <SF_BROADCAST_INFO*>calloc(1, info_size)
                retcode = self.thisPtr.command(command, info_ptr, info_size)
                if retcode != C_SF_TRUE \
                    or tmp_info.coding_history_size \
                        != info_ptr.coding_history_size:
                    raise RuntimeError("PySndfile::error:: second call to {0} for extended coding history failed, this should not happen", command)
                ret.coding_history = \
                    info_ptr.coding_history[:info_ptr.coding_history_size] \
                        .decode("UTF-8")
            finally:
                free(info_ptr)
        return ret

    def _broadcast_set_command(self, command, arg):
        """Defines broadcast extension information

        :param command: the command id
        :type command: int
        :param arg: broadcast information
        :type arg: :py:class:`SfBroadcastInfo`
        :returns: None
        :rtype: None
        :raises RuntimeError: if libsndfile reports failure
        """
        cdef SF_BROADCAST_INFO tmp_info
        cdef SF_BROADCAST_INFO* info_ptr = &tmp_info
        cdef int info_size = sizeof(SF_BROADCAST_INFO)
        cdef size_t length
        cdef uint64_t timeref
        tmp_str = arg.coding_history.encode("UTF-8")
        history_size = len(tmp_str) + 1
        try:
            if history_size > 256:
                info_size = sizeof(SF_BROADCAST_INFO) + (history_size - 256)
                info_ptr = <SF_BROADCAST_INFO*>malloc(info_size)
            _assign_char_field(info_ptr.description, arg.description, 256,
                               command, "description")
            _assign_char_field(info_ptr.originator, arg.originator, 32, command,
                               "originator")
            _assign_char_field(info_ptr.originator_reference,
                               arg.originator_reference, 32, command,
                               "originator_reference")
            _assign_char_field(info_ptr.origination_date, arg.origination_date,
                               10, command, "origination_date")
            _assign_char_field(info_ptr.origination_time, arg.origination_time,
                               8, command, "origination_time")
            timeref = arg.time_reference
            info_ptr.time_reference_low = timeref & 0xffffffff
            info_ptr.time_reference_high = timeref >> 32
            info_ptr.version = arg.version
            if arg.umid:
                length = len(arg.umid)
                if length > 64:
                    raise RuntimeError("PySndfile::error:: umid is too long ({0}) in {1}, maximum length is 64".format(length, commands_id_to_name[command]))
                for ui in range(length):
                    info_ptr.umid[ui] = arg.umid[ui]
                if length < 64:
                    memset(info_ptr.umid + length, 0, 64 - length)
                else:
                    memset(info_ptr.umid, 0, 64)
            _write_new_broadcast_member(info_ptr, 414,
                                        _check_int16_range(arg.loudness_value,
                                                           command,
                                                          "loudness_value"))
            _write_new_broadcast_member(info_ptr, 416,
                                        _check_int16_range(arg.loudness_range,
                                                           command,
                                                           "loudness_range"))
            _write_new_broadcast_member(
                info_ptr, 418, _check_int16_range(arg.max_true_peak_level,
                                                  command,
                                                  "max_true_peak_level"))
            _write_new_broadcast_member(
                info_ptr, 420, _check_int16_range(arg.max_momentary_loudness,
                                                  command,
                                                  "max_momentary_loudness"))
            _write_new_broadcast_member(
                info_ptr, 422, _check_int16_range(arg.max_shortterm_loudness,
                                                  command,
                                                  "max_shortterm_loudness"))
            memset(info_ptr.reserved, 0, 180)
            info_ptr.coding_history_size = len(tmp_str)
            for si in range(info_ptr.coding_history_size):
                info_ptr.coding_history[si] = tmp_str[si]
            info_ptr.coding_history[info_ptr.coding_history_size] = 0
            retcode = self.thisPtr.command(command, info_ptr, info_size)
            _check_command_retval(retcode, command, C_SF_FALSE)
        finally:
            if info_size != sizeof(SF_BROADCAST_INFO):
                free(info_ptr)
        return None

    def _channel_map_get_command(self, command):
        """Retrieves the channel map

        :param command: the command id
        :type command: int
        :returns: a list of strings (one per channel) or None
        :rtype: list[str]
        """
        cdef size_t nc = self.thisPtr.channels()
        cdef size_t datasize = nc * sizeof(int)
        cdef int* tmp_map = <int*>calloc(1, datasize)
        try:
            retcode = self.thisPtr.command(command, tmp_map, datasize)
            if retcode == C_SF_TRUE:
                ret = []
                for ci in range(nc):
                    ret.append(channel_map_id_to_name[tmp_map[ci]])
                return ret
            else:
                return None
        finally:
            free(tmp_map)

    def _channel_map_set_command(self, command, arg):
        """Defines the channel map

        :param command: the command id
        :type command: int
        :param arg: a list of strings that must be keys in :py:data:`channel_map_name_to_id`, one per channel
        :type arg: list[str]
        :raises RuntimeError: if the size of arg does not match the number of channels or if libsndfile reports failure
        """
        nc = self.thisPtr.channels()
        if len(arg) != nc:
            raise RuntimeError("PySndfile::error:: wrong number of channels ({0}) in {1}, should be {2}".format(len(arg), commands_id_to_name[command], nc))
        cdef int datasize = nc * sizeof(int)
        cdef int* tmp_map = <int*>malloc(datasize)
        try:
            for ci in range(nc):
                tmp_map[ci] = channel_map_name_to_id[arg[ci]]
            retcode = self.thisPtr.command(command, tmp_map, datasize)
            _check_command_retval(retcode, command, C_SF_FALSE)
        finally:
            free(tmp_map)
        return None

    def _int32_get_command(self, command):
        """Retrieves an integer value

        :param command: the command id
        :type command: int
        :returns: an signed integer value
        :rtype: int
        :raises RuntimeError: if libsndfile reports failure
        """
        cdef int32_t tmp_int = 0
        cdef int ret = self.thisPtr.command(command, &tmp_int, sizeof(int32_t))
        _check_command_retval(ret, command, C_SF_FALSE)
        return tmp_int

    def _bitrate_set_command(self, command, arg):
        """Defines the bitrate mode

        :param command: the command id
        :type command: int
        :param arg: a string that is one of the keys in :py:data:`bitrate_mode_name_to_id`
        :type arg: str
        :returns: None
        :rtype: None
        :raises RuntimeError: if libsndfile reports failure
        """
        cdef int tmp_int = bitrate_mode_name_to_id[arg]
        _check_command_retval(self.thisPtr.command(command, &tmp_int,
                                                   sizeof(int)),
                              command, C_SF_FALSE)
        return None

    def _cart_set_command(self, command, arg):
        """Defines Cart chunk information

        :param command: the command id
        :type command: int
        :param arg: Cart chunk information
        :type arg: :py:class:`SfCartInfo`
        :raises RuntimeError: if libsndfile reports failure
        """
        cdef SF_CART_INFO tmp_info
        cdef SF_CART_INFO* info_ptr = &tmp_info
        cdef int info_size = sizeof(SF_CART_INFO)
        cdef size_t length
        tmp_str = arg.tag_text.encode("UTF-8")
        tag_text_size = len(tmp_str) + 1
        try:
            if tag_text_size > 256:
                info_size = sizeof(SF_CART_INFO) + (tag_text_size - 256)
                info_ptr = <SF_CART_INFO*>malloc(info_size)
            _assign_char_field(info_ptr.version, arg.version, 4, command,
                               "version")
            _assign_char_field(info_ptr.title, arg.title, 64, command, "title")
            _assign_char_field(info_ptr.artist, arg.artist, 64, command,
                               "artist")
            _assign_char_field(info_ptr.cut_id, arg.cut_id, 64, command,
                               "cut_id")
            _assign_char_field(info_ptr.client_id, arg.client_id, 64, command,
                               "client_id")
            _assign_char_field(info_ptr.category, arg.category, 64, command,
                               "category")
            _assign_char_field(info_ptr.classification, arg.classification, 64,
                               command, "classification")
            _assign_char_field(info_ptr.out_cue, arg.out_cue, 64, command,
                               "out_cue")
            _assign_char_field(info_ptr.start_date, arg.start_date, 10, command,
                               "start_date")
            _assign_char_field(info_ptr.start_time, arg.start_time, 8, command,
                               "start_time")
            _assign_char_field(info_ptr.end_date, arg.end_date, 10, command,
                               "end_date")
            _assign_char_field(info_ptr.end_time, arg.end_time, 8, command,
                               "end_time")
            _assign_char_field(info_ptr.producer_app_id, arg.producer_app_id,
                               64, command, "producer_app_id")
            _assign_char_field(info_ptr.producer_app_version,
                               arg.producer_app_version, 64, command,
                               "producer_app_version")
            _assign_char_field(info_ptr.user_def, arg.user_def, 64, command,
                               "user_def")
            info_ptr.level_reference = _check_int32_range(arg.level_reference,
                                                          command,
                                                          "level_reference")
            l = len(arg.post_timers)
            if l > 8:
                raise RuntimeError("PySndfile::error:: command {0} post_times is too big ({1}) maximum size is 8".format(commands_id_to_name[command], l))
            memset(info_ptr.post_timers, 0, 8 * sizeof(SF_CART_TIMER))
            for pti in range(l):
                _assign_char_field(info_ptr.post_timers[pti].usage,
                                   arg.post_timers[pti].usage, 4, command,
                                   "post_timers.usage")
                info_ptr.post_timers[pti].value = \
                    _check_int32_range(arg.post_timers[pti].value, command,
                                       "post_timers.value")
            memset(info_ptr.reserved, 0, 276)
            _assign_char_field(info_ptr.url, arg.url, 1024, command, "url")
            info_ptr.tag_text_size = len(tmp_str)
            for si in range(info_ptr.tag_text_size):
                info_ptr.tag_text[si] = tmp_str[si]
            info_ptr.tag_text[info_ptr.tag_text_size] = 0
            _check_command_retval(
                self.thisPtr.command(command, info_ptr, info_size),
                command, C_SF_FALSE)
        finally:
            if info_size != sizeof(SF_CART_INFO):
                free(info_ptr)
        return None

    def _cart_get_command(self, command):
        """Retrieves Cart chunk information

        :param command: the command id
        :type command: int
        :returns: Cart chunk information or None
        :rtype: :py:class:`SfCartInfo` or None
        """
        cdef SF_CART_INFO tmp_info
        cdef SF_CART_INFO* info_ptr = NULL
        memset(&tmp_info, 0, sizeof(SF_CART_INFO))
        retcode = self.thisPtr.command(command, &tmp_info, sizeof(SF_CART_INFO))
        if retcode != C_SF_TRUE:
            return None
        ret = SfCartInfo(
            version = _read_from_char_field(tmp_info.version, 4),
            title = _read_from_char_field(tmp_info.title, 64),
            artist = _read_from_char_field(tmp_info.artist, 64),
            cut_id = _read_from_char_field(tmp_info.cut_id, 64),
            client_id = _read_from_char_field(tmp_info.client_id, 64),
            category = _read_from_char_field(tmp_info.category, 64),
            classification = _read_from_char_field(tmp_info.classification, 64),
            out_cue = _read_from_char_field(tmp_info.out_cue, 64),
            start_date = _read_from_char_field(tmp_info.start_date, 10),
            start_time = _read_from_char_field(tmp_info.title, 8),
            end_date = _read_from_char_field(tmp_info.end_date, 10),
            end_time = _read_from_char_field(tmp_info.end_time, 8),
            producer_app_id = _read_from_char_field(tmp_info.producer_app_id,
                                                    64),
            producer_app_version = \
                _read_from_char_field(tmp_info.producer_app_version, 64),
            user_def = _read_from_char_field(tmp_info.user_def, 64),
            level_reference = tmp_info.level_reference, post_timers = [],
            url = _read_from_char_field(tmp_info.url, 1024), tag_text = None)
        for pti in range(8):
            if tmp_info.post_timers[pti].usage[0]:
                ret.post_timers.append(SfCartTimer(
                    usage = _read_from_char_field(
                        tmp_info.post_timers[pti].usage, 4),
                    value = tmp_info.post_timers[pti].value))
        if tmp_info.tag_text_size < 256:
            ret.tag_text = \
                tmp_info.tag_text[:tmp_info.tag_text_size].decode("UTF-8")
        else:
            try:
                info_size = sizeof(SF_CART_INFO) \
                            + (tmp_info.tag_text_size - 255)
                info_ptr = <SF_CART_INFO*>calloc(1, info_size)
                retcode = self.thisPtr.command(command, info_ptr, info_size)
                if retcode != C_SF_TRUE \
                    or tmp_info.tag_text_size != info_ptr.tag_text_size:
                    raise RuntimeError("PySndfile::error:: second call to {0} for extended tag text failed, this should not happen", command)
                ret.tag_text = \
                    info_ptr.tag_text[:info_ptr.tag_text_size].decode("UTF-8")
            finally:
                free(info_ptr)
        return ret

    def _int_set_command(self, command, arg):
        """Sets an integer value

        :param command: the command id
        :type command: int
        :param arg: the integer value
        :type arg: int
        :returns: None
        :rtype: None
        :raises RuntimeError: if libsndfile reports failure
        """
        cdef int tmp_int = arg
        _check_command_hybrid_retval(self.thisPtr.command(command, &tmp_int,
                                                          sizeof(int)),
                                     command)
        return None

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

