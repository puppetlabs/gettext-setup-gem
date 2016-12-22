# gettext-setup gem

This is a simple gem to set up i18n for Ruby projects (including [Sinatra](www.sinatrarb.com/) web apps) using gettext and fast gettext.

This project sets the default locale to English. If the user has set a different locale in their browser preferences, and we support the user's preferred locale, strings and data formatting will be customized for that locale.

## Terminology

**Translatable strings** - User-facing strings that are in scope for i18n (see the in scope/out of scope sections [here](https://confluence.puppetlabs.com/display/ENG/i18n#i18n-TasksandMilestones)).

**POT file** - Portable Objects Template. This is the file that stores externalized English strings. It includes the source file and line number of the string.

**PO file** - A bilingual file containing the source English strings (msgid) and target language strings (msgstr). This file is generated from the POT file and is where translated strings are added. A PO file is generated for each language.

**Transifex** - A translation management system. When PO files are updated, the updates are pulled into Transifex and translated there.

## Setup for your project

These are the poingant bits of this example that you need to replicate in
your project:

1. Add `gem 'gettext-setup'` to your `Gemfile`.
1. Copy `locales/config-sample.yaml` to your project and put it into a
`locales` directory as `config.yaml`.
1. Edit `locales/config.yaml` and make the necessary changes for your
   project
1. Add these three lines to your `Rakefile`:
```
    spec = Gem::Specification.find_by_name 'gettext-setup'
    load "#{spec.gem_dir}/lib/tasks/gettext.rake"
    GettextSetup.initialize(File.absolute_path('locales', File.dirname(__FILE__)))
```
1. Add this line to the top of your `app.rb`:
    `require 'gettext-setup'`
1. Add these lines inside the class declared in your `app.rb`:
```
    include FastGettext::Translation
    GettextSetup.initialize(File.absolute_path('locales', File.dirname(__FILE__)))
    before do
      FastGettext.locale = GettextSetup.negotiate_locale(env["HTTP_ACCEPT_LANGUAGE"])
    end
```

## Writing translatable code

### Use full sentences
Write user-facing strings as full sentences rather than joining multiple strings to form a full sentence because the word order in other languages can be different to English. See [Tips on writing translation-friendly strings](https://confluence.puppetlabs.com/display/ENG/Tips+for+writing+translation-friendly+strings).

### Use the translation function _()
Wrap user-facing strings in the `_()` function so they can be externalized to a POT file.

E.g.  `_("Hello, world!")`

### Interpolation
To add dynamic data to a string, use the following string formatting and translation function:

`_("We negotiated a locale of %{locale}") % {locale: FastGettext.locale}`

### Pluralize with the n_() function

Wrap strings that include pluralization with the `n_()` function.

E.g. `n_("There is %{count} bicycle in %{city}", "There are %{count} bicycles in %{city}", num_bikes) % {count: num_bikes, city: "Beijing"},`

Pluralization rules vary across languages. The pluralization rules are specified in the PO file and look something like this `Plural-Forms: nplurals=2; plural=(n > 1);`. This is the pluralization rule for German. It means that German has two pluralization rules. The first rule is `plural=n > 1)` and the second rule is all other counts.

Plurals are selected from the PO file by index. Here's an example of how a
pluralized string is handled in a PO file:

`msgid "%{count} file"
`msgid_plural "%{count} files"
`msgstr[0] "%{count} Dateien"
`msgstr[1] "%{count} Datei"

The `msgid` is the singular version of the English source string that's pulled in to the POT file and PO from the code file.

The `msgid_plural` is the plural version of the English source string.

The two `msgstr` lines show that German has two rules for pluralization. The indices map to the `Plural-Forms: nplurals=2; plural=(n > 1);` rule that we specified in the PO file. The `[0]` index represents `plural=(n > 1)` and the `[1]` index represents all other pluralization cases (in other words, when the count equals 0 or 1).

### Comments
To provide translators with some contextual information or instructions about a string, precede the string with a comment. Start the comment with "TRANSLATOR: " to make it obvious that you are providing instructions for the translator. The comment gets pulled in to the POT file and will show up as a comment in Transifex.

E.g. `# TRANSLATOR: The placeholder in this string represents the name of a parameter.`

## Translation workflow

1. Wrap the translation function around translatable strings in code files

2. Run `rake gettext:pot` to parse the source code and extract translatable strings into the message catalog in `locales/<project_name>.pot`. If a POT file already exists, this rake task will update the POT file. Do this before making a pull request that includes changes to user-facing strings.

3. Run `rake gettext:po[<lang>]` to create/update language-specific PO files. This step will be managed by the localization team, and will usually happen prior to a new release.

4. When a PO file is updated, a git hook is used to automatically pull the new/updated strings into Transifex ready for translation.

5. When the PO file reaches 100% translated and reviewed in Transifex, it is pulled back into the locale folder.

6. PE checks the user's locale settings (the browser settings for web apps, or the system settings for the CLI). If we support the preferred locale, PE uses the PO file for that locale. Otherwise, it uses the default locale (en_US).

## TODO

1. Locale-specific formatting of numbers, dates, etc.
2. Separate out the locales that are supported for testing/dev and production so we can add test translations without shipping them.
