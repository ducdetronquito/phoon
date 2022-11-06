from asynchttpserver import nil
import cgi
import options
import strtabs

type
    Request* = ref object
        request: asynchttpserver.Request
        headers*: asynchttpserver.HttpHeaders
        query: Option[StringTableRef]


proc new*(responseType: type[Request], request: asynchttpserver.Request, headers: asynchttpserver.HttpHeaders): Request =
    return Request(request: request, headers: headers)


proc path*(self: Request): string =
    return self.request.url.path


proc httpMethod*(self: Request): asynchttpserver.HttpMethod =
    return self.request.reqMethod


proc query*(self: Request, field: string): Option[string] =
    if self.query.isNone:
        self.query = some(self.request.url.query.readData())

    var value = self.query.unsafeGet().getOrDefault(field)
    if value == "":
        return none(string)
    else:
        return some(value)


export options
