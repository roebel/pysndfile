# cython: embedsignature=True

import numpy as np
import warnings
import os

cimport numpy as cnp
cimport libc.string
cimport libc.stdlib

cdef extern from "sndfile.hh":

    cdef struct SF_FORMAT_INFO:
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
    
    cdef cppclass SNDFILE_ref :
        SNDFILE *sf
        SF_INFO sfinfo
        int ref
         
    
    ctypedef SF_FORMAT_INFO SF_FORMAT_INFO
    cdef int sf_command(SNDFILE *sndfile, int command, void *data, int datasize)
    cdef int sf_format_check (const SF_INFO *info)
    cdef cppclass SndfileHandle :
        SNDFILE_ref *p
        SndfileHandle(const char *path, int mode, int format, int channels, int samplerate)
        SndfileHandle(const int fh, int mode, int format, int channels, int samplerate)
        sf_count_t frames()
        int format()
        int channels()
        int samplerate()
        int seekable()
        int error()
        char* strError()
        int command (int cmd, void *data, int datasize)
        sf_count_t seek (sf_count_t frames, int whence)
        void writeSync () 
        sf_count_t read (short *ptr, sf_count_t items) 
        sf_count_t read (int *ptr, sf_count_t items) 
        sf_count_t read (float *ptr, sf_count_t items) 
        sf_count_t read (double *ptr, sf_count_t items)
        sf_count_t write (const short *ptr, sf_count_t items) 
        sf_count_t write (const int *ptr, sf_count_t items) 
        sf_count_t write (const float *ptr, sf_count_t items) 
        sf_count_t write (const double *ptr, sf_count_t items)
        sf_count_t readf (short *ptr, sf_count_t items) 
        sf_count_t readf (int *ptr, sf_count_t items) 
        sf_count_t readf (float *ptr, sf_count_t items) 
        sf_count_t readf (double *ptr, sf_count_t items)
        sf_count_t writef (const short *ptr, sf_count_t items) 
        sf_count_t writef (const int *ptr, sf_count_t items) 
        sf_count_t writef (const float *ptr, sf_count_t items) 
        sf_count_t writef (const double *ptr, sf_count_t items)

    
    
    cdef int SF_FORMAT_WAV = 0x010000    # /* Microsoft WAV format (little endian default). */
    cdef int SF_FORMAT_AIFF = 0x020000   # /* Apple/SGI AIFF format (big endian). */
    cdef int SF_FORMAT_AU   = 0x030000   # /* Sun/NeXT AU format (big endian). */
    cdef int SF_FORMAT_RAW  = 0x040000   # /* RAW PCM data. */
    cdef int SF_FORMAT_PAF  = 0x050000   # /* Ensoniq PARIS file format. */
    cdef int SF_FORMAT_SVX  = 0x060000   # /* Amiga IFF / SVX8 / SV16 format. */
    cdef int SF_FORMAT_NIST  = 0x070000  # /* Sphere NIST format. */
    cdef int SF_FORMAT_VOC  = 0x080000   # /* VOC files. */
    cdef int SF_FORMAT_IRCAM  = 0x0A0000 # /* Berkeley/IRCAM/CARL */
    cdef int SF_FORMAT_W64  = 0x0B0000   # /* Sonic Foundry's 64 bit RIFF/WAV */
    cdef int SF_FORMAT_MAT4  = 0x0C0000  # /* Matlab (tm) V4.2 / GNU Octave 2.0 */
    cdef int SF_FORMAT_MAT5  = 0x0D0000  # /* Matlab (tm) V5.0 / GNU Octave 2.1 */
    cdef int SF_FORMAT_PVF  = 0x0E0000   # /* Portable Voice Format */
    cdef int SF_FORMAT_XI  = 0x0F0000    # /* Fasttracker 2 Extended Instrument */
    cdef int SF_FORMAT_HTK  = 0x100000   # /* HMM Tool Kit format */
    cdef int SF_FORMAT_SDS  = 0x110000   # /* Midi Sample Dump Standard */
    cdef int SF_FORMAT_AVR  = 0x120000   # /* Audio Visual Research */
    cdef int SF_FORMAT_WAVEX  = 0x130000 # /* MS WAVE with WAVEFORMATEX */
    cdef int SF_FORMAT_SD2  = 0x160000   # /* Sound Designer 2 */
    cdef int SF_FORMAT_FLAC  = 0x170000  # /* FLAC lossless file format */
    cdef int SF_FORMAT_CAF  = 0x180000   # /* Core Audio File format */

    #/* Subtypes from here on. */
    cdef int SF_FORMAT_PCM_S8  = 0x0001  # /* Signed 8 bit data */
    cdef int SF_FORMAT_PCM_16  = 0x0002  # /* Signed 16 bit data */
    cdef int SF_FORMAT_PCM_24  = 0x0003  # /* Signed 24 bit data */
    cdef int SF_FORMAT_PCM_32  = 0x0004  # /* Signed 32 bit data */

    cdef int SF_FORMAT_PCM_U8  = 0x0005  # /* Unsigned 8 bit data (WAV and RAW only) */

    cdef int SF_FORMAT_FLOAT  = 0x0006   # /* 32 bit float data */
    cdef int SF_FORMAT_DOUBLE  = 0x0007  # /* 64 bit float data */

    cdef int SF_FORMAT_ULAW  = 0x0010    # /* U-Law encoded. */
    cdef int SF_FORMAT_ALAW  = 0x0011    # /* A-Law encoded. */
    cdef int SF_FORMAT_IMA_ADPCM = 0x0012# /* IMA ADPCM. */
    cdef int SF_FORMAT_MS_ADPCM  = 0x0013# /* Microsoft ADPCM. */

    cdef int SF_FORMAT_GSM610  = 0x0020  # /* GSM 6.10 encoding. */
    cdef int SF_FORMAT_VOX_ADPCM = 0x0021# /* OKI / Dialogix ADPCM */
    cdef int SF_FORMAT_G721_32  = 0x0030 # /* 32kbs G721 ADPCM encoding. */
    cdef int SF_FORMAT_G723_24  = 0x0031 # /* 24kbs G723 ADPCM encoding. */
    cdef int SF_FORMAT_G723_40  = 0x0032 # /* 40kbs G723 ADPCM encoding. */

    cdef int SF_FORMAT_DWVW_12  = 0x0040 # /* 12 bit Delta Width Variable Word encoding. */
    cdef int SF_FORMAT_DWVW_16  = 0x0041 # /* 16 bit Delta Width Variable Word encoding. */
    cdef int SF_FORMAT_DWVW_24  = 0x0042 # /* 24 bit Delta Width Variable Word encoding. */
    cdef int SF_FORMAT_DWVW_N  = 0x0043  # /* N bit Delta Width Variable Word encoding. */

    cdef int SF_FORMAT_DPCM_8  = 0x0050  # /* 8 bit differential PCM (XI only) */
    cdef int SF_FORMAT_DPCM_16  = 0x0051 # /* 16 bit differential PCM (XI only) */

    #    /* Endian-ness options. */
    cdef int SF_ENDIAN_FILE = 0x00000000 # /* Default file endian-ness. */
    cdef int SF_ENDIAN_LITTLE  = 0x100000# /* Force little endian-ness. */
    cdef int SF_ENDIAN_BIG  = 0x20000000 # /* Force big endian-ness. */
    cdef int SF_ENDIAN_CPU  = 0x30000000 # /* Force CPU endian-ness. */

    cdef int SF_FORMAT_SUBMASK  = 0x0000FFFF
    cdef int SF_FORMAT_TYPEMASK = 0x0FFF0000
    cdef int SF_FORMAT_ENDMASK  = 0x30000000

    # commands
    cdef int SFC_GET_LIB_VERSION        = 0x1000
    cdef int SFC_GET_LOG_INFO  = 0x1001

    cdef int SFC_GET_NORM_DOUBLE  = 0x1010
    cdef int SFC_GET_NORM_FLOAT  = 0x1011
    cdef int SFC_SET_NORM_DOUBLE  = 0x1012
    cdef int SFC_SET_NORM_FLOAT  = 0x1013
    cdef int SFC_SET_SCALE_FLOAT_INT_READ  = 0x1014

    cdef int SFC_GET_SIMPLE_FORMAT_COUNT  = 0x1020
    cdef int SFC_GET_SIMPLE_FORMAT  = 0x1021

    cdef int SFC_GET_FORMAT_INFO  = 0x1028

    cdef int SFC_GET_FORMAT_MAJOR_COUNT  = 0x1030
    cdef int SFC_GET_FORMAT_MAJOR  = 0x1031
    cdef int SFC_GET_FORMAT_SUBTYPE_COUNT  = 0x1032
    cdef int SFC_GET_FORMAT_SUBTYPE  = 0x1033

    cdef int SFC_CALC_SIGNAL_MAX  = 0x1040
    cdef int SFC_CALC_NORM_SIGNAL_MAX  = 0x1041
    cdef int SFC_CALC_MAX_ALL_CHANNELS  = 0x1042
    cdef int SFC_CALC_NORM_MAX_ALL_CHANNELS  = 0x1043
    cdef int SFC_GET_SIGNAL_MAX  = 0x1044
    cdef int SFC_GET_MAX_ALL_CHANNELS  = 0x1045

    cdef int SFC_SET_ADD_PEAK_CHUNK  = 0x1050

    cdef int SFC_UPDATE_HEADER_NOW  = 0x1060
    cdef int SFC_SET_UPDATE_HEADER_AUTO  = 0x1061

    cdef int SFC_FILE_TRUNCATE  = 0x1080

    cdef int SFC_SET_RAW_START_OFFSET  = 0x1090

    cdef int SFC_SET_DITHER_ON_WRITE  = 0x10A0
    cdef int SFC_SET_DITHER_ON_READ  = 0x10A1

    cdef int SFC_GET_DITHER_INFO_COUNT  = 0x10A2
    cdef int SFC_GET_DITHER_INFO  = 0x10A3

    cdef int SFC_GET_EMBED_FILE_INFO  = 0x10B0

    cdef int SFC_SET_CLIPPING  = 0x10C0
    cdef int SFC_GET_CLIPPING  = 0x10C1

    cdef int SFC_GET_INSTRUMENT  = 0x10D0
    cdef int SFC_SET_INSTRUMENT  = 0x10D1

    cdef int SFC_GET_LOOP_INFO  = 0x10E0

    cdef int SFC_GET_BROADCAST_INFO  = 0x10F0
    cdef int SFC_SET_BROADCAST_INFO  = 0x10F1

    cdef int SF_STR_TITLE  = 0x01
    cdef int SF_STR_COPYRIGHT  = 0x02
    cdef int SF_STR_SOFTWARE  = 0x03
    cdef int SF_STR_ARTIST  = 0x04
    cdef int SF_STR_COMMENT  = 0x05
    cdef int SF_STR_DATE  = 0x06

    cdef int SF_FALSE  = 0
    cdef int SF_TRUE  = 1

    #        /* Modes for opening files. */
    cdef int SFM_READ   = 0x10
    cdef int SFM_WRITE  = 0x20
    cdef int SFM_RDWR   = 0x30

    cdef int SEEK_SET = 0
    cdef int SEEK_CUR = 1
    cdef int SEEK_END = 2
    
    cdef int SF_ERR_NO_ERROR  = 0
    cdef int SF_ERR_UNRECOGNISED_FORMAT  = 1
    cdef int SF_ERR_SYSTEM  = 2
    cdef int SF_ERR_MALFORMED_FILE  = 3
    cdef int SF_ERR_UNSUPPORTED_ENCODING  = 4
    
    cdef int SF_COUNT_MAX  = 0x7FFFFFFFFFFFFFFFLL
            
