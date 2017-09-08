;-----------------------------------------------------------------------
;----------------------EXERCÍCIO DE PROGRAMAÇÃO-------------------------
;-----------------------------------------------------------------------
; 
; 							DEL - CT - UFES
; 				Sistemas Embarcados I - ELE 8575 - 2017/1
; 				Autor: Vitor Henrique de Moraes Escalfoni
; 								Turma: 06 
;
;-----------------------------------------------------------------------
;----------------------INICIALIZAÇÃO DO PROGRAMA------------------------
;-----------------------------------------------------------------------
segment code
..start:
	  
mov ax,data
mov ds,ax
mov ax,stack
mov ss,ax
mov sp,stacktop

;salvar modo corrente de video (vendo como está o modo de video da maquina)
mov ah,0Fh
int 10h
mov [modo_anterior],al   
;alterar modo de video para gráfico 640x480 16 cores
mov al,12h
mov ah,0
int 10h

;Inicialização da interface gráfica do programa
mov byte[cor],branco_intenso ; Inicialmente, tudo branco


call cria_divisorias
call escreve_mensagens
call arquivo
call processa_dados
jmp sair

;-----------------------------------------------------------------------
;-------------------------ABERTURA DE ARQUIVOS--------------------------
;-----------------------------------------------------------------------
arquivo:
	; Salva contexto
	push ax     
	push bx
	push cx
	push dx
	
	; Abrir arquivo somente para leitura
	mov ah,3dh        
	mov al,00h
	mov dx,file_name
	int 21h
	; file_handle grava um 'endereco' pra poder usar o arquivo
	mov [file_handle],ax  
	; Verifica se o arquivo foi aberto corretamente
	jnc leitura_arquivo
	mov	bx,msg_erro1		;mensagem de erro ao abrir
	mov	dh,28				;linha 0-29
	mov	dl,0				;coluna 0-79
	mov	byte[cor],vermelho
	call imprime
	jmp sair_arquivo

leitura_arquivo:
	;lendo primeira linha, capacidade do tanque
	mov	bx,[file_handle]	;em bx o file handle. ax foi entregue pelo int 21h anterior
	mov	dx,dados			;em dx onde vai escrever os dados
	mov	cx,2243				;em cx o numero de bytes a serem lidos no arquivo
	mov	ah,3fh				;comando pra int 21h ler arquivo
	int	21h
	
	; Verifica se o arquivo foi lido corretamente
	jnc fechar_arquivo
	; Caso contrário, envia mensagem de erro e sai do arquivo
	mov	bx,msg_erro2		;mensagem de erro ao sair
	mov	dh,28				;linha 0-29
	mov	dl,0				;coluna 0-79
	mov	byte[cor],vermelho
	call imprime

fechar_arquivo:
	mov	bx,[file_handle]	;em bx o file handle
	mov	ah,3eh				;comando da int 21h pra fechar arquivos
	int	21h
	jnc	sair_arquivo		;se não houve erro ao sair, não exibe mensagem e sai do programa
	
	mov	bx,msg_erro3		;mensagem de erro ao sair
	mov	dh,28				;linha 0-29
	mov	dl,0				;coluna 0-79
	mov	byte[cor],vermelho
	call imprime

sair_arquivo:
	pop   dx
	pop   cx
	pop   bx    
	pop   ax
	ret

;-----------------------------------------------------------------------
;-----------------------PROCESSAMENTO DE DADOS--------------------------
;-----------------------------------------------------------------------
processa_dados:
	; Limpa varíaveis utilizadas no processamento
	xor bx, bx
	xor cx, cx
	xor dx, dx
	xor si, si
	xor di, di
	
	; Primeira Linha -> Capacidade do tanque
	mov ax, 99				; Valor Máximo de 99 lts
	call captura_dado
	mov [capacidade], ax	; Armazena Capacidade do Tanque
	inc byte[leituras]
	; Restante das Linhas -> Pulsos de roda, rotação do motor, turbina combustível e temperatura
leitura_linhas:
	; Pulsos da roda	
	mov ax, 12000			; Valor Máximo de 12000 pulsos 
	call captura_dado
	push ax
	; Pulsos rotação
	inc si
	mov ax, 65000			; Valor Máximo de 65000 pulsos
	call captura_dado
	push ax
	; Pulsos Turbina
	inc si
	mov ax, 3000			; Valor Máximo de 3000 pulsos
	call captura_dado
	push ax
	; Temperatura
	inc si
	mov ax, 200				; Valor Máximo de 200ºC
	call captura_dado
	push ax

	; Esta leitura e processamento deve durar 1 segundo
	call calcula_valor_final
	call atualiza_display
	call delay
    call testatecla
	add di, 6
	cmp di, 90
	je reinicia_buffer
	cmp byte[leituras], 15	; Numero máximo de leituras no buffer
	jge leitura_linhas
	inc byte[leituras]		; Incremeta as leituras, para cálculo inicial adequado
	jmp leitura_linhas		;de velocidade média

reinicia_buffer:
	xor di, di
    jmp leitura_linhas

;-----------------------------------------------------------------------
;-----Calculo dos valores finais de cada variavel exibida no visor------
;-----------------------------------------------------------------------
; Recebe as leituras do arquivo na pilha e chama, ordenadamente, as
;funções para cálculo dos valores finais
;-----------------------------------------------------------------------
calcula_valor_final:
	push bp
	mov	bp, sp

	; Temperatura
	mov ax,[bp+4]
	mov byte[temp_inst], al
	
	; Pulsos do Sensor do Combustível
	mov ax,[bp+6]
	call calcula_litros_consumidos
	
	; Pulsos de Rotação do Motor
	mov ax,[bp+8]
	call calcula_rotacao_inst

	; Pulsos de Roda
	mov ax,[bp+10]
	call calcula_quilometragem
	call calcula_odometria_parcial
	call calcula_velocidade_inst

	call calcula_velocidade_media
	call calcula_litros_inst
	call calcula_autonomia

	pop	bp
	ret 8
;-----------------------------------------------------------------------
;-------------Funções para cálculo de valores finais--------------------
;-----------------------------------------------------------------------
calcula_quilometragem:
	push ax
	push bx
	push dx

	xor bh, bh
	xor dx, dx
	mov bl, 100					; Pulso*(56/100) -> Cada pulso corresponde a 0,56 cm andados pelo carro
	div	bl 						; AX/BL -> Q = AL, R = AH
	mov ah, 56					
	mul ah						; AL*AH = AX
	mov bl, 10
	div bx						; (DS:AX)/BX -> Q = AX, R = DX
	mov word[buffer_dados+di+2], ax
	add ax, word[quilometragem_m]
	xor bx, bx
	soma_quilometragem:
		cmp ax, 10000			; Verifica se andou 1000 m
		jl sair2
		add bl, 1				; Soma 1 km ao mostrador
		sub ax, 10000
		jg soma_quilometragem
	sair2:
		add word[quilometragem], bx
		mov word[quilometragem_m], ax
	
	pop dx
	pop bx
	pop ax
	ret

