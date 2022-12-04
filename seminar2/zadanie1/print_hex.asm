; print_hex.asm
section .data
codes:
    db      '0123456789ABCDEF'

section .text

%define EXIT 60
%define STDOUT 1
%define SYS_CALL 1
%define TETRAD 4
global _start
exit:
    mov  rax, EXIT            ; invoke 'exit' system call
    xor  rdi, rdi
    syscall
print_hex:
    mov  rax, rdi
    mov  rdi, STDIN
    mov  rdx, 1
    mov  rcx, 64
	; Each 4 bits should be output as one hexadecimal digit
	; Use shift and bitwise AND to isolate them
	; the result is the offset in 'codes' array
    .loop:
        push rax
        sub  rcx, TETRAD
        ; cl is a register, smallest part of rcx
        ; rax -- eax -- ax -- ah + al
        ; rcx -- ecx -- cx -- ch + cl
        sar  rax, cl
        and  rax, 0xf

        lea  rsi, [codes + rax]
        mov  rax, SYS_CALL

        ; syscall leaves rcx and r11 changed
        push rcx
        syscall
        pop  rcx

        pop rax
        ; test can be used for the fastest 'is it a zero?' check
        ; see docs for 'test' command
        test rcx, rcx
        jnz .loop
        call exit
        ret

_start:
    mov rdi, 0x1122334455667788
    call print_hex
    jmp exit

    
