package chip8

import "../config"
import "core:fmt"

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

memory_get_short :: proc(memory: ^Memory, index: int) -> u16 {
	byte1 := memory_get(memory, index)
	byte2 := memory_get(memory, index + 1)

	return u16(byte1) << 8 | u16(byte2)
}
