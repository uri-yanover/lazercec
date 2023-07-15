# lazercec
Lazy tool to turn off/on a TV based on an arbitrary condition.

Some ideas:
* `nmblookup <hostname>`
* `ping <hostname> -c 1 -w 1`
* `(! ping -n -t 1 -c 1 192.168.1.1)`

Useful links:
* https://ubuntu-mate.community/t/controlling-raspberry-pi-with-tv-remote-using-hdmi-cec/4250
* https://www.cec-o-matic.com/
* https://support.justaddpower.com/kb/article/68-cec-over-ip-control/

Bullseye bug

```
https://issueexplorer.com/issue/MichaIng/DietPi/4881
contains the relevant commands

cd /tmp
curl -sSfLO 'https://archive.raspberrypi.org/debian/pool/main/libc/libcec/cec-utils_4.0.7+dfsg1-1+rpt2_armhf.deb'
sudo apt install --reinstall --allow-downgrades ./cec-utils_4.0.7+dfsg1-1+rpt2_armhf.deb

cd /usr/lib/arm-linux-gnueabihf
dpkg -L libraspberrypi0 | grep '/usr/lib/arm-linux-gnueabihf/.*\.so.0' | while read -r line
do
line=${line#/usr/lib/arm-linux-gnueabihf/}
ln -s "$line" "${line%.0}"
done

cd /tmp

for file in \
	https://archive.raspberrypi.org/debian/pool/main/libc/libcec/libcec4_4.0.7+dfsg1-1+rpt2_armhf.deb \
	https://archive.raspberrypi.org/debian/pool/main/libc/libcec/libcec-dev_4.0.7+dfsg1-1+rpt2_armhf.deb \ 
	https://archive.raspberrypi.org/debian/pool/main/libc/libcec/cec-utils_4.0.7+dfsg1-1+rpt2_armhf.deb \
	; do
	curl $file -o "$(basename "$file")"
	sudo dpkg -i "$(basename "$file")"
done
```
