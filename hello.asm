; hello.asm 
section .data
message: db  'hello, world!', 10

section .text

%define EXIT 60
%define STDOUT 1
%define SIZE_MESSAGE 14
global _start

exit:                        ; Это метка начала функции exit
    mov  rax, EXIT           ; Это функция exit
    xor  rdi, rdi
    push 0xaa
    
    push 0xbb
    syscall

print_string:                ; Это метка начала функции print_string
    mov  rax, STDOUT         ; Это функция print_string
    mov  rdi, STDOUT
    mov  rsi, message
    mov  rdx, SIZE_MESSAGE
    syscall
    ret                      ; Выход из функции print_string

_start:
    call print_string        ; Вызов функции print_string
    call print_string        ; Вызов функции print_string
    call exit                ; Вызов функции exit
