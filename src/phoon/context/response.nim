import asynchttpserver


type
    Cookie = object
        name: string
        value: string


proc to_string*(self: Cookie): string =
    return self.name & "=" & self.value


type
    Response* = ref object
        status: HttpCode
        body: string
        headers: HttpHeaders
        cookies: seq[Cookie]


proc get_body*(self: Response): string =
    return self.body


proc get_status*(self: Response): HttpCode =
    return self.status


proc get_headers*(self: Response): HttpHeaders =
    return self.headers


proc compile*(self: Response): Response =
    if len(self.cookies) == 0:
        return self

    for cookie in self.cookies:
        self.headers["Set-Cookie"] = cookie.to_string()

    return self


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
    self.cookies.add(Cookie(name: name, value: value))
    return self
