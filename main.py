#!/usr/bin/env python3
import subprocess
import click
from json import load
from dataclasses import dataclass, field
from time import sleep
from typing import Callable, Optional
import logging
import click_log
import asyncio
from async_lines import start_dialogue

_logger = logging.getLogger(__name__)
click_log.basic_config(_logger)


async def get_tv_status(dialogue):
    dialogue.send_line('pow 0')
    async for line in dialogue.get_lines():
        if line.startswith('power status'):
            return line == 'power status: on'
            break

async def set_tv_on(dialogue):
    dialogue.send_line('on 0')

    await get_tv_status(dialogue)
    await asyncio.sleep(15)
    status = await get_tv_status(dialogue)
    if not status:
        raise RuntimeError('TV not on')
    dialogue.send_line('tx 1F:82:20:00')
    async for line in dialogue.get_lines():
        if line == 'waiting for input':
            break

async def set_tv_standby(dialogue):
    dialogue.send_line('standby 0')

    while True:
        await get_tv_status(dialogue)
        await asyncio.sleep(10)
        status = await get_tv_status(dialogue)
        if status:
            raise RuntimeError('TV not off')

 
async def main_loop(configuration_file_name):
    dialogue = await start_dialogue('/usr/bin/cec-client')
    
    while True:
        await asyncio.sleep(1)
        is_tv_up = await get_tv_status(dialogue)
        is_source_up = get_source_status(configuration_file_name)

        if (is_source_up, is_tv_up) == (True, False):
            await set_tv_on(dialogue)
        elif (is_source_up, is_tv_up) == (False, True):
            await set_tv_standby(dialogue)

@dataclass
class _Configuration(object):
    poll_shell_script: str
    poll_interval_seconds: int


def get_source_status(configuration_file_name: str):
    with open(configuration_file_name, 'rt') as configuration_file:
        configuration = _Configuration(**load(configuration_file))

        outcome = subprocess.run(configuration.poll_shell_script, shell=True)
        _logger.info(f'Check outcome is {outcome}')

        return outcome.returncode == 0


@dataclass
class _State(object):
    state: Optional[bool] = None
    count: int = 0

    @staticmethod
    def _go_up():
        if _TV.is_on():
            _logger.info('Already on')
        else:
            _logger.info('Powering on!')
            _TV.power_on()
        result = subprocess.run('echo tx 1F:82:20:00 | cec-client -s', stderr=subprocess.STDOUT, shell=True)
        print('cec client switch to screen 1', result.stdout)

    
    @staticmethod
    def _go_down():
        if _TV.is_on():
            _logger.info('Standing by!')
            _TV.standby()
        else:
            _logger.info('Already off')

    def __call__(self, new_state: bool):
        _logger.debug(f'current state {self.state}, counter {self.count}, new {new_state}')
        if self.state is None:
            self.state = new_state
        else:
            if self.state == new_state:
                self.count += 1

                if self.count >= 1:
                    if self.state:
                        self._go_up()
                    else:
                        self._go_down()
            else:
                self.state = new_state
                self.count = 0


@click.command()
@click_log.simple_verbosity_option(logger=_logger)
@click.option('-c', '--configuration', 'configuration_file_name', type=click.Path(), help='JSON configuration file')
def main(configuration_file_name: str):
    asyncio.get_event_loop().run_until_complete(main_loop(configuration_file_name))

if __name__ == '__main__':
    main()
