import db_postgres
import strutils, times, json
import "db"

type
  Value* = ref object of RootObj
    id : int
    date : float
    value : int64

proc newValue(id : string, date : string, value : string) : Value =
  return Value(
    id : id.parseInt(),
    date : date.parse("yyyy-MM-dd HH:mm:ss").toTime().toSeconds() * 1000,
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
    fromSeconds(json["date"].getFNum() / 1000),
    json["value"].getStr().parseInt(),
    json["meter"].getNum()
  )

proc editValue*(pgdb : DbConn, json : JsonNode) : bool =
  return pgdb.tryExec(
    sql"UPDATE value SET date=?, value=? WHERE id=?",
    fromSeconds(json["date"].getFNum() / 1000),
    json["value"].getStr().parseInt(),
    json["id"].getNum()
  )

proc deleteValue*(pgdb : DbConn, json : JsonNode) : bool =
  try:
    pgdb.exec(
      sql"DELETE FROM value WHERE id=?",
      json["id"].getNum()
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