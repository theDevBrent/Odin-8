package chip8

import "../config"

Stack :: struct {
	stack: [config.TOTAL_STACK_DEPTH]u16,
}

stack_in_bound :: proc(chip8: ^Chip8) {
	assert(chip8.registers.SP < config.TOTAL_STACK_DEPTH)
}

stack_push :: proc(chip8: ^Chip8, val: u16) {
	stack_in_bound(chip8)
	chip8.stack.stack[chip8.registers.SP] = val
	chip8.registers.SP += 1
}


stack_pop :: proc(chip8: ^Chip8) -> u16 {
	chip8.registers.SP -= 1
	stack_in_bound(chip8)
	return chip8.stack.stack[chip8.registers.SP]
}
