# -*- encoding: utf-8 -*-

def metadata_pot_file_path
  File.join(locale_path, GettextSetup.config['project_name'] + '_metadata.pot')
end

def generate_new_pot_metadata
  metadata = load_metadata_information
  open(metadata_pot_file_path, 'w') do |f|
    f << <<-DOC
#
#, fuzzy
# msgid ""
# msgstr ""
"Project-Id-Version: PACKAGE VERSION\\n"
"Report-Msgid-Bugs-To: \\n"
"POT-Creation-Date: #{DateTime.now} \\n"
"PO-Revision-Date: YEAR-MO-DA HO:MI+ZONE\\n"
"Last-Translator: FULL NAME <EMAIL@ADDRESS>\\n"
"Language-Team: LANGUAGE <LL@li.org>\\n"
"MIME-Version: 1.0\\n"
"Content-Type: text/plain; charset=UTF-8\\n"
"Content-Transfer-Encoding: 8bit\\n"
"X-Generator: Translate Toolkit 2.0.0\\n"
#
            DOC

    if metadata.key?('summary')
      f << <<-DOC
#. metadata.json
#: .summary
msgid "#{metadata['summary']}"
msgstr ""

              DOC
    end

    if metadata.key?('description')
      f << <<-DOC
#. metadata.json
#: .description
msgid "#{metadata['description']}"
msgstr ""

              DOC
    end
  end
end

def load_metadata_information
  metadata_file = 'metadata.json'
  file = open(metadata_file)
  json = file.read
  JSON.parse(json)
end