calcula_odometria_parcial:
	push ax
	push bx
	push dx

	xor bh, bh
	xor dx, dx
	mov bl, 100					; Pulso*(56/100) -> Cada pulso corresponde a 0,56 cm andados pelo carro
	div	bl 						; AX/BL -> Q = AL, R = AH
	mov ah, 56					
	mul ah						; AL*AH = AX
	mov bl, 10
	div bx						; (DS:AX)/BL -> Q = AX, R = DX
	add ax, word[odometro_m]
	xor bx, bx
	soma_odometro:
		cmp ax, 10000			; Verifica se andou 1000 m
		jl sair3
		add bl, 1				; Soma 1 km ao mostrador
		sub ax, 10000
		jg soma_odometro
	sair3:
		add word[odometro], bx
		mov word[odometro_m], ax
	
	pop dx
	pop bx
	pop ax
	ret

calcula_litros_consumidos:
	push ax
	push bx

	; Cada pulso corresponde a 0,1 ml de combustível utilizado						
	mov word[buffer_dados+di+4], ax
	add ax, word[litros_con_ml]
	cmp ax, 10000				; Verifica se gastou 1000 ml
	jl sair4
	add word[litros_con], 1		; Soma 1 l ao mostrador
	sub ax, 10000
	
	sair4:
		mov word[litros_con_ml], ax
	pop bx
	pop ax
	ret

calcula_rotacao_inst:
	push ax
	push bx
	push dx

	xor dx, dx
	mov bx, 8 					; Pulso/8 -> Cada 8 pulsos de rotação do motor correspondem a 1 RPM 				
	div bx						; DX:AX/BX -> Q = AX, R = DX
	mov word[rotacao_inst], ax

	pop dx
	pop bx
	pop ax
	ret

calcula_velocidade_inst:
	push ax
	push bx
	push dx

	xor bh, bh
	xor dx, dx
	mov bl, 100		; Pulso*(56/1000) -> Cada pulso corresponde a 0,56 cm andados pelo carro
	div	bl 			; AX/BL -> Q = AL, R = AH
	mov ah, 56					
	mul ah			; AL*AH = AX
	mov bl, 10
	div bx			; (DS:AX)/BX -> Q = AX, R = DX
	xor dx, dx
	mov bx, 36		; 36/100 -> Conversão m/s para km/h
	mul bx			; AX*BX = DS:AX
	mov bx, 100		; Divisor
	div bx			; (DS:AX)/BX -> Q = AX, R = DX

	mov byte[velocidade_inst], al
	xor ax, ax
	mov al, byte[velocidade_inst]
	mov dl, 65
	mov dh, 18
	call imprime_decimal
	mov word[buffer_dados+di], ax
	
	pop dx
	pop bx
	pop ax
	ret

calcula_velocidade_media:
	push ax
	push bx
	push cx
	push dx
	push di

	xor ax, ax
	xor dx, dx
	mov cx, 15
	soma_buffer_velocidade:
		mov bx, word[buffer_dados+di]
		add ax, bx
		add di, 6
		cmp di, 90
		jl segue1
		xor di, di
		segue1:
		loop soma_buffer_velocidade
	
	xor bh, bh
	mov bl, byte[leituras]			; Velocidade(m/s)/leituras -> obtenção da média
	div bx							; (DS:AX)/BX -> Q = AX, R = DX

	mov word[velocidade_med], ax

	pop di
	pop dx
	pop cx
	pop bx
	pop ax
	ret

calcula_litros_inst:
	push ax
	push bx
	push cx
	push dx

	xor dx, dx
	mov al, byte[capacidade]
	mov bx, word[litros_con]
	sub al, bl					; Combustível Restante
	mov bl, 10					; Será multiplicado por 10 para adequar ao mostrador
	mul bl						; AL*BL = AX
	mov cx, ax					
	mov ax, word[litros_con_ml]	 
	mov bx, 1000
	div bx
	sub cx, ax					; Precisão de 1 ponto decimal para exibição
	mov word[litros_inst], cx

	pop dx
	pop cx
	pop bx
	pop ax
	ret

calcula_autonomia:
	push ax
	push bx
	push cx
	push dx
	push di

	xor ax, ax
	xor dx, dx
	mov cx, 15
	soma_buffer:
		mov bx, word[buffer_dados+di+2] ; Buffer Quilometragem
		add ax, bx
		mov bx, word[buffer_dados+di+4] ; Buffer Litros Consumidos
		add dx, bx
		add di, 6
		cmp di, 90
		jl segue2
		xor di, di
		segue2:
		loop soma_buffer

	mov bx, dx					; Autonomia = (litros_inst/10)*buffer_quilometragem/buffer_litros_con
	xor dx, dx					; Limpa DX para a divisão
	div bx						; (DS:AX)/BX -> Q = AX, R = DX
	mov word[desempenho], ax	; Desempenho = buffer_quilometragem/buffer_litros_con
	push ax						
	mov ax, dx					; Multiplicaremos o resto da divisão por 10
	mov cl, 10					; Para obter a primeira casa decimal, aumentando a precisão
	xor dx, dx					; Limpa DX para a multiplicação
	mul cl						; AX*CL -> AX
	div bx						; (DS:AX)/BX -> Q = AX, R = DX
	mov word[desempenho_m], ax
	mov bx, ax	
	pop ax
	mul cl						; Multiplicamos por 10 para somar com o decimal anterior
	add ax, bx					; De forma a aumentar a precisão
	xor dx, dx					; Limpa DX para a multiplicação
	mov bx, word[litros_inst]
	mul bx						; BX*AX -> (DS:AX)
	xor dx, dx					; Limpa DX para a divisão
	mov bx, 100					; Divide por cem para ajustar as multiplicações anteriores
	div bx						; (DS:AX)/BX -> Q = AX, R = DX
	mov word[autonomia], ax
	
	pop di
	pop dx
	pop cx
	pop bx
	pop ax
	ret