_encoding_id_tuple = (
    ('pcms8' , SF_FORMAT_PCM_S8),
    ('pcm16' , SF_FORMAT_PCM_16),
    ('pcm24' , SF_FORMAT_PCM_24),
    ('pcm32' , SF_FORMAT_PCM_32),
    ('pcmu8' , SF_FORMAT_PCM_U8),

    ('float32' , SF_FORMAT_FLOAT),
    ('float64' , SF_FORMAT_DOUBLE),

    ('ulaw'      , SF_FORMAT_ULAW),
    ('alaw'      , SF_FORMAT_ALAW),
    ('ima_adpcm' , SF_FORMAT_IMA_ADPCM),
    ('ms_adpcm'  , SF_FORMAT_MS_ADPCM),

    ('gsm610'    , SF_FORMAT_GSM610),
    ('vox_adpcm' , SF_FORMAT_VOX_ADPCM),

    ('g721_32'   , SF_FORMAT_G721_32),
    ('g723_24'   , SF_FORMAT_G723_24),
    ('g723_40'   , SF_FORMAT_G723_40),

    ('dww12' , SF_FORMAT_DWVW_12),
    ('dww16' , SF_FORMAT_DWVW_16),
    ('dww24' , SF_FORMAT_DWVW_24),
    ('dwwN'  , SF_FORMAT_DWVW_N),

    ('dpcm8' , SF_FORMAT_DPCM_8),
    ('dpcm16', SF_FORMAT_DPCM_16)
    )


