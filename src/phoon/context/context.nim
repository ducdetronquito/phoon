from asynchttpserver import nil
import request
import response
import ../routing/tree


type
    Context* = ref object
        request*: request.Request
        parameters*: Parameters
        response*: Response


proc from_request*(context_type: type[Context], std_request: asynchttpserver.Request): Context =
    var request = Request.new(std_request = std_request, headers = std_request.headers)
    return Context(request: request, response: Response.new())
