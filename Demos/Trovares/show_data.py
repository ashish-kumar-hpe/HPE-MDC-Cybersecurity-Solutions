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
    self._parser.add_argument('-d', '--dryrun', action='store_true')
    self._parser.add_argument('-l', '--lanl', action='store_true',
        help='show lanl graph summary only')
    self._parser.add_argument('-p', '--port', type=int, default=4367,
        help='connect to this port, default=4367')

  def run(self, arguments=[]):
    self._opts = self._parser.parse_args(arguments)
    #print("show_data._opts: {}".format(self._opts))

    if not self._opts.dryrun:
      conn = xgt.Connection(port=self._opts.port)

      if self._opts.lanl:
        self.print_lanl_summary(conn)
      else:
        tables = conn.get_table_frames()
        for table in tables:
          print("TableFrame {0} has {1:,} rows".format(
                table.name, table.num_rows))
        vertices = conn.get_vertex_frames()
        for vertex in vertices:
          print("VertexFrame {0} has {1:,} vertices".format(
                vertex.name, vertex.num_vertices))
        edges = conn.get_edge_frames()
        total_edges = 0
        for edge in edges:
          total_edges += edge.num_edges
          print("EdgeFrame {0} has {1:,} edges".format(
                edge.name, edge.num_edges))
        print("Total edges over all frames: {0:,}".format(total_edges))

  def print_lanl_summary(self, conn):
    # Retrieve schema
    devices = conn.get_vertex_frame('Devices')
    netflow = conn.get_edge_frame('Netflow')
    events1v = conn.get_edge_frame('Events1v')
    events2v = conn.get_edge_frame('Events2v')

    print('Devices (vertices): {:,}'.format(devices.num_vertices))
    print('Netflow (edges): {:,}'.format(netflow.num_edges))
    print('Host-only event (edges): {:,}'.format(events1v.num_edges))
    print('Host-communication event (edges): {:,}'.format(events2v.num_edges))
    print('Total number of edges: {:,}'.format(
        netflow.num_edges + events1v.num_edges + events2v.num_edges))

#----------------------------------------------------------------------------

if __name__ == '__main__' :
  m=Main(description='Show the graph information in the running xgtd')
  m.run(sys.argv[1:])
