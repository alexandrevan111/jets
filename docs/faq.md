---
title: FAQ
nav_order: 79
---

**Q: How do I set cookies from Jets?**

You can set cookies with the `cookies` helper in the controller. The cookies helper acts like a hash.

```ruby
class PostsController < ApplicationController
  def index
    cookies[:favorite] = "chocolate"
    render json: {message: "yummy cookies set"}
  end
```

**Q: How do I set headers from Jets?**

You can set headers with the `set_header` method in the controller.  Here is an example

```ruby
  def index
    set_header("MyHeader", "foobar")
    response.set_header("Custom", "MyHeader") # also works to set headers
    response.headers["Custom2"] = "MyHeader" # also works to set headers
  end
```

**Q: How do I skip the prompt for the question "Is it okay to send your gem data to Lambdagems? (Y/n)?" in a script or CI Pipeline?**

You use the env `JETS_AGREE` env variable. Examples:

    export JETS_AGREE=yes
    jets deploy

or

    JETS_AGREE=yes jets deploy
    JETS_AGREE=no jets deploy

{% include prev_next.md %}