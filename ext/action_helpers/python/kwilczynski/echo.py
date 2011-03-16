#!/usr/bin/env python

import sys
import time
import mcollective_action as mc

if __name__ == '__main__':
    mc = mc.MCollectiveAction()
    request = mc.request()
    mc.message = request['data']['message']
    mc.time = time.strftime('%c')
    mc.info("An example echo agent")

    sys.exit(0)

# vim: set ts=4 sw=4 et :