;-----------------------------------------------------------------------
; A partir dos valores armazenados na memória, atualiza cada mostrador no
;display.
;-----------------------------------------------------------------------
atualiza_display:
	push ax
	push bx
	push cx
	push dx
	push si
	push di

	;atualiza mostrador temperatura
	xor ah, ah
	mov al, byte[temp_inst]
	mov bl, 20
	div bl					; AX/BL -> Q = AL, R = AH
	mov di,	1				; Indicando Temperatura
	add al, 1				; Separando as barras como 0-9,10-19,...
	mov byte[barra_final+di], al
	mov si, 336				; x0
	mov cx,	28				; l
	mov dx,	10				; h
	call atualiza_mostrador
	
	;atualiza mostrador gasolina disponivel
	mov ax, word[litros_inst]
	mov bl, byte[capacidade]
	div bl					; AX/BL -> Q = AL, R = AH
	xor di, di				; Indicando Gasolina
	mov byte[barra_final+di], al
	mov si, 276				; x0
	mov cx,	28				; l
	mov dx,	10				; h	
	call atualiza_mostrador
	

	mov ax, word[quilometragem]
	mov dl,	51
	mov dh, 20
	call imprime_decimal
	;imprime quilometragem(10^-1 km)
	xor dx,dx
	mov ax, word[quilometragem_m]
	mov bx, 1000
	div bx
	add al, 30h
	mov dh, 20
	mov dl, 53
	call imprime_caractere

	;imprime odometria
	mov ax, word[odometro]
	mov dl,	51
	mov dh, 22
	call imprime_decimal
	;imprime odometro(10^-1 km)
	xor dx, dx
	mov ax, word[odometro_m]
	mov bx, 1000
	div bx
	add al, 30h
	mov dh, 22
	mov dl, 53	
	call imprime_caractere

	;imprime autonomia
	mov ax, word[autonomia]
	mov dl,	53
	mov dh, 24
	call imprime_decimal

	;imprime velocidade média
	mov ax, word[velocidade_med]
	mov dl,	52
	mov dh, 26
	call imprime_decimal

	;imprime litros consumidos
	mov ax, word[litros_con]
	mov dl,	51
	mov dh, 28
	call imprime_decimal
	;imprime litros consumidos(10^-1 lts)
	xor dx, dx
	mov ax, word[litros_con_ml]
	mov bx, 1000
	div bx
	add al, 30h
	mov dh, 28
	mov dl, 53
	call imprime_caractere

	;imprime desempenho médio
	mov ax, word[desempenho]
	mov dl,	68
	mov dh, 27
	call imprime_decimal
	;imprime desempenho médio(10^-1 km)
	mov al, byte[desempenho_m]
	add al, 30h
	mov dh, 27
	mov dl, 70
	call imprime_caractere

	;atualiza velocimetro
	;mov al, byte[velocidade_inst]
	;mov dl, 65
	;mov dh, 18
	;call imprime_decimal

	;atualiza mostrador rpm
	mov ax, word[rotacao_inst]
	mov dl,	18
	mov dh, 18
	call imprime_decimal
		

	;sair
	pop di
	pop si
	pop dx
	pop cx
	pop bx
	pop ax
	ret
;-----------------------------------------------------------------------
; Função que capturas dados na variável da memória na qual foram armazenadas
;as informações obtidas do arquivo "leitura.txt". Analisa byte por byte e
;retorna a leitura convertida em decimal.
;-----------------------------------------------------------------------
captura_dado:
	mov bh,[dados+si]

	cmp bh, 2ch	; ',' (vírgula) em ASCII
	jne compara_final
	jmp asciiparadecimal

	compara_final:
	cmp bh, 0dh	; <cr> (carrier r) indicando fim da linha
	jne segue
	add si, 2
	mov bh, [dados+si]
	cmp bh, 46h	;'F' indica final do arquivo
	jne asciiparadecimal
    mov si, 5
	jmp asciiparadecimal

	segue:
	; Número decimal 0- 9 = (Número em ASCII - 30h)
	sub bh, 30h ; O valor em ascii do byte lido é passado para bh
	
	mov bl, ch	; Milhar vira Dezena de Milhar
	mov ch, cl 	; Centena vira Milhar
	mov cl, dh 	; Dezena vira Centena
	mov dh, dl 	; Unidade vira Dezena
	mov dl, bh 	; Unidade recebe valor lido
	
	inc si
	jmp captura_dado

;-----------------------------------------------------------------------
; Função que gera um número juntando os digitos, mutiplicando-os por 
; seus respectivos valores de base e somando-os 
;-----------------------------------------------------------------------
asciiparadecimal:
	; BX(decimal) <- 10000*BL(dezena de milhar) + 1000*CH(milhar) + 100*CL(centena) + 10*DH(dezena) + DL(unidade)
	push ax		; Guarda o valor máximo da leitura para comparação com decimal ao final do processo

	xor bh, bh 	; BL -> Dezena de Milhar
	mov ax, 10000
	push dx
	mul bx 		; Multiplica AX por BX. Conteudo armazenado em DX:AX
	pop dx
	push ax

	mov bl, ch 	; Milhar
	mov ax, 1000
	push dx
	mul bx 		; Multiplica AX por BX. Conteudo armazenado em DX:AX
	pop dx
    pop bx
	add bx, ax 

	mov al, cl	; Centena
	mov ah, 100
	mul ah		; Multiplica AL por AH. Conteudo armazenado em AX 
	add bx, ax 
	
	mov al, dh	; Dezena
	mov ah, 10
	mul ah
	add bx, ax
		
	add bl, dl 	; Unidade

	pop ax 		; AX recebe o valor máximo da leitura

	;cmp bx, ax
	;jge sair1	; Se BX >= AX finaliza conversão, e retorna AX 
	mov ax, bx 	; Mudança feita pois AX é usado pelas funções MUL e DIV nos proximos procedimentos
	
	sair1:	
	xor bx, bx ; Após formado número, limpo os dígitos para não sujar uma próxima leitura
	xor cx, cx
	xor dx, dx

	ret