encoding_name_to_id = dict(_encoding_id_tuple)
encoding_id_to_name = dict([(id, enc) for enc, id in _encoding_id_tuple])

_fileformat_id_tuple = (
    ( 'wav' , SF_FORMAT_WAV),
    ('aiff' , SF_FORMAT_AIFF),
    ('au'   , SF_FORMAT_AU),
    ('raw'  , SF_FORMAT_RAW),
    ('paf'  , SF_FORMAT_PAF),
    ('svx'  , SF_FORMAT_SVX),
    ('nist' , SF_FORMAT_NIST),
    ('voc'  , SF_FORMAT_VOC),
    ('ircam', SF_FORMAT_IRCAM),
    ('wav64', SF_FORMAT_W64),
    ('mat4' , SF_FORMAT_MAT4),
    ('mat5' , SF_FORMAT_MAT5),
    ('pvf'  , SF_FORMAT_PVF),
    ('xi'   , SF_FORMAT_XI),
    ('htk'  , SF_FORMAT_HTK),
    ('sds'  , SF_FORMAT_SDS),
    ('avr'  , SF_FORMAT_AVR),
    ('wavex', SF_FORMAT_WAVEX),
    ('sd2'  , SF_FORMAT_SD2),
    ('flac' , SF_FORMAT_FLAC),
    ('caf'  , SF_FORMAT_CAF),
    )

