Settings = YAML.load_file(
  Rails.root.join('config/settings.yml')
).deep_symbolize_keys.freeze
