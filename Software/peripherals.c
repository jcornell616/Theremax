/*
 * peripherals.c
 * Jackson Cornell
 *
 * Functions to initialize AIC23 microphone and TMS320 ADCs, as well as start conversion for ADCA0-2
 */

#include <stdint.h>
#include <F28x_Project.h>
#include "peripherals.h"
#include "InitAIC23.h"

// turns on AIC23 microphone
void MicOn(void) {
    uint16_t command;
    command = softpowerdown();  // Power down
    SpiTransmit(command);
    SmallDelay();
    command = linput_volctl(LIM);   // Mute left line in
    SpiTransmit(command);
    SmallDelay();
    command = rinput_volctl(RIM);   // Mute right line in
    SpiTransmit(command);
    SmallDelay();
    command = lhp_volctl(LHV);       // Left headphone volume control
    SpiTransmit(command);
    SmallDelay();
    command = rhp_volctl(RHV);       // Right headphone volume control
    SpiTransmit(command);
    SmallDelay();
    command = aaudpath();       // Turn on DAC and mic
    SpiTransmit(command);
    SmallDelay();
    command = digaudiopath();       // Disable DAC mute, add de-emph
    SpiTransmit(command);
    SmallDelay();
    command = fullpowerup();    //power up
    SpiTransmit(command);
    SmallDelay();
}

// Initialize ADCASOC0-2 for 12-bit software-triggered conversion on pins ADCA0-2
void InitADCA(void) {
    EALLOW;
    //Set ADCA clock
    AdcaRegs.ADCCTL2.bit.PRESCALE = 6;
    //Set ADCA to 12-bit, single-ended
    AdcSetMode(ADC_ADCA, ADC_RESOLUTION_12BIT, ADC_SIGNALMODE_SINGLE);
    //Power up ADCA
    AdcaRegs.ADCCTL1.bit.ADCPWDNZ = 1;
    //Wait for ADCA to power up
    DELAY_US(1000);
    //Pin A0-A4
    AdcaRegs.ADCSOC0CTL.bit.CHSEL = 0;
    AdcaRegs.ADCSOC1CTL.bit.CHSEL = 1;
    AdcaRegs.ADCSOC2CTL.bit.CHSEL = 2;
    //Sample and hold window
    AdcaRegs.ADCSOC0CTL.bit.ACQPS = 14;
    AdcaRegs.ADCSOC1CTL.bit.ACQPS = 14;
    AdcaRegs.ADCSOC2CTL.bit.ACQPS = 14;
}

// Start conversion for ADCASOC0-2 with results being found in AdcaResultRegs.ADCRESULTx
void StartConversionADCA(void) {
    //Start conversion for ADCASOC0-2
    AdcaRegs.ADCSOCFRC1.all = 0b111;
}

// Initialize GPIO for absolute encoder on GPIO16-19
void InitEncoder(void) {

    EALLOW;

    GpioCtrlRegs.GPAPUD.bit.GPIO16 = 0;
    GpioCtrlRegs.GPAPUD.bit.GPIO17 = 0;
    GpioCtrlRegs.GPAPUD.bit.GPIO18 = 0;
    //GpioCtrlRegs.GPAPUD.bit.GPIO19 = 0;

    GpioCtrlRegs.GPAGMUX2.bit.GPIO16 = 0;
    GpioCtrlRegs.GPAGMUX2.bit.GPIO17 = 0;
    GpioCtrlRegs.GPAGMUX2.bit.GPIO18 = 0;
    //GpioCtrlRegs.GPAGMUX2.bit.GPIO19 = 0;

    GpioCtrlRegs.GPAMUX2.bit.GPIO16 = 0;
    GpioCtrlRegs.GPAMUX2.bit.GPIO17 = 0;
    GpioCtrlRegs.GPAMUX2.bit.GPIO18 = 0;
    //GpioCtrlRegs.GPAMUX2.bit.GPIO19 = 0;

    GpioCtrlRegs.GPADIR.bit.GPIO16 = 0;
    GpioCtrlRegs.GPADIR.bit.GPIO17 = 0;
    GpioCtrlRegs.GPADIR.bit.GPIO18 = 0;
    //GpioCtrlRegs.GPADIR.bit.GPIO19 = 0;
}

// return current state as selected by absolute encoder
state_t GetState(void) {
    state_t current_state;
    // get GPIO
    Uint16 data = (GpioDataRegs.GPADAT.bit.GPIO19)<<2 || (GpioDataRegs.GPADAT.bit.GPIO18)<<1
                || (GpioDataRegs.GPADAT.bit.GPIO17); //|| (GpioDataRegs.GPADAT.bit.GPIO16);
    // select state
    switch(data) {
        case 0:
            current_state = VOCODER;
            break;
        case 1:
            current_state = THEREMIN_PS;
            break;
        case 2:
            current_state = AUDIO_PS;
            break;
        case 3:
            current_state = THEREMIN_AUDIO;
            break;
        case 4:
            current_state = THEREMIN;
            break;
        case 5:
            current_state = AUDIO;
            break;
        default:
            current_state = UNDEF;
            break;
    }
    return current_state;
}
