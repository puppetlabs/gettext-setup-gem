# sinatra-i18n

This is a sample project demonstrating the very basics of doing i18n for a
[Sinatra](www.sinatrarb.com/) web app. It is fully functional, and you
should be able to just do `bundle install && rackup` to get things
working. The `/` route will show some messages in the locale that best fits
your `Accept-Language` header (additional translations most welcome !) The
`/show` route will just report the negotiated locale.

This project sets the default locale to English. If the user has set a different locale in their browser preferences, and we support the user's preferred locale, strings and data formatting will be customized for that locale.

## Setup for your project

These are the poingant bits of this example that you need to replicate in
your project:

1. Add `gem 'fast_gettext'` to your `Gemfile`
1. Add `gem 'gettext'` to your `Gemfile` in the `:development` group
1. Copy `lib/sinatra-i18n/gettext_setup.rb` into your project
1. Copy `locales/config.yaml` to your project and put it into the `locales`
directory there.
1. Edit `locales/config.yaml` and make the necessary changes for your
   project
1. Copy `lib/tasks/gettext.rake` into your project and include it in your
   `Rakefile` the same way this project's `Rakefile` does
1. Add a `before` filter to your project that mirrors the `before` filter
in `app.rb`

### Writing translatable code

Please read the [fast_gettext](https://github.com/grosser/fast_gettext)
documentation on the details of using the various translation functions it
provides, such as `_` and `n_`.

Frequently, e.g., before making a pull request, you should regenerate the
message catalog in `locales/<project_name>.pot` by running `rake
gettext:pot`

You can create and/or update translations for specific languages, which
live in `locales/<lang>/<project_name>.po` with the Rake task `rake
gettext:po[<lang>]`. This should generally only be done in coordination
with a translator.

## TODO

1. Locale-specific formatting of numbers, dates, etc.
