import db_postgres
import strutils, json
import "db", "value"

type
  Meter* = ref object of RootObj
    id : int
    name : string
    number : string
    unit : string
    values : seq[Value]

proc newMeter(id : string, name : string, number : string, unit : string, values : seq[Value]) : Meter = 
  return Meter(
    id : id.parseInt(),
    name : name,
    number : number,
    unit : unit,
    values : values
  )

proc newMeter(row : Row, values : seq[Value] = @[]) : Meter =
  return newMeter(row[0], row[1], row[2], row[3], values)

proc allMeters*(pgdb: DbConn) : seq[Meter] =
  var rows : seq[Row] = pgdb.getAllRows(sql"SELECT * FROM meter order by 1")
  var meters : seq[Meter] = @[]
  for row in rows:
    meters.add(
      newMeter(row, getValues(pgdb, row[0], 12))
    )
  return meters

proc oneMeter*(pgdb : DbConn, id : string) : Meter =
  return newMeter(
    pgdb.getRow(sql"SELECT * FROM meter WHERE id=?", id))

proc meterByValue*(pgdb : DbConn, id : string) : Meter =
  return newMeter(
    pgdb.getRow(sql"SELECT * FROM meter WHERE id = (SELECT meter_id FROM value WHERE id = ? GROUP BY meter_id)", id))

proc saveMeter*(pgdb : DbConn, json : JsonNode) : bool =
  return pgdb.tryExec(
    sql"INSERT INTO meter (id, name, number, unit) VALUES (?, ?, ?, ?)",
    pgdb.getValue(sql"SELECT max(id) FROM meter").parseInt() + 1, 
    json["name"].getStr(), 
    json["number"].getStr(), 
    json["unit"].getStr()
  )

proc editMeter*(pgdb : DbConn, json : JsonNode) : bool =
  return pgdb.tryExec(
    sql"UPDATE meter SET name=?, number=?, unit=? WHERE id=?",
    json["name"].getStr(), 
    json["number"].getStr(), 
    json["unit"].getStr(),
    json["id"].getNum
  )

proc deleteMeter*(pgdb : DbConn, json : JsonNode) : bool =
  try:
    var id : int = json["id"].getNum().int
    pgdb.exec(sql"DELETE FROM value WHERE meter_id=?", id)
    pgdb.exec(sql"DELETE FROM meter WHERE id=?", id)
    return true
  except:
    echo getCurrentExceptionMsg()
    return false

proc toJson*(meter : Meter) : JsonNode =
  var values = %* {}
  for value in meter.values:
    values.add(value.toJson())
  return %* { 
    "id" : meter.id, 
    "name" : meter.name, 
    "number": meter.number, 
    "unit": meter.unit,
    "values": values
  }