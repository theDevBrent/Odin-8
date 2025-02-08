package chip8

import "../config"

Registers :: struct {
	V:  [config.TOTAL_DATA_REGISTERS]u8,
	I:  u16,
	DT: u8,
	ST: u8,
	PC: u16,
	SP: u8,
}
