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
      [conn.drop_frame(_) for _ in ['Netflow','Events1v','Events2v','Devices']]

      self.define_schemas(conn)

      if self._opts.show:
        import show_data
        show_data.Main().run()
        

  def define_schemas(self, conn):
      devices = conn.create_vertex_frame(
            name='Devices',
            schema=[['device', xgt.TEXT]],
            key='device')

      netflow = conn.create_edge_frame(
            name='Netflow',
            schema=[['epochtime', xgt.INT],
                    ['duration', xgt.INT],
                    ['srcDevice', xgt.TEXT],
                    ['dstDevice', xgt.TEXT],
                    ['protocol', xgt.INT],
                    ['srcPort', xgt.INT],
                    ['dstPort', xgt.INT],
                    ['srcPackets', xgt.INT],
                    ['dstPackets', xgt.INT],
                    ['srcBytes', xgt.INT],
                    ['dstBytes', xgt.INT]],
            source=devices,
            target=devices,
            source_key='srcDevice',
            target_key='dstDevice')

      events1v = conn.create_edge_frame(
            name='Events1v',
            schema=[['epochtime', xgt.INT],
                   ['eventID', xgt.INT],
                   ['logHost', xgt.TEXT],
                   ['userName', xgt.TEXT],
                   ['domainName', xgt.TEXT],
                   ['logonID', xgt.INT],
                   ['processName', xgt.TEXT],
                   ['processID', xgt.INT],
                   ['parentProcessName', xgt.TEXT],
                   ['parentProcessID', xgt.INT]],
            source=devices,
            target=devices,
            source_key='logHost',
            target_key='logHost')
           
      events2v = conn.create_edge_frame(
            name='Events2v',
            schema = [['epochtime',xgt.INT],
                     ['eventID',xgt.INT],
                     ['logHost',xgt.TEXT],
                     ['logonType',xgt.INT],
                     ['logonTypeDescription',xgt.TEXT],
                     ['userName',xgt.TEXT],
                     ['domainName',xgt.TEXT],
                     ['logonID',xgt.INT],
                     ['subjectUserName',xgt.TEXT],
                     ['subjectDomainName',xgt.TEXT],
                     ['subjectLogonID',xgt.TEXT],
                     ['status',xgt.TEXT],
                     ['src',xgt.TEXT],
                     ['serviceName',xgt.TEXT],
                     ['destination',xgt.TEXT],
                     ['authenticationPackage',xgt.TEXT],
                     ['failureReason',xgt.TEXT],
                     ['processName',xgt.TEXT],
                     ['processID',xgt.INT],
                     ['parentProcessName',xgt.TEXT],
                     ['parentProcessID',xgt.INT]],
            source = 'Devices',
            target = 'Devices',
            source_key = 'src',
            target_key = 'logHost')

if __name__ == '__main__' :
  m=Main(description='Define the LANL graph schema')
  m.run(sys.argv[1:])
