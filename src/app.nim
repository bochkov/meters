import os, logging, strutils
import db_postgres
import jester, asyncdispatch, json, httpcore
import "db"
import "meter", "value"

let
  cpars : seq[TaintedString] = commandLineParams()
  fpars : JsonNode = parseJson(readFile("meters.json"))

var level = lvlInfo
if cpars.contains("-debug"):
  level = lvlAll
let log : Logger = newConsoleLogger(levelThreshold = level)
addHandler(log)

logging.info("DB = $1:*****@$2:$3/$4" % [
  fpars["db"]["user"].getStr(),
  fpars["db"]["host"].getStr(),
  $fpars["db"]["port"].getInt(),
  fpars["db"]["schema"].getStr()
])

var dbCon : DbConn = newConn(
  "",
  fpars["db"]["user"].getStr(),
  fpars["db"]["pass"].getStr(),
  "host=$1 port=$2 dbname=$3" % [
    fpars["db"]["host"].getStr(),
    $fpars["db"]["port"].getInt(),
    fpars["db"]["schema"].getStr()
  ]
)

routes:
  get "/":
    resp readFile("public/html/index.html")

  get "/api/meter/all/":
    var retre = %* []
    for meter in dbCon.allMeters():
      retre.add( %* meter.toJson() )
    resp($retre, contentType = "application/json")

  get "/api/meter/@id/":
    resp($dbCon.oneMeter(@"id").toJson(), contentType = "application/json")

  post "/api/meter/save/":
    if dbCon.saveMeter(parseJson(request.body)):
      resp(Http200, """{"success": true}""", contentType = "application/json")
    else:
      resp(Http400, """{"success": false}""", contentType = "application/json")

  post "/api/meter/update/":
    if dbCon.editMeter(parseJson(request.body)):
      resp(Http200, """{"success": true}""", contentType = "application/json")
    else:
      resp(Http400, """{"success": false}""", contentType = "application/json")

  post "/api/meter/delete/":
    if dbCon.deleteMeter(parseJson(request.body)):
      resp(Http200, """{"success": true}""", contentType = "application/json")
    else:
      resp(Http400, """{"success": false}""", contentType = "application/json")

  get "/api/value/@id/":
    var retre = dbCon.oneValue(@"id").toJson()
    retre["meter"] = %* dbCon.meterByValue(@"id").toJson()
    resp($retre, contentType = "application/json")

  post "/api/value/save/":
    if dbCon.saveValue(parseJson(request.body)):
      resp(Http200, """{"success": true}""", contentType = "application/json")
    else:
      resp(Http400, """{"success": false}""", contentType = "application/json")

  post "/api/value/update/":
    if dbCon.editValue(parseJson(request.body)):
      resp(Http200, """{"success": true}""", contentType = "application/json")
    else:
      resp(Http400, """{"success": false}""", contentType = "application/json")

  post "/api/value/delete/":
    if dbCon.deleteValue(parseJson(request.body)):
      resp(Http200, """{"success": true}""", contentType = "application/json")
    else:
      resp(Http400, """{"success": false}""", contentType = "application/json")

runForever()