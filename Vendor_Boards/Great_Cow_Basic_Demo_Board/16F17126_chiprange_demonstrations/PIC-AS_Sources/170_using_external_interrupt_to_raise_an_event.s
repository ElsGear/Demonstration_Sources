;Program compiled by Great Cow BASIC (1.00.00 Release Candidate 2022-11-06 (Windows 64 bit) : Build 1189) for Microchip PIC-AS
;  See the GCBASIC forums at http://sourceforge.net/projects/gcbasic/forums,
;  Check the documentation and Help at http://gcbasic.sourceforge.net/help/,
;or, email:
;   evanvennn at users dot sourceforge dot net

;********************************************************************************


;Set up the assembler options (Chip type, clock source, other bits and pieces)
;PROCESSOR   16F17126
 PAGEWIDTH   180
 RADIX       DEC
 TITLE       "d:\GreatCowBASICGits\Demonstration_Sources.git\trunk\Vendor_Boards\Great_Cow_Basic_Demo_Board\16F17126_chiprange_demonstrations\170_using_external_interrupt_to_raise_an_event.s"
 SUBTITLE    "11-14-2022"

; Reverse lookup file(s)
; C:\Program Files\Microchip\xc8\v2.40\pic\include\proc\pic16f17126.inc
; C:\Program Files\Microchip\xc8\v2.40\pic\dat\cfgmap\16f17126.cfgmap
; Alternative CONFIG file is to be found at C:\Program Files\Microchip\xc8\vX.YY\pic\dat\cfgdata as per Microchip support ticket #00730936 

;********************************************************************************

;********************************************************************************
;Explicit CONFIG
 CONFIG FCMEN=ON                                 ;C1 Reverselookup FCMEN = ON
 CONFIG CLKOUTEN=OFF                             ;C1 Reverselookup CLKOUTEN = OFF
 CONFIG RSTOSC=HFINTOSC_32MHz                    ;C1 Reverselookup RSTOSC = HFINTOSC_32MHZ
 CONFIG FEXTOSC=OFF                              ;C1 Reverselookup FEXTOSC = OFF
 CONFIG MCLRE=INTMCLR                            ;C1 Reverselookup MCLRE = INTMCLR
 CONFIG WDTE=OFF                                 ;C1 Reverselookup WDTE = OFF
 CONFIG LVP=OFF                                  ;C1 Reverselookup LVP = OFF
 CONFIG WRTSAF=OFF                               ;C1 Reverselookup WRTSAF = OFF
 CONFIG WRTD=OFF                                 ;C1 Reverselookup WRTD = OFF
 CONFIG WRTB=OFF                                 ;C1 Reverselookup WRTB = OFF
 CONFIG CPD=OFF                                  ;C1 Reverselookup CPD = OFF
 CONFIG CP=OFF                                   ;C1 Reverselookup CP = OFF
;Inferred CONFIG


;********************************************************************************
; The XC8 xc.inc include file.  This MUST be placed after the CONFIG statements.

 #include <xc.inc>

;********************************************************************************

;Set aside RAM memory locations for variables. All variables are global.
GLOBAL	DELAYTEMP
 DELAYTEMP                        EQU 112          ; 0X70
GLOBAL	DELAYTEMP2
 DELAYTEMP2                       EQU 113          ; 0X71
GLOBAL	SAVEDELAYTEMP
 SAVEDELAYTEMP                    EQU 32          ; 0X20
GLOBAL	SAVEDELAYTEMP2
 SAVEDELAYTEMP2                   EQU 33          ; 0X21
GLOBAL	SAVEPCLATH
 SAVEPCLATH                       EQU 34          ; 0X22
GLOBAL	SAVESYSTEMP1
 SAVESYSTEMP1                     EQU 35          ; 0X23
GLOBAL	SYSBITVAR0
 SYSBITVAR0                       EQU 36          ; 0X24
GLOBAL	SYSBSR
 SYSBSR                           EQU 37          ; 0X25
GLOBAL	SYSSTATUS
 SYSSTATUS                        EQU 127          ; 0X7F
GLOBAL	SYSTEMP1
 SYSTEMP1                         EQU 38          ; 0X26
GLOBAL	SYSW
 SYSW                             EQU 126          ; 0X7E
GLOBAL	SYSWAITTEMPUS
 SYSWAITTEMPUS                    EQU 117          ; 0X75
GLOBAL	SYSWAITTEMPUS_H
 SYSWAITTEMPUS_H                  EQU 118          ; 0X76

;********************************************************************************

 PSECT   PROGMEM0,delta=2, abs
 RESETVEC:
;VECTORS
	ORG	0
	PAGESEL	BASPROGRAMSTART
	GOTO	BASPROGRAMSTART
	ORG	4
GLOBAL	INTERRUPT
INTERRUPT:

;********************************************************************************

;SAVE CONTEXT
	MOVWF	SYSW
	SWAPF	STATUS,W
	MOVWF	SYSSTATUS
	MOVF	BSR,W
	BANKSEL	STATUS
	MOVWF	SYSBSR