fileformat_name_to_id = dict (_fileformat_id_tuple)
fileformat_id_to_name = dict ([(id, format) for format, id in _fileformat_id_tuple])

_endian_to_id_tuple = (
    ('file'   , SF_ENDIAN_FILE),
    ('little' , SF_ENDIAN_LITTLE),
    ('big'    , SF_ENDIAN_BIG),
    ('cpu'    , SF_ENDIAN_CPU)
    )

endian_name_to_id = dict(_endian_to_id_tuple)
endian_id_to_name = dict([(id, endname) for endname, id in _endian_to_id_tuple])

_commands_to_id_tuple = (
    ("SFC_GET_LIB_VERSION" , SFC_GET_LIB_VERSION),
    ("SFC_GET_LOG_INFO" ,     SFC_GET_LOG_INFO),
    
    ("SFC_GET_NORM_DOUBLE" , SFC_GET_NORM_DOUBLE),
    ("SFC_GET_NORM_FLOAT" , SFC_GET_NORM_FLOAT),
    ("SFC_SET_NORM_DOUBLE" , SFC_SET_NORM_DOUBLE),
    ("SFC_SET_NORM_FLOAT" , SFC_SET_NORM_FLOAT),
    ("SFC_SET_SCALE_FLOAT_INT_READ" , SFC_SET_SCALE_FLOAT_INT_READ),

    ("SFC_GET_SIMPLE_FORMAT_COUNT" , SFC_GET_SIMPLE_FORMAT_COUNT),
    ("SFC_GET_SIMPLE_FORMAT" , SFC_GET_SIMPLE_FORMAT),

    ("SFC_GET_FORMAT_INFO" , SFC_GET_FORMAT_INFO),

    ("SFC_GET_FORMAT_MAJOR_COUNT" , SFC_GET_FORMAT_MAJOR_COUNT),
    ("SFC_GET_FORMAT_MAJOR" , SFC_GET_FORMAT_MAJOR),
    ("SFC_GET_FORMAT_SUBTYPE_COUNT" , SFC_GET_FORMAT_SUBTYPE_COUNT),
    ("SFC_GET_FORMAT_SUBTYPE" , SFC_GET_FORMAT_SUBTYPE),

    ("SFC_CALC_SIGNAL_MAX" , SFC_CALC_SIGNAL_MAX),
    ("SFC_CALC_NORM_SIGNAL_MAX" , SFC_CALC_NORM_SIGNAL_MAX),
    ("SFC_CALC_MAX_ALL_CHANNELS" , SFC_CALC_MAX_ALL_CHANNELS),
    ("SFC_CALC_NORM_MAX_ALL_CHANNELS" , SFC_CALC_NORM_MAX_ALL_CHANNELS),
    ("SFC_GET_SIGNAL_MAX" , SFC_GET_SIGNAL_MAX),
    ("SFC_GET_MAX_ALL_CHANNELS" , SFC_GET_MAX_ALL_CHANNELS),

    ("SFC_SET_ADD_PEAK_CHUNK" , SFC_SET_ADD_PEAK_CHUNK),

    ("SFC_UPDATE_HEADER_NOW" , SFC_UPDATE_HEADER_NOW),
    ("SFC_SET_UPDATE_HEADER_AUTO" , SFC_SET_UPDATE_HEADER_AUTO),

    ("SFC_FILE_TRUNCATE" , SFC_FILE_TRUNCATE),

    ("SFC_SET_RAW_START_OFFSET" , SFC_SET_RAW_START_OFFSET),

    ("SFC_SET_DITHER_ON_WRITE" , SFC_SET_DITHER_ON_WRITE),
    ("SFC_SET_DITHER_ON_READ" , SFC_SET_DITHER_ON_READ),

    ("SFC_GET_DITHER_INFO_COUNT" , SFC_GET_DITHER_INFO_COUNT),
    ("SFC_GET_DITHER_INFO" , SFC_GET_DITHER_INFO),

    ("SFC_GET_EMBED_FILE_INFO" , SFC_GET_EMBED_FILE_INFO),

    ("SFC_SET_CLIPPING" , SFC_SET_CLIPPING),
    ("SFC_GET_CLIPPING" , SFC_GET_CLIPPING),

    ("SFC_GET_INSTRUMENT" , SFC_GET_INSTRUMENT),
    ("SFC_SET_INSTRUMENT" , SFC_SET_INSTRUMENT),

    ("SFC_GET_LOOP_INFO" , SFC_GET_LOOP_INFO),

    ("SFC_GET_BROADCAST_INFO" , SFC_GET_BROADCAST_INFO),
    ("SFC_SET_BROADCAST_INFO" , SFC_SET_BROADCAST_INFO),
    )
    

