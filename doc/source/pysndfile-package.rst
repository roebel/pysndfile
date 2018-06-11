pysndfile package
===================

============================================

pysndfile.sndio module
----------------------

.. automodule:: pysndfile.sndio
    :members:
    :undoc-members:
    :show-inheritance:

============================================
       
PySndfile wrapper class and methods
------------------------------------

Mappings from libsndfile enums to pysndfile strings
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

.. data:: pysndfile.stringtype_name_to_id
   dict mapping of pysndfile's stringtype nams to libsndfile's stringtype ids.

.. data:: pysndfile.stringtype_id_to_name
   dict mapping of libsndfile's stringtype ids to pysndfile's stringtype names.

.. data:: pysndfile.commands_name_to_id
   dict mapping of pysndfile's commandtype names to libsndfile's commandtype ids.

.. data:: pysndfile.commands_id_to_name
   dict mapping of libsndfile's commandtype ids to pysndfile's commandtype names.

.. data:: pysndfile.endian_name_to_id
   dict mapping of pysndfile's endian names to libsndfile's endian ids.

.. data:: pysndfile.endian_id_to_name
   dict mapping of libsndfile's endian ids to pysndfile's endian names.

.. data:: pysndfile.fileformat_name_to_id
   dict mapping of pysndfile's fileformat names to libsndfile's major fileformat ids.

.. data:: pysndfile.fileformat_id_to_name
   dict mapping of libsndfile's major fileformat ids to pysndfile's major fileformat names.


Support functions
^^^^^^^^^^^^^^^^^^^^^^^^^^^^

.. autofunction:: pysndfile.construct_format
.. autofunction:: pysndfile.get_pysndfile_version
.. autofunction:: pysndfile.get_sndfile_version
.. autofunction:: pysndfile.get_sndfile_formats
.. autofunction:: pysndfile.get_sndfile_encodings
.. autofunction:: pysndfile.get_sf_log

PySndfile class
^^^^^^^^^^^^^^^^^^^

.. autoclass:: pysndfile.PySndfile
    :members:
    :undoc-members:
    :show-inheritance:


