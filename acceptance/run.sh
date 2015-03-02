#!/bin/sh

beaker --hosts hosts.yaml \
    --pre-suite pre-suite $*
