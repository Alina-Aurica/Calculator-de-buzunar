.386
.model flat, stdcall
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;includem biblioteci, si declaram ce functii vrem sa importam
includelib msvcrt.lib
extern exit: proc
extern printf: proc
extern scanf: proc
extern sscanf: proc
extern strlen: proc
extern strtok: proc
extern strcpy: proc
extern strcmp: proc
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;declaram simbolul start ca public - de acolo incepe executia
public start
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;sectiunile programului, date, respectiv cod
.data
msj1 db "Alegeti o optiune: 1. Sinus; 2. Logaritm; 3. Operatii aritmetice", 13, 10, 0
msj2 db "Introduceti o expresie:", 13, 10, 0
rezultat dq 0
rez dd 0
format1 db "%s", 0
format2 db "%f", 0
format4 db "%lf", 13, 10, 0
format6 db "%d", 0
format7 db "%s", 13, 10, 0
expresie db 40 dup(0)
stop db "exit", 0
sir1 db 40 dup(0)        ;retine semnele
sir2 dd 40 dup(0)        ;retine numerele
sinus db "sin", 0
logaritm db "log", 0
expresie_separare db "+-*/= ", 0
x dd ?
n dd 0
null db "NULL", 0
lungime_expresie dd 0
lungime_sir1 dd 0
lungime_sir2 dd 0
subsir dd 40 dup(0)      ;retine sirurile de caractere despartite prin strtok
pii db "pi",0

.code

afisare MACRO rezultat
	push dword ptr [rezultat+4]
	push dword ptr [rezultat]
	push offset format4
	call printf
	add ESP, 12
ENDM

sin MACRO expresie
	local bucla_sinus, cheama_s_proc
	push offset expresie
	call strlen              ;lungime sir
	add ESP, 4
	
	mov ECX, EAX             ;incarcam lungimea sirului in ECX
    mov EBX, 0
		
		bucla_sinus:
			mov DL, expresie[EBX+4]
			mov expresie[EBX], DL
			inc EBX
			cmp EBX, ECX
			jnz bucla_sinus
		mov DL, expresie[EAX-1-4]
		mov expresie[EAX-2-4], DL    ;facem expresia in asa fel incat sa poata fi calculata prin sir1
		mov expresie[EAX-1-4]," "
		
		push offset expresie
		push offset format7        ;afisam expresia care ramane
		call printf
		
		sir expresie
	
	finit
	fld rezultat                  ;se incarca numarul
	fsin
	fstp rezultat
	
ENDM

log MACRO expresie
	local bucla_logaritm, cheama_1_proc
	push offset expresie
	call strlen              ;lungime sir
	add ESP, 4
	
	mov ECX, EAX             ;incarcam lungimea sirului in ECX
    mov EBX, 0
		
		bucla_logaritm:
			mov DL, expresie[EBX+4]
			mov expresie[EBX], DL
			inc EBX
			cmp EBX, ECX
			jnz bucla_logaritm
		mov DL, expresie[EAX-1-4]
		mov expresie[EAX-2-4], DL    ;facem expresia in asa fel incat sa poata fi calculata prin sir1
		mov expresie[EAX-1-4]," "
		
		push offset expresie
		push offset format7        ;afisam expresia care ramane
		call printf
		
		sir expresie
			
	finit
	fld1
	fld ST(0)
	fld rezultat       ;se incarca numarul
	fyl2x 
	fstp rezultat
	
endm

adunare PROC
	push EBP
	mov EBP, ESP
	sub ESP, 8
	
	finit
	fld dword ptr [EBP+8]
	fld dword ptr [EBP+12]      ;incarcarea celor 2 numere
	fadd
	fstp rez
	
	mov ESP, EBP
	pop EBP
	ret 8
adunare ENDP

scadere PROC
	push EBP
	mov EBP, ESP
	sub ESP, 8

	finit
	fld dword ptr [EBP+8]
	fld dword ptr [EBP+12]       ;incarcarea celor 2 numere
	fsub
	fstp rez
	
	mov ESP, EBP
	pop EBP
	ret 8
scadere ENDP

inmultire PROC
	push EBP
	mov EBP, ESP
	sub ESP, 8
	
	finit
	fld dword ptr [EBP+8]
	fld dword ptr [EBP+12]       ;incarcarea celor 2 numere
	fmul
	fstp rez
	
	mov ESP, EBP
	pop EBP
	ret 8
inmultire ENDP

impartire PROC
	push EBP
	mov EBP, ESP
	sub ESP, 8
	
	finit
	fld dword ptr [EBP+8]
	fld dword ptr [EBP+12]        ;incarcarea celor 2 numere
	fdiv
	fstp rez
	
	mov ESP, EBP
	pop EBP
	ret 8
