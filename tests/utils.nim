from asynchttpserver import HttpMethod, Request
from uri import parseUri


proc GetRequest*(path: string): Request =
    let uri = parseUri(path)
    return Request(
      reqMethod: HttpMethod.HttpGet,
      url: uri
    )

proc PostRequest*(path: string): Request =
    let uri = parseUri(path)
    return Request(
        reqMethod: HttpMethod.HttpPost,
        url: uri
    )
