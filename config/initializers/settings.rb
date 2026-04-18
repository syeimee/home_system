Settings = YAML.safe_load(
  ERB.new(Rails.root.join('config/settings.yml').read).result,
  permitted_classes: [Symbol],
  aliases: true
).deep_symbolize_keys.freeze
