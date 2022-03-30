#!/usr/bin/env python
# -*- coding: utf-8 -*- --------------------------------------------------===#
#
#              Copyright 2019 Trovares Inc.  All rights reserved.
#
#===----------------------------------------------------------------------===#

import argparse
import os
import sys

import xgt
import xgtcli

#----------------------------------------------------------------------------

class Main(xgtcli.MainBase):
  def __init__(self, name=None, description=None):
    super(Main, self).__init__(name, description)
    self._parser.add_argument('-d', '--dryrun', action='store_true')
    self._parser.add_argument('-p', '--port', type=int, default=4367,
        help='connect to this port, default=4367')
    self._parser.add_argument('-s', '--show', action='store_true')

  def run(self, arguments=[]):
    self._opts = self._parser.parse_args(arguments)

    if not self._opts.dryrun:
      conn = xgt.Connection(port=self._opts.port)

      # Drop all old/existing frames
      [conn.drop_frame(_) for _ in ['tt_table']]

      self.define_schemas(conn)

      if self._opts.show:
        import show_data
        show_data.Main().run()

  def define_schemas(self, conn):
    table = conn.create_table_frame(
        name='tt_table',
        schema=[['src', xgt.INT],
                ['tgt', xgt.INT],
                ['timestamp', xgt.INT]]
        )

if __name__ == '__main__' :
  m=Main(description='Define the TT graph schema')
  m.run(sys.argv[1:])
