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
      help="Show a list of all jobs, including completed and canceled jobs.")
    self._parser.add_argument('-j', '--job', type=int, default=0,
      help="Show information about this one job id")
    self._parser.add_argument('-p', '--port', type=int, default=4367,
        help='connect to this port, default=4367')
    self._parser.add_argument('-v', '--verbose', action='count',
      help="Show verbose information, repeat for more verbosity")

  def run(self, arguments=[]):
    self._opts = self._parser.parse_args(arguments)
    conn = xgt.Connection(port=self._opts.port)

    # Step 1:  make/retrieve a list of jobs
    if self._opts.job > 0:
      job_list = conn.get_jobs([self._opts.job])
    else:
      jobs = conn.get_jobs()
      if self._opts.all:
        job_list = jobs
      else:
        job_list = [j for j in jobs if j.status == 'running']
      if len(job_list) == 0:
        print("No jobs")
        return

    # Step 2:  sort the list by ID, then print the information
    jobs_sorted = sorted(job_list, key=lambda j: j.id)
    self.highest_job_number(jobs_sorted[-1].id)
    for job in jobs_sorted:
      self.print_job_info(job)

  def highest_job_number(self, number):
    """compute the number of digits required to display the largest job id"""
    self._digits = 1
    while number > 9:
      self._digits += 1
      number /= 10

  def print_job_info(self, job):
    format_0 = "{0:" + str(self._digits) + "d}"
    spaces = ("{0:" + str(self._digits) + "}").format(' ')
    print((format_0 + ": {1}").format(job.id, job.status))
    if self._opts.verbose:
      if job.status == 'running':
        print("{0}  started on {1}".format(spaces, job.start_time))
      elif job.status != 'scheduled':        
        duration = job.end_time - job.start_time
        print("{0}  started on {1}, ended on {2}, duration: {3}".format(spaces,
            job.start_time, job.end_time, duration))
      if job.status == 'failed':
        print("{0}  Error message: {1}".format(spaces, job.error))
        if self._opts.verbose > 1:
          trace_lines = job.trace.split('\u000a')
          print("")
          for l in trace_lines:
            print("{0}  {1}".format(spaces, l))

#----------------------------------------------------------------------------

if __name__ == '__main__' :
  m=Main(description='Show information about xGT jobs')
  m.run(sys.argv[1:])
