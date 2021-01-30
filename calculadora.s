	.global	_start

	/* Alocação de espaço para dois valores */
	valor1: .byte	8
	valor2: .byte	8

_start:

	@@@@@ Leitura e escrita do primeiro operando a partir do console @@@@@ 

	/* int read(int fd, const void *buf, size_t count) */
	mov     r0, #0      @ fd -> stdin
	ldr     r1, =buffer1 @ buf -> buffer
	ldr		r2, =valor1
	mov     r7, #3      @ read é syscall #3
	svc     #0x55       @ executa syscall 
	mov	r2, r0

	/* int write(int fd, const void *buf, size_t count) */
	mov     r0, #1      @ fd -> stdout
	ldr     r1, =buffer1 @ buf -> msg
	mov     r7, #4      @ write é syscall #4
	svc     0x55        @ executa syscall 

	bl conv @ chama função para converter número em ASCII a partir do console em hexa
	mov r9,r10 @ armazena o resultado em hexa do primeiro valor em r9

	@@@@@ Leitura e escrita do operador a partir do console @@@@@

		/* int read(int fd, const void *buf, size_t count) */
	mov     r0, #0      @ fd -> stdin
	ldr     r1, =operador @ buf -> buffer
	mov		r2, #1
	mov     r7, #3      @ read é syscall #3
	svc     #0x55       @ executa syscall 

	/* int write(int fd, const void *buf, size_t count) */
	mov     r0, #1      @ fd -> stdout
	ldr     r1, =operador @ buf -> msg
	mov     r7, #4      @ write é syscall #4
	svc     0x55        @ executa syscall 

	@@@@@ Leitura e escrita do segundo operando a partir do console @@@@@

		/* int read(int fd, const void *buf, size_t count) */
	mov     r0, #0      @ fd -> stdin
	ldr     r1, =buffer2 @ buf -> buffer
	ldr		r2, =valor2
	mov     r7, #3      @ read é syscall #3
	svc     #0x55       @ executa syscall 
	mov	r2, r0

	/* int write(int fd, const void *buf, size_t count) */
	mov     r0, #1      @ fd -> stdout
	ldr     r1, =buffer2 @ buf -> msg
	mov     r7, #4      @ write é syscall #4
	svc     0x55        @ executa syscall 

	@ faz a conversão e armazena o segundo operando em hexa no r12
	bl conv
	mov r12,r10 

	@@@@@ Escreve o caracter "=" no console @@@@@

	/* int write(int fd, const void *buf, size_t count) */
	mov     r0, #1      @ fd -> stdout
	ldr     r1, =msg @ buf -> msg
	ldr 	r2, =len
	mov     r7, #4      @ write é syscall #4
	svc     0x55        @ executa syscall  
	
	@ empilha o primeiro e o segundo operando
	push {r9}
	push {r12}

	@ carrega o operador inserido em r4
	ldr r4,=operador
	ldr r4,[r4,#0]

	@ compara o operador inserido pelo usuário com o valor em hexa das operações (+,-,*,/) @

	cmp		r4,#0x2b // compara o valor que está no r4 com a operação desejada
	bleq	sum // chama a função soma

	cmp		r4,#0x2d
	bleq	sub // chama a função de subtração

	cmp		r4,#0x2f
	bleq	div // chama a função de divisão

	cmp		r4,#0x2a
	bleq	mult // chama a função de multiplicação

	@@@@@

	push {r0} @ empilha o resultado
	ldr   r3, =resultado @ carrega no r3 o endereço do buffer
	mov r10,#0 @ zera o r10 pois deve estar zerado antes da conversão em ascii
	b 	 para_ascii @ procede para a conversão em ascii

	/* operações da calculadora */

	sum:
		push 	{lr} // empilha o endereço de retorno
		ldr		r0,[sp, #8] // carrega o primeiro argumento da função
		ldr		r1,[sp, #4] // carrega o segundo argumento da função
		add 	r0,r0,r1 // guarda resultado da operação no r2
		pop 	{pc} // retorno da função
	sub:
		push	{lr}
		ldr		r0,[sp, #8]
		ldr		r1,[sp, #4]
		sub 	r0,r0,r1
		pop 	{pc}
	div:
		push	{lr}
		ldr		r0,[sp, #8]
		ldr		r1,[sp, #4]
		mov		r2, #0
		bl		div2
		mov		r0, r2
		pop 	{pc}
	div2:
		push	{lr}
		cmp 	r0,r1
		itt		ge		  // próximas duas instruções são condicionais
		subge	r0,r0,r1
        addge	r2,r2,#1
		cmp		r0, r1
        blge	div2
		pop		{pc}
	mult:
		push	{lr}
		ldr		r0,[sp, #8]
		ldr		r1,[sp, #4]
		mov		r2, #0
		bl		mult2
		mov		r0, r2
		pop		{pc}
	mult2:	
		push	{lr}
		cmp		r0,#0		
		subne 	r0,r0,#1
		addne	r2,r2,r1
		cmp		r0,#0
		bne 	mult2
		pop		{pc}

// Conversão para ascii
para_ascii:
	push  {lr}
	mov    r8, #10 // base decimal

	ldr    r4, [sp, #4] 
	push  {r4} // empilha o resultado da operação
	push  {r8} // e o valor da base
	bl     div
	mov    r9, r0 // r9 = r4 / 10
	add    sp, #8

	push  {r8} // empilha o valor da base 
	push  {r9} // e o resultado anterior
	bl     mult
	mov    r6, r0 // r6 = r9 * 10
	add    sp, #8

	sub    r7, r4, r6 // r7 = r4 - r6 (LSDD)
	add    r7, #'0'   // soma 48 para obter o valor em ascii
	strb   r7, [r3, #-1]! // armazena o valor em bytes no buffer e atualiza o registrador
	
	cmp    r9, #0 // condição de parada
	add    r10,#2 // utilizado para contabilizar a quantidade de bytes que serão escritos na saída
	beq    fim
	push  {r9}
	bl     para_ascii // chamada recursiva até o r9 valer 0

@ converte o o vetor de caracteres inserido em ASCII para hexa para poder realizar a operação desejada
	conv:
		push {lr}
		mov r10,#0
		mov r3,#0 @ zera o registrador que guarda a posição
		mov r6,r1 @ guarda o endereço do vetor em r6
		mov r4,r0 @ número de bytes do vetor
		bl conv2
		pop {pc}
	conv2:
		push {lr}
		mov r5,#0
		sub r4,r4,#1 @ subtrai 1 para obter número certo de expoentes
		cmp r4, #0 @ verifica se o expoente é zero
		ite eq
		moveq r8,#1 @ se for igual a zero move 1 para r8
		movne r8,#10 @ se não for utiliza 10 (valor da base)
		ldrb r2, [r6, r3] @ carrega em r2 o valor posição do vetor guardada em r3
		sub r2,r2,#0x30 @ subtrai para obter o decimal
		push {r2,r8} 
		bl mult @ número do vetor * 10
		pop {r2,r8}
		add r5,r5,r0 @ soma o resultado com o resultado da operação
		add r3,r3,#1 @ desloca para o próximo caracter
		push {r0,r4}
		cmp r4,#1 
		it gt @ se r4>1, significa que o expoente é maior que 1
		blgt exp @ multiplica por 10 até obter o resultado correto
		pop {r0,r4}
		cmp r2,r12 @ compara o valor em r2 com r12
		moveq r0,r12 @ se r2=12, significa que a função "exp" foi executada e o resultado está em r12
		add r10,r10,r0 @ r10 (resultado final) + r0 (resultado parcial)
		cmp r4,#0 @ se r4=0 a conversão foi finalizada, caso contrário procede para recursão
		blne conv2
		pop {pc}

@ procedimento para quando o expoente for maior que 1
	exp:
		push {lr}
		mov r12,r5
		ldr r7,[sp, #8] @ carrega o número de bytes do vetor em r7
		ldr r0,[sp,#4] @ carrega o resultado parcial
		bl exp2
		pop {pc}
	exp2:
		push {lr}
		sub r7,r7,#1 @ r7 = r7 - 1
		cmp r7,#1
		itt ge @ se r7 >= 1
		movge r0,r12 @ r0 <- r12
		blge exp3 @ procede para fazer a multiplicação por 10
		pop {pc} @ se r7 = 0, não precisa mais multiplicar por 10 
	exp3:
		push {lr}
		push {r0,r8}
		bl mult @ r0 (resultado parcial) * 10
		mov r12,r2 @ r12 <- r2 (resultado da multiplicação)
		pop {r0,r8}
		bl exp2 @ volta para exp2 para conferir se ainda precisa multiplicar por 10
		pop {pc}


/* fim do programa */
fim:

	@ apresenta o resultado final no console
	mov     r0, #1
	mov		r2, r10 
	mov     r1, r3		 
	mov     r7, #4
	svc     0x055

	@ escreve a mensagem de continuação para o usuário 
	mov     r0, #1
	ldr		r1, =msg_continua 
	ldr     r2, =continua_len
	mov     r7, #4 
	svc      0x055

	@ lê a opção inserida pelo usuário
	mov     r0, #0
	ldr     r1, =opcao
	mov		r2, #1
	mov     r7, #3    
	svc     #0x55     

	@ carrega a opção do usuário em r1
	ldr r1,[r1]
	cmp r1,#0x79 @ se for igual a 'y' vai para o começo
	beq _start

	/* exit(int status) */
	mov     r0, #0      @ status -> 0
	mov     r7, #1      @ exit é syscall #1
	svc     #0x55       @ executa syscall 

	/* símbolo em ascii de igualdade antes do resultado final */
	msg:
	.ascii   "="
	len = . - msg

	@ mensagem para perguntar ao usuário se ele deseja continuar o programa
	msg_continua:
	.ascii	"\nContinuar(y/n) ?\n"
	continua_len = . - msg_continua

	/* buffers dos operandos, do operador, do resultado final e da opção de continuar do usuário */
	operador:
	.skip 128

	buffer1:
	.skip 128

	buffer2:
	.skip 128

	resultado:
	.skip 128

	opcao:
	.skip 128
