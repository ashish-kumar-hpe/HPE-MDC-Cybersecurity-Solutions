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
    self._parser.add_argument('-p', '--port', type=int, default=4367,
        help='connect to this port, default=4367')
    self._parser.add_argument('-s', '--show', action='store_true',
        help='show data sizes in xgtd server')
    self._parser.add_argument('-t', '--table', action='store_true',
        help='load into a table (not graph components)')
    self._parser.add_argument('datafile', nargs='+')

  def run(self, arguments=[]):
    self._opts = self._parser.parse_args(arguments)
    # print("show_data._opts: {}".format(self._opts))

    urls = ["xgtd://{0}".format(_) for _ in self._opts.datafile]
    
    if self._opts.dryrun:
      print("urls: {}".format(urls))

    else:
      conn = xgt.Connection(port=self._opts.port)

      # Retrieve schema
      if self._opts.table:
        self._table = conn.get_table_frame('Table')
        load_structure = self._table
      else:
        self._nodes = conn.get_vertex_frame('Nodes')
        self._edges = conn.get_edge_frame('Edges')
        load_structure = self._edges

      # load data
      time_start = time.time()
      print("Loading Data from {0:d} files ...".format(len(urls)))
      if len(urls) > 0:
        load_structure.load(urls)
      time_end = time.time()
      xgtcli.print_time(time_end - time_start, "Time to load data")

      if self._opts.show:
        import show_data
        show_data.Main().run()

#----------------------------------------------------------------------------

if __name__ == '__main__' :
  m=Main(description='Load some TT data into xgtd')
  m.run(sys.argv[1:])
