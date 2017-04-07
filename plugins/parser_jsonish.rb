module Fluent
  class TextParser
    class JSONishParser < JSONParser

      Plugin.register_parser('jsonish', self)

      def initialize
        super
      end

      def valid_json?(json)
        !!JSON.parse(json)
      rescue JSON::ParserError => _e
        false
      end

      def parse(text)
        record = @load_proc.call(text)
        time = Engine.now
        inner_json = nil

        begin
          inner_json = @load_proc.call(record["log"])
        rescue
          inner_json = nil
        end

        if inner_json.nil?
          yield time, record
        else
          record.delete("log")
          new_log = record.merge(inner_json)
          yield time, new_log
        end
      end
    end
  end
end

