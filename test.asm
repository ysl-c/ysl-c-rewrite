jmp __func__main
ret
jmp __func_end__putch
__func__putch:
mov ah, 0x0E
mov al, [__func__putch.__var__ch]
int 0x10
ret
__func__putch.__var__ch:
dw 0
__func_end__putch:
jmp __func_end__main
__func__main:
mov word [__func__putch.__var__ch], 72
call __func__putch
mov word [__func__putch.__var__ch], 105
call __func__putch
ret
__func_end__main: