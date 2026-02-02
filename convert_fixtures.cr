require "json"
require "yaml"

Dir.glob("spec/fixtures/grammar/*.json").each do |file|
  puts "Converting: #{file}"
  begin
    content = File.read(file)
    # Basic comment stripping if JSON parse fails?
    # Simple recursive cleaner? No, assume they are valid JSON now (since specs pass).

    data = JSON.parse(content)

    # We want to preserve structure.
    # JSON::Any to YAML.

    yaml_content = data.to_yaml

    new_file = file.sub(/\.json$/, ".yml")
    File.write(new_file, yaml_content)
    puts "  -> #{new_file}"

    # Optional: Delete old file
    File.delete(file)
  rescue e
    puts "FAILED: #{file} - #{e.message}"
  end
end
