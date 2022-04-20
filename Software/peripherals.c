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
#include "AIC23.h"

// turns on AIC23 microphone
void MicOn(void) {
    uint16_t command;
    command = softpowerdown();  // Power down
    SpiaTransmit(command);
    SmallDelay();
    command = linput_volctl(LIM);   // Mute left line in
    SpiaTransmit(command);
    SmallDelay();
    command = rinput_volctl(RIM);   // Mute right line in
    SpiaTransmit(command);
    SmallDelay();
    command = lhp_volctl(LHV);       // Left headphone volume control
    SpiaTransmit(command);
    SmallDelay();
    command = rhp_volctl(RHV);       // Right headphone volume control
    SpiaTransmit(command);
    SmallDelay();
    command = aaudpath();       // Turn on DAC and mic
    SpiaTransmit(command);
    SmallDelay();
    command = digaudiopath();       // Disable DAC mute, add de-emph
    SpiaTransmit(command);
    SmallDelay();
    command = fullpowerup();    //power up
    SpiaTransmit(command);
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

    EALLOW;

        GpioCtrlRegs.GPAPUD.bit.GPIO0 = 0;
        GpioCtrlRegs.GPAPUD.bit.GPIO1 = 0;
        GpioCtrlRegs.GPAPUD.bit.GPIO2 = 0;
        GpioCtrlRegs.GPAPUD.bit.GPIO3 = 0;

        GpioCtrlRegs.GPAGMUX1.bit.GPIO0 = 0;
        GpioCtrlRegs.GPAGMUX1.bit.GPIO1 = 0;
        GpioCtrlRegs.GPAGMUX1.bit.GPIO2 = 0;
        GpioCtrlRegs.GPAGMUX1.bit.GPIO3 = 0;

        GpioCtrlRegs.GPAMUX1.bit.GPIO0 = 0;
        GpioCtrlRegs.GPAMUX1.bit.GPIO1 = 0;
        GpioCtrlRegs.GPAMUX1.bit.GPIO2 = 0;
        GpioCtrlRegs.GPAMUX1.bit.GPIO3 = 0;

        GpioCtrlRegs.GPADIR.bit.GPIO0 = 0;
        GpioCtrlRegs.GPADIR.bit.GPIO1 = 0;
        GpioCtrlRegs.GPADIR.bit.GPIO2 = 0;
        GpioCtrlRegs.GPADIR.bit.GPIO3 = 0;
}

// return current state as selected by absolute encoder
state_t GetState(void) {
    state_t current_state;
    // get GPIO
    Uint16 data = (GpioDataRegs.GPADAT.all) & 0xF;
    // select state
    switch(data) {
        case 9:
            current_state = VOCODER;
            break;
        case 12:
            current_state = THEREMIN_PS;
            break;
        case 13:
            current_state = AUDIO_PS;
            break;
        case 14:
            current_state = THEREMIN;
            break;
        case 15:
            current_state = AUDIO;
            break;
        default:
            current_state = UNDEF;
            break;
    }
    return current_state;
}

// Turn on line input
void LineOn(void) {
    uint16_t command;
    command = nomicaaudpath();  // Power down
    SpiaTransmit(command);
    SmallDelay();
}
