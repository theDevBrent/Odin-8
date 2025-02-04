package chip8

import "../config"

Memory :: struct {
	memory: [config.MEMORY_SIZE]u8,
}

is_in_memory_bounds :: proc(index: int) {
	assert(index >= 0 && index < config.MEMORY_SIZE)
}

memory_set :: proc(memory: ^Memory, index: int, val: u8) {
	is_in_memory_bounds(index)
	memory.memory[index] = val
}


memory_get :: proc(memory: ^Memory, index: int) -> u8 {
	is_in_memory_bounds(index)
	return memory.memory[index]
}
