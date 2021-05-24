ORG 00H
RS EQU P2.0
RW EQU P2.1
E  EQU P2.2
SEL EQU 41H      ;SEL merupakan penanda jenis operasi yang dilakukan ke LCD
KEYPAD EQU P3
BUZZER EQU P2.5

SETB P2.4         ;Inisialisasi sensor
CLR P2.5          ;Inisialisasi Buzzer

MAIN:   ACALL CLEARSCREEN ;Memanggil fungsi untuk mode konfigurasi Awal/Reset, dengan CLEARSCREEN dan CMD
	ACALL TEXT1 	  ;Memanggil fungsi untuk mode menulis text pertama, dengan TEXT dan DWR
	ACALL LINE2 	  ;Memanggil fungsi untuk mode konfigurasi pindah cursor ke baris 2
	ACALL TEXT2 	  ;Memanggil fungsi untuk mode menulis text kedua dengan TEXT2 dan DWR ("Scanning..")
	ACALL DELAY

CHECKSENSOR:	JNB P2.4,CHECKSENSOR    		;Check nilai sensor. Jika terdeteksi, tampilkan tulisan lain di LCD (alert)
		SETB P2.5 				;Menyalakan BUZZER
		CLR P2.7 				;Menyalakan LED
		ACALL CLEARSCREEN 			;Clear Screen lagi untuk print set text Alert 
		ACALL TEXT1 				;Memanggil fungsi untuk mode menulis text pertama, dengan TEXT dan DWR
		ACALL LINE2 				;Memanggil fungsi untuk mode konfigurasi pindah cursor ke baris 2
		ACALL TEXT3 				;Memanggil fungsi untuk mode menulis text ketiga dengan TEXT3 dan DWR ("Alert!!")
		ACALL DELAY
		ACALL DELAY2
		ACALL KEYMAIN 				;Memanggil fungsi untuk keypad untuk password untuk mematikan alarm
		CHECKSENSOR2:JB P2.4,CHECKSENSOR2       ;Jika sudah tidak terdeteksi apa-apa, kembali ke (scanning)
		SJMP MAIN 				;Loop untuk MAIN program (looping sensor mendeteksi intruder)

TEXT1:  MOV DPTR,#TEXTSENSOR    ;Mulai masuk mode writing text1 ('SENSOR')
	D1:CLR A          	;Mengclear A untuk menyiapkan tiap kata dari data pointer dimasukkan ke A
	MOVC A,@A+DPTR    	;Meload kata dari data pointer ke A 
	ACALL DWR         	;Memanggil fungsi write
	INC DPTR          	;Meload kata selanjutnya data pointer
	CJNE A,0,D1    		;Jika menemui EOF 0, writing berhenti. Jika tidak, lanjut writing
	RET

TEXT2:  MOV DPTR,#TEXTSCANNING​  ;Mulai masuk mode writing text2 ('SCANNING..')
	D2:CLR A          	;Mengclear A untuk menyiapkan tiap kata dari data pointer dimasukkan ke A
	MOVC A,@A+DPTR    	;Meload kata dari data pointer ke A 
	ACALL DWR         	;Memanggil fungsi write
	INC DPTR          	;Meload kata selanjutnya data pointer
	CJNE A,0,D2   		;Jika menemui EOF 0, writing berhenti. Jika tidak, lanjut writing
	RET

TEXT3:  MOV DPTR,#TEXTALERT​  	;Mulai masuk mode writing text2 ('ALERT!!')
	D3:CLR A          	;Mengclear A untuk menyiapkan tiap kata dari data pointer dimasukkan ke A
	MOVC A,@A+DPTR    	;Meload kata dari data pointer ke A 
	ACALL DWR         	;Memanggil fungsi write
	INC DPTR          	;Meload kata selanjutnya data pointer
	CJNE A,0,D3   		;Jika menemui EOF 0, writing berhenti. Jika tidak, lanjut writing
	RET

LINE2:	MOV A,#0C0H ;Fungsi konfigurasi untuk pindah ke baris 2 LCD
	ACALL CMD
	RET