command_name_to_id = dict(_commands_to_id_tuple)
command_id_to_name = dict([(id, com) for com, id in _commands_to_id_tuple])

def get_sndfile_version():
    """
    return a tuple of ints representing the version of the libsdnfile that is used
    """
    cdef int status
    cdef char buffer[256]

    st = sf_command(NULL, SFC_GET_LIB_VERSION, buffer, 256)
    version = buffer
    
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


def get_sndfile_formats():
    """Return lists of available file formats supported by libsndfile and pysndfile."""
    fmt = []
    for i in get_sndfile_formats():
        # Handle the case where libsndfile supports a format we don't
        if not i in fileformat_id_to_name:
            warnings.warn("Format {0:x} supported by libsndfile but not "
                          "yet supported by PySndfile".format(i & SF_FORMAT_TYPEMASK))
        else:
            fmt.append(fileformat_id_to_name[i & SF_FORMAT_TYPEMASK])
    return fmt


def get_sndfile_encodings(major):
    """
    Return lists of available encoding for the given major format.
    """

    # make major an id
    if major in fileformat_id_to_name:
        pass
    elif major in fileformat_name_to_id:
        major = fileformat_name_to_id[major]
    else:
        raise ValueError("PySndfile::File format {0} not known by PySndfile".format(str(major)))
    
    if major not in get_sndfile_formats():
        raise ValueError("PySndfile::File format {0}:{1:x} not supported by libsndfile".format(fileformat_id_to_name[major], major))

    enc = []
    for i in get_sub_formats_for_major(major):
        # Handle the case where libsndfile supports an encoding we don't
        if i not in encoding_id_to_name:
            warnings.warn("Encoding {0:x} supported by libsndfile but not by PySndfile"
                          .format(i & SF_FORMAT_SUBMASK))
        else:
            enc.append(encoding_id_to_name[i & SF_FORMAT_SUBMASK])
    return enc

