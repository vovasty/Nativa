#!/bin/sh

# KillTunnel.sh
# Nativa
#
# Created by Vladimir Solomenchuk on 17.03.10.
# Copyright 2010 aramzamzam.net. All rights reserved.

set arguments = $@
ps -opid,args | awk /$arguments/ | awk '!/(SSHCommand.sh|KillTunnel.sh|PID|grep|expect)/ {print $1}' | xargs kill