;-----------------------------------------------------------------------
;-------------------FUNÇÕES DE INTERFACE GRÁFICA------------------------
;-----------------------------------------------------------------------
cria_divisorias:
	push ax
	push bx
	push cx
	push dx
	
	; Borda 
	mov ax, 0 		; x0
	mov bx, 0		; y0
	mov cx, 639		; l
	mov dx, 479		; h
	call retangulo	
	
	; Identificação 
	mov ax, 40 		; x0 	
	mov bx, 430		; y0
	mov cx, 560		; l
	mov dx, 40		; h
	call retangulo

	; Desempenho Médio
	mov ax, 500		; x0
	mov bx, 12		; y0
	mov cx, 100		; l
	mov dx, 86		; h
	call retangulo

	; Quilometragem
	mov ax, 170		; x0
	mov bx, 140		; y0
	mov cx, 300		; l
	mov dx, 26		; h
	call retangulo
	
	; Odômetro Parcial
	mov bx, 108		; y0
	call retangulo
	
	; Autonomia
	mov bx, 76		; y0
	call retangulo
	
	; Velocidade Média
	mov bx, 44		; y0
	call retangulo
	
	; Litros Consumidos
	mov bx, 12		; y0
	call retangulo
	
	; Velocimetro
	mov ax, 507 	; pos x central	
	push ax
	mov ax, 295 	; pos y	central
	push ax
	mov	 ax, 130 	; raio
	push ax
	call circle
	mov ax, 507
	push ax
	mov ax, 295
	push ax
	mov ax, 10
	push ax
	call circle

	; RPM
	mov ax, 132 	; pos x	central
	push ax
	mov ax, 295 	; pos y	central
	push ax
	mov	ax, 132 	; raio
	push ax
	call circle 	;
	mov ax, 132
	push ax
	mov ax, 295
	push ax
	mov ax, 10
	push ax
	call circle

	; Gasolina
	mov ax, 270		; x0
	mov bx, 225		; y0
	mov cx, 40		; l
	mov dx, 167		; h
	call retangulo

	; Temperatura
	mov ax, 330		; x0
	call retangulo

	; Divisórias Gasolina
	mov byte[cor], azul
	mov ax, 275		; x0
	mov bx, 230		; y0
	mov dx, 13		; h
	mov cx, 10		; numero de divisórias
	divisorias_gasolina:
		push cx
		mov cx, 30		; l
		call retangulo
		pop cx
		add bx, 16
		loop divisorias_gasolina
	
	; Divisórias Temperatura
	mov ax, 335		; x0
	mov bx, 230		; y0
	mov dx, 13		; h
	mov cx, 10		; número de divisórias
	divisorias_temperatura:
		push cx
		mov cx, 30		; l
		call retangulo
		pop cx
		add bx, 16
		loop divisorias_temperatura	

	mov byte[cor], branco_intenso
	
	pop dx
	pop cx
	pop bx
	pop ax
	
	ret
