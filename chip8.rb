module Chip8
	class Emulator
		def initialize(rom)
			@memory = Memory.new(rom)
			@cpu = CPU.new
		end
		
		def run_next_cycle
			@cpu.execute(@memory)
		end
	end

	class Memory
		INITIAL_MEMORY = 0x200

		def initialize(rom)
			@memory = Array.new(0x1000, 0x0)
			rom.each_with_index do |opcode, i|
				@memory[INITIAL_MEMORY + i] = opcode
			end
		
			@current_address = INITIAL_MEMORY
		end

		def current_opcode
			puts "Memory: #{@memory}"
			puts "Current address: #{@current_address.to_s(16)}"
			@memory[@current_address]
		end

		def [](address)
		  @memory[address]	
		end

		def []=(address, value)
			@memory[address] = value
		end

		# Steps n opcodes
		def step!(n = 2)
			@current_address += 2
		end
	end

	class CPU
		def execute(memory)
			opcode = memory.current_opcode
			
			puts "Opcode: #{(opcode & 0xF000)}"

			case (opcode & 0xF000)
			when 0x6000 # 6xkk - LD Vx, byte
				register = (opcode & 0x0F00) >> 8
				value = (opcode & 0x00FF)
				memory.V[register] = value
				memory.step!
			else
				raise "#{opcode.to_s(16)} not implemented yet!"
			end
		end
	end
end
