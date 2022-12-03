; print_string.asm 
section .data
message: db  'hello, world!', 10

section .text

global _start

%define STDOUT 1

string_length:
    xor rax, rax
    push rbx ; Callee-saved 

.loop:
    mov sil, byte[rdi+rax]
    test sil, sil
    jz .end
    inc rax
    jmp .loop

.end:
    pop rbx ; Callee-saved
    ret


print_string:
    push rdi
    call string_length
    pop rdi
    mov rsi, rdi
    mov rax, 1
    mov rdx, rax
    mov rdi, STDOUT
    syscall
    ret