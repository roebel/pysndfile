/*
** Copyright (C) 2005-2011 Erik de Castro Lopo <erikd@mega-nerd.com>
**
** All rights reserved.
**
** Redistribution and use in source and binary forms, with or without
** modification, are permitted provided that the following conditions are
** met:
**
**     * Redistributions of source code must retain the above copyright
**       notice, this list of conditions and the following disclaimer.
**     * Redistributions in binary form must reproduce the above copyright
**       notice, this list of conditions and the following disclaimer in
**       the documentation and/or other materials provided with the
**       distribution.
**     * Neither the author nor the names of any contributors may be used
**       to endorse or promote products derived from this software without
**       specific prior written permission.
**
** THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
** "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED
** TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR
** PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR
** CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL,
** EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO,
** PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS;
** OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY,
** WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR
** OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF
** ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
*/

/*
** The above modified BSD style license (GPL and LGPL compatible) applies to
** this file. It does not apply to libsndfile itself which is released under
** the GNU LGPL or the libsndfile test suite which is released under the GNU
** GPL.
** This means that this header file can be used under this modified BSD style
** license, but the LGPL still holds for the libsndfile library itself.
*/

/*
** sndfile.hh -- A lightweight C++ wrapper for the libsndfile API.
**
** All the methods are inlines and all functionality is contained in this
** file. There is no separate implementation file.
**
** API documentation is in the doc/ directory of the source code tarball
** and at http://www.mega-nerd.com/libsndfile/api.html.
*/

#ifndef SNDFILE_HH
#define SNDFILE_HH

#ifndef READTHEDOCS_ENV
#include <sndfile.h>
#else
typedef int sf_count_t;
typedef void* SNDFILE;
struct SF_INFO{
  int frames;
  int channels;
  int format;
  int samplerate;
  int sections;
  int seekable;
};
enum
{       /* True and false */
  SF_FALSE        = 0,
  SF_TRUE         = 1,
  
  /* Modes for opening files. */
  SFM_READ        = 0x10,
  SFM_WRITE       = 0x20,
  SFM_RDWR        = 0x30,
  
  SF_AMBISONIC_NONE               = 0x40,
  SF_AMBISONIC_B_FORMAT   = 0x41
} ;

enum
{
  SF_FORMAT_WAV                   = 0x010000,             /* Microsoft WAV format (little endian default). */
  SF_FORMAT_AIFF                  = 0x020000,             /* Apple/SGI AIFF format (big endian). */
  SF_FORMAT_AU                    = 0x030000,             /* Sun/NeXT AU format (big endian). */
  SF_FORMAT_RAW                   = 0x040000,             /* RAW PCM data. */
  SF_FORMAT_PAF                   = 0x050000,             /* Ensoniq PARIS file format. */
  SF_FORMAT_SVX                   = 0x060000,             /* Amiga IFF / SVX8 / SV16 format. */
  SF_FORMAT_NIST                  = 0x070000,             /* Sphere NIST format. */
  SF_FORMAT_VOC                   = 0x080000,             /* VOC files. */
  SF_FORMAT_IRCAM                 = 0x0A0000,             /* Berkeley/IRCAM/CARL */
  SF_FORMAT_W64                   = 0x0B0000,             /* Sonic Foundry's 64 bit RIFF/WAV */
  SF_FORMAT_MAT4                  = 0x0C0000,             /* Matlab (tm) V4.2 / GNU Octave 2.0 */
  SF_FORMAT_MAT5                  = 0x0D0000,             /* Matlab (tm) V5.0 / GNU Octave 2.1 */
  SF_FORMAT_PVF                   = 0x0E0000,             /* Portable Voice Format */
  SF_FORMAT_XI                    = 0x0F0000,             /* Fasttracker 2 Extended Instrument */
  SF_FORMAT_HTK                   = 0x100000,             /* HMM Tool Kit format */
  SF_FORMAT_SDS                   = 0x110000,             /* Midi Sample Dump Standard */
  SF_FORMAT_AVR                   = 0x120000,             /* Audio Visual Research */
  SF_FORMAT_WAVEX                 = 0x130000,             /* MS WAVE with WAVEFORMATEX */
  SF_FORMAT_SD2                   = 0x160000,             /* Sound Designer 2 */
  SF_FORMAT_FLAC                  = 0x170000,             /* FLAC lossless file format */
  SF_FORMAT_CAF                   = 0x180000,             /* Core Audio File format */
  SF_FORMAT_WVE                   = 0x190000,             /* Psion WVE format */
  SF_FORMAT_OGG                   = 0x200000,             /* Xiph OGG container */
  SF_FORMAT_MPC2K                 = 0x210000,             /* Akai MPC 2000 sampler */
  SF_FORMAT_RF64                  = 0x220000,             /* RF64 WAV file */
  
