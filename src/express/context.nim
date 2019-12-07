import asynchttpserver
import response
import express/routing/tree

type
    Context* = ref object
        request*: Request
        response*: Response
        parameters*: Parameters


proc from_request*(context_type: type[Context], request: Request): Context =
    var context = system.new(Context)
    context.request = request
    return context


proc Response*(self: Context, status_code: HttpCode, body: string) =
    self.response = Response(status_code: status_code, body: body)
