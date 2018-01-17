# gettext-setup gem

This is a simple gem to set up i18n for Ruby projects (including [Sinatra](http://www.sinatrarb.com/) web apps) using gettext and fast gettext.

This project sets the default locale to English. If the user has set a different locale in their browser preferences, and we support the user's preferred locale, strings and data formatting will be customized for that locale.

## Terminology

**Translatable strings** - User-facing strings that are in scope for i18n (see the in scope/out of scope sections [here](https://confluence.puppetlabs.com/display/ENG/i18n#i18n-TasksandMilestones)).

**POT file** - Portable Objects Template. This is the file that stores externalized English strings. It includes the source file and line number of the string.

**PO file** - A bilingual file containing the source English strings (msgid) and target language strings (msgstr). This file is generated from the POT file and is where translated strings are added. A PO file is generated for each language.

**Transifex** - A translation management system. When POT files are updated, the updates are pushed to Transifex. Transifex generates a PO file for each language that has been set up in the Transifex project. Translators enter the string translations in the PO for their language.

## Setup for your project

These are the poignant bits of this example that you need to replicate in your project:

1. Add `gem 'gettext-setup'` to your `Gemfile`.
2. Copy `locales/config-sample.yaml` to your project and put it into a
`locales` directory as `config.yaml`.
3. Edit `locales/config.yaml` and make the necessary changes for your project
4. Add these three lines to your `Rakefile`, ensuring the `locales` directory is found by the last line:
   ```ruby
   spec = Gem::Specification.find_by_name 'gettext-setup'
   load "#{spec.gem_dir}/lib/tasks/gettext.rake"
   GettextSetup.initialize(File.absolute_path('locales', File.dirname(__FILE__)))
   ```
5. Add these lines at the start of your app (`app.rb` for server-side, the executable binary for CLI applications):
   ```ruby
   require 'gettext-setup'
   GettextSetup.initialize(File.absolute_path('locales', File.dirname(__FILE__)))
   ```
   Note that the second line may require modification to find the `locales` directory.
6. For client-side applications, add this line:
   ```ruby
   GettextSetup.negotiate_locale!(GettextSetup.candidate_locales)
   ```
7. For server-side applications, add these lines:
   ```ruby
   before do
       GettextSetup.negotiate_locale!(env["HTTP_ACCEPT_LANGUAGE"])
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

Plurals are selected from the PO file by index. 

Here's an example of how a pluralized string is handled in a PO file:

```
msgid "%{count} file"
msgid_plural "%{count} files"
msgstr[0] "%{count} Dateien"
msgstr[1] "%{count} Datei"
```

The `msgid` is the singular version of the English source string that's pulled in to the POT file and PO from the code file.

The `msgid_plural` is the plural version of the English source string.

The two `msgstr` lines show that German has two rules for pluralization. The indices map to the `Plural-Forms: nplurals=2; plural=(n > 1);` rule that we specified in the PO file. The `[0]` index represents `plural=(n > 1)` and the `[1]` index represents all other pluralization cases (in other words, when the count equals 0 or 1).

When Transifex generates a PO file for a specific language, it automatically adds the appropriate pluralization rules in the PO file. 

### Comments
To provide translators with some contextual information or instructions about a string, precede the string with a comment using `#. `. The comment gets pulled in to the POT file and will show up as a comment in Transifex.

E.g. `#. The placeholder in this string represents the name of a parameter.`

## Translation workflow

1. Wrap the translation function around translatable strings in code files

2. A CI job checks code commits to see if any changes have been made to user-facing strings. If changes have been made, the CI job parses the source code and extracts translatable strings into a POT file. If a POT file already exists, the CI job will update the existing POT file. (If the CI job hasn't already been added to your pipeline, you will need to add it.)

3. When a POT file is updated, the Transifex webhook pushes the new POT file to Transifex ready for translation. (If your POT file hasn't been added to the Transifex integration yet, you will need to get it added.)

4. When a PO file reaches 100% translated and reviewed, a webhook pushes it back to the source repo ready to be consumed by your app. 

5. Your app checks the user's locale settings (the browser settings for web apps, or the system settings for the CLI). If we support the user's preferred locale, the app will display strings in the user's language. Otherwise, it defaults to English.

## Merge Pot files rake task

The rake task that merges .pot files is present for the internationalisation of a module. This task uses 'msgcat', which is only natively present on OSes that are GNU based. For running this task locally on another OS, you will need to download the gettext pkg and install it locally:
https://pkgs.org/download/gettext

This task will run within the gettext setup locales_path provided by GettextSetup. The result will be a merged pot file created from all pot files kept in this location.

By default, the merged pot file is locales_path/project_name.pot. This can be overridden when calling the method by providing a chosen path.

Please note: Since the default merged file name is project_name.pot, it will override anything of that name within the locales directory.
