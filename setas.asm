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
;-------------------------Funções de desenho de setas-----------------------
;---------------------------------------------------------------------------
;   Exemplos ilustrativos para desenho de setas. 
;   Os parametros que devem ser passados são posição "x" inicial (x0 em ax),
;posição "y" inicial (y0 em bx), tamanho da seta (k em cx), seu tipo (di) e
;sua cor (byte[cor]). Estes podem ser passados dentro das funções indicadas 
;abaixo, ou podem ser passados no ponto do código onde são chamadas as 
;funções de desenho.
;   Para o projeto do elevador, recomenda-se criar uma função dessas (como 
;"seta_subida_1andar_int"), indicando a posição onde cada seta ficará e 
;atribuir seu tipo e cor quando essas funções forem chamadas. Assim pode-se 
;apagar a seta anterior e redesenhá-la com o tipo e cor desejada.
;   Caso a seta tenha sempre o mesmo tipo e cor, pode-se especificar dentro
;da função, tirando a necessidade de sempre ter que atribuir fora, quando a
;função for chamada. O mesmo pode ser feito com o tamanho da seta.
;   Para apagar a seta, basta chamar a função utilizando os mesmos parametros,
;porém com a cor "preto" em byte[cor].
;---------------------------------------------------------------------------
seta_1:
	mov byte[cor], vermelho
	mov ax, 20			;x0
	mov bx, 230			;y0
	mov cx, 7			;k
    mov di, 1           ;Tipo Comum Cheia
	call desenha_seta
	
seta_2:
	mov byte[cor], amarelo
	mov ax, 100			;x0
	mov bx, 230			;y0
	mov cx, 14			;k
    mov di, 5           ;Tipo Invertida Cheia
	call desenha_seta
	
seta_dupla1:
	mov byte[cor], verde
	mov ax, 200			;x0
	mov bx, 230			;y0
	mov cx, 21			;k
	mov di, 1           ;Tipo Duplo Cheio
	call desenha_seta
	mov byte[cor], verde
	mov ax, 200			;x0
	mov bx, 230			;y0
	mov cx, 21			;k
	inc di
	call desenha_seta
	dec di

seta_3:
	mov byte[cor], cyan_claro
	mov ax, 310			;x0
	mov bx, 230			;y0
	mov cx, 28			;k
    mov di, 3           ;Tipo Comum
	call desenha_seta	
	
seta_4:
	mov byte[cor], azul
	mov ax, 425			;x0
	mov bx, 230			;y0
	mov cx, 35			;k
    mov di, 2           ;Tipo Invertido
	call desenha_seta	

seta_dupla2:
	mov byte[cor], magenta
	mov ax, 555			;x0
	mov bx, 230			;y0
	mov cx, 42			;k
    mov di, 3           ;Tipo Duplo
	call desenha_seta
	mov byte[cor], magenta
	mov ax, 555			;x0
	mov bx, 230			;y0
	mov cx, 42			;k
	inc di
    mov byte[cor], magenta
	call desenha_seta
	dec di

; Vai para a saida do código, que espera uma tecla ser apertada para sair
    jmp saida

;---------------------------------------------------------------------------
; Função Desenha Seta (x0, y0, tipo, cor)
; ax 	-> x0  : Posicao X do ponto inferior esquerdo do quadrado de base
; bx 	-> y0  : Posicao Y do ponto inferior esquerdo do quadrado de base
; cx	-> k   : Escala (Tamanho)
; di	-> tipo: 1 - Cheia Comum, 2 - Cheia Invertida, 3 - Comum , 4 - Dupla, 
;				 5 - Invertida
; byte[cor]: Indica a cor utilizada
;---------------------------------------------------------------------------
; O desenho de cada seta é baseado no desenho de um quadrado de base, com
;um triangulo acima e com o ponto de encontro entre os dois apagado. Se for
;do tipo cheio, o ponto de encontro entre os dois é mantido. Uma seta dupla 
;é apenas o desenho de uma seta comum, sobreposto de uma seta invertida.
; Para desenhar uma seta dupla, é preciso chamar a função para seta comum
;(di=1 ou di=3) e depois chamar novamente, no mesmo ponto, porém com um 
;tipo acima (di=2 ou di=4). O tipo 4 garante que as duas junções entre o 
;quadrado e os triangulos serão apagadas, por isso existem 5 tipos e não 4.
;---------------------------------------------------------------------------
desenha_seta:
	pusha
    
	;Quadrado de lado k
	mov dx, cx		; h = l = k
	call retangulo

	cmp di, 4
	jge seta_invertida      ;Tipo Dupla/Invertida
	cmp di, 2
	je seta_invertida       ;Tipo Cheia Invertida

	;Triangulo de base 2*k, altura k
	mov si, ax		;x0	
	mov ax, cx		;k
	mov cx, 2		
	div cl			;k/2
	xor ah, ah		
	sub si, ax		;x0-k/2
	push ax			;k/2
	mov ax, si		;x0t = x0-k/2
	add bx, dx		;y0t = y0+k
	mov cx, dx		;k
	add cx, cx		;b = 2*k
	call triangulo

    pop si			;k/2
	cmp di, 1       ;Tipo Cheia Comum
	je sair 

	;Limpa Divisória
	mov byte[cor], preto
	add ax, si		;x0t + k/2 = x0
	push ax 		;x1 -> x0
	push bx 		;y1 -> y0t = y0 + k 
	add ax, dx		;x0 + k
	push ax 		;x2 -> x0 + k
	push bx 		;y2 -> y0 + k
	call line
	jmp sair

