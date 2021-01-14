	.global	_start

	/* Definição de dois valores */
	.equ	valor1,25
	.equ	valor2,5

_start:

	/* int write(int fd, const void *buf, size_t count) */
	mov     r0, #1      @ fd -> stdout
	ldr     r1, =msg    @ buf -> msg
	ldr     r2, =len    @ count -> len(msg)
	mov     r7, #4      @ write é syscall #4
	svc     0x055       @ executa syscall 

	/* int read(int fd, const void *buf, size_t count) */
	mov     r0, #0      @ fd -> stdin
	ldr     r1, =buffer0 @ buf -> buffer
	mov     r7, #3      @ read é syscall #3
	svc     #0x55       @ executa syscall 
	
	// guarda a escolha da operação no r4
	ldr		r4, =buffer0 // carrega o endereço do buffer0 no r4
	ldr		r4, [r4] 	 // carrega o valor no r4

	/* escolha da operação */

	// move os valores para os registradores e os empilha
	mov	r0,#valor1
	push {r0}
	mov	r1,#valor2
	push {r1} 
	
	cmp		r4,#49 // compara o valor que está no r4 com a operação desejada
	bleq	sum // chama a função soma

	cmp		r4,#50
	bleq	sub // chama a função de subtração

	cmp		r4,#51 
	bleq	div // chama a função de divisão

	cmp		r4,#52
	bleq	mult // chama a função de multiplicação

	push {r0} // empilha o resultado
	ldr   r3, =resultado // carrega no r3 o endereço do buffer
	b 	 para_ascii // procede para a conversão em ascii

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
		add 	r2,r2,r1
		sub 	r0,r0,#1
		cmp 	r0,#0
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
	add    sp, #4

/* fim do programa */
fim:
	
	/* int write(int fd, const void *buf, size_t count) */
	mov     r0, #1
	mov		r2, r10  @ quantidade de bytes a serem mostrados na saída
	mov     r1, r3	 @ começo da cadeia é em r3	 
	mov     r7, #4   @ write é syscall #4
	svc     0x055    @ executa syscall

	/* exit(int status) */
	mov     r0, #0      @ status -> 0
	mov     r7, #1      @ exit é syscall #1
	svc     #0x55       @ executa syscall 

	/* mensagem inicial para o usuário selecionar uma operação */
	msg:
	.ascii   "Ola. Bem-vindo a calculadora ARM. Escolha uma operacao\n\n1-Adicao\n2-Subtracao\n3-Divisao\n4-Multiplicacao\n\nResultado: "
	len = . - msg

	/* guarda a opção selecionada pelo usuário */
	buffer0:
	.byte 4

	/* guarda a o vetor de caracteres do resultado final */
	resultado:
	.skip 128
