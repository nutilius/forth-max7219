( vim:filetype=forth:   )
( ********************* )
( words for servicing LED diplay with MAX7219 )
( using SPI interface in PIC18F4525           )
( flashforh 5.0                               )
( vctl@vctl.pl                                )

$ff94 constant trisc    
$ff9e constant pir1    
$ffc5 constant sspcon2   
$ffc6 constant sspcon1   
$ffc7 constant sspstat   
$ffc8 constant sspadd    
$ffc9 constant sspbuf    
( --- Set i/o lines --- )
( SDO --> TRISC<5> clr  )
( SCK --> TRISC<3> clr  )
( RC2 --> TRISC<2> clr  )

( --- SSPSTAT reg   --- )                             
(    b7 - SMP  - sample bit )
(         1 - inp data sampled at end )
(         0 - inp data sampled at mid )
(    b6 - CKE  - clk select bit       )
(         1 - xmit on transition from active to idle )
(         0 - xmit on transition from idle to active )
(    b5 - D/A  - only I2C )
(    b4 - P    - only I2C )
(    b3 - S    - only I2C )
(    b2 - R/#W - only I2C )
(    b1 - UA   - only i2C )
(    b0 - BF   - buffer full status )

( --- SSPCON1 reg   --- )
(    b7 - WCOL
(    b6 - SSPOV
(    b5 - SSPEN - 
(    b4 - CKP - clk polarity               )
(               1 - idle state clk is hi   )
(               0 - idle state clk is lo   )
( b3-b0 - SSPM3:SSPM0                      )
(  0101 - SPI Slave  clk=SCK #SS disables  )  
(  0100 - SPI Slave  clk=SCK #SS enabled   )  
(  0011 - SPI Master clk=TMR2/2            )  
(  0010 - SPI Master clk=FOSC/64           )  
(  0001 - SPI Master clk=FOSC/16           )  
(  0000 - SPI Master clk=FOSC/4            )  
: spi-init 
    %00101100 trisc mclr
    %01000000 sspstat c!
    %00100000 sspcon1 c!     ( For 8 Mhz - 2 Mhz transmission )
    %00001000 pir1    mclr   ( Clear MSSP interrupt flag )
;


/ wait for end of spi transmission
( wait until sspstat lowest bit is 1 )
: spi-wait begin sspstat c@ %00000001 dup rot and xor until ; 

( send byte of data to SPI waiting first for MSSP      ) 
( interrup flag set to 1 - means transfer complete     )
( assume that flag was cleared in spi-init             )
( takes one byte and leave empty stack                 )
( alternative - leave read byte on stack - remove drop )
( byte -- -)
: spi-send 
    sspbuf dup c@ drop c! 
    $08 pir1 
    begin 
        2dup     ( flag addr flag addr )
        c@       ( flag addr flag value )
        and      ( flag addr 8-if-set,0-if-clr )
    until ( wait until set )
    ( flag addr )
    mclr ( clear interrupt flag )
    sspbuf c@ drop ( remove drop to save read byte on stack )
;

( dsp-ack use bit 02 of port C to strobe LOAD )
( input in MAX7219                            )
( - -- -)
: dsp-ack 
    %00000100 portc 2dup mset 1 ms mclr 
;


( dsp-send send first addr next data to       )
( MAX serial register                         )
( addr data -- - )
: dsp-send 
    swap spi-send spi-send dsp-ack 
;


