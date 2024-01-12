#!/usr/bin/env python3
import subprocess
import click
from json import load
from dataclasses import dataclass, field
from time import sleep
from typing import Callable, Optional
import logging
import asyncio
from async_lines import start_dialogue

_LOGGER = logging.getLogger(__name__)


async def get_tv_status(dialogue):
    async for line in dialogue.conduct(('pow 0',)):
        split_line = line.split('power status: ', 1)
        result = None
        if len(split_line) == 2:
            _LOGGER.debug('reported status %s', split_line[1])
            result = split_line[1]

    return result
    # Can return: 'on', 'standby', 'in transition from standby to on', 'in transition from on to standby'

async def set_tv_on(dialogue):
    async for _ in dialogue.conduct(('on 0',)):
        pass

    await asyncio.sleep(15)
    status = await get_tv_status(dialogue)
    if status != 'on':
        raise RuntimeError(f'TV not on, status={status}')
    async for line in dialogue.conduct(('tx 1F:82:20:00',)):  # Switch input source
        if line == 'waiting for input':
            return

async def set_tv_standby(dialogue):
    async for _ in dialogue.conduct(('standby 0',)):
        pass
    await get_tv_status(dialogue)
    await asyncio.sleep(15)
    status = await get_tv_status(dialogue)
    if status != 'standby':
        raise RuntimeError(f'TV not off, status={status}')
 
async def main_loop(configuration_file_name):
    dialogue = await start_dialogue('/usr/bin/cec-client')
    
    while True:
        await asyncio.sleep(1)
        tv_status = await get_tv_status(dialogue)
        is_source_up = get_source_status(configuration_file_name)

        if (is_source_up, tv_status) == (True, 'standby'):
            _LOGGER.info('Source up, TV standby. Turning TV on.')
            await set_tv_on(dialogue)
        elif (is_source_up, tv_status) == (False, 'on'):
            _LOGGER.info('Source down, TV on. Setting TV to standby.')
            await set_tv_standby(dialogue)

@dataclass
class _Configuration(object):
    poll_shell_script: str
    poll_interval_seconds: int


def get_source_status(configuration_file_name: str):
    with open(configuration_file_name, 'rt') as configuration_file:
        configuration = _Configuration(**load(configuration_file))

        outcome = subprocess.run(configuration.poll_shell_script, shell=True, capture_output=True)
        _LOGGER.debug(f'Check outcome is {outcome}')

        return outcome.returncode == 0


def _logging_levelstr_to_level(levelstr: str):
    return logging.getLevelNamesMapping()[levelstr]


@click.command()
@click.option('-v', '--logging-level', type=_logging_levelstr_to_level, help='Logging level', default='INFO')
@click.option('-c', '--configuration', 'configuration_file_name', type=click.Path(), help='JSON configuration file')
def main(configuration_file_name: str, logging_level):
    logging.basicConfig(level=logging_level, format='%(asctime)s %(levelname)-8s %(message)s')
    asyncio.get_event_loop().run_until_complete(main_loop(configuration_file_name))

if __name__ == '__main__':
    main()
