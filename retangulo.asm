;---------------------------------------------------------------------------
;-------------------------------Inicialização-------------------------------
;---------------------------------------------------------------------------  
segment code
..start:
	mov ax,data
	mov ds,ax
	mov ax,stack
	mov ss,ax
	mov sp,stacktop
; salvar modo corrente de video(vendo como está o modo de video da maquina)
    mov ah,0Fh
    int 10h
    mov [modo_anterior],al   
; alterar modo de video para gráfico 640x480 16 cores
    mov al,12h
   	mov ah,0
    int 10h

;---------------------------------------------------------------------------
;-----------Exemplos ilustrativos para o desenho de retangulos--------------
;---------------------------------------------------------------------------

borda: 
    mov byte[cor], branco_intenso
	mov ax, 0 		    ; x0
	mov bx, 0		    ; y0
	mov cx, 639		    ; l
	mov dx, 479		    ; h
	call retangulo	

retangulo_1:
	mov byte[cor], vermelho
	mov ax, 20			; x0
	mov bx, 230			; y0
	mov cx, 7			; l
    mov dx, 14          ; h
	call retangulo
	
retangulo_2:
	mov byte[cor], amarelo
	mov ax, 100			; x0
	mov bx, 230			; y0
	mov cx, 21			; l
    mov dx, 14          ; h
	call retangulo
	
retangulo_3:
	mov byte[cor], verde
	mov ax, 200			; x0
	mov bx, 230			; y0
	mov cx, 21			; l
	mov dx, 28          ; h
	call retangulo

retangulo_4:
	mov byte[cor], cyan_claro
	mov ax, 310			; x0
	mov bx, 230			; y0
	mov cx, 28			; l
    mov dx, 35          ; h
	call retangulo	
	
retangulo_5:
	mov byte[cor], azul
	mov ax, 425			; x0
	mov bx, 230			; y0
	mov cx, 35			; l
    mov dx, 42          ; h
	call retangulo	

retangulo_6:
	mov byte[cor], magenta
	mov ax, 555			; x0
	mov bx, 230			; y0
	mov cx, 42			; l
    mov dx, 49          ; h
    call retangulo
    
; Vai para a saida do código, que espera uma tecla ser apertada para sair
    jmp saida

;---------------------------------------------------------------------------
; Função Retangulo (x0, y0, h, l)
; ax 	-> x0 : Posicao X do ponto inferior esquerdo
; bx 	-> y0 : Posicao Y do ponto inferior esquerdo 
; cx 	-> l  : Lado do retangulo
; dx 	-> h  : Altura do retangulo
; di 	-> tipo 1/2 - Cheio , 3/4/5 - Simples
; byte[cor]: Indica a cor utilizada
;---------------------------------------------------------------------------
; Caso se queira usar a função separadamente, e quiser alterar o valor 
;dos tipos, basta mudar o valor usado na comparação antes do preenchimento
;do retangulo.
;---------------------------------------------------------------------------
retangulo:
	push cx
	push dx
	push si
	push di

	;Divisória esquerda              
	push ax ;x1 -> x0
	push bx ;y1 -> y0
	push ax ;x2 -> x0
	mov si, bx
	add si, dx
	push si ;y2 -> y0 + h
	call line
	
	;Divisória direita
	mov si, ax
	add si, cx
	push si ; x1 -> x0 + l
	push bx ; y1 -> y0
	push si ; x2 -> x0 + l
	mov si, bx
	add si, dx
	push si ; y2 -> y0 + h
	call line
	
	;Divisória inferior
	push ax ; x1 -> x0
	push bx ; y1 -> y0
	mov si, ax
	add si, cx
	push si ; x2 -> x0 + l
	push bx ; y2 -> y0
	call line
	
	push di
	;Divisória superior
	push ax ; x1 -> x0
	mov si, bx
	add si, dx
	push si ; y1 -> y0 + h
	mov di, ax
	add di, cx
	push di ; x2 -> x0 + l
	push si ; y2 -> y0 + h
	call line

	pop di
	cmp di, 2   
	ja sair3    ; Tipo Simples

retangulo_cheio:
	mov si, dx; si recebe h
	mov dx, cx; dx recebe l
	mov cx, si; cx recebe h

preenche_retangulo:
		;Divisória superior
		push ax ; x1 -> x0
		mov si, bx
		add si, cx
		push si ; y1 -> y0 + h
		mov di, ax
		add di, dx
		push di ; x2 -> x0 + l
		push si ; y2 -> y0 + h
		call line
		loop preenche_retangulo

sair3:
	pop di
	pop si
	pop dx
	pop cx	
	ret

;---------------------------------------------------------------------------
;-----------------------FUNÇÕES AUXILIARES DE DESENHO-----------------------
;---------------------------------------------------------------------------

;---------------------------------------------------------------------------	
;--------------------------Função que plota um ponto------------------------
;---------------------------------------------------------------------------
plot_xy:
	push bp
	mov bp,sp
	pushf
	push ax
	push bx
	push cx
	push dx
	push si
	push di
	mov ah,0ch
	mov al,[cor]
	mov bh,0
	mov dx,479
	sub dx,[bp+4]
	mov cx,[bp+6]
	int 10h
	pop di
	pop si
	pop dx
	pop cx
	pop bx
	pop ax
	popf
	pop bp
	ret 4

