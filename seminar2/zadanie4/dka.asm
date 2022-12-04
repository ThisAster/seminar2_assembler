section .data
message: db  'true', 10
message2: db  'false', 10

%define EXIT 60
%define STDOUT 1

section .text
global _start
print_string:
    mov  rdx, rsi
    mov  rsi, rdi
    mov  rax, 1
    mov  rdi, STDOUT
    syscall
    mov rax, EXIT
    xor rdi, rdi
    syscall

getsymbol:    
    xor rax, rax ; 0 - read syscall number
    xor rdi, rdi ; 0 - stdin
    push 0 ; space for char
    mov rsi, rsp 
    mov rdx, 1 ; read 1 byte
    syscall
    pop rax
    ret


_A:
    call getsymbol
    cmp al, '+'
    je _B
    cmp al, '-'
    je _B
; The indices of the digit characters in ASCII
; tables fill a range from '0' = 0x30 to '9' = 0x39
; This logic implements the transitions to labels
; _E and _C
    cmp al, '0'
    jb _E
cmp al, '9'
    ja _E
    jmp _C
_B:
    call getsymbol
    cmp al, '0'
    jb _E
    cmp al, '9'
    ja _E
    jmp _C
_C:
    call getsymbol
    cmp al, 0xA
    je _D
    cmp al, '0'
    jb _E
    cmp al, '9'
    ja _E
    test al, al
    jz _D
    jmp _C
_D:
    mov rdi, message
    mov rsi, 5
    call print_string
_E:
; code to notify about failure
    mov rdi, message2
    mov rsi, 6
    call print_string

_start:
    call _A

