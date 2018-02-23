#include <p10f200.inc>
    
    __CONFIG _WDTE_OFF & _CP_OFF & _MCLRE_ON
    
tmp1	    EQU	10h
tmp2	    EQU	11h
tmp3	    EQU	12h
tmp4	    EQU	13h
trisShadow  EQU	14h
  
  org	0x00
  
  clrf	GPIO		    ;set all output pins to '0'
  
  movlw	0Fh		    ;set all pins as input
  movwf	trisShadow
  tris	6
  
  movlw	088h
  option		    ;Enable weak internal pull ups
  
main	movlw	01Bh	    ;there are 28 init bytes for SSD1306
	movwf	tmp3
cmd	call	I2CStart
	
	movlw	078h	    ;SSD1306 I2C Address
	call	TransmitByte
	call	SlaveAck
	
	movlw	000h	    ;0x00 indicates a command byte
	call	TransmitByte
	call	SlaveAck
	
	movfw	tmp3
	call	InitData    ;load next init byte
	call	TransmitByte
	call	SlaveAck
	
	call	I2CStop
	
	decf	tmp3,f
	btfss	tmp3,7	    ;check if end of loop is reached
	goto	cmd
	
clear	call	I2CStart    ;loop to clear the whole screen
	
	movlw	078h
	call	TransmitByte
	call	SlaveAck
	
	movlw	040h
	call	TransmitByte
	call	SlaveAck
	
refill	movlw	080h
	movwf	tmp3
	incf	tmp4,f
	
loop	movlw	000h	    ;send '0' to clear the screen
	call	TransmitByte
	call	SlaveAck
	
	decfsz	tmp3
	goto	loop
	
	btfss	tmp4,3	    ;stop if loop reached 8*128 (cleared every pixel then)
	goto	refill
	
	call	I2CStop
	
drawC	call	I2CStart    ;draws a square on the screen
	
	movlw	078h
	call	TransmitByte
	call	SlaveAck
	
	movlw	040h	    ;0x40 indicates a data byte
	call	TransmitByte
	call	SlaveAck
	
	movlw	05h	    ;square has 6 bytes to send
	movwf	tmp3
	
	clrf	tmp4
	
dLoop	movfw	tmp3
	
	call	SquareData  ;fetch next data byte
	call	TransmitByte
	call	SlaveAck
	
	decf	tmp3,f
	btfss	tmp3,7	    ;check if end is reached
	goto	dLoop
	
	call	I2CStop
	
	goto	clear	    ;jump to clear the screen again
	
;Generate Clock for Slave Ack
SlaveAck:
    call    GP1On
    call    GP0On
    call    GP0Off
    retlw   0
    
;GP1 is Data Line (SDA)
GP1On:
    bsf	    trisShadow,1
    movfw   trisShadow
    tris    6
    retlw   0
    
GP1Off:
    bcf	    trisShadow,1
    movfw   trisShadow
    tris    6
    retlw   0
    
;GP0 is Clock Line (SCL)
GP0On:
    bsf	    trisShadow,0
    movfw   trisShadow
    tris    6
    retlw   0
    
GP0Off:
    bcf	    trisShadow,0
    movfw   trisShadow
    tris    6
    retlw   0
    
;Generates an I2C start condition
I2CStart:
    call    GP1Off
    call    GP0Off
    retlw   0
    
;Generates an I2C stop condition
I2CStop:
    call    GP1Off
    call    GP0On
    call    GP1On
    retlw   0
    
TransmitByte:	movwf	tmp1	;tmp1 containsn the byte to be sent
		movlw	08h
		movwf	tmp2
sr  call    GP0Off		;clock falling edge
    rlf	    tmp1,f		;shift tmp1 to the left (affects carry bit)
    btfss   STATUS,C		;check carry
    call    GP1Off		;turn pin to '0' if carry = '0'
    btfsc   STATUS,C
    call    GP1On		;turn pin to '1' if carry = '1'
    call    GP0On		;clock rising edge
    decfsz  tmp2		;decrement loop variable
    goto    sr
    call    GP0Off		;falling edge of the last bit
    retlw   0
    
;init Sequence of the SSD1306 (video description)
InitData:
    addwf   PCL,F   ;add w-register to program counter
    retlw   0AFh
    retlw   014h
    retlw   08Dh
    retlw   020h
    retlw   0DBh
    retlw   012h
    retlw   0DAh
    retlw   022h
    retlw   0D9h
    retlw   0F0h
    retlw   0D5h
    retlw   000h
    retlw   0D3h
    retlw   0A4h
    retlw   03Fh
    retlw   0A8h
    retlw   0A6h
    retlw   0A1h
    retlw   03Fh
    retlw   081h
    retlw   040h
    retlw   010h
    retlw   000h
    retlw   0C8h
    retlw   0B0h
    retlw   000h
    retlw   020h
    retlw   0AEh
    
;Bytes to print a square
SquareData:
    addwf   PCL,F
    retlw   07Fh
    retlw   07Fh
    retlw   07Fh
    retlw   07Fh
    retlw   07Fh
    retlw   07Fh
    
    END
    