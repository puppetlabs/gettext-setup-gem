# sinatra-i18n

This is a sample project demonstrating the very basics of doing i18n for a
[Sinatra](www.sinatrarb.com/) web app. It is fully functional, and you
should be able to just do `bundle install && rackup` to get things
working. The `/` route will show some messages in the locale that best fits
your `Accept-Language` header (additional translations most welcome!) The
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

## Writing translatable code

### Use full sentences
Write user-facing strings as full sentences rather than concatenating fragments of a sentence because the word order in other languages can be different to English. See [Tips on writing translation-friendly strings](https://confluence.puppetlabs.com/display/ENG/Tips+for+writing+translation-friendly+strings).

### Wrap strings in the translation function _()
Wrap user-facing strings in the `_()` function so they can be externalized to a POT file.

E.g.  `_("Hello, world!")`

### Use sprintf interpolation to add dynamic data

To add dynamic data to user-facing strings, use sprintf interpolation.
E.g. `_("We negotiated a locale of %{locale}") % {locale:
FastGettext.locale}]`

### Pluralize with the n_() function

Wrap strings that include pluralization with the `n_()` function.

E.g. `n_("There is %{count} bicycle in %{city}", "There are %{count} bicycles in %{city}") % {count: 1, city: "Beijing"},`

Pluralization rules vary across languages. The pluralization rules are specified in the PO file and look something like this `Plural-Forms: nplurals=2; plural=(n > 1);`.

Plurals are selected from the PO file by index. Here's an example of how a
pluralized string is handled in a PO file:

    msgid "%{count} file"
    msgid_plural "%{count} files"
    msgstr[0] "%{count} Datei"
    msgstr[1] "%{count} Dateien"

### Comments

Frequently, e.g., before making a pull request, you should regenerate the
message catalog in `locales/<project_name>.pot` by running `rake
gettext:pot`

## Translation workflow

1. Wrap the translation function around translatable strings in code files

2. Run `rake gettext:find` to parse the source code and extract translatable strings into a POT file

3. Run `rake gettext:po[<lang>]` to create/update language-specific PO files (Note: This step will be managed by the localization team)

4. PE checks the user's locale. If we support the preferred locale, PE uses the PO file for that locale. Otherwise, it uses the default locale (en_US).

## Terminology

Translatable strings - user-facing strings that are in scope for i18n (see ??)
POT file - Portable Objects Template.
PO file - A bilingual file containing the source English strings and target language strings
Transifex - A translation management system. When PO files are updated, the updates are pulled into Transifex and translated there.

You can create and/or update translations for specific languages, which
live in `locales/<lang>/<project_name>.po` with the Rake task `rake gettext:po[<lang>]`. This should generally only be done in coordination with a translator.

## TODO

1. Locale-specific formatting of numbers, dates, etc.
