#!/usr/bin/env python
# -*- coding: utf-8 -*- --------------------------------------------------===#
#
#              Copyright 2019 Trovares Inc.  All rights reserved.
#
#===----------------------------------------------------------------------===#

import pprint
import sys

import xgt
import xgtcli

#----------------------------------------------------------------------------

class Main(xgtcli.MainBase):
  def __init__(self, name=None, description=None):
    super(Main, self).__init__(name, description)
    self._parser.add_argument('-b', '--batch', action='store_true',
      help="show the first page of display, then quit")
    self._parser.add_argument('-l', '--lines', type=int, default=20,
      help="number of line to display, default=20")
    self._parser.add_argument('-p', '--port', type=int, default=4367,
        help='connect to this port, default=4367')
    self._parser.add_argument('-t', '--table', type=str, default='answer',
      help="scroll through data in this table")

  def run(self, arguments=[]):
    self._opts = self._parser.parse_args(arguments)
    conn = xgt.Connection(port=self._opts.port)
    
    self.scroll(conn, self._opts.table, self._opts.lines)
  
  def scroll(self, conn, tableName, lines):
    table = conn.get_table_frame(tableName)
    numRows = table.num_rows
    offset = 0
    schema = table.schema
    self.print_schema(schema)
    
    if numRows == 0:
      print("Zero rows in table")
      return

    while offset < numRows:
      d = table.get_data(offset, lines)
      print("Offset: %s" % str(offset))

      for row in d:
        line = ', '.join(['"'+f+'"' if isinstance(f, str) else str(f) for f in row])
        print(line)

      if self._opts.batch:
        offset = numRows

      if offset < numRows:
        d = '?'
        while d == '?':
          d = raw_input("More rows ('?' for help)>>> ")
          if d == '?':
            self.print_help()
          if d == 's' or d == 'S':
            self.print_schema(schema)
            d = '?'

        if d == 'q' or d == 'Q':
          offset = numRows
        elif d == 'b' or d == 'B':
          offset -= (2 * lines)
          if offset < 0:
            offset = 0
        else:
          offset += lines

  def print_help(self):
    print("'q' or 'Q' : quits program")
    print("'b' or 'B' : moves backward (upwards) in the row display")
    print("'s' or 'S' : shows the schema")
    print("' '        : empty return moves forward")

  def print_schema(self, schema):
    res = ""
    for col in schema:
      colname = col[0]
      if col[1]=='int':
        coltype = 'xgt.INT'
      elif col[1]=='text':
        coltype = 'xgt.TEXT'
      elif col[1]=='float':
        coltype = 'xgt.FLOAT'
      elif col[1]=='datetime':
        coltype = 'xgt.DATETIME'
      else:
        coltype = 'xgt.UNKNOWN'
      if len(res) > 0:
        res += ", "
      res += "{0}:{1}".format(colname, coltype)
    print(res)

#----------------------------------------------------------------------------

if __name__ == '__main__' :
  m=Main(description='Scroll through data in a table')
  m.run(sys.argv[1:])
