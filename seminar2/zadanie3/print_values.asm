; print_hex.asm
section .data
codes:
    db      '0123456789ABCDEF'

section .text

%define EXIT 60
%define NEW_STRING 10
%define STDOUT 1
%define SYS_CALL 1
%define TETRAD 4
global _start
exit:
    mov  rax, EXIT            ; invoke 'exit' system call
    xor  rdi, rdi
    syscall

; Принимает код символа и выводит его в stdout
print_char:
    push rdi
    mov rax, 1
    mov rdi, STDOUT
    mov rsi, rsp
    mov rdx, 1
    syscall
    pop rdi
    ret



; Переводит строку (выводит символ с кодом 0xA) 
print_newline:
    mov rdi, NEW_STRING
    call print_char
    ret

print_hex:
    mov  rdi, STDOUT
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
        ret

_start:
    sub rsp, 3; reserve space in stack
    mov byte [rsp], 0xAA
    mov byte [rsp+1], 0xBB
    mov byte [rsp+2], 0xCC

    xor rax, rax
    mov al, [rsp]
    call print_hex
    call print_newline
    mov al, [rsp+1]
    call print_hex
    call print_newline
    mov al, [rsp+2]
    call print_hex
    call print_newline

    add rsp, 3 ; free space in stack

    jmp exit
