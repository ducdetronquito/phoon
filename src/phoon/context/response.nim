import asynchttpserver


type
    Response* = ref object
        status: HttpCode
        body: string
        headers: HttpHeaders


proc get_body*(self: Response): string =
    return self.body


proc get_status*(self: Response): HttpCode =
    return self.status


proc get_headers*(self: Response): HttpHeaders =
    return self.headers


proc new*(response_type: type[Response]): Response =
    return Response(status: Http200, body: "", headers: newHttpHeaders())


proc body*(self: Response, body: string): Response {.discardable.} =
    self.body = body
    return self


proc status*(self: Response, status: HttpCode): Response {.discardable.} =
    self.status = status
    return self


proc headers*(self: Response, key: string, value: string): Response {.discardable.} =
    self.headers.add(key, value)
    return self


proc cookie*(self: Response, name: string, value: string): Response {.discardable.} =
    self.headers.add("Set-Cookie", name & "=" & value)
    return self
