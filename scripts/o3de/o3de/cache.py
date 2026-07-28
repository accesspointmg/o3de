#
# Copyright (c) Contributors to the Open 3D Engine Project.
# For complete copyright and license terms please see the LICENSE at the root of this distribution.
#
# SPDX-License-Identifier: Apache-2.0 OR MIT
#
#

import argparse
import json
import logging
import pathlib
import sys
import urllib.parse
import urllib.request
import hashlib
from datetime import datetime, timezone
from o3de import o3de_object, utils, validation

logger = logging.getLogger('o3de.cache')
logging.basicConfig(format=utils.LOG_FORMAT)


def get_cache_file_uri(uri: str):
    # check if the passed in uri is a path or uri
    uri_path = pathlib.Path(uri)
    if uri_path.exists():
        uri = uri_path.as_uri()

    # convert the uri to a cache file path
    parsed_uri = urllib.parse.urlparse(uri)
    uri_sha256 = hashlib.sha256(parsed_uri.geturl().encode())
    cache_file = o3de_object.get_user_o3de_cache_path() / str(uri_sha256.hexdigest())
    return cache_file, parsed_uri


def _run_cache(args: argparse) -> int:
    if args.get_cache_file_uri:
        cache_file, parsed_uri = get_cache_file_uri(args.get_cache_file_uri)
        print (f'Cache file: {cache_file}')
        return 0

    return 1 
    
def add_args(subparsers) -> None:
    """
    add_args is called to add subparsers arguments to each command such that it can be
    a central python file such as o3de.py.
    It can be run from the o3de.py script as follows
    call add_args and execute: python o3de.py cache --get-cache-file-uri https://apmg/Marine/gem.json

    :param subparsers: the caller instantiates subparsers and passes it in here
    """
    cache_subparser = subparsers.add_parser('cache')

    group = cache_subparser.add_mutually_exclusive_group(required=False)
    group.add_argument('-gcfu', '--get-cache-file-uri', type=str, required=False,
                       help='returns the cache file associated with the uri')

    cache_subparser.set_defaults(func=_run_cache)