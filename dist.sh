#! /bin/bash

python setup.py sdist
echo now do
echo twine upload -r test dist/pysndfile-1.3.2.tar.gz
echo for testing and
echo twine upload -r pypi dist/pysndfile-1.3.2.tar.gz
echo for final distribution