;-----------------------------------------------------------------------
; Função responsável por escrever as mensagens em tela
;-----------------------------------------------------------------------
escreve_mensagens:
	push ax
	push bx
	push cx
	push dx
	
	; Matéria
	mov bx,msg1				;mensagem exibida
	mov dh,1           		;linha 0-29
	mov dl,24     			;coluna 0-79
	call imprime

	; Nome
	mov bx,msg2 			;mensagem exibida
	mov dh,2           		;linha 0-29
	mov dl,22     			;coluna 0-79
	call imprime

	; Quilometragem
	mov bx,msg3     		;mensagem exibida
	mov dh,20          		;linha 0-29
	mov dl,22     			;coluna 0-79
	call imprime
	; Unidade
	mov bx,unit1     		;mensagem exibida
	mov dl,56     			;coluna 0-79
	call imprime
	; Digito Decimal
	mov al,'.'     			;mensagem exibida
	mov dl,52     			;coluna 0-79
	call imprime_caractere

	; Odometro Parcial
	mov bx,msg4     		;mensagem exibida
	mov dh,22          		;linha 0-29
	mov dl,22     			;coluna 0-79
	call imprime
	; Unidade
	mov bx,unit1     		;mensagem exibida
	mov dl,56     			;coluna 0-79
	call imprime
	; Digito Decimal
	mov al,'.'     			;mensagem exibida
	mov dl,52     			;coluna 0-79
	call imprime_caractere

	; Autonomia 
	mov bx,msg5     		;mensagem exibida
	mov dh,24          		;linha 0-29
	mov dl,22     			;coluna 0-79
	call imprime
	; Unidade
	mov bx,unit1     		;mensagem exibida
	mov dl,56     			;coluna 0-79
	call imprime

	; Velocidade Media
	mov bx,msg6     		;mensagem exibida
	mov dh,26          		;linha 0-29
	mov dl,22     			;coluna 0-79
	call imprime
	; Unidade
	mov bx,unit2     		;mensagem exibida
	mov dl,54     			;coluna 0-79
	call imprime

	; Litros Consumidos
	mov bx,msg7     		;mensagem exibida
	mov dh,28          		;linha 0-29
	mov dl,22     			;coluna 0-79
	call imprime
	; Unidade
	mov bx,unit3     		;mensagem exibida
	mov dl,55     			;coluna 0-79
	call imprime
	; Digito Decimal
	mov al,'.'     			;mensagem exibida
	mov dl,52     			;coluna 0-79
	call imprime_caractere

	; Desempenho Médio
	mov bx,msg8     		;mensagem exibida
	mov dh,24          		;linha 0-29
	mov dl,64     			;coluna 0-79
	call imprime
	mov bx,msg9     		;mensagem exibida
	mov dh,25          		;linha 0-29
	mov dl,65     			;coluna 0-79
	call imprime
	; Unidade
	mov bx,unit4     		;mensagem exibida
	mov dh,28 				;linha 0-29
	mov dl,66     			;coluna 0-79
	call imprime
	; Digito Decimal
	mov al,'.'     			;mensagem exibida
	mov dh,27				;linha 0-29
	mov dl,69     			;coluna 0-79
	call imprime_caractere

	; Gasolina
	mov bx,msg10     		;mensagem exibida
	mov dh,16          		;linha 0-29
	mov dl,35     			;coluna 0-79
	call imprime

	;Temperatura
	mov bx,msg11     		;mensagem exibida
	mov dh,16          		;linha 0-29
	mov dl,42     			;coluna 0-79
	call imprime

	;Rotação Motor
	mov bx,unit5     		;mensagem exibida
	mov dh,16          		;linha 0-29
	mov dl,15     			;coluna 0-79
	call imprime
	mov bx,unit6     		;mensagem exibida
	mov dh,17          		;linha 0-29
	mov dl,14     			;coluna 0-79
	call imprime
	
	;Numerais Rotação Motor
	mov al,'0'     			;mensagem exibida
	mov dh, 14          	;linha 0-29
	mov dl, 5     			;coluna 0-79
	call imprime_caractere
	mov al,'1'     			;mensagem exibida
	mov dh, 11          	;linha 0-29
	mov dl, 3     			;coluna 0-79
	call imprime_caractere
	mov al,'2'     			;mensagem exibida
	mov dh, 8         		;linha 0-29
	mov dl, 5     			;coluna 0-79
	call imprime_caractere
	mov al,'3'     			;mensagem exibida
	mov dh, 6          		;linha 0-29
	mov dl, 9     			;coluna 0-79
	call imprime_caractere
	mov al,'4'     			;mensagem exibida
	mov dh, 5          		;linha 0-29
	mov dl, 16     			;coluna 0-79
	call imprime_caractere
	mov al,'5'     			;mensagem exibida
	mov dh, 6          		;linha 0-29
	mov dl, 23     			;coluna 0-79
	call imprime_caractere
	mov byte[cor], vermelho
	mov al,'6'     			;mensagem exibida
	mov dh, 8          		;linha 0-29
	mov dl, 27     			;coluna 0-79
	call imprime_caractere
	mov al,'7'     			;mensagem exibida
	mov dh, 11          	;linha 0-29
	mov dl, 29     			;coluna 0-79
	call imprime_caractere
	mov al,'8'     			;mensagem exibida
	mov dh, 14          	;linha 0-29
	mov dl, 27     			;coluna 0-79
	call imprime_caractere
	mov byte[cor], branco_intenso

	;Velocimetro
	mov bx,unit2     		;mensagem exibida
	mov dh,16          		;linha 0-29
	mov dl,61     			;coluna 0-79
	call imprime
	
	;Numerais Velocimetro
	mov al, '0'     		;mensagem exibida
	mov dh, 16          	;linha 0-29
	mov dl, 54     			;coluna 0-79
	call imprime_caractere
	mov al, 20     			;mensagem exibida
	mov dh, 14				;linha 0-29
	mov dl, 52				;coluna 0-79
	call imprime_decimal
	mov al, 40     			;mensagem exibida
	mov dh, 12				;linha 0-29
	mov dl, 51				;coluna 0-79
	call imprime_decimal
	mov al, 60     			;mensagem exibida
	mov dh, 10				;linha 0-29
	mov dl, 51				;coluna 0-79
	call imprime_decimal
	mov al, 80     			;mensagem exibida
	mov dh, 8				;linha 0-29
	mov dl, 52				;coluna 0-79
	call imprime_decimal
	mov al, 100     		;mensagem exibida
	mov dh, 6				;linha 0-29
	mov dl, 55				;coluna 0-79
	call imprime_decimal
	mov al, 120     		;mensagem exibida
	mov dh, 5				;linha 0-29
	mov dl, 59				;coluna 0-79
	call imprime_decimal
	mov al, 140     		;mensagem exibida
	mov dh, 4				;linha 0-29
	mov dl, 64				;coluna 0-79
	call imprime_decimal
	mov al, 160     		;mensagem exibida
	mov dh, 5				;linha 0-29
	mov dl, 69				;coluna 0-79
	call imprime_decimal
	mov al, 180     		;mensagem exibida
	mov dh, 6				;linha 0-29
	mov dl, 72				;coluna 0-79
	call imprime_decimal
	mov al, 200     		;mensagem exibida
	mov dh, 8				;linha 0-29
	mov dl, 75				;coluna 0-79
	call imprime_decimal
	mov al, 220     		;mensagem exibida
	mov dh, 10				;linha 0-29
	mov dl, 76				;coluna 0-79
	call imprime_decimal
	mov byte[cor], vermelho
	mov al, 240				;mensagem exibida
	mov dh, 12				;linha 0-29
	mov dl, 76				;coluna 0-79
	call imprime_decimal
	mov ax, 260 			;mensagem exibida
	mov dh, 14				;linha 0-29
	mov dl, 75				;coluna 0-79
	call imprime_decimal
	mov ax, 280				;mensagem exibida
	mov dh, 16				;linha 0-29
	mov dl, 73				;coluna 0-79
	call imprime_decimal
	mov byte[cor], branco_intenso

	
	;Botão Aumenta Delay
	mov bx,msg12     		;mensagem exibida
	mov dh,25          		;linha 0-29
	mov dl,1     			;coluna 0-79
	call imprime

	;Botão Diminui Delay
	mov bx,msg13     		;mensagem exibida
	mov dh,26          		;linha 0-29
	mov dl,1     			;coluna 0-79
	call imprime

	;Botão Zerar Odometro
	mov bx,msg14     		;mensagem exibida
	mov dh,27          		;linha 0-29
	mov dl,1     			;coluna 0-79
	call imprime

	;Botão Sair
	mov bx,msg15     		;mensagem exibida
	mov dh,28          		;linha 0-29
	mov dl,1     			;coluna 0-79
	call imprime

	pop dx
	pop cx
	pop bx
	pop ax

	ret
	
;-----------------------------------------------------------------------
;-------------------------FUNÇÕES DE DESENHO----------------------------
;-----------------------------------------------------------------------

;-----------------------------------------------------------------------	
; Função que plota um ponto
;-----------------------------------------------------------------------
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

;-----------------------------------------------------------------------
; Função que desenha linhas
;-----------------------------------------------------------------------
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

;-----------------------------------------------------------------------
; Função Retangulo (x0, y0, h, l)
; ax 	-> x0 : Posicao X do ponto inferior esquerdo
; bx 	-> y0 : Posicao Y do ponto inferior esquerdo 
; cx 	-> l  : Lado do retangulo
; dx 	-> h  : Altura do retangulo
; [cor] -> cor do lados	
;-----------------------------------------------------------------------
retangulo:
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
	pop si	
	ret

;--------------------------------------------------------------------
; Função Retangulo Cheio
; ax 	-> x0 : Posicao X do ponto inferior esquerdo
; bx 	-> y0 : Posicao Y do ponto inferior esquerdo 
; cx 	-> l  : Lado do retangulo
; dx 	-> h  : Altura do retangulo
; [cor] -> cor do lados
;--------------------------------------------------------------------
retangulo_cheio:
	push cx
	push dx
	push si
	push di


	call retangulo

	mov si, dx; si recebe h
	mov dx, cx; dx recebe l
	mov cx, si; cx recebe h

	preenche:
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
		dec cx
		loop preenche

	pop di
	pop si
	pop dx
	pop cx
	ret

