import db_postgres
import strutils, times, json
import "db"

type
  Value* = ref object of RootObj
    id : int
    date : int64
    value : int64

proc newValue(id : string, date : string, value : string) : Value =
  var dt: string = date
  if date.contains("."):
    dt = date.substr(0, date.find('.')-1)
  return Value(
    id : id.parseInt(),
    date : dt.parse("yyyy-MM-dd HH:mm:ss").toTime().toUnix() * 1000,
    value : value.parseInt()
  )

proc newValue(row : Row) : Value =
  return newValue(row[0], row[1], row[2])

proc getValues*(pgdb: DbConn, id : string, limit : int) : seq[Value] =
  var rows : seq[Row] = pgdb.getAllRows(sql"SELECT * FROM value WHERE meter_id=? ORDER BY date DESC LIMIT ?", id, limit)
  var vals : seq[Value] = @[]
  for row in rows:
    vals.add(
      newValue(row)
    )
  return vals

proc getValues*(pgdb: DbConn, id : string) : seq[Value] =
  var rows : seq[Row] = pgdb.getAllRows(sql"SELECT * FROM value WHERE meter_id=? ORDER BY date DESC", id)
  var vals : seq[Value] = @[]
  for row in rows:
    vals.add(
      newValue(row)
    )
  return vals

proc oneValue*(pgdb : DbConn, id : string) : Value =
    return newValue(
      pgdb.getRow(sql"SELECT * FROM value WHERE id=?", id))

proc saveValue*(pgdb : DbConn, json : JsonNode) : bool =
  return pgdb.tryExec(
    sql"INSERT INTO value (id, date, value, meter_id) VALUES (?, ?, ?, ?)",
    pgdb.getValue(sql"SELECT max(id) FROM value").parseInt() + 1,
    fromUnix((json["date"].getFloat() / 1000).toBiggestInt()),
    json["value"].getStr().parseInt(),
    json["meter"].getInt()
  )

proc editValue*(pgdb : DbConn, json : JsonNode) : bool =
  return pgdb.tryExec(
    sql"UPDATE value SET date=?, value=? WHERE id=?",
    fromUnix((json["date"].getFloat() / 1000).toBiggestInt()),
    json["value"].getStr().parseInt(),
    json["id"].getInt()
  )

proc deleteValue*(pgdb : DbConn, json : JsonNode) : bool =
  try:
    pgdb.exec(
      sql"DELETE FROM value WHERE id=?",
      json["id"].getInt()
    )
    return true
  except:
    echo getCurrentExceptionMsg()
    return false

proc toJson*(value : Value) : JsonNode =
  return %* {
    "id" : value.id,
    "date" : value.date,
    "value": value.value
  }