seta_invertida:
	;Triangulo de base 2*k, altura k
	mov si, ax		;x0
	mov ax, cx		;k
	mov cx, 2		
	div cl			;k/2
	xor ah, ah		
	sub si, ax		;x0-k/2
	push ax			;k/2
	mov ax, si		;x0t = x0-k/2
	mov cx, dx		;k
	add cx, cx		;b = 2*k
	call triangulo

    pop si			;k/2
    cmp di, 2       ;Tipo Cheia Invertida 
    je sair

	;Limpa Divisória
	;mov cl, byte[cor]	;Salva a cor para poder atribuir depois. # Bug a ser resolvido #
	mov byte[cor], preto
	add ax, si		;x0t + k/2 = x0
	push ax 		;x1 -> x0
	push bx 		;y1 -> y0
	add ax, dx		;x0 + k
	push ax 		;x2 -> x0 + k
	push bx 		;y2 -> y0
	call line

	cmp di, 4       ;Tipo Dupla
	jne sair

	; Limpa Divisória 2
	push ax 		;x1 -> x0 + k
	add bx, dx
	push bx 		;y1 -> y0 + k
	sub ax, dx		;x0 + k - k 
	push ax 		;x2 -> x0
	push bx 		;y2 -> y0 + k
	call line
	
sair:
	;mov byte[cor], cl
	popa
	ret

;---------------------------------------------------------------------------
; Função Triangulo (x0, y0)
; ax -> x0 	: Posicao X do ponto inferior esquerdo
; bx -> y0 	: Posicao Y do ponto inferior esquerdo
; cx -> b  	: Base do triangulo
; dx -> h  	: Altura do triangulo 
; di -> Tipo: 1 - Cheia Comum, 2 - Cheia Invertida, 3 - Comum, 4 - Dupla, 
;		      5 - Invertida
; byte[cor]: Indica a cor utilizada
;---------------------------------------------------------------------------
; Caso se queira usar a função separadamente, e quiser alterar o valor dos 
;tipos, basta mudar o valor usado na comparação antes do preenchimento do
;triangulo.
;---------------------------------------------------------------------------
triangulo:
	pusha

	push cx	;Guarda b

	;Base        
	push ax ;x1 -> x0
	push bx ;y1 -> y0
	mov si, ax
	add si, cx
	push si ;x2 -> x0 + b
	push bx ;y2 -> y0
	call line
	
	;Divide a Base por 2
	mov si, ax  ;x0
	mov ax, cx  ;b
	mov cx, 2	
	div cl		;al -> q(b/2)
	xor ah, ah	
	
	cmp di, 4
	jge triangulo_invertido     ;Tipo Duplo/Invertido
	cmp di, 2
	je triangulo_invertido      ;Tipo Invertido Cheio

	;Triangulo Comum
	;Linha Esquerda
	push si 	;x1 -> x0
	push bx 	;y1 -> y0
	add ax, si	
	push ax 	;x2 -> x0 + b/2
	add dx, bx
	push dx 	;y2 -> y0 + h
	call line 
	
	cmp di, 1
	je preenche_triangulo       ;Tipo Comum Cheio

	;Linha Direita
    pop cx      ;b
	push ax 	;x1 -> x0 + b/2
	push dx 	;y1 -> y0 + h
	add si, cx
	push si 	;x2 -> x0 + b
	push bx 	;y2 -> y0
	call line
	jmp sair1

triangulo_invertido:
	;Linha Esquerda
	push si 	;x1 -> x0
	push bx 	;y1 -> y0
	add ax, si	
	push ax 	;x2 -> x0 + b/2
	mov cx, bx
	sub bx, dx
	push bx 	;y2 -> y0 - h
	mov dx, bx
	mov bx, cx
	call line
	
	cmp di, 2
	je preenche_triangulo       ; Tipo Invertido Cheio

	;Linha Direita
	pop cx      ;b
	push ax 	;x1 -> x0 + b/2
	push dx 	;y1 -> y0 - h
	add si, cx
    push si     ;x2 -> x0 + b
	push bx 	;y2 -> y0
	call line
	jmp sair1
	
preenche_triangulo:
	pop di		;Recebe b
	mov cx, di	;Variável loop
	;Preenche Losango
losango1:
	add si, 1	
	push si		;x1 -> x0 + 1*i
	push bx		;y1 -> y0
	add ax, 1	
	push ax		;x2 -> x0 + b/2 + 1*i
	push dx		;y2 -> y0 + h
	call line
	loop losango1
	
	mov cx, di	;Variável loop
	mov byte[cor], preto
	;Linha Direita
	add si, cx
	push si 	;x1 -> x0 + b + b
	push bx 	;y1 -> y0
	push ax		;x2 -> x0 + b/2 + b
	push dx		;y2 -> y0 + h
	call line
	;Preenche Losango da Volta
	sub cx, 1
losango2:
	sub si, 1	
	push si		;x1 -> x0 + 2*b - 1*i
	push bx		;y1 -> y0
	sub ax, 1	
	push ax		;x2 -> x0 + 3*b/2 - 1*i
	push dx		;y2 -> y0 + h
	call line
	loop losango2
	mov ax, di	
	mov byte[cor], branco_intenso

sair1:
	popa
	ret

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