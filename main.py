#!/usr/bin/env python3
import subprocess
import click
from json import load
from dataclasses import dataclass
from time import sleep
from typing import Callable, Optional
import logging
import click_log

import cec

_logger = logging.getLogger(__name__)
click_log.basic_config(_logger)

cec.init()

_TV = cec.Device(cec.CECDEVICE_TV)

@dataclass
class _Configuration(object):
    poll_shell_script: str
    poll_interval_seconds: int


def poll(configuration_file_name: str, transition: Callable[[bool], None]):
    with open(configuration_file_name, 'rt') as configuration_file:
        configuration = _Configuration(**load(configuration_file))

        outcome = subprocess.run(configuration.poll_shell_script, shell=True)
        _logger.info(f'Check outcome is {outcome}')

        transition(outcome.returncode == 0)

        sleep(configuration.poll_interval_seconds)


@dataclass
class _State(object):
    state: Optional[bool] = None
    count: int = 0

    @staticmethod
    def _go_up():
        _logger.info('Powering on!')
        _TV.power_on()
    
    @staticmethod
    def _go_down():
        _logger.info('Standing by!')
        _TV.standby()

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
    state = _State()
    while True:
        poll(configuration_file_name, state)

if __name__ == '__main__':
    main()
