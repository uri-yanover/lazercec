import asyncio
from dataclasses import dataclass
from typing import Tuple, Optional

@dataclass
class SubprocessLineDialogue():
    _proc: asyncio.subprocess.Process
    _timeout_seconds: float = 1.0
    _termination_ordered: bool = False

    async def get_lines(self):
        while True:
            output = None
            await self._proc.stdin.drain()
            try:
                output = await asyncio.wait_for(self._proc.stdout.readline(), timeout=self._timeout_seconds)
            except TimeoutError:
                if self._termination_ordered:
                    self._proc.terminate()
                else:
                    continue

            if output is not None:
                line = output.decode('utf-8')
                if len(line) > 0 and line[-1] == '\n':
                    line = line[:-1]
                print('line ', line)
                yield line

            try:
                await asyncio.wait_for(self._proc.wait(), timeout=0.1)
                return
            except TimeoutError:
                pass
   
        
    def send_line(self, line: Optional[str]):
        if line is None:
            self._termination_ordered = True
        else:
            self._proc.stdin.write(line.encode('utf-8') + b'\n')


async def start_dialogue(cmd: Tuple[str, ...]):
    process = await asyncio.create_subprocess_shell(
        cmd,
        stdin=asyncio.subprocess.PIPE,
        stdout=asyncio.subprocess.PIPE,
    )
        # stderr=asyncio.subprocess.PIPE)
    return SubprocessLineDialogue(process)


async def _test_start_dialogue():
    x = await start_dialogue('/bin/cat')
    
    x.send_line('hello')
    x.send_line('hello1')
    x.send_line('hello2')
    x.send_line('hello3')

    async for element in x.get_lines():
        print(element)
        if '3' in element:
            x.send_line(None)

    

if __name__ == '__main__':
    asyncio.get_event_loop().run_until_complete(_test_start_dialogue())


