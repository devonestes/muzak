# What is Mutation Testing?

Mutation testing is the process of programmatically introducing bugs to an application by mutating
the application's source code and then running that application's test suite.

## What can mutation testing do for me?

Mutation testing can serve several goals:

1. Identifying untested code paths
2. Identifying unused code paths
3. Identifying tests that never fail
4. Identifying tests that always fail together (duplicate coverage)
5. Identifying tests that run slowly and rarely fail (what some consider "low value" tests)

All of those benefits put together means that mutation testing can help us "test our tests," both
for any tests that might be missing, and to help us reduce time spent running unnecessary or low
value tests.

## But isn't mutation testing slow?

Yes, in its most basic form mutation testing is rather slow. You can make thousands of mutations
in a reasonably sized application, and for each of those mutations you might potentially need to
run your entire test suite. If there were no optimizations to how mutation testing was run, this
would indeed take an unreasonably long time!

To combat this, Muzak limits the number of mutations generated in each run to 25, and by default
it will stop the test suite at the first failure for each mutation. This, combined with Elixir's
easy ability to run asynchronous tests, makes mutation testing a relatively quick process, but at
the cost of poor coverage for the application that's being tested.

There are many better ways of reducing mutation testing run time that don't sacrifice nearly as
much mutation coverage, though, and those options are all available in [Muzak
Pro](muzak.md#muzak-pro).

## Can I get an example?

Sure! Imagine that we have the below module:

```
defmodule Authorization do
  def user_can_modify?(user, resource) do
    user.role in [:admin, :owner] or user.id in resource.member_ids
  end
end
```

And for that module, we have these tests:

```
defmodule AuthorizationTest do
  use ExUnit.Case, async: true

  describe "user_can_modify?/2" do
    test "returns true if the user is a member" do
      user = %{id: 1, role: :reader}
      resource = %{member_ids: [1]}
      assert Authorization.user_can_modify?(user, resource)
    end

    test "returns true if the user is an admin" do
      user = %{id: 1, role: :admin}
      resource = %{member_ids: []}
      assert Authorization.user_can_modify?(user, resource)
    end

    test "returns false if the user isn't an admin, owner or member" do
      user = %{id: 1, role: :reader}
      resource = %{member_ids: []}
      refute Authorization.user_can_modify?(user, resource)
    end
  end
end
```

All those tests will pass, and we also have 100% test coverage (if we're measuring by lines of
code executed during our test suite). However, it is still possible to break that code in a way
that _won't_ trigger a failing test by applying the following mutation:

```
# original
user.role in [:admin, :owner] or user.id in resource.member_ids

# mutation
user.role in [:admin, :random_atom] or user.id in resource.member_ids
```

To resolve this, we would add a test that would catch this mutation:

```
test "returns true if the user is an owner" do
  user = %{id: 1, role: :owner}
  resource = %{member_ids: []}
  assert Authorization.user_can_modify?(user, resource)
end
```

This is just one very simple example of how mutation testing can help, but when it's used
regularly in real applications it can make a _huge_ difference.

## Should I try to get 100% coverage?

No - and in fact, it may not even be possible! There are things that we can't test with a single
automated test suite, such as code that's conditionally executed when running on a given operating
system or in a given environment. There's also the case of "equivalent mutants," where the
mutation that's made satisfies all conditions in the application and therefore doesn't produce a
failing test because the mutation is technically valid. This _might_ mean that your application
could be improved in some way, but this is often more of a hassle than it's worth.

Of course test coverage needs vary from application to application, but 95% coverage is a
reasonable goal that most applications can achieve.
