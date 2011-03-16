#!/usr/bin/env python

import os
import sys

class Error(Exception):
    pass

class MissingModule(Error):
    pass

class MissingFiles(Error):
    pass

class MissingEnvironemntVariable(Error):
    pass

class FileReadError(Error):
    pass

class JSONParsingError(Error):
    pass

try:
    import simplejson as json
except ImportError:
    raise MissingModule('Unable to load JSON module. Missing module?')

class MCollectiveAction(object):

    _environment_variables = [ 'MCOLLECTIVE_REQUEST_FILE',
                               'MCOLLECTIVE_REPLY_FILE' ]

    def __init__(self):
        self._info  = sys.__stdout__
        self._error = sys.__stderr__ 

        for entry in '_reply', '_request':
            self.__dict__[entry] = {}

        self._arguments = sys.argv[1:]

        if len(self._arguments) < 2:
            try:
                for variable in self._environment_variables:
                    self._arguments.append(os.environ[variable])
            except KeyError:
                raise MissingEnvironemntVariable("Environment variable `%s' "
                                                 "is not set." % variable)

        self._request_file, self._reply_file = self._arguments

        if len(self._request_file) == 0 or len(self._reply_file) == 0:
            raise MissingFiles("Both request and reply files have to be set.")

    def __setattr__(self, name, value):
        if name.startswith('_'):
            object.__setattr__(self, name, value)
        else:
            self.__dict__['_reply'][name] = value

    def __getattr__(self, name):
        if name.startswith('_'):
            return self.__dict__.get(name, None)
        else:
            return self.__dict__['_reply'].get(name, None)

    def __del__(self):
        if self._reply:
            try:
                file = open(self._reply_file, 'w')
                json.dump(self._reply, file)
                file.close()
            except IOError, error:
                raise FileReadError("Unable to open reply file `%s': %s" %
                                    (self._reply_file, error))

    def info(self, message):
        print >> self._info, message
        self._info.flush()

    def error(self, message):
        print >> self._error, message
        self._error.flush()

    def fail(self, message, exit_code=1):
        self.error(message)
        sys.exit(exit_code)

    def reply(self):
        return self._reply

    def request(self):
        if self._request:
            return self._request
        else:
            try:
                file = open(self._request_file, 'r')
                self._request = json.load(file)
                file.close()
            except IOError, error:
                raise FileReadError("Unable to open request file `%s': %s" %
                                    (self._request_file, error))
            except json.JSONDecodeError, error:
                raise JSONParsingError("An error occurred during parsing of "
                                       "the JSON data in the file `%s': %s" %
                                       (self._request_file, error))
                file.close()

            return self._request

# vim: set ts=4 sw=4 et :
