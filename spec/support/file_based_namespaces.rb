RSpec.shared_examples 'a file based namespace' do |content, expected_settings|
  before do
    allow(PDK::Util::Filesystem).to receive(:mkdir_p)
  end

  describe '#parse_file' do
    context 'when the file contains valid data' do
      before do
        expect(subject).to receive(:load_data).and_return(content)
      end

      it 'returns the parsed data' do
        settings = {}
        subject.parse_file(subject.file) { |k, v| settings[k] = v }

        expect(settings.keys).to eq(expected_settings.keys)
        expected_settings.each do |expected_key, expected_value|
          expect(settings[expected_key].value).to eq(expected_value)
        end
      end
    end

    context 'when the file is deleted mid-read' do
      before do
        allow(PDK::Util::Filesystem).to receive(:read_file).with(subject.file).and_raise(Errno::ENOENT, 'error')
      end

      it 'raises PDK::Config::LoadError' do
        result = subject
        expect { result.parse_file(result.file) {} }.to raise_error(PDK::Config::LoadError, /error/)
      end
    end

    context 'when the file is unreadable' do
      before do
        allow(PDK::Util::Filesystem).to receive(:read_file).with(subject.file).and_raise(Errno::EACCES)
      end

      it 'raises PDK::Config::LoadError' do
        result = subject
        expect do
          result.parse_file(result.file) {}
        end.to raise_error(PDK::Config::LoadError, "Unable to open #{result.file} for reading")
      end
    end
  end

  context 'when serializing deserializing data' do
    before do
      expect(subject).to receive(:load_data).and_return(content)
    end

    it 'does not add or lose any data when round tripping the serialization' do
      # Force the file to be loaded
      expected_settings.each_key { |k| subject[k] }
      # Force a setting to be saved by setting a single known value
      expect(PDK::Util::Filesystem).to receive(:write_file).with(subject.file, content)
      key = expected_settings.keys[0]
      subject[key] = expected_settings[key]
    end
  end
end

# content should include a settings called 'extra_setting' and 'foo' where:
#   * foo is included in the schema
#   * extra_setting is NOT included in the schema
RSpec.shared_examples 'a file based namespace with a schema' do |content|
  before do
    allow(PDK::Util::Filesystem).to receive(:mkdir_p)
    allow(subject).to receive(:load_data).and_return(content)
  end

  describe '#parse_file' do
    context 'when the file does not exist or is unreadable' do
      before do
        allow(subject).to receive(:load_data).and_return(nil)
      end

      it 'yields schema based settings' do
        result = subject
        expect { |o| result.parse_file(result.file, &o) }.to yield_control
      end
    end

    context 'when the file content is parsable but not valid according to the schema' do
      let(:schema_data) do
        # Expects foo to be the letter `x` 128 times
        <<-SCHEMA
        {
          "definitions": {},
          "$schema": "http://json-schema.org/draft-06/schema#",
          "$id": "http://puppet.com/schema/does_not_exist.json",
          "type": "object",
          "title": "A Schema",
          "properties": {
            "foo": {
              "$id": "#/properties/foo",
              "title": "A property",
              "type": "string",
              "pattern": "x{128,128}"
            }
          }
        }
        SCHEMA
      end

      it 'raises LoadError' do
        result = subject
        expect { result.parse_file(result.file) { |i| } }.to raise_error(PDK::Config::LoadError)
      end
    end
  end

  describe '#[]=' do
    it 'raises ArgumentError if the setting does not exist' do
      expect { subject['does_not_exist_at_all'] = 'baz' }.to raise_error(ArgumentError, /Setting 'does_not_exist_at_all' does not exist/)
    end
  end

  describe 'to_h' do
    it 'includes settings that are not in the schema' do
      expect(subject.to_h).to include('extra_setting' => Object)
    end
  end
end

RSpec.shared_examples 'a file based namespace without a schema' do
  before do
    allow(PDK::Util::Filesystem).to receive(:mkdir_p)
  end

  describe '#parse_file' do
    context 'when the file does not exist or is unreadable' do
      before do
        allow(subject).to receive(:load_data).and_return(nil)
      end

      it 'does not yield any results' do
        result = subject
        expect { |o| result.parse_file(result.file, &o) }.not_to yield_control
      end
    end
  end

  describe '#[]=' do
    it 'dynamically adds settings if they do not exist' do
      subject['missing'] = 'something'
      expect(subject[:missing]).to eq('something')
    end
  end
end

RSpec.shared_examples 'a yaml file based namespace' do
  before do
    allow(PDK::Util::Filesystem).to receive(:mkdir_p)
  end

  describe '#parse_file' do
    context 'when the file contains invalid YAML' do
      let(:data) { "---\n\tfoo: bar" }

      it 'raises PDK::Config::LoadError' do
        expect { yaml_config.parse_file(tempfile) {} }.to raise_error(PDK::Config::LoadError, /syntax error/i)
      end
    end

    context 'when the file contains valid YAML with invalid data classes' do
      let(:data) { "--- !ruby/object:File {}\n" }

      it 'raises PDK::Config::LoadError' do
        expect { yaml_config.parse_file(tempfile) {} }.to raise_error(PDK::Config::LoadError, /unsupported class/i)
      end
    end
  end

  describe '#serialize_data' do
    subject(:serialized_data) { yaml_config.serialize_data(yaml_config.to_h) }

    context 'when there is no data stored' do
      it 'writes an empty YAML hash to disk' do
        expect(serialized_data).to eq("--- {}\n")
      end
    end

    context 'when there is data stored' do
      it 'writes the YAML document to disk' do
        yaml_config['foo'] = 'bar'
        expect(serialized_data).to eq("---\nfoo: bar\n")
      end
    end
  end
end

RSpec.shared_examples 'a json file based namespace' do
  describe '#serialize_data' do
    subject(:serialized_data) { json_config.serialize_data(json_config.to_h) }

    context 'when there is no data stored' do
      it 'serializes to an empty JSON object' do
        expect(serialized_data).to match(/^\{\}$/)
      end
    end

    context 'when there is data stored' do
      it 'serializes to a JSON object string' do
        json_config.setting('foo')
        json_config['foo'] = 'bar'
        expect(serialized_data).to eq("{\n  \"foo\": \"bar\"\n}")
      end
    end
  end
end
