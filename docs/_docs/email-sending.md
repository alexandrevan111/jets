---
title: Email Sending
---

Jets supports sending emails via ActionMailer.

## Example

Here's an example showing how to get started with email.

    jets new demo
    cd demo
    jets generate mailer UserMailer new_user

This generates starter `app/mailers/application_mailer.rb` and `app/mailers/user_mailer.rb` examples.

## Sending Email

Here's an example of how to send email:

    $ jets console
    > UserMailer.new_user.deliver

If your ActionMailer class uses params you can provide them via the `with` method.  Example:

```ruby
class UserMailer < ApplicationMailer
  def notify_user
    @post = params[:post]
    mail(to: "to@example.org", subject: "Check out this post")
  end
end
```

Then in the console:

    $ jets console
    > posts = Posts.first
    > UserMailer.with(post: post).notify_user.deliver

## Synchronous Sending

Though ActionMailer itself supports sending email asynchronously, Jets use of ActionMailer does not currently. Emails are delivered synchronously. Asynchronously support will be added in time. Pull requests are welcome.

<a id="prev" class="btn btn-basic" href="{% link _docs/initializers.md %}">Back</a>
<a id="next" class="btn btn-primary" href="{% link _docs/email-configuration.md %}">Next Step</a>
<p class="keyboard-tip">Pro tip: Use the <- and -> arrow keys to move back and forward.</p>
