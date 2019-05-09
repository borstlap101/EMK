    list p=PIC18F45K22
    #include "p18f45K22.inc"

    ;--- Configuration bits ---
    CONFIG  FOSC = INTIO67        ; Oscillator Selection bits (Internal oscillator block, port function on RA6 and RA7)
    CONFIG  WDTEN = OFF           ; Watchdog Timer Enable bit (WDT is controlled by SWDTEN bit of the WDTCON register)
    CONFIG  LVP	= ON              ; Low voltage programming
    ;--- Configuration bits ---
    
    global  PWM
    global  PWMISR

    extern  Average1
    extern  trans
    extern  tenmsDelay

    ORG     0x00
    GOTO    setup

    ORG     0x08
    BTFSC   PIR1,TMR2IF
    CALL    PWMISR,FAST
    RETFIE


setup
    BSF		OSCCON,IRCF0
    BCF		OSCCON,IRCF1
    BSF		OSCCON,IRCF2   

    MOVLB	0xF		    ; Set BSR for banked SFRs
    CLRF	PORTA		; Initialize PORTA by clearing output data latches
    CLRF	LATA		; Alternate method to clear output data latches
    CLRF	TRISA		; clear bits for all pins
    BSF     TRISA,0     ; Disable digital output driver
    CLRF	ANSELA		; clear bits for all pins	
    BSF     ANSELA,0    ; Disable digital input buffer

    ;setup port for transmission
    CLRF    FSR0
    MOVLW   b'00100100'	;enable TXEN and BRGH
    MOVWF   TXSTA1
    MOVLW   b'10010000'	    ;enable serial port and continuous receive 
    MOVWF   RCSTA1
    MOVLW   D'25'
    MOVWF   SPBRG1
    CLRF    SPBRGH1
    BCF	    BAUDCON1,BRG16	; Use 8 bit baud generator
    BSF	    TRISC,TX		; make TX an output pin
    BSF	    TRISC,RX		; make RX an input pin
    CLRF    PORTC
    CLRF    ANSELC
    MOVLW   b'11011000'  	; Setup port C for serial port.

    MOVLW   0x0

    GOTO    start

start
    BSF     PORTA,7
    GOTO    PWM 
    call    Average1
    call    trans
    call    tenmsDelay

;<editor-fold defaultstate="collapsed" desc="PWM Setup">
PWMSetup:
    CLRF    CCP1CON
    MOVLW   .199
    MOVWF   PR2
    MOVLW   .179
    MOVWF   CCPR1L
    BCF	    TRISC,CCP1
    MOVLW   b'01111010'	    ;16 prescale, 16 postscale, timer off
    MOVWF   T2CON   
    MOVLW   b'00011100'	    ;.25, PWM mode
    MOVWF   CCP1CON 
    CLRF    TMR2
    BSF	    T2CON, TMR2ON
    BSF     PIE1, TMR2IE     ; enable interrupts from the timer
    bsf     INTCON,PEIE      ; Enable peripheral interrupts
    bsf     INTCON,GIE       ; Enable global interrupts
    ;write ISR that does the same thing as the polling 
	
    RETURN
    ;</editor-fold>

PWMISR
    BCF	    PIR1,TMR2IF
    CLRF    TMR2
    RETURN
    
PWM:

    CALL    PWMSetup
    return

    end