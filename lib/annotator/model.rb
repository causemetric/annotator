module Annotator

  # Represents a single model file and associated class
  class Model

    def initialize(filename)
      @filename = filename
      @blocks = Hash.new {[]}
    end

    # Model class
    def klass
      begin 
        @filename.split('app/models/').last.split(/\.rb$/).first.camelize.constantize
      rescue Exception
        nil
      end
    end

    # Split file into 3 blocks: before attributes, attributes block, and after
    # If there's no attributes block, content will be in :after part (for easier insertion)
    def parse
      @file = File.read(@filename).strip
      current_block = :before
      return @nodoc = true if @file.match(/^# Attributes\(nodoc\):$/i)
      @file.split("\n").each do |line|
        if line.match(/^#{Regexp.escape Attributes::HEADER} *$/)
          current_block = :attributes
          next
        end
        current_block = :after if current_block == :attributes && !line.match(Attributes::R_ATTRIBUTE_LINE)
        @blocks[current_block] += [line]
      end

      @blocks[:after], @blocks[:before] = @blocks[:before], [] if @blocks[:after].empty?
    end

    # If this file does not have associated AR class it should be skipped
    def skipped?
      !klass || !klass.ancestors.include?(ActiveRecord::Base) || @nodoc
    end

    # Save changes to file if there were any
    def update_file
      output = (@blocks[:before] + @blocks[:attributes] + @blocks[:after]).join("\n").strip + "\n"
      File.open(@filename,'w') { |f| f.write(output) } if output != @file
    end

    # Update file with new database information
    def update!
      parse
      return true if skipped?
      attributes = Attributes.new klass, @blocks[:attributes]
      attributes.update!
      @blocks[:attributes] = attributes.lines
      update_file
    end
  end
end