;Fungsi CLEARSCREEN untuk meng-clear screen dan memasukkan konfigurasi awal
CLEARSCREEN:    MOV A,#38H​        ;38H dipindahkan ke P1 dari A (di CMD)= 00111000 = Function Set = Inisialisasi LCD menggunakan 2 baris, operasi 8-bit
		ACALL CMD
		ACALL DELAY
		MOV A,#0FH​        ;0FH = 00001111 = Display ON/OFF Control = menyalakan display, menyalakan cursor, dan menyalakan kedip cursor
		ACALL CMD
		ACALL DELAY
		MOV A,#01H​        ;01H = 00000001 = Clear Display = mereset display dan membalikkan cursor ke awal
		ACALL CMD
		ACALL DELAY
		MOV A,#06H​	  ;06H = 00000110 = Entry Mode Set = Tiap write/read, kursor gerak ke kiri
		ACALL CMD
		ACALL DELAY
		RET
;Fungsi CMD untuk meng-apply konfigurasi 
CMD:    MOV P1,A
	CLR P2.0          ;!
	CLR P2.1          ;!! RS = 0 R/W = 0 menandakan LCD masuk mode Konfigurasi
	SETB P2.2         ;Rising Edge Clock
	ACALL DELAY
	CLR P2.2          ;Falling Edge Clock, meng-apply konfigurasi dari P1
	RET

;Fungsi DWR = write untuk menulis kata dari data pointer ke LCD, memasukkan kata dari A ke P1
DWR:	MOV P1,A
	SETB P2.0         ;!
	CLR P2.1          ;!! RS = 1 R/W = 0 Menandakan LCD masuk mode Writing
	SETB P2.2         ;Rising Edge Clock
	ACALL DELAY
	ACALL DELAY
	ACALL DELAY
	ACALL DELAY
	CLR P2.2          ;Falling Edge Clock, menuliskan kata dari P1
	RET

;Delay
DELAY:	MOV R3,#70  	  ;Subroutine delay start
HERE2:	MOV R4,#200
HERE:	DJNZ R4,HERE
	DJNZ R3,HERE2
	RET

KEYMAIN:ACALL INIT_LCDK            ;MAIN2 merupakan bagian program untuk menangani kerja Keypad untuk memasukkan password Alarm
        ACALL READ_KEYSCAN	   ;Memanggil Fungsi untuk membaca pencetan User di Keypad
        ACALL LINE1                ;Memindahkan kursor ke baris 1
        MOV DPTR,#CHECKMSG         ;Meload tulisan bahwa password user sedang dicek
       	ACALL PRINT_LCDK           ;Menuliskan tulisan ke LCD dari #CHKMSG
       	ACALL DELAY
       	ACALL CHECK_PASS           ;Memanggil fungsi pengecekan password
       	LJMP MAIN                  ;Setelah selesai, program kembali ke state awal (scanning)


TURNOFF:  CLR P2.5		   ;TURNOFF merupakan fungsi untuk mematikan alarm dan buzzer ketika password yang dimasukkan benar
	  SETB P2.7                ;Menggunakan inverter, LED mati ketika bit portnya high
	  LJMP CLEARSCREEN
	  RET

INIT_LCDK:MOV DPTR,#INIT_CODES    ;Melakukan inisialisasi LCD untuk pengerjaan dengan keypad
          SETB SEL                ;SEL ini merupakan selektor untuk menentukan mode LCD nanti pada PRINT_LCDK, apa ingin menulis (DWR) atau meng-apply konfigurasi (CMD)
          ACALL PRINT_LCDK
          CLR SEL
          RET

PRINT_LCDK:  CLR A                  ;Indexed Addressing kalimat yang berkaitan dengan pengerjaan keypad untuk dituliskan di LCD dengan DWR
             MOVC A,@A+DPTR
             JZ EXIT                ;Jika menemui EOF 0, EXIT atau RETURN function
             INC DPTR
             JB SEL,CMD1            ;Jika SEL, ke CMD. Jika tidak, ke DWR
             ACALL DWR              ;Memanggil fungsi untuk mencetak huruf ke LCD
             SJMP PRINT_LCDK

CMD1:   ACALL CMD                   ;Bagian dari subroutine PRINT_LCDK untuk melakukan CMD dan kembali melanjutkan loop PRINT_LCDK
        SJMP PRINT_LCDK

EXIT:	RET

LINE1: 	MOV A,#80H               ;Fungsi untuk memindahkan kursor LCD ke baris pertama
	ACALL CMD
	RET

CLRSCR: MOV A,#01H               ;Melakukan clear screen LCD untuk pengerjaan dengan keypad
	ACALL CMD
	RET

DELAY1:   MOV R3,#250            ;Fungsi Delay kedua, untuk delay tambahan input keypad
HERED1:   MOV R4,#0FFH
HERED1_2: DJNZ R4,HERED1_2
	  DJNZ R3,HERED1
	  RET

