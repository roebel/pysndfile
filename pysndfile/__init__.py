from __future__ import absolute_import
#
# Copyright (C) 2014 IRCAM
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
from ._pysndfile import PySndfile, get_pysndfile_version, get_sndfile_version, get_sndfile_formats, get_sndfile_encodings, get_sf_log, construct_format, encoding_id_to_name, encoding_name_to_id, max_supported_string_length, fileformat_name_to_id, fileformat_id_to_name, endian_name_to_id, endian_id_to_name, commands_name_to_id, commands_id_to_name, stringtype_name_to_id, stringtype_id_to_name, SF_FORMAT_SUBMASK, SF_FORMAT_TYPEMASK, SF_FORMAT_ENDMASK

from . import sndio
from . import Faiff

__all__ = [
    "PySndfile", "construct_format", "get_pysndfile_version", "get_sndfile_version",
    "get_sndfile_formats", "get_sndfile_encodings", "get_sf_log",
    "encoding_id_to_name", "encoding_name_to_id", "max_supported_string_length",
    "fileformat_name_to_id", "fileformat_id_to_name", "endian_name_to_id",
    "endian_id_to_name", "commands_name_to_id", "commands_id_to_name",
    "stringtype_name_to_id", "stringtype_id_to_name",
    "sndio", "Faiff", "SF_FORMAT_SUBMASK", "SF_FORMAT_TYPEMASK", "SF_FORMAT_ENDMASK"
    ]
