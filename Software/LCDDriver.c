#include <F28x_Project.h>
#include <OneToOneI2CDriver.h>
#include "LCDDriver.h"

//send command to LCD using I2C driver
void LCD_Send_Command(Uint16 command) {
    //split command into nibbles
    Uint16 highByte = (command & 0b11110000);
    Uint16 lowByte = (command & 0b00001111)<<4;
    //two states being sent
    Uint16 enLow = 0b1000;
    Uint16 enHigh = 0b1100;
    //send data
    Uint16 data[] = {(highByte | enHigh),(highByte | enLow),(lowByte | enHigh),(lowByte | enLow)};
    I2C_O2O_SendBytes(data, 4);
}

//send character to LCD using I2C driver
void LCD_Send_Char(Uint16 data) {
    //split command into nibbles
    Uint16 highByte = (data & 0b11110000);
    Uint16 lowByte = (data & 0b00001111)<<4;
    //two states being sent
    Uint16 enLow = 0b1001;
    Uint16 enHigh = 0b1101;
    //send data
    Uint16 _data[] = {(highByte | enHigh),(highByte | enLow),(lowByte | enHigh),(lowByte | enLow)};
    I2C_O2O_SendBytes(_data, 4);
}

//send char string to LCD
void LCD_String(char str[], Uint16 length) {
    for (Uint16 i = 0; i < length; i++) {
        LCD_Send_Char(str[i]);
    }
}

void LCD_Init() {
    EALLOW;

    I2C_O2O_Master_Init(slaveAddress, sysClkMhz, I2CClkKHz);
    LCD_Send_Command(FUNCTIONSET1);
    LCD_Send_Command(FUNCTIONSET2);
    LCD_Send_Command(_4BIT2LINEMODE);
    LCD_Send_Command(CURSORDISPLAYSHIFT);
    LCD_Send_Command(CLEARDISPLAY);
}
