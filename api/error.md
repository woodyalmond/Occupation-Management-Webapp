Traceback (most recent call last):
  File "/opt/alarmapp/api/server.py", line 1155, in <module>
    run()
  File "/opt/alarmapp/api/server.py", line 1147, in run
    repository.ensure_schema()
  File "/opt/alarmapp/api/server.py", line 319, in ensure_schema
    cursor.execute("ALTER TABLE tasks ADD COLUMN IF NOT EXISTS sort_order INT NOT NULL DEFAULT 0")
  File "/opt/alarmapp/api/.venv/lib/python3.12/site-packages/pymysql/cursors.py", line 159, in execute
    result = self._query(query)
             ^^^^^^^^^^^^^^^^^^
  File "/opt/alarmapp/api/.venv/lib/python3.12/site-packages/pymysql/cursors.py", line 330, in _query
    conn.query(q)
  File "/opt/alarmapp/api/.venv/lib/python3.12/site-packages/pymysql/connections.py", line 582, in query
    self._affected_rows = self._read_query_result(unbuffered=unbuffered)
                          ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
  File "/opt/alarmapp/api/.venv/lib/python3.12/site-packages/pymysql/connections.py", line 847, in _read_query_result
    result.read()
  File "/opt/alarmapp/api/.venv/lib/python3.12/site-packages/pymysql/connections.py", line 1245, in read
    first_packet = self.connection._read_packet()
                   ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
  File "/opt/alarmapp/api/.venv/lib/python3.12/site-packages/pymysql/connections.py", line 803, in _read_packet
    packet.raise_for_error()
  File "/opt/alarmapp/api/.venv/lib/python3.12/site-packages/pymysql/protocol.py", line 219, in raise_for_error
    err.raise_mysql_exception(self._data)
  File "/opt/alarmapp/api/.venv/lib/python3.12/site-packages/pymysql/err.py", line 154, in raise_mysql_exception
    raise errorclass(errno, errval, sqlstate=sqlstate)
pymysql.err.ProgrammingError: (1064, "You have an error in your SQL syntax; check the manual that corresponds to your MySQL server version for the right syntax to use near 'IF NOT EXISTS sort_order INT NOT NULL DEFAULT 0' at line 1")