impartire ENDP

cautare_operatori MACRO expresie                    ;cautam operatorii
	local cauta_operatorii, adauga, finish_cautare
	
	xor ECX, ECX      ;index de parcurgere al sirului expresie
	xor EBX, EBX      ;initializam indexul de parcurgere de la sir1
	cauta_operatorii:
		cmp expresie[ECX], "="     ;compara caracterul cu "="
		je finish_cautare
		cmp expresie[ECX], "+"     ;compara caracterul cu "+"
		je adauga
		cmp expresie[ECX], "-"     ;compara caracterul cu "-"
		je adauga
		cmp expresie[ECX], "*"     ;compara caracterul cu "*"
		je adauga
		cmp expresie[ECX], "/"     ;compara caracterul cu "/"
		je adauga
		inc ECX
	jmp cauta_operatorii        ;iese din bucla cand intalneste caracterul "="
	
	adauga:
		xor EDX, EDX
		mov DL, expresie[ECX]
		mov sir1[EBX], DL
		inc EBX               ;pregatim sir1 de o inserare pe pozitia urmatoare
		inc ECX               ;mutam la urmatorul caracter stringul expresie
	jmp cauta_operatorii
	
	finish_cautare:
		xor EDX, EDX
		mov DL, expresie[ECX]
		mov sir1[EBX], DL
		inc EBX               
		inc ECX
	
	mov lungime_sir1, EBX     ;salvam in variabila lungime_sir1 lungimea sir1
	
ENDM


cautare_numere MACRO expresie
	local conversie, subsir_nenul, subsir_nul    ;incarca_pi, fct_sscanf, pune_in_sir
	
	;pentru a extrage numerele din sir folosim functia strtok
	push offset expresie_separare
	push offset expresie
	call strtok                ;primul apel al functiei
	add ESP, 8
	
	;rezultatul se salveaza in EAX
	push EAX
	push offset subsir
	call strcpy
	add ESP, 8
	
	xor EBX, EBX        ;initializam cu 0 indexul pentru sir2
	
	conversie:         
        ;conversia lui subsir in numar real
		
		;push offset subsir
		;push offset pii
		;call strcmp        ;verific daca e pi
		;add ESP, 8
		
		;cmp EAX, 0
		;je incarca_pi       ;daca da, il incarc in coprocesor
		;jmp fct_sscanf      ;daca nu, fac mai departe
		
		;incarca_pi:
		;finit
		;fldpi
		;fstp n
		;jmp pune_in_sir
		
		;fct_sscanf:
		push offset n
		push offset format2
		push offset subsir    
		call sscanf          ;convertim in numar real
		add ESP, 12
		;jmp pune_in_sir
		
		;pune_in_sir:
		push n
		pop sir2[EBX]        ;am pus numarul in sir2
		inc lungime_sir2     ;incrementam lungimea sir2
		add EBX, 4         
		mov n, 0           ;reinitializam variabila ajutatoare n
		
		subsir_nenul:
			
			push offset expresie_separare
			push 0
			call strtok
			add ESP, 8
			
			cmp EAX,0
			je subsir_nul
			
			push EAX
			push offset subsir     ;adaugam din nou in subsir
			call strcpy
			add ESP, 8
			
			jmp conversie
			
	subsir_nul:              ;s-a realizat deja conversia tuturor numerelor
		xor EDX, EDX
		xor EBX, EBX

ENDM


