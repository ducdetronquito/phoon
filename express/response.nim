import asynchttpserver


type
    Response* = object
        status_code*: HttpCode
        body*: string
