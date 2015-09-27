from setuptools import setup, find_packages
from codecs import open
from os import path

here = path.abspath(path.dirname(__file__))

with open(path.join(here, 'DESCRIPTION.md'), encoding='utf-8') as f:
    long_description = f.read()
with open(os.path.join(mypackage_root_dir, 'VERSION')) as version_file:
    version = version_file.read().strip()

steup(
    name='cinch',
    version=version,
    description='A manager of big files.',
    long_description=long_description,
    url='https://github.com/weakish/cinch/',
    author='Jakukyo Friel',
    author_email='weakish@gmail.com',
    license='BSD-0-Clause',
    keyword='archiving backup sync annex console',

    classifiers=[
        'Development Status :: 1 - Planning',
        'Environment :: Console',
        'Intended Audience :: End Users/Desktop',
        'License :: Freely Distributable',
        'Natural Language :: English',
        'Operating System :: POSIX',
        'Programming Language :: Python :: 2.7',
        'Topic :: System :: Archiving',
    ],

    packages=find_packages(),
    install_requires=[
        'pycapnp',
        'xxhash'
    ],
    include_package_data = True,


)
