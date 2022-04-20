#ifndef LCDDRIVER_H_
#define LCDDRIVER_H_

//constants
#define FUNCTIONSET1 0x33
#define FUNCTIONSET2 0x32
#define _4BIT2LINEMODE 0x28
#define CURSORDISPLAYSHIFT 0x0F
#define SHIFTCURSOR 0x06
#define CLEARDISPLAY 0x01
#define NEWLINE 0xC0

#define slaveAddress 0x27
#define sysClkMhz 200
#define I2CClkKHz 12

void LCD_Init();

void LCD_Send_Command(Uint16 command);

void LCD_Send_Char(Uint16 data);

void LCD_String(char str[], Uint16 length);

#endif