cdef get_sub_formats_for_major(int major):
    """
    Retrieve list of subtype formats given the major format specified as int.

    """
    cdef int nsub
    cdef int i
    cdef SF_FORMAT_INFO info
    cdef SF_INFO sfinfo

    sf_command (NULL, SFC_GET_FORMAT_SUBTYPE_COUNT, &nsub, sizeof(int))

    subs = []
    # create a valid sfinfo struct
    sfinfo.channels   = 1
    sfinfo.samplerate = 44100
    for i in range(nsub):
        info.format = i
        sf_command (NULL, SFC_GET_FORMAT_SUBTYPE, &info, sizeof (info))
        sfinfo.format = (major & SF_FORMAT_TYPEMASK) | info.format
        if sf_format_check(&sfinfo):
            subs.append(info.format)

    return subs

def get_sndfile_formats():
    """
        retrieve list of major format ids
    """
    cdef int nmajor
    cdef int i
    cdef SF_FORMAT_INFO info

    sf_command (NULL, SFC_GET_FORMAT_MAJOR_COUNT, &nmajor, sizeof(int))

    majors = []
    for i in xrange(nmajor):
        info.format = i
        sf_command (NULL, SFC_GET_FORMAT_MAJOR, &info, sizeof (info))
        majors.append(info.format)

    return majors