  /* Subtypes from here on. */
  
  SF_FORMAT_PCM_S8                = 0x0001,               /* Signed 8 bit data */
  SF_FORMAT_PCM_16                = 0x0002,               /* Signed 16 bit data */
  SF_FORMAT_PCM_24                = 0x0003,               /* Signed 24 bit data */
  SF_FORMAT_PCM_32                = 0x0004,               /* Signed 32 bit data */
  
  SF_FORMAT_PCM_U8                = 0x0005,               /* Unsigned 8 bit data (WAV and RAW only) */
  
  SF_FORMAT_FLOAT                 = 0x0006,               /* 32 bit float data */
  SF_FORMAT_DOUBLE                = 0x0007,               /* 64 bit float data */
  SF_FORMAT_SUBMASK               = 0x0000FFFF,
  SF_FORMAT_TYPEMASK              = 0x0FFF0000,
  SF_FORMAT_ENDMASK               = 0x30000000,
  
  SF_FORMAT_ULAW                  = 0x0010,               /* U-Law encoded. */
  SF_FORMAT_ALAW                  = 0x0011,               /* A-Law encoded. */
  SF_FORMAT_IMA_ADPCM             = 0x0012,               /* IMA ADPCM. */
  SF_FORMAT_MS_ADPCM              = 0x0013,               /* Microsoft ADPCM. */
  
  SF_FORMAT_GSM610                = 0x0020,               /* GSM 6.10 encoding. */
  SF_FORMAT_VOX_ADPCM             = 0x0021,               /* OKI / Dialogix ADPCM */
  
  SF_FORMAT_G721_32               = 0x0030,               /* 32kbs G721 ADPCM encoding. */
  SF_FORMAT_G723_24               = 0x0031,               /* 24kbs G723 ADPCM encoding. */
  SF_FORMAT_G723_40               = 0x0032,               /* 40kbs G723 ADPCM encoding. */
  
  SF_FORMAT_DWVW_12               = 0x0040,               /* 12 bit Delta Width Variable Word encoding. */
  SF_FORMAT_DWVW_16               = 0x0041,               /* 16 bit Delta Width Variable Word encoding. */
  SF_FORMAT_DWVW_24               = 0x0042,               /* 24 bit Delta Width Variable Word encoding. */
  SF_FORMAT_DWVW_N                = 0x0043,               /* N bit Delta Width Variable Word encoding. */
  
  SF_FORMAT_DPCM_8                = 0x0050,               /* 8 bit differential PCM (XI only) */
  SF_FORMAT_DPCM_16               = 0x0051,               /* 16 bit differential PCM (XI only) */
  
  SF_FORMAT_VORBIS                = 0x0060,               /* Xiph Vorbis encoding. */
  
  SF_FORMAT_ALAC_16               = 0x0070,               /* Apple Lossless Audio Codec (16 bit). */
  SF_FORMAT_ALAC_20               = 0x0071,               /* Apple Lossless Audio Codec (20 bit). */
  SF_FORMAT_ALAC_24               = 0x0072,               /* Apple Lossless Audio Codec (24 bit). */
  SF_FORMAT_ALAC_32               = 0x0073,               /* Apple Lossless Audio Codec (32 bit). */
  
  /* Endian-ness options. */
  
  SF_ENDIAN_FILE                  = 0x00000000,   /* Default file endian-ness. */
  SF_ENDIAN_LITTLE                = 0x10000000,   /* Force little endian-ness. */
  SF_ENDIAN_BIG                   = 0x20000000,   /* Force big endian-ness. */
  SF_ENDIAN_CPU                   = 0x30000000,   /* Force CPU endian-ness. */
  
};

