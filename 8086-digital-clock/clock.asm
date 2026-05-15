; Simple Digital Clock in 8086 Assembly
; Counts seconds properly with software-only implementation

.model small
.stack 100h

.data
    ; Time variables
    hour    db 12    ; Current hour (1-12)
    minute  db 0     ; Current minute (0-59)
    second  db 0     ; Current second (0-59)
    is_pm   db 0     ; 0 for AM, 1 for PM
    
    ; Display strings
    msg     db "Digital Clock (Press ESC to exit)", 0Dh, 0Ah, "$"
    time    db "00:00:00 AM$"

.code
main proc
    mov ax, @data
    mov ds, ax
    
    ; Clear screen
    mov ax, 0600h    ; Scroll entire window up (clear)
    mov bh, 07h      ; Normal attribute (white on black)
    mov cx, 0000h    ; Upper left corner (0,0)
    mov dx, 184Fh    ; Lower right corner (24,79)
    int 10h
    
    ; Display message
    mov ah, 09h
    lea dx, msg
    int 21h
    
    ; Initialize time from system
    call init_time
    
    ; Main clock loop
clock_loop:
    ; Display current time
    call display_time
    
    ; Delay for approximately 1 second
    call delay
    
    ; Update time (increment second)
    call update_time
    
    ; Check for ESC key
    mov ah, 01h      ; Check if key pressed
    int 16h
    jz clock_loop    ; If no key, continue loop
    
    mov ah, 00h      ; Get key
    int 16h
    cmp al, 27       ; Check if ESC (ASCII 27)
    jne clock_loop   ; If not ESC, continue loop
    
    ; Exit program
    mov ax, 4C00h
    int 21h
main endp

;--------------------------------------
; Initialize time from system clock
;--------------------------------------
init_time proc
    ; Get system time
    mov ah, 2Ch      ; DOS function: Get System Time
    int 21h
    ; CH = hour (0-23)
    ; CL = minute (0-59)
    ; DH = second (0-59)
    
    ; Convert 24-hour to 12-hour format
    mov al, ch       ; AL = hour (0-23)
    
    ; Set AM/PM flag
    cmp al, 12
    jb am_time
    mov is_pm, 1     ; PM
    jmp hour_check
am_time:
    mov is_pm, 0     ; AM
    
hour_check:
    ; Convert hour to 12-hour format
    cmp al, 12       ; If hour = 12
    je set_hour      ; 12 stays as 12
    cmp al, 0        ; If hour = 0 (midnight)
    je set_to_12     ; 0 becomes 12
    cmp al, 12       ; If hour > 12
    ja subtract_12   ; Subtract 12
    jmp set_hour     ; Otherwise use as is
    
set_to_12:
    mov al, 12       ; Set hour to 12
    jmp set_hour
    
subtract_12:
    sub al, 12       ; Convert to 12-hour format
    
set_hour:
    mov hour, al     ; Store hour
    mov minute, cl   ; Store minute
    mov second, dh   ; Store second
    
    ret
init_time endp

;--------------------------------------
; Display current time
;--------------------------------------
display_time proc
    ; Format time string
    call format_time
    
    ; Position cursor
    mov ah, 02h      ; Set cursor position
    mov bh, 0        ; Page 0
    mov dh, 2        ; Row 2
    mov dl, 0        ; Column 0
    int 10h
    
    ; Display time
    mov ah, 09h
    lea dx, time
    int 21h
    
    ret
display_time endp

;--------------------------------------
; Format time string with current values
;--------------------------------------
format_time proc
    ; Format hours
    mov al, hour
    call format_digit
    mov time[0], ah      ; Tens digit
    mov time[1], al      ; Ones digit
    
    ; Format minutes
    mov al, minute
    call format_digit
    mov time[3], ah      ; Tens digit
    mov time[4], al      ; Ones digit
    
    ; Format seconds
    mov al, second
    call format_digit
    mov time[6], ah      ; Tens digit
    mov time[7], al      ; Ones digit
    
    ; Set AM/PM
    cmp is_pm, 0
    je set_am
    mov time[9], 'P'     ; PM
    jmp format_done
set_am:
    mov time[9], 'A'     ; AM
format_done:
    
    ret
format_time endp

;--------------------------------------
; Format a number (0-99) to ASCII digits
; Input: AL = number
; Output: AH = tens digit, AL = ones digit
;--------------------------------------
format_digit proc
    mov ah, 0        ; Clear AH
    mov bl, 10       ; Divisor
    div bl           ; AL = quotient (tens), AH = remainder (ones)
    
    add al, '0'      ; Convert tens to ASCII
    xchg ah, al      ; Swap AH and AL
    add al, '0'      ; Convert ones to ASCII
    
    ret
format_digit endp

;--------------------------------------
; Update time (increment second)
;--------------------------------------
update_time proc
    ; Increment second
    inc second
    cmp second, 60
    jb done_update
    
    ; Second reached 60, reset and increment minute
    mov second, 0
    inc minute
    cmp minute, 60
    jb done_update
    
    ; Minute reached 60, reset and increment hour
    mov minute, 0
    inc hour
    
    ; Check if hour needs to roll over
    cmp hour, 12
    jbe check_noon
    mov hour, 1      ; Hour > 12, reset to 1
    jmp done_update
    
check_noon:
    ; Toggle AM/PM at noon or midnight
    cmp hour, 12
    jne done_update
    xor is_pm, 1     ; Toggle AM/PM
    
done_update:
    ret
update_time endp

;--------------------------------------
; Simple software delay (approximately 1 second)
;--------------------------------------
delay proc
    push ax
    push cx
    push dx
    
    ; Simple nested loop delay
    mov cx, 10       ; Outer loop count
outer_delay:
    push cx
    mov cx, 0FFFFh   ; Inner loop count
inner_delay:
    nop              ; No operation (takes CPU cycles)
    nop              ; Additional NOPs to slow down
    nop
    nop
    loop inner_delay ; Decrement CX and loop until zero
    pop cx
    loop outer_delay ; Decrement CX and loop until zero
    
    pop dx
    pop cx
    pop ax
    ret
delay endp

end main
