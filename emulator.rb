require_relative 'chip8.rb'

if ARGV.length < 1
	puts "Usage: ruby emulator.rb ROM_NAME"
	return
end

rom = File.open(ARGV[0], 'rb') { |file| file.read }.unpack('C*')

emulator = Chip8::Emulator.new(rom)
while(true)
	emulator.run_next_cycle
end
