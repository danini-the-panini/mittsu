module Mittsu
  ShaderChunk = {}.tap do |chunks|
    Dir.new(File.join(__dir__, 'shader_chunk')).each do |file_name|
      next unless file_name.end_with? '.glsl'
      file_path = File.join(__dir__, 'shader_chunk', file_name)
      chunk_name = File.basename(file_name, '.glsl')
      chunk = File.read(file_path)
      # chunk = "// #{chunk_name}\n#{chunk}"
      chunks[chunk_name.to_sym] = chunk
    end
  end
end