cdef class PySndfile:
    """\
    PySndfile is the core class to read/write audio files. Once an instance is
    created, it can be used to read and/or writes data from numpy arrays, query
    the audio file meta-data, etc...

    Parameters
    ----------
    filename : string or int
        name of the file to open (string), or file descriptor (integer)
    mode : string
        'r' for read, 'w' for write, or 'rw' for read and
        write.
    format : Format
        Required when opening a new file for writing, or to read raw audio
        files (without header).
    channels : int
        number of channels.
    samplerate : int
        sampling rate.

    Returns
    -------
        sndfile: as Sndfile instance.

    Notes
    -----
    format, channels and samplerate need to be given only in the write modes
    and for raw files."""
    cdef SndfileHandle *thisPtr
    cdef int fd
    cdef char* filename
    def __cinit__(self, filename, mode='r', int format=0,
                 int channels=0, int samplerate=0):
        cdef int sfmode
        cdef const char*cfilename
        cdef int fh
        # -1 will indicate that the file has been open from filename, not from
        # file descriptor
        self.fd = -1
        self.thisPtr = NULL

        # Check the mode is one of the expected values
        if mode == 'r':
            sfmode = SFM_READ
        elif mode == 'w':
            sfmode = SFM_WRITE
            if format is 0:
                raise ValueError( "PySndfile::opening for writing requires a format argument !")
        elif mode == 'rw':
            sfmode  = SFM_RDWR
            if format is 0:
                raise ValueError( "PySndfile::opening for writing requires a format argument !")
        else:
            raise ValueError("PySndfile::mode {0} not recognized".format(str(mode)))

        self.fd = -1
        if isinstance(filename, int):
            fh = filename
            self.thisPtr = new SndfileHandle(fh, sfmode, format, channels, samplerate)
            self.filename = ""
            self.fd = filename
        else:
            if filename[0] == "~" and len(filename) > 2:
                filename = os.path.join(libc.stdlib.getenv('HOME'),
                                        filename[2:])
            cfilename = filename
            self.thisPtr = new SndfileHandle(cfilename, sfmode, format, channels, samplerate)
            self.filename = filename

        if self.thisPtr == NULL:
            raise IOError("error while opening %s\n\t->%s" % (str(filename), self.thisPtr.strError()))


        self.set_auto_clipping(True)

    def __dealloc__(self):
        del self.thisPtr

    def command(self, command, arg) :
        """
        interface for passing commands via sf_command to underlying soundfile
        """
        return self.thisPtr.command(command, NULL, arg);

    def set_auto_clipping( self, arg = True) :
        return self.thisPtr.command(SFC_SET_CLIPPING, NULL, arg);
             
    def writeSync(self):
        """\
        call the operating system's function to force the writing of all
        file cache buffers to disk the file.

        No effect if file is open as read"""
        self.thisPtr.writeSync()
        
                  
    def __str__( self):
        repstr = ["----------------------------------------"]
        if not self.fd == -1:
            repstr += ["File        : %d (opened by file descriptor)" % self.fd]
        else:
            repstr += ["File        : %s" % self.filename]
        repstr  += ["Channels    : %d" % self.thisPtr.channels()]
        repstr  += ["Sample rate : %d" % self.thisPtr.samplerate()]
        repstr  += ["Frames      : %d" % self.thisPtr.frames()]
        repstr  += ["Raw Format  : %#010x" % self.thisPtr.format()]
        repstr  += ["File format : %s" % fileformat_id_to_name[self.thisPtr.format()& SF_FORMAT_TYPEMASK]]
        repstr  += ["Encoding    : %s" % encoding_id_to_name[self.thisPtr.format()& SF_FORMAT_SUBMASK]]
        #repstr  += ["Endianness  : %s" % ]
        #repstr  += "Sections    : %d\n" % self._sfinfo.sections
        repstr  += ["Seekable    : %s\n" % self.thisPtr.seekable()]
        #repstr  += "Duration    : %s\n" % self._generate_duration_str()
        return "\n".join(repstr)

    def read_frames(self, sf_count_t nframes=-1, dtype=np.float64):
        """\
        Read the given number of frames and put the data into a numpy array of
        the requested dtype.

        Parameters
        ----------
        nframes : int
            number of frames to read (default = -1 -> read all).
        dtype : numpy dtype
            dtype of the returned array containing read data (see note).

        Notes
        -----
        One column per channel.

        """
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
            return y[:, 0]
        return y

    cdef read_frames_double(self, sf_count_t nframes):
        cdef sf_count_t res
        cdef cnp.ndarray[cnp.float64_t, ndim=2] ty = np.empty((nframes, self.thisPtr.channels()),
                                                                dtype=np.float64, order='C')

        res = self.thisPtr.readf(<double*>ty.data, nframes)
        if not res == nframes:
            raise RuntimeError("Asked %d frames, read %d" % (nframes, res))
        return ty

    cdef read_frames_float(self, sf_count_t nframes):
        cdef sf_count_t res
        # Use Fortran order to cope with interleaving
        cdef cnp.ndarray[cnp.float32_t, ndim=2] ty = np.empty((nframes, self.thisPtr.channels()),
                                                                dtype=np.float32, order='C')

        res = self.thisPtr.readf(<float*>ty.data, nframes)
        if not res == nframes:
            raise RuntimeError("Asked %d frames, read %d" % (nframes, res))
        return ty

    cdef read_frames_int(self, sf_count_t nframes):
        cdef sf_count_t res
        # Use Fortran order to cope with interleaving
        cdef cnp.ndarray[cnp.int32_t, ndim=2] ty = np.empty((nframes, self.thisPtr.channels()),
                                                            dtype=np.int32, order='C')

        res = self.thisPtr.readf(<int*>ty.data, nframes)
        if not res == nframes:
            raise RuntimeError("Asked %d frames, read %d" % (nframes, res))
        return ty

    cdef read_frames_short(self, sf_count_t nframes):
        cdef sf_count_t res
        # Use Fortran order to cope with interleaving
        cdef cnp.ndarray[cnp.int16_t, ndim=2] ty = np.empty((nframes, self.thisPtr.channels()),
                                                            dtype=np.short, order='C')

        res = self.thisPtr.readf(<short*>ty.data, nframes)
        if not res == nframes:
            raise RuntimeError("Asked %d frames, read %d" % (nframes, res))
        return ty

    def write_frames(self, cnp.ndarray input):
        """\
        write 1 or 2 dimensional array into sndfile.

        Parameters
        ----------
        input : numpy array containing data to write.

        Notes
        -----
        One column per channel.

        updates the write pointer.

        if the input type is float, and the file encoding is an integer type,
        you should make sure the input data are normalized normalized data
        (that is in the range [-1..1] - which will corresponds to the maximum
        range allowed by the integer bitwidth)."""
        cdef int nc
        cdef sf_count_t nframes

        # First, get the number of channels and frames from input
        if input.ndim == 2:
            nc = input.shape[1]
            nframes = input.size / nc
        elif input.ndim == 1:
            nc = 1
            input = input[:, None]
            nframes = input.size
        else:
            raise ValueError("PySndfile::write_frames::error cannot handle arrays of {0:d} dimensions, please restrict to  2 dimensions".format(input.ndim))

        # Number of channels should be the one expected
        if not nc == self.thisPtr.channels():
            raise ValueError("Expected %d channels, got %d" %
                             (self.thisPtr.channels(), nc))

        input = np.require(input, requirements = 'C')

        
        # XXX: check for overflow ?
        if input.dtype == np.float64:
            if (self.thisPtr.format() & SF_FORMAT_SUBMASK) not in [SF_FORMAT_FLOAT, SF_FORMAT_DOUBLE]:
                if (np.max(np.abs(input.flat)) > 1.) :
                    warnings.warn("write_frames::warning::audio data has been clipped while writing to file {0}.".format(self.filename))
            res = self.thisPtr.writef(<double*>input.data, nframes)
        elif input.dtype == np.float32:
            if (self.thisPtr.format() & SF_FORMAT_SUBMASK) not in [SF_FORMAT_FLOAT, SF_FORMAT_DOUBLE]:
                if (np.max(np.abs(input.flat)) > 1.) :
                    warnings.warn("write_frames::warning::audio data has been clipped while writing to file {0}.".format(self.filename))
            res = self.thisPtr.writef(<float*>input.data, nframes)
        elif input.dtype == np.int32:
            res = self.thisPtr.writef(<int*>input.data, nframes)
        elif input.dtype == np.short:
            res = self.thisPtr.writef(<short*>input.data, nframes)
        else:
            raise RuntimeError("type of input %s not understood" % str(input.dtype))

        if not(res == nframes):
            raise IOError("write %d frames, expected to write %d"
                          % res, nframes)

    def format(self) :
        if self.thisPtr:
            return self.thisPtr.format()
        return 0
    def channels(self) :
        if self.thisPtr:
            return self.thisPtr.channels()
        return 0
    def frames(self) :
        if self.thisPtr:
            return self.thisPtr.frames()
        return 0
    def samplerate(self) :
        if self.thisPtr:
            return self.thisPtr.samplerate()
        return 0
    def seekable(self) :
        if self.thisPtr:
            return self.thisPtr.seekable()
        return 0

    def seek(self, sf_count_t offset, int whence=SEEK_SET, mode='rw'):
        """\
        Seek into audio file: similar to python seek function, taking only in
        account audio data.

        Parameters
        ----------
        offset : int
            the number of frames (eg two samples for stereo files) to move
            relatively to position set by whence.
        whence : int
            only 0 (beginning), 1 (current) and 2 (end of the file) are
            valid.
        mode : string
            If set to 'rw', both read and write pointers are updated. If
            'r' is given, only read pointer is updated, if 'w', only the
            write one is (this may of course make sense only if you open
            the file in a certain mode).

        Returns
        -------
        offset : int
            the number of frames from the beginning of the file

        Notes
        -----

        Offset relative to audio data: meta-data are ignored.

        if an invalid seek is given (beyond or before the file), an IOError is
        launched; note that this is different from the seek method of a File
        object."""
        cdef sf_count_t pos
        if mode == 'rw':
            # Update both read and write pointers
            pos = self.thisPtr.seek(offset, whence)
        elif mode == 'r':
            whence = whence | SFM_READ
            pos = self.thisPtr.seek(offset, whence)
        elif mode == 'w':
            whence = whence | SFM_WRITE
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
        cdef int whence = SEEK_SET     
       
        if mode == 'rw':
            # Update both read and write pointers
            pos = self.thisPtr.seek(0, whence)
        elif mode == 'r':
            whence = whence | SFM_READ
            pos = self.thisPtr.seek(0, whence)
        elif mode == 'w':
            whence = whence | SFM_WRITE
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