;--------------------------------------------------------------------
; Função Circle
; [bp+8] -> xc : Posição X do centro (xc+r<639) e (xc-r>0)
; [bp+6] -> yc : Posição Y do centro (yc+r<479) e (yc-r>0)
; [bp+4] -> r  : Raio  
; [cor]  -> cor da circunferencia
;--------------------------------------------------------------------
circle:
	push 	bp
	mov	 	bp,sp
	pushf                        ;coloca os flags na pilha
	push 	ax
	push 	bx
	push	cx
	push	dx
	push	si
	push	di
	
	mov		ax,[bp+8]    ; resgata xc
	mov		bx,[bp+6]    ; resgata yc
	mov		cx,[bp+4]    ; resgata r
	
	mov 	dx,bx	
	add		dx,cx       ;ponto extremo superior
	push    ax			
	push	dx
	call plot_xy
	
	mov		dx,bx
	sub		dx,cx       ;ponto extremo inferior
	push    ax			
	push	dx
	call plot_xy
	
	mov 	dx,ax	
	add		dx,cx       ;ponto extremo direita
	push    dx			
	push	bx
	call plot_xy
	
	mov		dx,ax
	sub		dx,cx       ;ponto extremo esquerda
	push    dx			
	push	bx
	call plot_xy
		
	mov		di,cx
	sub		di,1	 ;di=r-1
	mov		dx,0  	;dx será a variável x. cx é a variavel y
	
	;aqui em cima a lógica foi invertida, 1-r => r-1
	;e as comparações passaram a ser jl => jg, assim garante 
	;valores positivos para d

	stay:				;loop
		mov		si,di
		cmp		si,0
		jg		inf       ;caso d for menor que 0, seleciona pixel superior (não  salta)
		mov		si,dx		;o jl é importante porque trata-se de conta com sinal
		sal		si,1		;multiplica por doi (shift arithmetic left)
		add		si,3
		add		di,si     ;nesse ponto d=d+2*dx+3
		inc		dx		;incrementa dx
		jmp		plotar
	inf:	
		mov		si,dx
		sub		si,cx  		;faz x - y (dx-cx), e salva em di 
		sal		si,1
		add		si,5
		add		di,si		;nesse ponto d=d+2*(dx-cx)+5
		inc		dx		;incrementa x (dx)
		dec		cx		;decrementa y (cx)
	
	plotar:	
		mov		si,dx
		add		si,ax
		push    si			;coloca a abcisa x+xc na pilha
		mov		si,cx
		add		si,bx
		push    si			;coloca a ordenada y+yc na pilha
		call plot_xy		;toma conta do segundo octante
		mov		si,ax
		add		si,dx
		push    si			;coloca a abcisa xc+x na pilha
		mov		si,bx
		sub		si,cx
		push    si			;coloca a ordenada yc-y na pilha
		call plot_xy		;toma conta do sétimo octante
		mov		si,ax
		add		si,cx
		push    si			;coloca a abcisa xc+y na pilha
		mov		si,bx
		add		si,dx
		push    si			;coloca a ordenada yc+x na pilha
		call plot_xy		;toma conta do segundo octante
		mov		si,ax
		add		si,cx
		push    si			;coloca a abcisa xc+y na pilha
		mov		si,bx
		sub		si,dx
		push    si			;coloca a ordenada yc-x na pilha
		call plot_xy		;toma conta do oitavo octante
		mov		si,ax
		sub		si,dx
		push    si			;coloca a abcisa xc-x na pilha
		mov		si,bx
		add		si,cx
		push    si			;coloca a ordenada yc+y na pilha
		call plot_xy		;toma conta do terceiro octante
		mov		si,ax
		sub		si,dx
		push    si			;coloca a abcisa xc-x na pilha
		mov		si,bx
		sub		si,cx
		push    si			;coloca a ordenada yc-y na pilha
		call plot_xy		;toma conta do sexto octante
		mov		si,ax
		sub		si,cx
		push    si			;coloca a abcisa xc-y na pilha
		mov		si,bx
		sub		si,dx
		push    si			;coloca a ordenada yc-x na pilha
		call plot_xy		;toma conta do quinto octante
		mov		si,ax
		sub		si,cx
		push    si			;coloca a abcisa xc-y na pilha
		mov		si,bx
		add		si,dx
		push    si			;coloca a ordenada yc-x na pilha
		call plot_xy		;toma conta do quarto octante
	
		cmp		cx,dx
		jb		fim_circle  ;se cx (y) está abaixo de dx (x), termina     
		jmp		stay		;se cx (y) está acima de dx (x), continua no loop
	
	
	fim_circle:
		pop		di
		pop		si
		pop		dx
		pop		cx
		pop		bx
		pop		ax
		popf
		pop		bp
		ret		6

;-----------------------------------------------------------------------
;------------------------FUNÇÕES DE ESCRITA EM TELA---------------------
;-----------------------------------------------------------------------

;-----------------------------------------------------------------------
;------------------------Função Imprime Caractere-----------------------
; 
; al = caracter em ASCII
; dh = linha (0-29)
; dl = coluna  (0-79)
;-----------------------------------------------------------------------
imprime_caractere:
	pushf
	push 		ax
	push 		bx
	push		cx
	
	; Posiciona cursor:
	mov     	ah,2
	mov     	bh,0
	int     	10h
	
	; Caractere escrito na posição do cursor:
    mov     	ah,9
    mov     	bh,0
    mov     	cx,1
	mov     	bl,[cor]
    int     	10h
	
	pop		cx
	pop		bx
	pop		ax
	popf
	ret


;-----------------------------------------------------------------------
;-----------------------Função Imprimir Mensagens-----------------------
;
; bx = mensagem (Terminada com '$'. Não precisa falar o número de caracteres)
; dh = linha 0-29
; dl = coluna 0-79
; byte[cor] = cor do caracter
;----------------------------------------------------------------------
imprime:
	pushf
	push 		ax
	push 		bx
	push		cx
		
	mov		cx,300				;em cx um valor alto para evitar loop infinito

loop_imprime:
	mov		al,[bx]
	cmp		al,'$'
	je		sai_imprime			;se al = '$', então acabou a string, sai da função
	call	imprime_caractere
	inc bx
	inc dl
	loop	loop_imprime
		
sai_imprime:
	pop		cx
	pop		bx
	pop		ax
	popf
	ret

