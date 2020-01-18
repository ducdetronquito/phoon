import phoon/routing/[errors, tree]
import options
import unittest


suite "Tree":

    test "Node children are prioratized":
        var tree = new Tree[string]
        tree.insert("/*", "wildcard")
        tree.insert("/{id}", "parametrized")
        tree.insert("/a", "strict")

        let children = tree.root.children[0].children
        check(children.len() == 3)
        check(children[0].path_type == PathType.Wildcard)
        check(children[1].path_type == PathType.Parametrized)
        check(children[2].path_type == PathType.Strict)

    test "A leaf node knows it's available parameters":
        var tree = new Tree[string]
        tree.insert("/{api_version}/users/{id}", "Bobby")

        let last_node = tree.root.children[0].children[0].children[0].children[0].children[0].children[0].children[0].children[0].children[0].children[0]
        check(last_node.is_leaf == true)
        check(last_node.parameters == ["api_version", "id"])


suite "Strict routes":

    test "Insert root route":
        var tree = Tree[string].new()
        tree.insert("/", "Home")
        let result = tree.match("/").get()
        check(result.value == "Home")

    test "Insert route":
        var tree = Tree[string].new()
        tree.insert("/users", "Bobby")
        let result = tree.match("/users").get()
        check(result.value == "Bobby")

    test "Can insert longer overlapping routes afterward":
        var tree = Tree[string].new()

        tree.insert("/", "Home")
        tree.insert("/users", "Bobby")
        tree.insert("/users/age", "42")

        check(tree.match("/").get().value == "Home")
        check(tree.match("/users").get().value == "Bobby")
        check(tree.match("/users/age").get().value == "42")

    test "Can insert longer overlapping routes beforehand":
        var tree = Tree[string].new()

        tree.insert("/users/age", "42")
        tree.insert("/users", "Bobby")
        tree.insert("/", "Home")

        check(tree.match("/").get().value == "Home")
        check(tree.match("/users").get().value == "Bobby")
        check(tree.match("/users/age").get().value == "42")

    test "Fail to retrieve an undefined route.":
        var tree = Tree[string].new()
        tree.insert("/users", "Bobby")
        check(tree.match("/admins").isNone == true)

    test "Fail to match when a path is fully parsed but the route is partially matched":
        var tree = Tree[string].new()
        tree.insert("/users-are-sexy", "Bobby")
        check(tree.match("/users").isNone == true)

    test "Fail to match when a path is not fully parsed but a route is found":
        var tree = Tree[string].new()
        tree.insert("/users", "Bobby")
        check(tree.match("/users-are-sexy").isNone == true)


suite "Wilcard routes":

    test "Cannot insert route with characters after wildcard":
        var tree = Tree[string].new()

        doAssertRaises(InvalidPathError):
            tree.insert("/user*-that-are-sexy", "Bobby")

    test "Insert a route with a wildcard":
        var tree = Tree[string].new()
        tree.insert("/user*", "Bobby")
        let last_node = tree.root.children[0].children[0].children[0].children[0].children[0].children[0]
        check(last_node.path == '*')
        check(last_node.path_type == PathType.Wildcard)

    test "Fail to match when a path is fully parsed but the route is partially matched":
        var tree = Tree[string].new()
        tree.insert("/users*", "Bobby")
        check(tree.match("/users").isNone == true)

    test "Match":
        var tree = Tree[string].new()
        tree.insert("/users*", "Bobby")
        let result = tree.match("/users-are-sexy").get()
        check(result.value == "Bobby")

    test "Match the longest prefix":
        var tree = Tree[string].new()
        tree.insert("/*", "Catch all")
        tree.insert("/users*", "Users")
        tree.insert("/users-are*", "Users are")
        tree.insert("/users-are-sex*", "Bobby")
        let result = tree.match("/users-are-sexy").get()
        check(result.value == "Bobby")

    test "Match wilcard route if a longer static path is not matched":
        var tree = Tree[string].new()
        tree.insert("/users-are-sexy-and-*", "Wilcard")
        tree.insert("/users-are-sexy-and-i-know-it", "Bobby")
        let result = tree.match("/users-are-sexy-and-i-know-nothing-john-snow").get()
        check(result.value == "Wilcard")

    test "Match wilcard route after failing to match a parametrized route":
        var tree = Tree[string].new()
        tree.insert("/users*", "Wilcard")
        tree.insert("/users/{id}/books", "Harry Potter")
        let result = tree.match("/users/10/bowls").get()
        check(result.value == "Wilcard")


suite "Parametrized routes":

    test "Fail to insert a route with a parameter name that contains the character {":
        var tree = new Tree[string]
        doAssertRaises(InvalidPathError):
            tree.insert("/users/{i{d}", "Bobby")

    test "Fail to insert a route with a parameter name that does not start with the character {":
        var tree = new Tree[string]
        doAssertRaises(InvalidPathError):
            tree.insert("/users/id}", "Bobby")

    test "Fail to insert a parametrized route if one already exists":
        var tree = new Tree[string]
        tree.insert("/users/{id}", "1")

        doAssertRaises(InvalidPathError):
            tree.insert("/users/{name}", "Bobby")

    test "Insert a route with a parameter":
        var tree = new Tree[string]
        tree.insert("/users/{id}", "Bobby")
        let parameter_node = tree.root.children[0].children[0].children[0].children[0].children[0].children[0].children[0].children[0]
        check(parameter_node.path == '{')
        check(parameter_node.path_type == PathType.Parametrized)
        check(parameter_node.parameter_name == "id")
        check(parameter_node.parameters == ["id"])

    test "Insert a route with two parameters":
        var tree = new Tree[string]
        tree.insert("/users/{id}/books/{title}", "Bobby")
        let id = tree.root.children[0].children[0].children[0].children[0].children[0].children[0].children[0].children[0]
        let books = id.children[0].children[0].children[0].children[0].children[0].children[0].children[0]
        let title = books.children[0]
        check(title.path == '{')
        check(title.path_type == PathType.Parametrized)
        check(title.parameter_name == "title")
        check(title.parameters == ["id", "title"])

    test "Fail to match when a path is fully parsed but the route is partially matched":
        var tree = Tree[string].new()
        tree.insert("/users/{id}/books", "Harry Potter")
        check(tree.match("/users/10/").isNone == true)

    test "Fail to match when a path is not fully parsed but a route is found":
        var tree = Tree[string].new()
        tree.insert("/users/{id}/", "Bobby")
        check(tree.match("/users/10/books").isNone == true)

    test "Match an ending parameter":
        var tree = Tree[string].new()
        tree.insert("/users/{id}", "Bobby")
        let result = tree.match("/users/10").get()
        check(result.value == "Bobby")
        check(result.parameters.get("id") == "10")

    test "Match a parameter suffixed by a static path":
        var tree = Tree[string].new()
        tree.insert("/users/{id}/books", "Harry Potter")
        let result = tree.match("/users/10/books").get()
        check(result.value == "Harry Potter")
        check(result.parameters.get("id") == "10")

    test "Retrieve a route with a parameter suffixed by a wildcard path":
        var tree = Tree[string].new()
        tree.insert("/users/{id}/boo*", "A boo")

        let result = tree.match("/users/10/booking").get()
        check(result.value == "A boo")
        check(result.parameters.get("id") == "10")

    test "Match several parameters":
        var tree = Tree[string].new()
        tree.insert("/users/{id}/books/{title}", "I have read this one !")
        let result = tree.match("/users/10/books/harry-potter").get()
        check(result.value == "I have read this one !")
        check(result.parameters.get("id") == "10")
        check(result.parameters.get("title") == "harry-potter")
