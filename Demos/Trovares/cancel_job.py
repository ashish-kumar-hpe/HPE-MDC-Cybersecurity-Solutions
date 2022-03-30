#!/usr/bin/env python
# -*- coding: utf-8 -*- --------------------------------------------------===#
#
#              Copyright 2019 Trovares Inc.  All rights reserved.
#
#===----------------------------------------------------------------------===#

import sys

import xgt
import xgtcli

#----------------------------------------------------------------------------

class Main(xgtcli.MainBase):
  def __init__(self, name=None, description=None):
    super(Main, self).__init__(name, description)
    self._parser.add_argument('-a', '--all', action='store_true',
      help="Cancel all jobs currently running")
    self._parser.add_argument('-j', '--job', type=int, default=0,
      help="Cancel this one job id")
    self._parser.add_argument('-p', '--port', type=int, default=4367,
        help='connect to this port, default=4367')

  def run(self, arguments=[]):
    self._opts = self._parser.parse_args(arguments)
    conn = xgt.Connection(port=self._opts.port)

    if self._opts.all:
      job_ids = conn.get_jobs()
      for job in sorted(job_ids):
        if conn.get_job_status(job) == "running":
          print("Canceling {}".formt(job))
          conn.cancel_job(job)
    else:
      conn.cancel_job(int(self._opts.job))

#----------------------------------------------------------------------------

if __name__ == '__main__' :
  m=Main(description='Cancel one or more jobs')
  m.run(sys.argv[1:])
