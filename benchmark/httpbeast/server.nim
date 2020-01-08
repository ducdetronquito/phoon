import asyncdispatch
import httpbeast
import options
import strutils 


proc onRequest(req: Request): Future[void] =
    if req.httpMethod == some(HttpGet):
        if req.path.get() == "/":
            req.send(Http200, "")

        if req.path.get().startsWith("/users/"):
            let id = req.path.get()[6 .. ^1]
            req.send(Http200, id)

    if req.httpMethod == some(HttpPost):
        if req.path.get() == "/users/":
            req.send(Http201, "")

run(onRequest, Settings(port: Port(8080)))