enum
{
  SFC_GET_LIB_VERSION                             = 0x1000,
  SFC_GET_LOG_INFO                                = 0x1001,
  SFC_GET_CURRENT_SF_INFO                 = 0x1002,
  
  
  SFC_GET_NORM_DOUBLE                             = 0x1010,
  SFC_GET_NORM_FLOAT                              = 0x1011,
  SFC_SET_NORM_DOUBLE                             = 0x1012,
  SFC_SET_NORM_FLOAT                              = 0x1013,
  SFC_SET_SCALE_FLOAT_INT_READ    = 0x1014,
  SFC_SET_SCALE_INT_FLOAT_WRITE   = 0x1015,
  
  SFC_GET_SIMPLE_FORMAT_COUNT             = 0x1020,
  SFC_GET_SIMPLE_FORMAT                   = 0x1021,
  
  SFC_GET_FORMAT_INFO                             = 0x1028,
  
  SFC_GET_FORMAT_MAJOR_COUNT              = 0x1030,
  SFC_GET_FORMAT_MAJOR                    = 0x1031,
  SFC_GET_FORMAT_SUBTYPE_COUNT    = 0x1032,
  SFC_GET_FORMAT_SUBTYPE                  = 0x1033,
  
  SFC_CALC_SIGNAL_MAX                             = 0x1040,
  SFC_CALC_NORM_SIGNAL_MAX                = 0x1041,
  SFC_CALC_MAX_ALL_CHANNELS               = 0x1042,
  SFC_CALC_NORM_MAX_ALL_CHANNELS  = 0x1043,
  SFC_GET_SIGNAL_MAX                              = 0x1044,
  SFC_GET_MAX_ALL_CHANNELS                = 0x1045,

  SFC_SET_ADD_PEAK_CHUNK                  = 0x1050,
  SFC_SET_ADD_HEADER_PAD_CHUNK    = 0x1051,

  SFC_UPDATE_HEADER_NOW                   = 0x1060,
  SFC_SET_UPDATE_HEADER_AUTO              = 0x1061,
  
  SFC_FILE_TRUNCATE                               = 0x1080,
  
  SFC_SET_RAW_START_OFFSET                = 0x1090,
  
  SFC_SET_DITHER_ON_WRITE                 = 0x10A0,
  SFC_SET_DITHER_ON_READ                  = 0x10A1,

  SFC_GET_DITHER_INFO_COUNT               = 0x10A2,
  SFC_GET_DITHER_INFO                             = 0x10A3,
  
  SFC_GET_EMBED_FILE_INFO                 = 0x10B0,
  
  SFC_SET_CLIPPING                                = 0x10C0,
  SFC_GET_CLIPPING                                = 0x10C1,
  
  SFC_GET_CUE_COUNT                               = 0x10CD,
  SFC_GET_CUE                                             = 0x10CE,
  SFC_SET_CUE                                             = 0x10CF,
  
  SFC_GET_INSTRUMENT                              = 0x10D0,
  SFC_SET_INSTRUMENT                              = 0x10D1,
  
  SFC_GET_LOOP_INFO                               = 0x10E0,
  
  SFC_GET_BROADCAST_INFO                  = 0x10F0,
  SFC_SET_BROADCAST_INFO                  = 0x10F1,
  
  SFC_GET_CHANNEL_MAP_INFO                = 0x1100,
  SFC_SET_CHANNEL_MAP_INFO                = 0x1101,
  
  SFC_RAW_DATA_NEEDS_ENDSWAP              = 0x1110,
  
  /* Support for Wavex Ambisonics Format */
  SFC_WAVEX_SET_AMBISONIC                 = 0x1200,
  SFC_WAVEX_GET_AMBISONIC                 = 0x1201,
  
  /*
  ** RF64 files can be set so that on-close, writable files that have less
  ** than 4GB of data in them are converted to RIFF/WAV, as per EBU
  ** recommendations.
  */
  SFC_RF64_AUTO_DOWNGRADE                 = 0x1210,
  SFC_SET_VBR_ENCODING_QUALITY    = 0x1300,
  SFC_SET_COMPRESSION_LEVEL               = 0x1301,
  
  /* Cart Chunk support */
  SFC_SET_CART_INFO                               = 0x1400,
  SFC_GET_CART_INFO                               = 0x1401,
  
