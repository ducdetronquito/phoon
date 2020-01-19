from asynchttpserver import nil
import phoon/context/request
import unittest
import uri


suite "Request":

    test "Get query parameter":
        var std_request = asynchttpserver.Request(
            reqMethod: asynchttpserver.HttpMethod.HttpGet,
            url: parseUri("https://yumad.bro/?name=bob")
        )
        var request = Request.new(std_request = std_request, headers = nil)
        check(request.query("name").get() == "bob")

    test "Get multiple query parameters":
        var std_request = asynchttpserver.Request(
            reqMethod: asynchttpserver.HttpMethod.HttpGet,
            url: parseUri("https://yumad.bro/?name=bob&age=42")
        )
        var request = Request.new(std_request = std_request, headers = nil)
        check(request.query("name").get() == "bob")
        check(request.query("age").get() == "42")

    test "Get missing query parameter":
        var std_request = asynchttpserver.Request(
            reqMethod: asynchttpserver.HttpMethod.HttpGet,
            url: parseUri("https://yumad.bro/?name=bob")
        )
        var request = Request.new(std_request = std_request, headers = nil)
        check(request.query("age").isNone)
    
    test "Url parameter are decoded on the fly":
        var std_request = asynchttpserver.Request(
            reqMethod: asynchttpserver.HttpMethod.HttpGet,
            url: parseUri("https://yumad.bro/?name=G%C3%BCnter")
        )
        var request = Request.new(std_request = std_request, headers = nil)
        check(request.query("name").get() == "Günter")
