import asynchttpserver
import response


type
    Context* = ref object
        request*: Request
        response: Response