  /* Following commands for testing only. */
  SFC_TEST_IEEE_FLOAT_REPLACE             = 0x6001,
  
  /*
  ** SFC_SET_ADD_* values are deprecated and will disappear at some
  ** time in the future. They are guaranteed to be here up to and
  ** including version 1.0.8 to avoid breakage of existing software.
  ** They currently do nothing and will continue to do nothing.
  */
  SFC_SET_ADD_DITHER_ON_WRITE             = 0x1070,
  SFC_SET_ADD_DITHER_ON_READ              = 0x1071
};
enum
{
  SF_STR_TITLE                                    = 0x01,
  SF_STR_COPYRIGHT                                = 0x02,
  SF_STR_SOFTWARE                                 = 0x03,
  SF_STR_ARTIST                                   = 0x04,
  SF_STR_COMMENT                                  = 0x05,
  SF_STR_DATE                                             = 0x06,
  SF_STR_ALBUM                                    = 0x07,
  SF_STR_LICENSE                                  = 0x08,
  SF_STR_TRACKNUMBER                              = 0x09,
  SF_STR_GENRE                                    = 0x10
};

typedef struct
{
  int                     format ;
  const char      *name ;
  const char      *extension ;
} SF_FORMAT_INFO;

typedef struct
{
  unsigned int sample_offset ;
  char name [256] ;
} SF_CUE_POINT;

typedef struct
{
  int             cue_count ;
  SF_CUE_POINT cue_points [100] ;
} SF_CUES;

#define SF_STR_FIRST    SF_STR_TITLE
#define SF_STR_LAST     SF_STR_GENRE

SNDFILE*  sf_open (const char*, int, SF_INFO*){return 0;}
SNDFILE* sf_open_fd (int, int, SF_INFO*, int){return 0;}
int  sf_error  (SNDFILE *) {return 0;}
const char* sf_strerror (SNDFILE *){return "";}
const char*     sf_error_number (int ) {return "";}

int sf_command(SNDFILE *, int , void *, int ) {return 0;}
int sf_format_check (const SF_INFO *) {return 0;}
sf_count_t sf_seek  (SNDFILE *, sf_count_t , int ) {return 0;}
int sf_set_string (SNDFILE *, int, const char* ) {return 0;}
const char* sf_get_string (SNDFILE *, int) {return "";}
const char * sf_version_string (void) {return "";}
sf_count_t sf_read_raw (SNDFILE *, void *, sf_count_t) {return 0;}
sf_count_t sf_write_raw(SNDFILE *, const void *, sf_count_t ) {return 0;}
sf_count_t sf_readf_short  (SNDFILE *, short *, sf_count_t ){return 0;} 
sf_count_t sf_writef_short (SNDFILE *, const short *, sf_count_t ) {return 0;} 

sf_count_t sf_readf_int(SNDFILE *, int *, sf_count_t ) {return 0;} 
sf_count_t sf_writef_int(SNDFILE *, const int *, sf_count_t ) {return 0;} 

sf_count_t sf_readf_float(SNDFILE *sndfile, float *ptr, sf_count_t frames) {return 0;} 
sf_count_t sf_writef_float(SNDFILE *sndfile, const float *ptr, sf_count_t frames) {return 0;} 

sf_count_t sf_readf_double(SNDFILE *, double *, sf_count_t ) {return 0;} 
sf_count_t sf_writef_double(SNDFILE *, const double *, sf_count_t ) {return 0;} 

sf_count_t sf_read_short  (SNDFILE *, short *, sf_count_t ){return 0;} 
sf_count_t sf_write_short (SNDFILE *, const short *, sf_count_t ) {return 0;} 

sf_count_t sf_read_int(SNDFILE *, int *, sf_count_t ) {return 0;} 
sf_count_t sf_write_int(SNDFILE *, const int *, sf_count_t ) {return 0;} 

sf_count_t sf_read_float(SNDFILE *sndfile, float *ptr, sf_count_t frames) {return 0;} 
sf_count_t sf_write_float(SNDFILE *sndfile, const float *ptr, sf_count_t frames) {return 0;} 

sf_count_t sf_read_double(SNDFILE *, double *, sf_count_t ) {return 0;} 
sf_count_t sf_write_double(SNDFILE *, const double *, sf_count_t ) {return 0;} 