;STORE SYSTEM VARIABLES
	MOVF	SYSTEMP1,W
	MOVWF	SAVESYSTEMP1
	MOVF	DELAYTEMP2,W
	MOVWF	SAVEDELAYTEMP2
	MOVF	DELAYTEMP,W
	MOVWF	SAVEDELAYTEMP
	MOVF	PCLATH,W
	MOVWF	SAVEPCLATH
	CLRF	PCLATH
;ON INTERRUPT HANDLERS
	BANKSEL	PIE0
	BTFSS	PIE0,4
	GOTO	NOTIOCIF
	BTFSS	PIR0,4
	GOTO	NOTIOCIF
	BANKSEL	STATUS
	CALL	INTERRUPTHANDLER
	BANKSEL	PIR0
	BCF	PIR0,4
	GOTO	INTERRUPTDONE
GLOBAL	NOTIOCIF
NOTIOCIF:
;USER INTERRUPT ROUTINE
GLOBAL	INTERRUPTDONE
INTERRUPTDONE:
;RESTORE CONTEXT
;RESTORE SYSTEM VARIABLES
	BANKSEL	SAVESYSTEMP1
	MOVF	SAVESYSTEMP1,W
	MOVWF	SYSTEMP1
	MOVF	SAVEDELAYTEMP2,W
	MOVWF	DELAYTEMP2
	MOVF	SAVEDELAYTEMP,W
	MOVWF	DELAYTEMP
	MOVF	SAVEPCLATH,W
	MOVWF	PCLATH
	MOVF	SYSBSR,W
	MOVWF	BSR
	SWAPF	SYSSTATUS,W
	MOVWF	STATUS
	SWAPF	SYSW,F
	SWAPF	SYSW,W
	RETFIE

;********************************************************************************

;START OF PROGRAM MEMORY PAGE 0
	ORG	46
GLOBAL	BASPROGRAMSTART
BASPROGRAMSTART:
;CALL INITIALISATION ROUTINES
	CALL	INITSYS
;ENABLE INTERRUPTS
	BSF	INTCON,7
	BSF	INTCON,6

;START OF THE MAIN PROGRAM
;''
;'' This demonstration will provide code for raising an event when a port changes.
;'' The port that is being set then inspected in PORTA.3. Why? Because we have the switch on that port.
;''
;'' When the event happens the LED is toggled.  The LED will toggle when the Signal value is 0.
;''
;'' This does not have a proper debounce check, you can add one.
;''
;''************************************************************************
;''@author  EvanV
;''@licence GPL
;''@version 1.00
;''@date    31.10.2022
;----- Configuration
;Chip Settings.
;Chip Settings.
;' -------------------PORTA----------------
;' Bit#:  -7---6---5---4---3---2---1---0---
;' IO:   -----------------SW----------ADC--
;'-----------------------------------------
;'
;' -------------------PORTB----------------
;' Bit#:  -7---6---5---4---3---2---1---0---
;' IO:    ---------------------------------
;'-----------------------------------------
;'
;' ------------------PORTC-----------------
;' Bit#:  -7---6---5---4---3---2---1---0---
;' IO:    ---------------LED--LED-LED LED--
;'-----------------------------------------
;Define constants to make things easier. We can reuse these at any time.
;Dir     RC0         Out
	BCF	TRISC,0
;Dir     RC1         Out
	BCF	TRISC,1
;Dir     RC2         Out
	BCF	TRISC,2
;Dir     RC3         Out
	BCF	TRISC,3
;Dir     POTENTIOMETER In
	BSF	TRISA,0
;Dir     SWITCHIN      In
	BSF	TRISA,3
;*****************************************************************************************************
;Main program commences here.. everything before this is setup for the board.
;Dim SWState as BIT
;Setup an Interrupt event when switch goes negative.
;IOCAN3 = 1
	BANKSEL	IOCAN
	BSF	IOCAN,3
;On Interrupt PORTChange  Call InterruptHandler
	BANKSEL	PIE0
	BSF	PIE0,4
;Loop forever
;Do
GLOBAL	SYSDOLOOP_S1
SYSDOLOOP_S1:
;Loop
	GOTO	SYSDOLOOP_S1
GLOBAL	SYSDOLOOP_E1
SYSDOLOOP_E1:
GLOBAL	BASPROGRAMEND
BASPROGRAMEND:
	SLEEP
	GOTO	BASPROGRAMEND

;********************************************************************************

;SOURCE: SYSTEM.H (159)
GLOBAL	INITSYS
INITSYS:
;asm showdebug This code block sets the internal oscillator to ChipMHz
;asm showdebug Default settings for microcontrollers with _OSCCON1_
;Default OSCCON1 typically, NOSC HFINTOSC; NDIV 1 - Common as this simply sets the HFINTOSC
;OSCCON1 = 0x60
	MOVLW	96
	BANKSEL	OSCCON1
	MOVWF	OSCCON1
;Default value typically, CSWHOLD may proceed; SOSCPWR Low power
;OSCCON3 = 0x00
	CLRF	OSCCON3
;Default value typically, MFOEN disabled; LFOEN disabled; ADOEN disabled; SOSCEN disabled; EXTOEN disabled; HFOEN disabled
;OSCEN = 0x00
	CLRF	OSCEN
