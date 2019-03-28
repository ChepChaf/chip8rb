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

		CHARACTER_BYTES = [
			[0xF0, 0x90, 0x90, 0x90, 0xF0], # "0"
			[0x20, 0x60, 0x20, 0x20, 0x70], # "1"
			[0xF0, 0x10, 0xF0, 0x80, 0xF0], # "2"
			[0xF0, 0x10, 0xF0, 0x10, 0xF0], # "3"
			[0x90, 0x90, 0xF0, 0x10, 0x10], # "4"
			[0xF0, 0x80, 0xF0, 0x10, 0xF0], # "5"
			[0xF0, 0x80, 0xF0, 0x90, 0xF0], # "6"
			[0xF0, 0x10, 0x20, 0x40, 0x40], # "7"
			[0xF0, 0x90, 0xF0, 0x90, 0xF0], # "8"
			[0xF0, 0x90, 0xF0, 0x10, 0xF0], # "9"
			[0xF0, 0x90, 0xF0, 0x90, 0x90], # "A"
			[0xE0, 0x90, 0xE0, 0x90, 0xE0], # "B"
			[0xF0, 0x80, 0x80, 0x80, 0xF0], # "C"
			[0xE0, 0x90, 0x90, 0x90, 0xE0], # "D"
			[0xF0, 0x80, 0xF0, 0x80, 0xF0], # "E"
			[0xF0, 0x80, 0xF0, 0x80, 0x80]  # "F"
		]

		attr_accessor :V, :I, :gfx, :stack

		def initialize(rom)
			@memory = Array.new(0x1000, 0x0)
			rom.each_with_index do |opcode, i|
				@memory[INITIAL_MEMORY + i] = opcode
			end

			@current_address = INITIAL_MEMORY

			self.V = Array.new(0x10, 0x0)
			self.I = 0
			self.gfx = Array.new(0x40, 0x0) {Array.new(0x20, 0x0)}
			self.stack = Array.new

			CHARACTER_BYTES.each_with_index do |character, ch_index|
				character.each_with_index do |byte, bt_index|
					@memory[(5 * ch_index) + bt_index] = byte
				end
			end
		end

		def current_opcode
			opcode = (@memory[@current_address] << 8) | @memory[@current_address + 1]
			puts "Current opcode: #{opcode.to_s(16)}"
			opcode
		end

		def pc=(address)
			@current_address = address
		end

		def pc
			@current_address
		end

		def [](address)
		  @memory[address]
		end

		def []=(address, value)
			@memory[address] = value
		end

		def step!(n = 2)
			@current_address += n
		end
	end

	class CPU
		def execute(memory)
			opcode = memory.current_opcode

			case (opcode & 0xF000)
			when 0x0000
				case (opcode & 0x00FF)
				when 0x00EE
					puts "Current: "
					puts "pc: #{memory.pc}"
					puts "stack: #{memory.stack}"
					memory.pc = memory.stack.pop
					puts "Final: "
					puts "pc: #{memory.pc}"
					puts "stack: #{memory.stack}"
				else
					raise "#{opcode.to_s(16)} not implemented yet!"
				end
			when 0x2000 # 2nnn - CALL addr
				# Call subroutine at nnn.
				# The interpreter increments the stack pointer,
				# then puts the current PC on the top of the stack.
				# The PC is then set to nnn.
				memory.stack.push(memory.pc)

				memory.pc = (opcode & 0x0FFF)
			when 0x6000 # 6xkk - LD Vx, byte
				# Set Vx = kk.
				x = (opcode & 0x0F00) >> 8
				kk = (opcode & 0x00FF)
				memory.V[x] = kk

 				memory.step!
			when 0x7000 # 7xkk - ADD Vx, byte
				# Set Vx = Vx + kk.
				x = (opcode & 0x0F00) >> 8
				kk = (opcode & 0x00FF)

				memory.V[x] += kk

				memory.step!
			when 0xA000 # Annn - LD I, addr
				# Set I = nnn.
				nnn = (opcode & 0x0FFF)
				memory.I = nnn

				memory.step!
			when 0xD000 # Dxyn - DRW Vx, Vy, nibble
				# Display n-byte sprite starting at memory location I at (Vx, Vy),
				# set VF = collision.
				n = (opcode & 0x000F)
				x = memory.V[(opcode & 0x0F00) >> 8]
				y = memory.V[(opcode & 0x00F0) >> 4]

				n.times do |index|
					sprite = memory[memory.I + index]
					memory.gfx[x][y + index] ^= sprite
				end

				memory.step!
			when 0xF000
				case (opcode & 0x00FF)
				when 0x0029 # Fx29 - LD F, Vx
					# Set I = location of sprite for digit Vx.
					x = (opcode & 0x0F00) >> 8
					memory.I = memory[x * 5]

					memory.step!
				when 0x0033 # Fx33 - LD B, Vx
					# Store BCD representation of Vx in memory locations
					# I, I+1, and I+2.
					x = (opcode & 0x0F00) >> 8
					memory[memory.I] = x / 100
					memory[memory.I + 1] = (x % 100) / 100
					memory[memory.I + 2] = x % 10

					memory.step!
				when 0x0065 # Fx65 - LD Vx, [I]
					# The interpreter reads values from memory starting at location I
					# into registers V0 through Vx.
					x = (opcode & 0x0F00) >> 8
					x.times do |index|
						memory.V[index] = memory[memory.I + index]
					end
					memory.step!
				else
					raise "#{opcode.to_s(16)} not implemented yet!"
				end
			else
				raise "#{opcode.to_s(16)} not implemented yet!"
			end
		end
	end
end
