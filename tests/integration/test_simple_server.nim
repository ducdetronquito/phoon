import httpClient
import os
import osproc
import strutils
import unittest


echo "Start Server"
var server = startProcess("tests/integration/bin/simple_server")

sleep(1000 * 5)


suite "Integration tests":
    var client = newHttpClient()

    test "Get request":
        let response = client.get("http://127.0.0.1:3000/")
        check(response.status == "200 OK")
        check(response.body == "I am a boring home page")

    test "Get request on an endpoint defined in a sub-router":
        let response = client.get("http://127.0.0.1:3000/nice/users")
        check(response.status == "200 OK")
        check(response.body == "Here are some nice users")

    test "Get request on a wildcard endpoint":
        let response = client.get("http://127.0.0.1:3000/abstract")
        check(response.status == "200 OK")
        check(response.body == "I am a wildard page !")
    
    test "Get request on a parametrized endpoint":
        let response = client.get("http://127.0.0.1:3000/books/how-to-poop-in-the-wood")
        check(response.status == "200 OK")
        check(response.body == "Of course I read 'how-to-poop-in-the-wood' !")

    test "Post request":
        let response = client.post("http://127.0.0.1:3000/about")
        check(response.status == "201 Created")
        check(response.body == "What are you talking about ?")

    test "Endpoint Not Found":
        let response = client.get("http://127.0.0.1:3000/an-undefined-url")
        check(response.status == "404 Not Found")
        check(response.body == "")

    test "Method not allowed on endpoint":
        let response = client.post("http://127.0.0.1:3000/")
        check(response.status == "405 Method Not Allowed")
        check(response.body == "")

    test "Fail to pass an authentication middleware":
        let response = client.get("http://127.0.0.1:3000/admins/")
        check(response.status == "401 Unauthorized")
        check(response.body == "")

    test "Succeed to pass an authentication middleware":
        client.headers = newHttpHeaders({ "simple-auth": "trust me" })
        let response = client.get("http://127.0.0.1:3000/admins/")
        check(response.status == "200 OK")
        check(response.body == "Admins, he is doing it sideways !")

    test "Can retrieve the response headers":
        let response = client.get("http://127.0.0.1:3000/json")
        check(response.headers["content-type"] == "application/json")

    test "Can access query parameters":
        let response = client.get("http://127.0.0.1:3000/query_parameters/?name=G%C3%BCnter")
        check(response.body == "Günter")

    test "Can access cookies":
        let response = client.get("http://127.0.0.1:3000/cookies/")
        check(response.headers["set-cookie"] == "name=Yay")

    test "Unhandled error":
        let response = client.get("http://127.0.0.1:3000/error/")
        check(response.code() == Http500)
        check(response.body.startsWith("invalid integer: Some business logic that should have been an int"))


echo "Close server"
server.kill()
server.close()
