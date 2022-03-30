#!/usr/bin/env python
# -*- coding: utf-8 -*- --------------------------------------------------===#
#
#              Copyright 2019 Trovares Inc.  All rights reserved.
#
#===----------------------------------------------------------------------===#

import sys
import time

import xgt
import xgtcli

#----------------------------------------------------------------------------

class Main(xgtcli.MainBase):
  def __init__(self, name=None, description=None):
    super(Main, self).__init__(name, description)
    self._parser.add_argument('-d', '--dryrun', action='store_true')
    self._parser.add_argument('-f', '--from', type=int, default=1,
                              help='from this day number, default=1')
    self._parser.add_argument('-p', '--port', type=int, default=4367,
        help='connect to this port, default=4367')
    self._parser.add_argument('-s', '--show', action='store_true',
        help='show data sizes in xgtd server')
    self._parser.add_argument('-t', '--to', type=int, default=90,
        help='to this day number, default=90')

  def run(self, arguments=[]):
    self._opts = self._parser.parse_args(arguments)
    #print("show_data._opts: {}".format(self._opts))

    r = range(vars(self._opts)['from'], self._opts.to+1)
    urls_events1v = ["xgtd://wls_day-{0:02d}_1v.csv".format(i) for i in r]
    urls_events2v = ["xgtd://wls_day-{0:02d}_2v.csv".format(i) for i in r]
    urls_netflow = ["xgtd://nf_day-{0:02d}.csv".format(i) for i in r]
    
    if self._opts.dryrun:
      print("event1v urls: {}".format(urls_events1v))
      print("event2v urls: {}".format(urls_events2v))
      print("netflow urls: {}".format(urls_netflow))

    else:
      conn = xgt.Connection(port=self._opts.port)

      # Retrieve schema
      self._devices = conn.get_vertex_frame('Devices')
      self._netflow = conn.get_edge_frame('Netflow')
      self._events1v = conn.get_edge_frame('Events1v')
      self._events2v = conn.get_edge_frame('Events2v')

      # load data
      time_start = time.time()
      print("Loading Events1v ...")
      if len(urls_events1v) > 0:
        self._events1v.load(urls_events1v)
      time_end_events1v = time.time()
      xgtcli.print_time(time_end_events1v - time_start, "Time to load events1v")

      print("Loading Events2v ...")
      if len(urls_events2v) > 0:
        self._events2v.load(urls_events2v)
      time_end_events2v = time.time()
      xgtcli.print_time(time_end_events2v - time_end_events1v, "Time to load events2v")
      
      print("Loading Netflow ...")
      if len(urls_netflow) > 0:
        self._netflow.load(urls_netflow)
      time_end_netflow = time.time()
      xgtcli.print_time(time_end_netflow - time_end_events2v, "Time to load netflow")
      
      xgtcli.print_time(time_end_netflow - time_start, "Time to load all data")

      if self._opts.show:
        import show_data
        show_data.Main().run()

#----------------------------------------------------------------------------

if __name__ == '__main__' :
  m=Main(description='Load some of the 90 days data into xgtd')
  m.run(sys.argv[1:])