DELAY2: MOV TMOD, #00000001B     ;Fungsi Delay ketiga, merupakan delay utama input keypad, pengecekan serta printing, menggunakan timer
	MOV TH0,#0FCH
        MOV TL0,#018H
        SETB TR0
HERED2:  JNB TF0,HERED2
        CLR TR0
        CLR TF0
	DJNZ R3,DELAY2
        RET

READ_KEYSCAN:   ACALL CLRSCR      		 ;Fungsi untuk masuk ke mode menerima input Keypad dari User
		ACALL LINE1
		MOV DPTR,#INPUTMSG               ;Meload tulisan ke LCD bahwa user diminta menginput 3 digit password
		ACALL PRINT_LCDK                 ;Mencetak tulisan dari #IPMSG
		ACALL LINE2                      ;Memindahkan kursor ke baris 2 
		MOV R0,#3D                       ;Membatasi password inputan menjadi 3 digit
		MOV R1,#02AH                     ;Memasukkan address ke register 1, di mana address ini yang menjadi tempat penyimpanan input user
		ACALL DELAY1

ROTATE:		ACALL KEY_SCAN            	 ;Looping untuk menerima inputan user sebanyak 3 digit password
		MOV @R1,A                        ;Indexed Addressing untuk menyimpan inputan user ke address di R1 (#02AH)
		ACALL DWR
		ACALL DELAY2
		ACALL DELAY1
		ACALL DELAY1
		MOV A, R1
		ADD A, #1H                       ;R1 sebagai tempat penyimpanan digit-digit password inputan user
		MOV R1, A
		DJNZ R0,ROTATE
		RET

CHECK_PASS:	MOV R0,#3D        		 ;Fungsi untuk melakukan pengecekan password user benar atau salah
		MOV R1,#02AH                     ;Memasukkan R1 dengan alamat tempat penyimpanan input user
		MOV DPTR,#PASSW                  ;Meload password yang valid untuk dibandingkan dengan input user

RPT:	CLR A                            ;Sub-bagian subroutine CHECK_PASS ini, berfungsi sebagai looping pengecekan password
	MOVC A,@A+DPTR                   ;Meload A dengan data pointer merujuk ke password yang valid di #PASSW
	XRL A,@R1                        ;Melakukan komparasi password dengan XOR 
	JNZ FAIL                         ;Jika password ada yang tidak cocok, maka FAIL, LCD menampilkan password invalid dan meminta input ulang
	INC R1                           ;Increment alamat untuk mengecek digit berikutnya
	INC DPTR
	DJNZ R0,RPT                      ;Mengecek setiap digit password
	ACALL CLRSCR                     ;Clear Screen untuk persiapan menampilkan ke LCD hasil pengecekan
	;ACALL LINE1
	MOV DPTR,#SUCCESS1               ;Bagian ini, TEXT_S1 dan TEXT_S2 menunjukkan bahwa password user benar, dan alarm akan mati
	ACALL PRINT_LCDK
	ACALL LINE2                      ;Pindah ke baris kedua untuk mencetak TEXT_S2
	ACALL DELAY1
	SETB P2.0
	MOV DPTR,#SUCCESS2
	ACALL PRINT_LCDK
	ACALL DELAY1
	LJMP TURNOFF                     ;Mematikan Alarm dan Buzzer dengan TURNOFF
	SJMP GOBACK                      ;Alarm dan Buzzer dan LED mati, program keluar kembali ke MAIN2 untuk kembali ke state awal (scanning)

FAIL:	ACALL CLRSCR                     ;Sub-bagian subroutine CHECK_PASS ini, TEXT_F1 dan TEXT_F2 menandakan bahwa password user invalid dan diminta retry
	ACALL LINE1
	MOV DPTR,#FAILED1
	ACALL PRINT_LCDK
	ACALL DELAY1
	ACALL LINE2
	MOV DPTR,#FAILED2
	ACALL PRINT_LCDK
	ACALL DELAY1
	LJMP KEYMAIN                     ;Kembali ke bagian untuk meminta ulang / retry input password
	GOBACK:                          ;Return / Kembali dari subroutine CHECK_PASS
	RET

KEY_SCAN:	MOV P3,#11111111B      		;Fungsi Key_SCAN serta NEXT1 sampai NEXT16 merupakan fungsi pengecekan tombol keypad yang ditekan oleh user
		CLR P3.0                        ;Di mana yang pertama dicek adalah baris pertama, (pengecekan baris yaitu row scanning)
		JB P3.4, KEYCHECK1              ;Dicocokkan baris pertama tersebut dengan tiap-tiap kolomnya (column scanning)
		MOV A,#49D ;ASCII = 1           ;Misalnya koordinat yang terdeteksi yaitu baris 1 kolom 1 yaitu tombol angka 1, maka user menekan tombol angka 1
		RET                             ;Jika tombol ditekan, print ke LCD. Jika tidak, lanjutkan row scanning dan column scanning keypad dengan JB 

KEYCHECK1:  JB P3.5,KEYCHECK2             ;Pengecekan kolom 2
	    MOV A,#50D ;2                 ;Tombol angka 2
	    RET

KEYCHECK2:  JB P3.6,KEYCHECK3             ;Pengecekan kolom 3
	    MOV A,#51D ;3                 ;Tombol angka 3
	    RET

KEYCHECK3:  JB P3.7,KEYCHECK4             ;Pengecekan kolom 4
	    MOV A,#65D ;A             	  ;Tombol karakter A
	    RET

KEYCHECK4:  SETB P3.0                 	  ;Jika tidak terdeteksi pencetan di baris pertama,
	    CLR P3.1                  	  ;maka lanjut pengecekan pencetan di baris kedua 
	    JB P3.4, KEYCHECK5        	  ;Pengecekan kolom 1
	    MOV A,#52D ;4             	  ;Tombol angka 4
	    RET

KEYCHECK5:  JB P3.5,KEYCHECK6             ;Pengecekan kolom 2
	    MOV A,#53D ;5                 ;Tombol angka 5
	    RET

KEYCHECK6:  JB P3.6,KEYCHECK7             ;Pengecekan kolom 3
	    MOV A,#54D ;6                 ;Tombol angka 6
	    RET

KEYCHECK7:  JB P3.7,KEYCHECK8             ;Pengecekan kolom 4
	    MOV A,#66D ;B                 ;Tombol karakter B
	    RET

KEYCHECK8:  SETB P3.1                     ;Lanjut ke baris 3
	    CLR P3.2
	    JB P3.4, KEYCHECK9            ;Pengecekan kolom 1
	    MOV A,#55D                    ;Tombol angka 7
	    RET

KEYCHECK9:  JB P3.5,KEYCHECK10            ;Pengecekan kolom 2
	    MOV A,#56D                    ;Tombol angka 8
	    RET

KEYCHECK10: JB P3.6,KEYCHECK11            ;Pengecekan kolom 3
	    MOV A,#57D                    ;Tombol angka 9
	    RET

KEYCHECK11: JB P3.7,KEYCHECK12            ;Pengecekan kolom 4
	    MOV A,#67D                    ;Tombol karakter C
	    RET

KEYCHECK12: SETB P3.2                     ;Baris terakhir
	    CLR P3.3
	    JB P3.4, KEYCHECK13           ;Pengecekan kolom 1
	    MOV A,#42D                    ;Tombol karakter *
	    RET

KEYCHECK13: JB P3.5,KEYCHECK14            ;Pengecekan kolom 2
	    MOV A,#48D                    ;Tombol angka 0
	    RET

KEYCHECK14: JB P3.6,KEYCHECK15            ;Pengecekan kolom 3
	    MOV A,#35D                    ;Tombol karakter #
	    RET

KEYCHECK15: JB P3.7,KEYCHECK16            ;Pengecekan kolom 4
	    MOV A,#68D                    ;Tombol karakter D
	    RET

KEYCHECK16: LJMP KEY_SCAN                 ;Jika tidak ada tombol terpencet, mengulangi dan loop terus untuk pengecekan tombol

INIT_CODES:  DB 0CH,01H,06H,80H,3CH,0 ;Konfigurasi LCD untuk dimasukkan menggunakan LCD_INIT dan CMD
PASSW: DB 49D,49D,51D,0               ;Password yang dipakai yaitu 113
;Kalimat-kalimat yang akan dicetak ke LCD, menggunakan data byte dan 0 sebagai penanda akhir kalimat
CHECKMSG: DB 'CHECKING PASSWORD',0
INPUTMSG: DB 'INPUT 3 DIGITS',0
SUCCESS1: DB 'PASSWORD VALID',0
SUCCESS2: DB 'ALARM INACTIVE',0
FAILED1: DB 'PASSWORD INVALID',0
FAILED2: DB 'TRY AGAIN',0
TEXTSENSOR: DB 'SENSOR',0
TEXTSCANNING: DB 'SCANNING..',0
TEXTALERT: DB 'ALERT!!',0
END