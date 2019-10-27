import options
import ../express/routing/tree
import unittest


suite "Tree":

    test "Insert root route":
        var tree = Tree[string].new()
        tree.insert("/", "Home")
        check(tree.retrieve("/").get() == "Home")

    test "Insert route":
        var tree = Tree[string].new()
        tree.insert("/users", "Bobby")

        check(tree.retrieve("/users").get() == "Bobby")

    test "Insert multiple routes":
        var tree = Tree[string].new()

        tree.insert("/", "Home")
        tree.insert("/users", "Bobby")
        tree.insert("/users/age", "42")

        check(tree.retrieve("/").get() == "Home")
        check(tree.retrieve("/users").get() == "Bobby")
        check(tree.retrieve("/users/age").get() == "42")

    test "Fail to retrieve an undefined route.":
        var tree = Tree[string].new()
        tree.insert("/users", "Bobby")

        check(tree.retrieve("/admins").isNone)

    test "Fail to retrieve a partial route.":
        var tree = Tree[string].new()
        tree.insert("/users-that-are-nice", "Bobby")

        check(tree.retrieve("/users").isNone)
