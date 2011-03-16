#!/bin/env python
# -*- coding: utf-8 -*- vim: set ts=4 et sw=4 fdm=indent :
import unittest, tempfile, simplejson, os, random

import mcollectiveah

class TestFunctions(unittest.TestCase):
    def test_raise_environ(self):
        try:
            del os.environ['MCOLLECTIVE_REQUEST_FILE']
            del os.environ['MCOLLECTIVE_REPLY_FILE']
        except: pass
        self.assertRaises(mcollectiveah.MCollectiveActionNoEnv, mcollectiveah.MCollectiveAction)

    def test_raise_file_error(self):
        os.environ['MCOLLECTIVE_REQUEST_FILE'] = '/tmp/mcollectiveah-test-request.%d' % random.randrange(100000)
        os.environ['MCOLLECTIVE_REPLY_FILE'] = '/tmp/mcollectiveah-test-reply.%d' % random.randrange(100000)

        self.assertRaises(mcollectiveah.MCollectiveActionFileError, mcollectiveah.MCollectiveAction)

        os.unlink(os.environ['MCOLLECTIVE_REPLY_FILE'])

    def test_echo(self):
        tin = tempfile.NamedTemporaryFile(mode='w', delete=False)
        self.data = {'message': 'test'}

        simplejson.dump(self.data, tin)
        os.environ['MCOLLECTIVE_REQUEST_FILE'] = tin.name
        tin.close()

        tout = tempfile.NamedTemporaryFile(mode='w')
        os.environ['MCOLLECTIVE_REPLY_FILE'] = tout.name
        tout.close()

        mc = mcollectiveah.MCollectiveAction()
        mc.reply['message'] = mc.request['message']
        del mc

        tout = open(os.environ['MCOLLECTIVE_REPLY_FILE'], 'r')
        data = simplejson.load(tout)
        tout.close()

        self.assertEqual(data, self.data)


        os.unlink(os.environ['MCOLLECTIVE_REQUEST_FILE'])
        os.unlink(os.environ['MCOLLECTIVE_REPLY_FILE'])

if __name__ == '__main__':
    unittest.main()
