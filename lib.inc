section .text
 
string_length:
    xor rax, rax
    .count:
      cmp byte [rdi+rax], 0
      je .end
      inc rax
      jmp .count
    .end:
      ret

print_string:
    push rdi
    call string_length
    pop rsi
    mov  rdx, rax
    mov  rax, 1
    mov  rdi, 1
    syscall
    ret


getsymbol:    
    xor rax, rax ;0 - read syscall number
    xor rdi, rdi ;0 - stdin
    push 0 ;space for char
    mov rsi, rsp 
    mov rdx, 1 ;read 1 byte
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


; Принимает указатель на строку, пытается
; прочитать из её начала беззнаковое число.
; Возвращает в rax: число, rdx : его длину в символах
; rdx = 0 если число прочитать не удалось
parse_uint:
    call _A
    ret
