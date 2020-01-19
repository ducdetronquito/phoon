from asynchttpserver import nil
import cgi
import options
import strtabs

type
    Request* = ref object
        request: asynchttpserver.Request
        headers*: asynchttpserver.HttpHeaders
        query_parameters: StringTableRef


proc new*(response_type: type[Request], std_request: asynchttpserver.Request, headers: asynchttpserver.HttpHeaders): Request =
    return Request(request: std_request, headers: headers)


proc path*(self: Request): string =
    return self.request.url.path


proc http_method*(self: Request): asynchttpserver.HttpMethod =
    return self.request.reqMethod


proc query*(self: Request, field: string): Option[string] =
    if self.query_parameters == nil:
        self.query_parameters = self.request.url.query.readData()

    var value = self.query_parameters.getOrDefault(field)
    if value == "":
        return none(string)
    else:
        return some(value)


export options
