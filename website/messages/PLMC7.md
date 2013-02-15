---
layout: default
title: Message detail for PLMC7
toc: false
---

Example Message
---------------

    Exiting after signal: SignalException: runner.rb:6:in `run': Interrupt

Additional Information
----------------------

When the MCollective daemon gets a signal from the Operating System that it does not specifically handle it will log this line before exiting.

You would see this whenever the daemon is stopped by init script or when sending it a kill signal, it will then proceed to disconnect from the middleware and exit its main loop