;----------------------------------------------------------------------
;-----------------------Função Imprimir Decimais-----------------------
; 
; Recebe um numeral, converte para ASCII e o imprime
; ax = mensagem em decimal ; recebe o numero HEX e converte em uma string de ASCII  
; cx = numero de caracteres
; dh = linha 0-29
; dl = coluna 0-79
; byte[cor] = cor do caracter
;----------------------------------------------------------------------
imprime_decimal:
    push ax ; salva os registradores que serão alterados
	push bx
	push cx	
	push dx
  	push di

	xor cx, cx
    mov bx, dx
	mov di, 10   
	loop_conversao: 
	xor dx, dx
	div di		; ax<-q(ax/bx)  dx<-r(ax/bx)
	add dl, 30h ; dl<-dl+30h
	push dx
	inc cl	
	cmp ax, 9
	jg loop_conversao    ; ax>9
		     
	mov dx, bx
	sub dl, cl	
	add al, 30h
	call imprime_caractere
	xor al, al				;limpa digito anterior, que pode ter sido deixado pela ultima inscrição
	dec dl
	call imprime_caractere
	inc dl

	loop_imprime_decimal:
	pop ax              ;proximo caracter
	inc dl              ;avanca a coluna
	call imprime_caractere
	loop loop_imprime_decimal

	pop di
	pop dx
	pop cx
	pop bx
	pop ax		
    ret


;-----------------------------------------------------------------------
;---------------------Função Atualiza Mostrador-------------------------
;
; Preenche ou limpa as divisórias dos mostradores de temperatura e combustível
; Entradas:
; di -> 0 ou 1, indicando gasolina ou temperatura
; cx, dx -> LxH (tamanho da divisória)
; si -> x0 (para a função "retangulo_cheio")
;-----------------------------------------------------------------------
atualiza_mostrador:	
	push ax
	push bx
	push di


	compara:
	xor bh, bh
	mov bl, byte[barra_atual+di]
	cmp byte[barra_final+di], bl
	je sair6
	jg preenche_divisoria
	jl limpa_divisoria

	preenche_divisoria:
	mov al, 16			
	mul bl				; AL*BL = AX
	mov bl, 231
	add bx, ax			; y0
	mov byte[cor], azul
	mov ax, si			; x0
	call retangulo_cheio
	inc byte[barra_atual+di]
	jmp compara

	limpa_divisoria:
	mov al, 16			
	mul bl				; AL*BL = AX
	mov bl, 231
	add bx, ax			; y0
	mov byte[cor], preto
	mov ax, si			; x0	
	call retangulo_cheio
	dec byte[barra_atual+di]
	jmp compara

	sair6:
	mov byte[cor], branco_intenso
	pop di
	pop bx
	pop ax
	ret
;-----------------------------------------------------------------------
;-------------------------Função Trigonometria--------------------------
;
;Cálcula o seno e o cosseno de um ângulo entre 0 e 359 graus
;Recebe o angulo em DI
;Retorna os valores em duas variáveis
;-----------------------------------------------------------------------
trigonometria:
	push ax
	push bx
	push di
	
	;Avalia quadrante
	mov ax, 2
	mul di
	mov di, ax
	cmp di, 180			;2*90
	jle primeiro
	cmp di, 360			;2*180
	jle segundo
	cmp di, 540			;2*270
	jle terceiro
	jmp quarto
	
	primeiro:
	mov ax, word[tabela_seno+di]	
	mov word[seno], ax				; sen(x)
	mov bx, 180
	sub bx, di
	mov ax, word[tabela_seno+bx]
	mov	word[cosseno], ax			; cos(x) = sen(90-x)
	jmp sair5
	
	segundo:
	mov bx, 360
	sub bx, di
	mov ax, word[tabela_seno+bx]
	mov word[seno], ax				; sen(x) = sen(180-x)
	mov bx, 180
	sub di, bx
	mov ax, word[tabela_seno+di]
	neg ax
	mov word[cosseno], ax			;cos(x) = -sen(x-90)
	jmp sair5
	
	terceiro:
	mov bx, 540
	sub bx, di
	mov ax, word[tabela_seno+bx]
	neg ax
	mov word[cosseno], ax 			; cos(x) = -sen(270-x)
	sub di, 360
	mov ax, word[tabela_seno+di] 
	neg ax
	mov word[seno], ax				; sen(x) = -sen(x-180)
	jmp sair5
	
	quarto:
	mov bx, 720
	sub bx, di
	mov ax, word[tabela_seno+bx]
	neg ax
	mov word[seno], ax				; sen(x) = -sen(360-x)
	mov bx, 540
	sub di, bx
	mov ax, word[tabela_seno+di]
	mov word[cosseno], ax			; cos(x) = sen(x-270)
	
	sair5:
	pop di
	pop bx
	pop ax
	ret

;-----------------------------------------------------------------------
; funções utilizadas para tentativa de criação do ponteiro
;-----------------------------------------------------------------------
ponto_final:
	;di -> deltax
	;si -> deltay
	test di, di
	js negativo1
	add bx, di
	jmp proximo
	negativo1:
	neg di
	sub bx, di
	proximo:
	test si, si
	js negativo2
	add cx, si
	ret
	negativo2:
	neg si
	sub cx, si
	ret

matriz_rotacao:
	push cx
	;x2 = x1*cos(theta) - y1*sen(theta)
	;y2 = x1*sen(theta) + y1*cos(theta)
	;di -> x1
	;si -> y1
	mov ax, word[cosseno]
	imul di
	mov bx, 1000
	idiv bx
	mov cx, ax			;ax -> x1*cos(theta)
	mov ax, word[seno]
	imul si
	mov bx, 1000
	idiv bx				;ax -> y1*sen(theta)
	sub cx, ax
	mov ax, word[seno]
	imul di
	mov bx, 1000
	idiv bx				;ax -> x1*sen(theta)
	mov di, cx			;di -> deltax
	mov cx, ax			 
	mov ax, word[cosseno]
	imul si
	mov bx, 1000
	idiv bx				;ax -> y1*cos(theta)
	add cx, ax
	mov si, cx			;si -> deltay
	
	pop cx
	ret

