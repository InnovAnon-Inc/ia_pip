#! /usr/bin/env python
# cython: language_level=3
# distutils: language=c++

""" pip """

import asyncio
import os
from pathlib                                 import Path
import subprocess
from typing                                  import List, Optional, Iterable
from typing                                  import ParamSpec

from structlog                               import get_logger

from ia_check_output.typ                     import Command
from ia_check_output.typ                     import Environment
from ia_check_output.main                    import acheck_output

P     :ParamSpec = ParamSpec('P')
logger           = get_logger()

# TODO

##
#
##

def _pip(
	mode           :str,
	*args          :P.args,
	is_remote      :bool=True,
	is_requirements:bool=False,
	**kwargs       :P.kwargs,
)->None:
	_args:List[str] = [ 'pip', mode, '--no-input', ]
	if is_remote:
		_args.extend(['--retries', '30', '--timeout', '1200',])
	if is_requirements:
		_args.extend(['-r', 'requirements.txt',])
	_args.extend(args)
	env  :Environment   = dict(os.environ)
	env['PAGER']        = 'groff -Tutf8 -mandoc'
	return (_args, env,)

async def pip_helper(
	mode           :str,
	*args          :P.args,
	is_remote      :bool=True,
	is_requirements:bool=False,
	**kwargs       :P.kwargs,
)->None:
	cmd:Command
	env:Environment
	cmd, env = _pip(
		mode,
		*args, **kwargs,)
	await logger.ainfo('cmd: %s', cmd)
	return await acheck_output(cmd, env=env, universal_newlines=True, **kwargs,)

async def pip_install(*args:str, **kwargs:P.kwargs,)->None:
	await pip_helper('install', *args, **kwargs,)

async def pip_wheel(mode:str, wheel_dir:Path, *args:str, **kwargs:P.kwargs,)->None:
	await pip_helper('wheel', mode, str(wheel_dir), *args, **kwargs,)

async def pip_wheel_build(wheel_dir:Path, *args:P.args, **kwargs:P.kwargs,)->None:
	await pip_wheel('--wheel-dir', wheel_dir, *args, **kwargs,)

async def pip_wheel_install(wheel_dir:Path, *args:P.args, **kwargs:P.kwargs,)->None:
	await pip_helper('--find-links', wheel_dir, *args, **kwargs,)

async def pip_install_requirements_v1(*args:P.args, **kwargs:P.kwargs)->None:
	""" pip install -r requirements.txt """
	await pip_install(*args, is_remote=True, is_requirements=True, **kwargs,)

async def pip_install_dot_v1(*args:P.args, **kwargs:P.kwargs)->None:
	""" pip install . """
	await pip_install('.', *args, is_remote=False, is_requirements=False, **kwargs,)

async def pip_wheel_requirements(wheel_dir:Path, *args:P.args, **kwargs:P.kwargs,)->None:
	""" pip wheel --wheel-dir {wheel_dir} -r requirements.txt """
	await pip_wheel_build(wheel_dir, *args, is_remote=True, is_requirements=True, **kwargs,)

async def pip_wheel_dot(wheel_dir:Path, *args:P.args, **kwargs:P.kwargs,)->None:
	""" pip wheel --wheel-dir {wheel_dir} . """
	await pip_wheel_build(wheel_dir, *args, is_remote=False, is_requirements=False, **kwargs,)

async def pip_install_requirements_v2(wheel_dir:Path, *args:P.args, **kwargs:P.kwargs,)->None:
	""" pip install --find-links {wheel_dir} -r requirements.txt """
	await pip_wheel_install(wheel_dir, *args, is_remote=False, is_requirements=True, **kwargs,)

async def pip_install_dot_v2(wheel_dir:Path, *args:P.args, **kwargs:P.kwargs,)->None:
	""" pip install --find-links {wheel_dir} . """
	await pip_wheel_install(wheel_dir, '.', *args, is_remote=False, is_requirements=False, **kwargs,)

##
#
##

async def pip_v1(*args:P.args, **kwargs:P.kwargs,)->None:
	await pip_install_requirements_v1(*args, **kwargs,)
	await pip_install_dot_v1         (*args, **kwargs,)

async def pip_v2_build              (wheel_dir:Path, *args:P.args, **kwargs:P.kwargs,)->None:
	await pip_wheel_requirements(wheel_dir, *args, **kwargs,)
	await pip_wheel_dot         (wheel_dir, *args, **kwargs,)

async def pip_v2_install                 (wheel_dir:Path, *args:P.args, **kwargs:P.kwargs,)->None:
	await pip_install_requirements_v2(wheel_dir, *args, **kwargs,)
	await pip_install_dot_v2         (wheel_dir, *args, **kwargs,)

async def pip_v2            (wheel_dir:Path, *args:P.args, **kwargs:P.kwargs,)->None:
	await pip_v2_build  (wheel_dir, *args, **kwargs,)
	await pip_v2_install(wheel_dir, *args, **kwargs,)

##
#
##

async def pip_upgrade(*pkgs:str,)->None:
	await pip_install('--upgrade', *pkgs, is_remote=True, is_requirements=False,)

async def pip_upgrade_pip()->None:
	await pip_upgrade('pip',)

##
#
##

async def _main()->None:
	await pip_upgrade_pip()

def main()->None:
	asyncio.run(_main())

if __name__ == '__main__':
	main()

__author__:str = 'you.com' # NOQA