void    sf_write_sync   (SNDFILE *) {}
int sf_close(SNDFILE *) {return 0;}
#endif

#include <string>
#include <new> // for std::nothrow

class SndfileHandle
{	private :
		struct SNDFILE_ref
		{	SNDFILE_ref (void) ;
			~SNDFILE_ref (void) ;

			SNDFILE *sf ;
			SF_INFO sfinfo ;
			int ref ;
			} ;

		SNDFILE_ref *p ;

	public :
			/* Default constructor */
			SndfileHandle (void) : p (NULL) {} ;
			SndfileHandle (const char *path, int mode = SFM_READ,
							int format = 0, int channels = 0, int samplerate = 0) ;
			SndfileHandle (std::string const & path, int mode = SFM_READ,
							int format = 0, int channels = 0, int samplerate = 0) ;
			SndfileHandle (int fd, bool close_desc, int mode = SFM_READ,
							int format = 0, int channels = 0, int samplerate = 0) ;

#ifdef ENABLE_SNDFILE_WINDOWS_PROTOTYPES
			SndfileHandle (LPCWSTR wpath, int mode = SFM_READ,
							int format = 0, int channels = 0, int samplerate = 0) ;
#endif

			~SndfileHandle (void) ;

			SndfileHandle (const SndfileHandle &orig) ;
			SndfileHandle & operator = (const SndfileHandle &rhs) ;

		/* Mainly for debugging/testing. */
		int refCount (void) const { return (p == NULL) ? 0 : p->ref ; }

		operator bool () const { return (p != NULL) ; }

		bool operator == (const SndfileHandle &rhs) const { return (p == rhs.p) ; }

		sf_count_t	frames (void) const		{ return p ? p->sfinfo.frames : 0 ; }
		int		format (void) const		{ return p ? p->sfinfo.format : 0 ; }
		int     	channels (void) const	{ return p ? p->sfinfo.channels : 0 ; }
		int		samplerate (void) const { return p ? p->sfinfo.samplerate : 0 ; }
                int             seekable(void) const {return p ? p->sfinfo.seekable : 0 ;} 
		int error (void) const ;
		const char * strError (void) const ;

		int command (int cmd, void *data, int datasize) ;

		sf_count_t	seek (sf_count_t frames, int whence) ;

		void writeSync (void) ;

		int setString (int str_type, const char* str) ;

		const char* getString (int str_type) const ;

		static int formatCheck (int format, int channels, int samplerate) ;

		sf_count_t read (short *ptr, sf_count_t items) ;
		sf_count_t read (int *ptr, sf_count_t items) ;
		sf_count_t read (float *ptr, sf_count_t items) ;
		sf_count_t read (double *ptr, sf_count_t items) ;

		sf_count_t write (const short *ptr, sf_count_t items) ;
		sf_count_t write (const int *ptr, sf_count_t items) ;
		sf_count_t write (const float *ptr, sf_count_t items) ;
		sf_count_t write (const double *ptr, sf_count_t items) ;

		sf_count_t readf (short *ptr, sf_count_t frames) ;
		sf_count_t readf (int *ptr, sf_count_t frames) ;
		sf_count_t readf (float *ptr, sf_count_t frames) ;
		sf_count_t readf (double *ptr, sf_count_t frames) ;

		sf_count_t writef (const short *ptr, sf_count_t frames) ;
		sf_count_t writef (const int *ptr, sf_count_t frames) ;
		sf_count_t writef (const float *ptr, sf_count_t frames) ;
		sf_count_t writef (const double *ptr, sf_count_t frames) ;

		sf_count_t	readRaw		(void *ptr, sf_count_t bytes) ;
		sf_count_t	writeRaw	(const void *ptr, sf_count_t bytes) ;

        int get_cue_count(void) {
           int num_cues = 0;
           int ret =sf_command (p->sf, SFC_GET_CUE_COUNT, &num_cues, sizeof(num_cues));

           if (ret == 0)
              return 0;
           return num_cues;
        }

		/**< Raw access to the handle. SndfileHandle keeps ownership. */
		SNDFILE * rawHandle (void) ;

		/**< Take ownership of handle, iff reference count is 1. */
		SNDFILE * takeOwnership (void) ;
} ;

/*==============================================================================
**	Nothing but implementation below.
*/

