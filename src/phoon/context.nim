import asynchttpserver
import response
import routing/tree

type
    Context* = ref object
        request*: Request
        response*: Response
        parameters*: Parameters


proc Response*(self: Context, status_code: HttpCode, body: string) =
    self.response = Response(status_code: status_code, body: body)