;-----------------------------------------------------------------------
;---------------------Interrupções do Teclado---------------------------
;-----------------------------------------------------------------------
testatecla:
    push ax
	push dx
	;Re-colore caracteres do menu
	mov al,'S'     			;mensagem exibida
	mov dh,25          		;linha 0-29
	mov dl,2     			;coluna 0-79
	call imprime_caractere
	mov al,'D'     			;mensagem exibida
	mov dh,26          		;linha 0-29
	mov dl,2     			;coluna 0-79
	call imprime_caractere
	mov al,'Z'     			;mensagem exibida
	mov dh,27          		;linha 0-29
	mov dl,2     			;coluna 0-79
	call imprime_caractere
	
	;Detecta tecla pressionada        
	mov ah, 0bh
	int 21h
	cmp al, 0
	je volta ; Se nenhuma tecla foi pressionada, repete programa
	mov ah, 08
	int 21h
	cmp al, 'd'
	je diminui_delay  ; Se tecla d foi pressionada, aumenta a taxa de atualizaçao
	cmp al, 's'
	je aumenta_delay ; Se tecla s foi pressionada, diminui a taxa de atualizacao
	cmp al,'z'
	je	zera_odometro
	cmp al, 'x'
	je sair     ; Se tecla x foi pressionada, sai do programa
    jmp volta
	diminui_delay:
	mov byte[cor], vermelho
	mov al,'D'     			;mensagem exibida
	mov dh,26          		;linha 0-29
	mov dl,2     			;coluna 0-79
	call imprime_caractere
    dec byte[delay_cnt]
    jmp volta
    aumenta_delay:
	mov byte[cor], vermelho
	mov al,'S'     			;mensagem exibida
	mov dh,25          		;linha 0-29
	mov dl,2     			;coluna 0-79
	call imprime_caractere
    inc byte[delay_cnt]
    jmp volta
	zera_odometro:
	mov byte[cor], vermelho
	mov al,'Z'     			;mensagem exibida
	mov dh,27          		;linha 0-29
	mov dl,2     			;coluna 0-79
	call imprime_caractere
	mov word[odometro], 0
	mov word[odometro_m], 0
    volta:
	mov byte[cor], branco_intenso
	pop dx
    pop ax
    ret
;-----------------------------------------------------------------------
;-------------------------------DELAY-----------------------------------
;-----------------------------------------------------------------------
delay:
	push    cx
	mov     cl, byte[delay_cnt]	; Carrega o valor 3 no registrador cx (contador para loop)
del2:
	push    cx              ; Coloca cx na pilha para usa-lo em outro loop
	mov     cx, 0           ; Zera cx
del1:
	loop    del1            ; No loop del1, cx eh decrementado seguidamente ate que volte a ser zero
	pop     cx              ; Recupera cx da pilha
	loop    del2            ; No loop del2, cx eh decrementado seguidamente ate que seja zero
	pop     cx
	ret
;-----------------------------------------------------------------------
;-------------------------SAÍDA DO PROGRAMA-----------------------------
;-----------------------------------------------------------------------
sair:
	mov byte[cor], vermelho
	mov al,'X'     			;mensagem exibida
	mov dh,28          		;linha 0-29
	mov dl,2     			;coluna 0-79
	call imprime_caractere
	mov  ah,08h
	int  21h
	mov ah,0                ; set video mode
	mov al,[modo_anterior]    ; modo anterior
	int 10h
	mov ax,4c00h
	int 21h 
 
;-----------------------------------------------------------------------
;------------------------SEGMENTO DE DADOS------------------------------
;-----------------------------------------------------------------------  
segment data

	; Constantes de cores utilizadas
	cor           	db    	branco_intenso

	preto			equ		0
	azul			equ		1
	verde			equ		2
	cyan      		equ		3
	vermelho    	equ		4
	magenta     	equ		5
	marrom      	equ		6
	branco      	equ		7
	cinza     		equ		8
	azul_claro    	equ		9
	verde_claro   	equ		10
	cyan_claro    	equ		11
	rosa      		equ		12
	magenta_claro 	equ		13
	amarelo     	equ		14
	branco_intenso  equ		15
	
	modo_anterior	db		0
	deltax		    dw		0 ;deltaX e deltaY utilizados pela função line
	deltay		    dw		0
	
	msg1      		db      'Sistemas Embarcados I - 2017/1$'
	msg2			db		'Vitor Henrique de Moraes Escalfoni$'
	msg3			db		'Quilometragem =$'
	msg4			db		'Od',147,'metro Parcial =$'
	msg5			db		'Autonomia =$'
	msg6			db		'Velocidade M',130,'dia =$'
	msg7			db		'Litros Consumidos =$'
	msg8			db		'Desempenho$'
	msg9			db		'M',130,'dio =$'
	msg10			db		'GAS$'
	msg11			db		'TEMP$'
	msg12			db		'[S] - Aumenta Delay$'	
	msg13			db		'[D] - Diminui Delay$'
	msg14			db		'[Z] - Zerar Odometro$'
	msg15			db		'[X] - Sair$'

	unit1			db		'Km$'
	unit2			db		'Km/h$'
	unit3			db 		'lts$'
	unit4			db		'Km/lt$'
	unit5			db		'RPM$'
	unit6			db		'x1000$'				

	msg_erro1		db		'Erro na abertura do arquivo$'
	msg_erro2		db		'Erro na leitura do arquivo$'
	msg_erro3		db		'Erro ao sair do arquivo$'

	; Tabela de seno de 0 a 90 graus, multiplicada por mil
	tabela_seno		dw 		0, 17, 35, 52, 70, 87, 104, 122, 139, 156
					dw		174, 191, 208, 225, 242, 259, 276, 292, 309, 326
					dw		342, 358, 375, 391, 407, 423, 438, 454, 470, 485
					dw		500, 515, 530, 545, 559, 574, 588, 602, 616, 629
					dw		643, 656, 669, 682, 695, 707, 719, 731, 743, 755
					dw		766, 777, 788, 799, 809, 819, 829, 839, 848, 857
					dw		866, 875, 883, 891, 899, 906, 914, 921, 927, 934
					dw		940, 946, 951, 956, 961, 966, 970, 974, 978, 982 		
					dw		985, 988, 990, 993, 995, 996, 998, 998, 999, 999, 1000

	seno			resw	1
	cosseno			resw 	1

	; Variáveis para leitura e abertura de arquivo
	file_name		db		'leitura.txt$',00h
	file_handle   	dw      0
	dados			resb	2243

	; variáveis para processamento de dados
	capacidade		db		0	; Capacidade do tanque em Litros	
	leituras		db		01h ; Usada no calculo da Velocidade Média
	buffer_dados	resw	45 	; 15 segundos x 4 dados por linha  
	delay_cnt		db		0Ah

	; variáveis para exibição de dados	
	quilometragem	dw		0
	quilometragem_m dw		0
	odometro		dw		0
	odometro_m		dw		0
	autonomia		dw		0
	velocidade_med	dw		0
	litros_con		dw		0
	litros_con_ml	dw		0
	desempenho		dw		0
	desempenho_m	db		0

	velocidade_inst	db		0
	rotacao_inst	dw		0
	litros_inst		dw		0
	temp_inst		db		0

	barra_atual		dw		0
	barra_final		dw		0

;-----------------------------------------------------------------------
;-----------------------------------------------------------------------
segment stack stack 
     resb 512 ; definição da pilha com total de 512 bytes
stacktop:
;-----------------------------------------------------------------------
;-----------------------------------------------------------------------
