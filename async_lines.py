import asyncio
from dataclasses import dataclass
from typing import Sequence, Optional, Tuple, List
from logging import getLogger
from time import monotonic

_LOGGER = getLogger(__name__)


@dataclass
class SubprocessLineDialogue:
    _proc: asyncio.subprocess.Process
    _termination_ordered: bool = False

    async def conduct(
        self,
        send_lines: Sequence[str] = (),
        order_termination: bool = False,
        timeout_seconds=5.0,
    ):
        start_time = monotonic()
        # One way
        self._termination_ordered = self._termination_ordered or order_termination

        for line in send_lines:
            self._proc.stdin.write(line.encode("utf-8") + b"\n")
        await self._proc.stdin.drain()

        while True:
            output = None
            try:
                remaining_time = start_time + timeout_seconds - monotonic()
                if remaining_time < 0:
                    break
                output = await asyncio.wait_for(
                    self._proc.stdout.readline(), timeout=remaining_time
                )
            except TimeoutError:
                pass

            if self._termination_ordered:
                self._proc.terminate()

            if output is not None:
                line = output.decode("utf-8")
                if len(line) > 0 and line[-1] == "\n":
                    line = line[:-1]
                _LOGGER.debug("line %s", line)
                yield line

        try:
            await asyncio.wait_for(self._proc.wait(), timeout=0.1)
        except TimeoutError:
            pass


async def start_dialogue(cmd: Tuple[str, ...]):
    _LOGGER.info("Starting dialogue, command is %s", cmd)
    process = await asyncio.create_subprocess_shell(
        cmd,
        stdin=asyncio.subprocess.PIPE,
        stdout=asyncio.subprocess.PIPE,
    )
    # stderr=asyncio.subprocess.PIPE)
    return SubprocessLineDialogue(process)


async def _test_start_dialogue():
    x = await start_dialogue("/bin/cat")

    x.send_line("hello")
    x.send_line("hello1")
    x.send_line("hello2")
    x.send_line("hello3")

    async for element in x.conduct_dialogue():
        print(element)
        if "3" in element:
            x.send_line(None)


if __name__ == "__main__":
    asyncio.get_event_loop().run_until_complete(_test_start_dialogue())