;---------------------------------------------------------------------------
;-----------------------Função que desenha linhas---------------------------
;---------------------------------------------------------------------------
line:
	push bp
	mov bp,sp
	pushf			 ; coloca os flags na pilha
	push ax
	push bx
	push cx
	push dx
	push si
	push di
	mov ax,[bp+10]   ; resgata os valores das coordenadas
	mov bx,[bp+8]    ; resgata os valores das coordenadas
	mov cx,[bp+6]    ; resgata os valores das coordenadas
	mov dx,[bp+4]    ; resgata os valores das coordenadas
	cmp ax,cx
	je line2
	jb line1
	xchg ax,cx
	xchg bx,dx
	jmp line1
	  
	line2:    ; deltax=0
		cmp bx,dx  ;subtrai dx de bx
		jb line3
		xchg bx,dx        ;troca os valores de bx e dx entre eles
	  
	line3:  ; dx > bx
		push ax
		push bx
		call plot_xy
		cmp bx,dx
		jne line31
		jmp fim_line
	 
	line31: 
		inc bx
		jmp line3
		;deltax <>0
	 
	line1:
		; comparar módulos de deltax e deltay sabendo que cx>ax
		; cx > ax
		push cx
		sub cx,ax
		mov [deltax],cx
		pop cx
		push dx
		sub dx,bx
		ja line32
		neg dx
	
	line32:   
		mov [deltay],dx
		pop dx
		push ax
		mov ax,[deltax]
		cmp ax,[deltay]
		pop ax
		jb line5
		; cx > ax e deltax>deltay
		push cx
		sub cx,ax
		mov [deltax],cx
		pop cx
		push dx
		sub dx,bx
		mov [deltay],dx
		pop dx
		mov si,ax
	 
	line4:
		push ax
		push dx
		push si
		sub si,ax ;(x-x1)
		mov ax,[deltay]
		imul si
		mov si,[deltax]   ;arredondar
		shr si,1
		; se numerador (DX)>0 soma se <0 subtrai
		cmp dx,0
		jl ar1
		add ax,si
		adc dx,0
		jmp arc1
	
	ar1:
		sub ax,si
		sbb dx,0
	
	arc1:
		idiv word [deltax]
		add ax,bx
		pop si
		push si
		push ax
		call plot_xy
		pop dx
		pop ax
		cmp si,cx
		je  fim_line
		inc si
		jmp line4
	
	line5:    
		cmp bx,dx
		jb  line7
		xchg ax,cx
		xchg bx,dx
	
	line7:
		push cx
		sub cx,ax
		mov [deltax],cx
		pop cx
		push dx
		sub dx,bx
		mov [deltay],dx
		pop dx
		mov si,bx
	 
	line6:
		push dx
		push si
		push ax
		sub si,bx ;(y-y1)
		mov ax,[deltax]
		imul si
		mov si,[deltay]   ;arredondar
		shr si,1
		; se numerador (DX)>0 soma se <0 subtrai
		cmp dx,0
		jl ar2
		add ax,si
		adc dx,0
		jmp arc2

	ar2:    
		sub ax,si
		sbb dx,0
	
	arc2:
		idiv word [deltay]
		mov di,ax
		pop ax
		add di,ax
		pop si
		push di
		push si
		call plot_xy
		pop dx
		cmp si,dx
		je fim_line
		inc si
		jmp line6
	 
	fim_line:
		pop di
		pop si
		pop dx
		pop cx
		pop bx
		pop ax
		popf
		pop bp
		ret 8

;---------------------------------------------------------------------------
;---------------------------SAÍDA DO PROGRAMA-------------------------------
;---------------------------------------------------------------------------
saida:
	mov  ah,08h
	int  21h
	mov ah,0                ; set video mode
	mov al,[modo_anterior]  ; modo anterior
	int 10h
	mov ax,4c00h
	int 21h 

;---------------------------------------------------------------------------
;----------------------------SEGMENTO DE DADOS------------------------------
;---------------------------------------------------------------------------
segment data

cor		db		branco_intenso

;	I R G B COR
;	0 0 0 0 preto
;	0 0 0 1 azul
;	0 0 1 0 verde
;	0 0 1 1 cyan
;	0 1 0 0 vermelho
;	0 1 0 1 magenta
;	0 1 1 0 marrom
;	0 1 1 1 branco
;	1 0 0 0 cinza
;	1 0 0 1 azul claro
;	1 0 1 0 verde claro
;	1 0 1 1 cyan claro
;	1 1 0 0 rosa
;	1 1 0 1 magenta claro
;	1 1 1 0 amarelo
;	1 1 1 1 branco intenso

preto		    equ		0
azul		    equ		1
verde		    equ		2
cyan		    equ		3
vermelho	    equ		4
magenta		    equ		5
marrom		    equ		6
branco		    equ		7
cinza		    equ		8
azul_claro	    equ		9
verde_claro	    equ		10
cyan_claro	    equ		11
rosa		    equ		12
magenta_claro	equ		13
amarelo		    equ		14
branco_intenso	equ	    15

modo_anterior	db		0
deltax		    dw	    0
deltay		    dw	    0

segment stack stack
resb 	512

stacktop:
;---------------------------------------------------------------------------
;scalfs, 2017
;---------------------------------------------------------------------------