inline
SndfileHandle::SNDFILE_ref::SNDFILE_ref (void)
: ref (1)
{}

inline
SndfileHandle::SNDFILE_ref::~SNDFILE_ref (void)
{	if (sf != NULL) sf_close (sf) ; }

inline
SndfileHandle::SndfileHandle (const char *path, int mode, int fmt, int chans, int srate)
: p (NULL)
{
	p = new (std::nothrow) SNDFILE_ref () ;

	if (p != NULL)
	{	p->ref = 1 ;

		p->sfinfo.frames = 0 ;
		p->sfinfo.channels = chans ;
		p->sfinfo.format = fmt ;
		p->sfinfo.samplerate = srate ;
		p->sfinfo.sections = 0 ;
		p->sfinfo.seekable = 0 ;

		p->sf = sf_open (path, mode, &p->sfinfo) ;
		} ;

	return ;
} /* SndfileHandle const char * constructor */

inline
SndfileHandle::SndfileHandle (std::string const & path, int mode, int fmt, int chans, int srate)
: p (NULL)
{
	p = new (std::nothrow) SNDFILE_ref () ;

	if (p != NULL)
	{	p->ref = 1 ;

		p->sfinfo.frames = 0 ;
		p->sfinfo.channels = chans ;
		p->sfinfo.format = fmt ;
		p->sfinfo.samplerate = srate ;
		p->sfinfo.sections = 0 ;
		p->sfinfo.seekable = 0 ;

		p->sf = sf_open (path.c_str (), mode, &p->sfinfo) ;
		} ;

	return ;
} /* SndfileHandle std::string constructor */

inline
SndfileHandle::SndfileHandle (int fd, bool close_desc, int mode, int fmt, int chans, int srate)
: p (NULL)
{
	if (fd < 0)
		return ;

	p = new (std::nothrow) SNDFILE_ref () ;

	if (p != NULL)
	{	p->ref = 1 ;

		p->sfinfo.frames = 0 ;
		p->sfinfo.channels = chans ;
		p->sfinfo.format = fmt ;
		p->sfinfo.samplerate = srate ;
		p->sfinfo.sections = 0 ;
		p->sfinfo.seekable = 0 ;

		p->sf = sf_open_fd (fd, mode, &p->sfinfo, close_desc) ;
		} ;

	return ;
} /* SndfileHandle fd constructor */

inline
SndfileHandle::~SndfileHandle (void)
{	if (p != NULL && --p->ref == 0)
		delete p ;
} /* SndfileHandle destructor */


inline
SndfileHandle::SndfileHandle (const SndfileHandle &orig)
: p (orig.p)
{	if (p != NULL)
		++p->ref ;
} /* SndfileHandle copy constructor */

inline SndfileHandle &
SndfileHandle::operator = (const SndfileHandle &rhs)
{
	if (&rhs == this)
		return *this ;
	if (p != NULL && --p->ref == 0)
		delete p ;

	p = rhs.p ;
	if (p != NULL)
		++p->ref ;

	return *this ;
} /* SndfileHandle assignment operator */

inline int
SndfileHandle::error (void) const
{	return sf_error (p->sf) ; }

inline const char *
SndfileHandle::strError (void) const
{	return sf_strerror (p->sf) ; }

inline int
SndfileHandle::command (int cmd, void *data, int datasize)
{	return sf_command (p->sf, cmd, data, datasize) ; }

inline sf_count_t
SndfileHandle::seek (sf_count_t frame_count, int whence)
{	return sf_seek (p->sf, frame_count, whence) ; }

inline void
SndfileHandle::writeSync (void)
{	sf_write_sync (p->sf) ; }

inline int
SndfileHandle::setString (int str_type, const char* str)
{	return sf_set_string (p->sf, str_type, str) ; }

inline const char*
SndfileHandle::getString (int str_type) const
{	return sf_get_string (p->sf, str_type) ; }

inline int
SndfileHandle::formatCheck (int fmt, int chans, int srate)
{
	SF_INFO sfinfo ;

	sfinfo.frames = 0 ;
	sfinfo.channels = chans ;
	sfinfo.format = fmt ;
	sfinfo.samplerate = srate ;
	sfinfo.sections = 0 ;
	sfinfo.seekable = 0 ;

	return sf_format_check (&sfinfo) ;
}

