import db_postgres

var conn : DbConn

proc newConn*(connection, user, password, database : string) : DbConn =
  if conn == nil:
    conn = open(connection, user, password, database)
    discard conn.setEncoding("utf-8")
  return conn