;Default value
;OSCTUNE = 0x00
	CLRF	OSCTUNE
;asm showdebug The MCU is a chip family ChipFamily
;asm showdebug OSCCON type is 102
;Set OSCFRQ values for MCUs with OSCSTAT... the 16F171xx MCU family
;OSCFRQ = 0b00000101
	MOVLW	5
	MOVWF	OSCFRQ
;asm showdebug _Complete_the_chip_setup_of_BSR,ADCs,ANSEL_and_other_key_setup_registers_or_register_bits
;Ensure all ports are set for digital I/O and, turn off A/D
;SET ADFM OFF
	BANKSEL	ADCON0
	BCF	ADCON0,2
;Switch off A/D Var(ADCON0)
;SET ADCON0.ADON OFF
	BCF	ADCON0,7
;ANSELA = 0
	BANKSEL	ANSELA
	CLRF	ANSELA
;ANSELC = 0
	CLRF	ANSELC
;Set comparator register bits for many MCUs with register CM2CON0
;C2EN = 0
	BANKSEL	CM2CON0
	BCF	CM2CON0,7
;C1EN = 0
	BCF	CM1CON0,7
;
;'Turn off all ports
;PORTA = 0
	BANKSEL	PORTA
	CLRF	PORTA
;PORTC = 0
	CLRF	PORTC
	RETURN

;********************************************************************************

;SOURCE: 170_USING_EXTERNAL_INTERRUPT_TO_RAISE_AN_EVENT.GCB (67)
GLOBAL	INTERRUPTHANDLER
INTERRUPTHANDLER:
;If IOCIF = 1 Then
	BANKSEL	PIR0
	BTFSS	PIR0,4
	GOTO	ENDIF1
;Is this our event?
;We must clear the flag in software
;IOCAF3  = 0
	BANKSEL	IOCAF
	BCF	IOCAF,3
;Save the state
;SWState = RC2
	BANKSEL	SYSBITVAR0
	BCF	SYSBITVAR0,0
	BTFSC	PORTC,2
	BSF	SYSBITVAR0,0
;Toggle the LED
;RC1 = !RC1
	CLRF	SYSTEMP1
	BTFSC	PORTC,1
	INCF	SYSTEMP1,F
	COMF	SYSTEMP1,F
	BCF	LATC,1
	BTFSC	SYSTEMP1,0
	BSF	LATC,1
;a little delay
;wait 100 us
	MOVLW	1
	MOVWF	DELAYTEMP2
GLOBAL	DELAYUSO1
DELAYUSO1:
	CLRF	DELAYTEMP
GLOBAL	DELAYUS1
DELAYUS1:
	DECFSZ	DELAYTEMP,F
	GOTO	DELAYUS1
	DECFSZ	DELAYTEMP2,F
	GOTO	DELAYUSO1
	MOVLW	9
	MOVWF	DELAYTEMP
GLOBAL	DELAYUS2
DELAYUS2:
	DECFSZ	DELAYTEMP,F
	GOTO	DELAYUS2
;Wait while SWITCHIN = SWState
GLOBAL	SYSWAITLOOP1
SYSWAITLOOP1:
	CLRW
	BTFSC	PORTA,3
	XORLW	255
	BTFSC	SYSBITVAR0,0
	XORLW	255
	BTFSC	STATUS,2
	GOTO	SYSWAITLOOP1
;End If
GLOBAL	ENDIF1
ENDIF1:
	BANKSEL	STATUS
	RETURN

;********************************************************************************

;START OF PROGRAM MEMORY PAGE 1
	PSECT	PROGMEM1,CLASS=CODE,SPACE=SPACE_CODE,DELTA=2, ABS, OVRLD 
	ORG	2048
;START OF PROGRAM MEMORY PAGE 2
	PSECT	PROGMEM2,CLASS=CODE,SPACE=SPACE_CODE,DELTA=2, ABS, OVRLD 
	ORG	4096
;START OF PROGRAM MEMORY PAGE 3
	PSECT	PROGMEM3,CLASS=CODE,SPACE=SPACE_CODE,DELTA=2, ABS, OVRLD 
	ORG	6144
;START OF PROGRAM MEMORY PAGE 4
	PSECT	PROGMEM4,CLASS=CODE,SPACE=SPACE_CODE,DELTA=2, ABS, OVRLD 
	ORG	8192
;START OF PROGRAM MEMORY PAGE 5
	PSECT	PROGMEM5,CLASS=CODE,SPACE=SPACE_CODE,DELTA=2, ABS, OVRLD 
	ORG	10240
;START OF PROGRAM MEMORY PAGE 6
	PSECT	PROGMEM6,CLASS=CODE,SPACE=SPACE_CODE,DELTA=2, ABS, OVRLD 
	ORG	12288
;START OF PROGRAM MEMORY PAGE 7
	PSECT	PROGMEM7,CLASS=CODE,SPACE=SPACE_CODE,DELTA=2, ABS, OVRLD 
	ORG	14336
;
; Declare Power-On-Reset entry point
;
 END     RESETVEC