/*---------------------------------------------------------------------*/

inline sf_count_t
SndfileHandle::read (short *ptr, sf_count_t items)
{	return sf_read_short (p->sf, ptr, items) ; }

inline sf_count_t
SndfileHandle::read (int *ptr, sf_count_t items)
{	return sf_read_int (p->sf, ptr, items) ; }

inline sf_count_t
SndfileHandle::read (float *ptr, sf_count_t items)
{	return sf_read_float (p->sf, ptr, items) ; }

inline sf_count_t
SndfileHandle::read (double *ptr, sf_count_t items)
{	return sf_read_double (p->sf, ptr, items) ; }

inline sf_count_t
SndfileHandle::write (const short *ptr, sf_count_t items)
{	return sf_write_short (p->sf, ptr, items) ; }

inline sf_count_t
SndfileHandle::write (const int *ptr, sf_count_t items)
{	return sf_write_int (p->sf, ptr, items) ; }

inline sf_count_t
SndfileHandle::write (const float *ptr, sf_count_t items)
{	return sf_write_float (p->sf, ptr, items) ; }

inline sf_count_t
SndfileHandle::write (const double *ptr, sf_count_t items)
{	return sf_write_double (p->sf, ptr, items) ; }

inline sf_count_t
SndfileHandle::readf (short *ptr, sf_count_t frame_count)
{	return sf_readf_short (p->sf, ptr, frame_count) ; }

inline sf_count_t
SndfileHandle::readf (int *ptr, sf_count_t frame_count)
{	return sf_readf_int (p->sf, ptr, frame_count) ; }

inline sf_count_t
SndfileHandle::readf (float *ptr, sf_count_t frame_count)
{	return sf_readf_float (p->sf, ptr, frame_count) ; }

inline sf_count_t
SndfileHandle::readf (double *ptr, sf_count_t frame_count)
{	return sf_readf_double (p->sf, ptr, frame_count) ; }

inline sf_count_t
SndfileHandle::writef (const short *ptr, sf_count_t frame_count)
{	return sf_writef_short (p->sf, ptr, frame_count) ; }

inline sf_count_t
SndfileHandle::writef (const int *ptr, sf_count_t frame_count)
{	return sf_writef_int (p->sf, ptr, frame_count) ; }

inline sf_count_t
SndfileHandle::writef (const float *ptr, sf_count_t frame_count)
{	return sf_writef_float (p->sf, ptr, frame_count) ; }

inline sf_count_t
SndfileHandle::writef (const double *ptr, sf_count_t frame_count)
{	return sf_writef_double (p->sf, ptr, frame_count) ; }

inline sf_count_t
SndfileHandle::readRaw (void *ptr, sf_count_t bytes)
{	return sf_read_raw (p->sf, ptr, bytes) ; }

inline sf_count_t
SndfileHandle::writeRaw (const void *ptr, sf_count_t bytes)
{	return sf_write_raw (p->sf, ptr, bytes) ; }

inline SNDFILE *
SndfileHandle::rawHandle (void)
{	return (p ? p->sf : NULL) ; }

inline SNDFILE *
SndfileHandle::takeOwnership (void)
{
	if (p == NULL || (p->ref != 1))
		return NULL ;

	SNDFILE * sf = p->sf ;
	p->sf = NULL ;
	delete p ;
	p = NULL ;
	return sf ;
}

#ifdef ENABLE_SNDFILE_WINDOWS_PROTOTYPES

inline
SndfileHandle::SndfileHandle (LPCWSTR wpath, int mode, int fmt, int chans, int srate)
: p (NULL)
{
	p = new (std::nothrow) SNDFILE_ref () ;

	if (p != NULL)
	{	p->ref = 1 ;

		p->sfinfo.frames = 0 ;
		p->sfinfo.channels = chans ;
		p->sfinfo.format = fmt ;
		p->sfinfo.samplerate = srate ;
		p->sfinfo.sections = 0 ;
		p->sfinfo.seekable = 0 ;

		p->sf = sf_wchar_open (wpath, mode, &p->sfinfo) ;
		} ;

	return ;
} /* SndfileHandle const wchar_t * constructor */

#endif

#endif	/* SNDFILE_HH */

