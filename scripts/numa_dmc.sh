#!/bin/sh
###
### 
sudo taskset -apc 0-17,36-53 `pgrep dmc` && \
	sudo /opt/redislabs/bin/dmc-cli -ts root list | grep worker | tail -14 | awk '{printf "%i\n",$3}' | xargs -i sudo taskset -pc 18-35,54-71 {}

