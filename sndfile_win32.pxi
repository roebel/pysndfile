from libc.stddef cimport wchar_t

cdef extern from *:
    """
    #define ENABLE_SNDFILE_WINDOWS_PROTOTYPES 1
    """

cdef extern from "Windows.h":
    ctypedef const wchar_t *LPCWSTR

cdef extern from "Python.h":
    wchar_t* PyUnicode_AsWideCharString(object, Py_ssize_t *)
    void PyMem_Free(void *p)


cdef extern from "pysndfile.hh":
    cdef cppclass SndfileHandle :
        SndfileHandle(const char *path, int mode, int format, int channels, int samplerate)
        SndfileHandle(const int fh, int close_desc, int mode, int format, int channels, int samplerate)
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
