require 'zlib'
require 'json'

module Gitlab
  module Ci
    module Build
      module Artifacts
        class Metadata
          VERSION_PATTERN = '[\w\s]+(\d+\.\d+\.\d+)'
          attr_reader :file, :path, :full_version

          def initialize(file, path)
            @file, @path = file, path
            @full_version = read_version
          end

          def version
            @full_version.match(/#{VERSION_PATTERN}/).captures.first
          end

          def errors
            gzip do|gz|
              read_string(gz) # version
              errors = read_string(gz)
              raise StandardError, 'Errors field not found!' unless errors
              JSON.parse(errors)
            end
          end

          def match!
            gzip do |gz|
              2.times { read_string(gz) } # version and errors fields
              match_entries(gz)
            end
          end

          def to_path
            Path.new(@path, *match!)
          end

          private

          def match_entries(gz)
            paths, metadata = [], []
            match_pattern = %r{^#{Regexp.escape(@path)}[^/\s]*/?$}

            until gz.eof? do
              begin
                path = read_string(gz)
                meta = read_string(gz)
               
                next unless path =~ match_pattern
                next unless path_valid?(path)

                paths.push(path)
                metadata.push(JSON.parse(meta.chomp, symbolize_names: true))
              rescue JSON::ParserError
                next
              end
            end

            [paths, metadata]
          end

          def path_valid?(path)
            !(path.start_with?('/') || path =~ %r{\.?\./})
          end

          def read_version
            gzip do|gz|
              version_string = read_string(gz)

              unless version_string
                raise StandardError, 'Artifacts metadata file empty!'
              end

              unless version_string =~ /^#{VERSION_PATTERN}/
                raise StandardError, 'Invalid version!'
              end

              version_string.chomp
            end
          end

          def read_uint32(gz)
            binary = gz.read(4)
            binary.unpack('L>')[0] if binary
          end

          def read_string(gz)
            string_size = read_uint32(gz)
            return false unless string_size
            gz.read(string_size)
          end

          def gzip
            open do |file|
              gzip = Zlib::GzipReader.new(file)
              result = yield gzip
              gzip.close
              result
            end
          end

          def open
            File.open(@file) { |file| yield file }
          end
        end
      end
    end
  end
end