sir MACRO expresie
	local operator, shift_right, numar, shift_left_sir1_1, shift_left_sir2_1, shift_left_sir1_2, shift_left_sir2_2, inmultire_impartire, stop_calcul_inm_imp, inm, imp, adunare_scadere, stop_calcul_ad_sc, ad, sc
	
	cautare_operatori expresie     ;apelez MACRO-ul care-mi formeaza sir1
	cautare_numere expresie       ;apelez MACRO-ul care-mi formeaza sir2
	
	mov EBX, lungime_sir1
	cmp EBX, lungime_sir2         ;comparam lungimile sirurilor de numere si de operatori - daca lg sir1 e mai mare, shift right de o pozitie in sir2 si adaugarea lui 0 pe prima poz
	ja operator                   ;expresia incepe cu un operatori
	jmp numar
		
	operator: 
		mov ECX, lungime_sir2
		shift_right:                 ;shift right de o pozitie pentru a-i face loc lui rez in sir2
			mov EAX, sir2[ECX*4-4]
			mov sir2[ECX*4], EAX
		loop shift_right
		mov EBX, rez                 ;punem rezultatul anterior pe prima pozitie a sir2
		mov sir2[0], EBX
	
	numar:
		mov EBP, 0
		mov rez, EBP              ;reinitializam 
		
		xor EDX, EDX             ;initializam indexul EDX pentru a parcurge din nou sir1
		mov ECX, lungime_sir1    ;punem lungimea sir1 in ECX
		
	;operatii
	;calculam mai intai inmultirile si impartirile
		inmultire_impartire:
			cmp sir1[EDX], "="
			je stop_calcul_inm_imp
			cmp sir1[EDX], "*"
			je inm
			cmp sir1[EDX], "/"
			je imp
			inc EDX
			mov EAX, EDX
		jmp inmultire_impartire
			
		inm:                             
			push sir2[EDX*4+4]        
			push sir2[EDX*4]           ;incarc numerele pe stiva
			call inmultire			  ;apelez functia inmultire
			push rez
			pop sir2[EDX*4+4]         ;variabila rezultat pe pozitia celui de-al 2-lea numar
			
			shift_left_sir1_1:             ;shift left pentru a scapa de semnul deja folosit
				mov BL, sir1[EDX+1]
				mov sir1[EDX], BL
				inc EDX
				cmp EDX, ECX
				jne shift_left_sir1_1
			
			shift_left_sir2_1:             ;shift left pentru a scapa de numarul deja folosit
				push sir2[EAX*4+4]
				pop sir2[EAX*4]
				inc EAX
				cmp EAX, ECX
				jne shift_left_sir2_1
				
			dec ECX
			inc EDX
			jmp stop_calcul_inm_imp
			
		imp:
			
			push sir2[EDX*4+4]        
			push sir2[EDX*4]           ;incarc numerele pe stiva
			call impartire               ;apelez functia inmultire
			push rez
			pop sir2[EDX*4+4]            ;variabila rezultat pe pozitia celui de-al 2-lea numar
			
			shift_left_sir1_2:             ;shift left pentru a scapa de semnul deja folosit
				mov BL, sir1[EDX+1]
				mov sir1[EDX], BL
				inc EDX
				cmp EDX, ECX
				jne shift_left_sir1_2
				
			shift_left_sir2_2:             ;shift left pentru a scapa de numarul deja folosit
				push sir2[EAX*4+4]
				pop sir2[EAX*4]
				inc EAX
				cmp EAX, ECX
				jne shift_left_sir2_2
			
			dec ECX
			inc EDX
			jmp stop_calcul_inm_imp
			
		stop_calcul_inm_imp:
			xor EDX, EDX             ;initializam indexul de parcurgere a sir1
				
		adunare_scadere:
			cmp sir1[EDX], "="
			je stop_calcul_ad_sc
			cmp sir1[EDX], "+"
			je ad
			cmp sir1[EDX], "-"
			je sc
			inc EDX
		jmp adunare_scadere
		
		ad:
			push sir2[EDX*4+4]
			push sir2[EDX*4]
			call adunare
			push rez
			pop sir2[EDX*4+4]
			
			inc EDX
			jmp adunare_scadere
			
		sc:
			push sir2[EDX*4+4]
			push sir2[EDX*4]
			call scadere
			push rez
			pop sir2[EDX*4+4]
			
			inc EDX
			jmp adunare_scadere
		
		stop_calcul_ad_sc:
			fld sir2[EDX*4]
			fstp rezultat           ;incarc rezultatul in variabila rezultat
	
ENDM

start: 

bucla:
	push offset msj1
	call printf
	add ESP, 4               ;mesaj de alegere a operatiei
	
	push offset x
	push offset format6      
	call scanf               
	add ESP, 8               ;citeste operatia aleasa
	
	push offset msj2
	call printf
	add ESP, 4               ;mesaj de introducere a expresiei
		
	push offset expresie
	push offset format1
	call scanf	
	add ESP, 8               ;citeste expresia de la tastatura
		
	push offset expresie
	push offset stop
	call strcmp              ;compara expresia cu exit
	add ESP, 8
		
	cmp EAX, 0               ;rezultatul compararii e retinut in eax
	jz final
	
	mov EAX, x               ;verificam ce operatie trebuie sa facem
	cmp EAX, 1
	je sinus_
		cmp EAX, 2
		je logaritm_
			cmp EAX, 3
			je operatie_
	
	sinus_:
	sin expresie           ;apelam functia sin
	jmp afisare_rez
	
	logaritm_:
	log expresie           ;apelam functia log
	jmp afisare_rez
	
	operatie_:
	sir expresie           ;apelam functie sir
	jmp afisare_rez
	
	afisare_rez:
	afisare rezultat        ;afiseaza rezultat
	
	jmp bucla
	
	final: 
	push 0
	call exit
	
end start
