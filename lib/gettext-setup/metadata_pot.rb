require 'erb'
require 'json'

module GettextSetup
  module MetadataPot
    def self.metadata_path
      File.join(GettextSetup.locales_path, GettextSetup.config['project_name'] + '_metadata.pot')
    end

    def self.template_path
      File.join(File.dirname(__FILE__), '../templates/metadata.pot.erb')
    end

    def self.metadata(metadata_file = 'metadata.json')
      if File.exist?(metadata_file)
        file = open(metadata_file)
        json = file.read
        JSON.parse(json)
      else
        {}
      end
    end

    def self.pot_string(metadata)
      b = binding.freeze
      # Uses `metadata`
      ERB.new(File.read(template_path)).result(b)
    end

    def self.generate_metadata_pot(pot_metadata = metadata, path = metadata_path)
      open(path, 'w') do |f|
        f << pot_string(pot_metadata)
      end
    end
  end
end
