#!/usr/bin/env bash
set -e

# This is a convence script to help us debug travis failures.
#
# StackOverflows used:
# - (socat) https://superuser.com/questions/123790/socat-and-rich-terminals-with-ctrlc-ctrlz-ctrld-propagation
# - (jobs %%) http://stackoverflow.com/questions/11239466/how-to-check-whether-a-background-job-is-alive-bash
#
# Listen with: socat TCP-l:3105,reuseaddr FILE:`tty`,raw,echo=0

echo "[+] Shelling out to $1:$2..."
( socat tcp-connect:$1:$2,connect-timeout=2 exec:'bash -li',pty,stderr,setsid,sigint,sane || echo "Debug shell not listening." ) &
while jobs %% >/dev/null 2>/dev/null; do echo "Shell to port $1:$2 still running..."; sleep 2; done
