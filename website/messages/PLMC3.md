---
layout: default
title: Message detail for PLMC3
toc: false
---

Example Message
---------------

    Cycling logging level due to USR2 signal

Additional Information
----------------------

When sending the mcollectived process the USR2 signal on a Unix based machine this message indicates that the signal for received and the logging level is being adjusted to the next higher level or back down to debug if it was already at it's highest level.

This message will be followed by another message similar to the one below:

    Logging level is now WARN
