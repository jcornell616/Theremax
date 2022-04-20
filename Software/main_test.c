#include <math.h>
#include <FPU.h>

#include <F28x_Project.h>
#include "AIC23.h"
#include "InitAIC23.h"
#include "OneToOneI2CDriver.h"
#include "LCD_lib.h"
#include "peripherals.h"
#include "LCDDriver.h"
//#include "SramSPIDriver.h"

void DMA_init(void);
interrupt void local_D_INTCH6_ISR(void);
interrupt void local_D_INTCH5_ISR(void);


interrupt void Timer1_isr(void);
void InitTimer1(void);
void InitAdca(void);

void initCFFT(void);
void initRFFT(void);
void initAll(void);

void clr_RFFT();
void clr_CFFT();

void phase_vocoder_fft(float[], float[], float[], float);
void fftshift(float[]);
void interpolation(float[], int*, float);
void unwrap_phase(float[],float[],int);

Uint16 inc_index(Uint16 i);
void outputFunc(void);

void init_testpin(void);

//BURST is number of burst - 1 in a transfer
//TRANSFER is number of bursts - 1 in a transfer
#define BURST 1
#define N (1 << FFT_STAGES)
#define TRANSFER N-1
#define TRANSFER_OUT N_out-1

#define FFT_STAGES     8
#define FFT_SIZE       (1 << FFT_STAGES)

#define MAX_OUT_SIZE N*4
#define W_LEN N
#define pi 3.14
#define N_out N*2


int16 ping[2*N], ping2[N*2], wPing[N*2]; //Buffers are 2*N because we are storing left and right channel audio
int16 pong[2*N_out], pong2[2*N_out];
float hann[N], prev[2*N], curr[2*N];
float in_buff_float[N], out_buff_float[N], temp[N], cir_out_buff[N_out];
float psi[N],phi[N];

//These three are used for interpolation function, with max size set for minimum stretch of 0.5
float x_ext[N_out];
float t[N_out];
float dt[N_out];
float y[N_out];

char* output = "Test Output";

#pragma DATA_SECTION(ping, "ramgs0"); //move ping pong buffers into data section
#pragma DATA_SECTION(ping2, "ramgs0");
#pragma DATA_SECTION(pong, "ramgs1");
#pragma DATA_SECTION(pong2, "ramgs15");
#pragma DATA_SECTION(prev, "ramgs2");
#pragma DATA_SECTION(curr, "ramgs2");
#pragma DATA_SECTION(hann, "ramgs3");
#pragma DATA_SECTION(wPing, "ramgs3");
#pragma DATA_SECTION(psi, "ramgs9");
#pragma DATA_SECTION(phi, "ramgs9");
#pragma DATA_SECTION(x_ext, "ramgs9");
#pragma DATA_SECTION(t, "ramgs10");
#pragma DATA_SECTION(dt, "ramgs11");
#pragma DATA_SECTION(y, "ramgs12");
#pragma DATA_SECTION(in_buff_float, "ramgs13");
#pragma DATA_SECTION(out_buff_float, "ramgs13");
#pragma DATA_SECTION(temp, "ramgs13");
#pragma DATA_SECTION(cir_out_buff, "ramgs14");

// RFFT STUFF
float RFFTinBuff[FFT_SIZE];
float RFFTmagBuff[FFT_SIZE/2+1];
float RFFTphaseBuff[FFT_SIZE/2+1];
float RFFToutBuff[FFT_SIZE];
float RFFTF32Coef[FFT_SIZE];

#pragma DATA_SECTION(RFFTinBuff,"ramgs4");
#pragma DATA_SECTION(RFFTmagBuff,"ramgs5");
#pragma DATA_SECTION(RFFToutBuff,"ramgs5");
#pragma DATA_SECTION(RFFTF32Coef,"ramgs6");
#pragma DATA_SECTION(RFFTphaseBuff,"ramgs6");

RFFT_F32_STRUCT rfft;
//RFFT_F32_STRUCT_Handle hnd_rfft = &rfft;

// CFFT STUFF
float CFFTin1Buff[FFT_SIZE*2];
float CFFTin2Buff[FFT_SIZE*2];
float CFFToutBuff[FFT_SIZE*2];
float CFFTF32Coef[FFT_SIZE];

#pragma DATA_SECTION(CFFTin1Buff,"ramgs7")
#pragma DATA_SECTION(CFFTin2Buff,"ramgs7")
#pragma DATA_SECTION(CFFToutBuff,"ramgs8")
#pragma DATA_SECTION(CFFTF32Coef,"ramgs8")

CFFT_F32_STRUCT cfft;
//CFFT_F32_STRUCT_Handle hnd_cfft = &cfft;


volatile int16 *ptrPing, *ptrPong, *ptrProcPing, *ptrProcPong; //pointer points to float values
volatile Uint16 ptrInFlag= 0;
volatile Uint16 ptrOutFlag = 0;
volatile TransferDoneFlag = 0;
volatile Uint16 wrapFlag = 0;
volatile Uint16 LCDupdate = 1;
volatile Uint16 index = 0;
volatile float stretch = 0.8f;
volatile state_t current_state = UNDEF;
// bin size =  Fs/N = 48k/256 = 187.5 Hz/bin


volatile Uint16 AdcData0 = 0;
volatile Uint16 AdcData1 = 0;

/*************** MyVariables *****************/
volatile float volume = 1.0f;
volatile float mix = 1.0f;
volatile float pitch = 1.0f;
/*********************************************/

/*************** MyFunctions *****************/
void UpdateSystemState(void);
void GetParameters(void);
/*********************************************/

int main(void)
{
    //set pointers to ping pong buffers
    ptrPing = (int16 *)&ping;
    ptrPong = (int16 *)&pong;

//-------------------------------------------------------------------------------------------------------------------------
    // hann window array
    for(Uint16 i=0; i<FFT_SIZE; i++) // for single channel audio
    {
        hann[i] = 0.5f*(1-cosf( 2.0f*3.14159f*i/( (float)((FFT_SIZE)-1) ) )); //Calculate hanning coeffs
        phi[i] = 0;
        psi[i] = 0;
    }

//-------------------------------------------------------------------------------------------------------------------------
    //initialize the timers, clocks, interrupts, ADC, Timer1, codec, McBSP, FFTs, and DMA
    initAll();
    //init_testpin();

    LCD_String("Test Out", 8);
//-------------------------------------------------------------------------------------------------------------------------

    while(1)
    {
        //GpioDataRegs.GPBSET.bit.GPIO56 = 1;//Turn test pin on

        if(LCDupdate)
        {
            UpdateSystemState();
            GetParameters();
        }
        /*if(TransferDoneFlag == 1) //DMA now takes longer than FFT
        {

            //save first half of current ping to last half of wPing
            /*for(Uint16 i=0; i<N; i++)
            {
                wPing[i+N] = ptrProcPing[i];
            }

        //-------------------------------------------------------------------------------------------------------------------------
            // Current Buff Phase vocoder
            for(Uint16 i=0; i<FFT_SIZE; i++) //Get current input
            {
                in_buff_float[i] = ( ( (float)ptrProcPing[2*i]*hann[i] + (float)ptrProcPing[(2*i)+1]*hann[i] ) / 2 );//avg L and R channel audio
            }
            clr_RFFT();
            clr_CFFT();

            int len = N;
            phase_vocoder_fft(in_buff_float, phi, psi, stretch); //Perform phase vocoder on input
            interpolation(in_buff_float, &len, stretch); //interpolate phase vocoder output, interpolated data is stored in y

            //store result of phase vocoder into the current buffer for overlap add
            for(Uint16 i=0; i<len; i++)
            {
                curr[i] = y[i];
            }

        //-------------------------------------------------------------------------------------------------------------------------

        //-------------------------------------------------------------------------------------------------------------------------
            // Window Phase Vocoder

            //Get window input
            for(Uint16 i=0; i<N; i++)
            {
                in_buff_float[i] = ( ( (float)wPing[2*i]*hann[i] + (float)wPing[(2*i)+1]*hann[i+1] ) / 2 ); //avg L and R channel audio (window buffer)
            }
            clr_RFFT();
            clr_CFFT();

            len = N;
            phase_vocoder_fft(in_buff_float, phi, psi, stretch); //Perform phase vocoder on input
            interpolation(in_buff_float, &len, stretch); //interpolate phase vocoder output, interpolated data is stored in y

            for(Uint16 i = 0; i < len/2; i++) //Perform overlap add
            {
                cir_out_buff[index] = (y[i]) + (prev[i+len/2]); //1st half of window added with 2nd half of prev
                index = inc_index(index);
                if(wrapFlag == 1)
                {
                    outputFunc();
                    wrapFlag = 0;
                }
            }

            for(Uint16 i = 0; i < len/2; i++)
            {
                cir_out_buff[index] = (y[i+len/2]) + (curr[i]); //2nd half of window added with 1st half of curr
                index = inc_index(index);
                if(wrapFlag == 1)
                {
                    outputFunc();
                    wrapFlag = 0;
                }
            }
        //-------------------------------------------------------------------------------------------------------------------------

            // save last half of current ping to 1st half of wPing
            for(Uint16 i=0; i<N; i++)
            {
                wPing[i] = ptrProcPing[i+N];
            }

            //store the current processed data buffer to be used for the next iteration
            for(Uint16 i=0; i<N; i++)
            {
                prev[i] = curr[i];
            }

        //--------------------------------------------------------------------------------------------------------------------------
            TransferDoneFlag = 0;
        }*/
        soft_del(100);
        //GpioDataRegs.GPBSET.bit.GPIO56 = 0;//Turn test pin off
     }
}

void outputFunc(void)
{
    for(Uint16 i=0; i<N_out*2; i += 2)//Overlap add output -> DMA
    {
        ptrProcPong[i] = (int16)(cir_out_buff[i/2]);
        ptrProcPong[i+1] = ptrProcPong[i]; // output to both channels
    }
}

void initCFFT(void)
{
    cfft.FFTSize   = FFT_SIZE;
    cfft.Stages    = FFT_STAGES;
    cfft.InPtr     = &CFFTin1Buff[0];  //Input buffer
    cfft.OutPtr    = &CFFToutBuff[0];  //Output buffer

    cfft.CoefPtr = &CFFTF32Coef[0];  //Twiddle factor buffer
    CFFT_f32_sincostable(&cfft);       //Calculate twiddle factor
}

void initRFFT(void)
{
    rfft.FFTSize   = FFT_SIZE;
    rfft.FFTStages = FFT_STAGES;
    rfft.InBuf     = &RFFTinBuff[0];  //Input buffer
    rfft.OutBuf    = &RFFToutBuff[0];  //Output buffer

    rfft.MagBuf    = &RFFTmagBuff[0];  //Magnitude buffer
    rfft.PhaseBuf  = &RFFTphaseBuff[0];  //Phase buffer

    rfft.CosSinBuf = &RFFTF32Coef[0];  //Twiddle factor buffer
    RFFT_f32_sincostable(&rfft);         //Calculate twiddle factor
}

void initAll(void)
{
    initRFFT();
    initCFFT();
    // Turn off watchdog timer
        // Set clock to 200MHz
            // Turn on peripheral clocks
    InitSysCtrl();
    //LCD_Init();
    // Disable global interrupt
    DINT;

    // Initialize PIE
        // Disable all interrupt groups and clears all interrupt flags
            // Initialize PIE vector table
    InitPieCtrl();
    IER = 0x0000;
    IFR = 0x0000;
    InitPieVectTable();

    // Initialize codec and McBSP
    InitSPIA();
    InitAIC23(DSP_16b);
    InitMcBSPb(DSP_16b);

    DMA_init();

    //InitTimer1();       // Initialize CPU timer 1
    InitAdca();         // Initialize ADC A channel 0

    InitEncoder();
}

void InitAdca(void)
{
    AdcaRegs.ADCCTL2.bit.PRESCALE = 6;                                 // Set ADCCLK to SYSCLK/4
    AdcSetMode(ADC_ADCA, ADC_RESOLUTION_12BIT, ADC_SIGNALMODE_SINGLE); // Initializes ADCA to 12-bit and single-ended mode. Performs internal calibration
    AdcaRegs.ADCCTL1.bit.ADCPWDNZ = 1;                                 // Powers up ADC
    soft_del(1000);
    AdcaRegs.ADCSOC0CTL.bit.CHSEL = 0;                                 // Sets SOC0 to channel 0 -> pin ADCINA0
    AdcaRegs.ADCSOC0CTL.bit.ACQPS = 14;                                // Sets sample and hold window -> must be at least 1 ADC clock long
}

void InitTimer1(void)
{
    InitCpuTimers();                            // Initialize all timers to known state
    ConfigCpuTimer(&CpuTimer1, 200, 500000);    // Configure CPU timer 1. 200 -> SYSCLK in MHz, 500000 -> period in usec. NOTE: Does NOT start timer
    PieVectTable.TIMER1_INT = &Timer1_isr;      // Assign timer 1 ISR to PIE vector table
    IER |= M_INT13;                             // Enable INT13 in CPU
    EnableInterrupts();                         // Enable PIE and CPU interrupts
    CpuTimer1.RegsAddr->TCR.bit.TSS = 0;        // Start timer 1
}

void DMA_init(void)
{
    EALLOW;

    // Set DMA transfer completes interrupts to ISR
    PieVectTable.DMA_CH6_INT= &local_D_INTCH6_ISR;
    PieVectTable.DMA_CH5_INT= &local_D_INTCH5_ISR;

    // Performs a hard reset on the DMA
    DMAInitialize();

    // source and destination pointers
    volatile Uint16 *DMA_CH6_Source = (volatile Uint16 *)&McbspbRegs.DRR2.all;
    volatile Uint16 *DMA_CH6_Dest = (volatile Uint16 *)ptrPing;

    volatile Uint16 *DMA_CH5_Source = (volatile Uint16 *)ptrPong;
    volatile Uint16 *DMA_CH5_Dest = (volatile Uint16 *)&McbspbRegs.DXR2.all;

    // Initialize source and destination addresses
    DMACH6AddrConfig(DMA_CH6_Dest,DMA_CH6_Source);
    DMACH5AddrConfig(DMA_CH5_Dest,DMA_CH5_Source);

    // Configures the burst size and source/destination step size
    // Burst size is 2 16-bit words (1 + 1)
    // Source address increments by 1 after word is transmitted (DRR2 -> DRR1)
    // Destination address increments by 1 after word is transmitted (DXR2 -> DXR1)
    DMACH6BurstConfig(BURST,1,1);
    DMACH5BurstConfig(BURST,1,1);

    // Configures the transfer size and source/destination step size
    DMACH6TransferConfig(TRANSFER,0xFFFF,1);
    DMACH5TransferConfig(TRANSFER_OUT,1,0xFFFF);

    // Configures source and destination wrapping
    // Source/Destination wrapping doesn't matter -> set to 0xFFFF so it's ignored
    DMACH6WrapConfig(0xFFFF, 0xFFFF, 0xFFFF, 0xFFFF);
    DMACH5WrapConfig(0xFFFF, 0xFFFF, 0xFFFF, 0xFFFF);

    // CH6 mode configuration:
    // Burst triggers after McBSPb RX, oneshot disabled, continuous mode enable
    // 16-bit data, interrupt enabled, interrupt triggers at end of transfer
    // CH5 mode configuration:
    // Burst triggers after McBSPb TX, oneshot disabled, continuous mode enable
    // 16-bit data, interrupt enabled, interrupt triggers at end of transfer
    DMACH6ModeConfig(74,PERINT_ENABLE,ONESHOT_DISABLE,CONT_ENABLE,       //74 -> MREVTB -> receive ready flag
                     SYNC_DISABLE,SYNC_SRC,OVRFLOW_DISABLE,SIXTEEN_BIT,
                     CHINT_END,CHINT_ENABLE);
    DMACH5ModeConfig(74,PERINT_ENABLE,ONESHOT_DISABLE,CONT_ENABLE,
                     SYNC_DISABLE,SYNC_SRC,OVRFLOW_DISABLE,SIXTEEN_BIT,
                     CHINT_END,CHINT_ENABLE);

    // Dual ported bridge connected to DMA
    EALLOW;
    CpuSysRegs.SECMSEL.bit.PF2SEL = 1;
    EDIS;


    // Interrupt enabling (pg.95)
    // PIE group 7, interrupt 6 -> DMA CH6
    // PIE group 7, interrupt 5 -> DMA CH5
    PieCtrlRegs.PIEIER7.bit.INTx6 = 1;
    PieCtrlRegs.PIEIER7.bit.INTx5 = 1;
    IER |= M_INT7;

    // Enables the PIE
    // Clears PIEACK register
    // Enables global interrupts
    EnableInterrupts();

    // Start DMA Channels
    StartDMACH6();
    StartDMACH5();
}


// DMA ISR
interrupt void local_D_INTCH6_ISR(void) //stores audio
{
    EALLOW;

    // ACK to receive more interrupts
    PieCtrlRegs.PIEACK.all |= PIEACK_GROUP7;

    //active addr = shadow addr
    if(ptrInFlag == 0)
    {
        ptrPing = (int16 *) &ping;          //array to be filled
        ptrProcPing = (int16 *) &ping2;     //array to be processed

        ptrInFlag = 1;
    }
    else
    {
        ptrPing = (int16 *) &ping2;
        ptrProcPing = (int16 *) &ping;

        ptrInFlag = 0;
    }

    DmaRegs.CH6.DST_ADDR_SHADOW = (Uint32)ptrPing;

    TransferDoneFlag = 1;

}

interrupt void local_D_INTCH5_ISR(void) //plays audio
{
    EALLOW;

    // ACK to receive more interrupts
    PieCtrlRegs.PIEACK.all |= PIEACK_GROUP7;

    //active addr = shadow addr
    if(ptrOutFlag == 0)
    {
        ptrPong = (int16 *) &pong;
        ptrProcPong = (int16 *) &pong2;
        ptrOutFlag = 1;
    }
    else
    {
        ptrPong = (int16 *) &pong2;
        ptrProcPong = (int16 *) &pong;
        ptrOutFlag = 0;
    }

    DmaRegs.CH5.SRC_ADDR_SHADOW = (Uint32)ptrPong;

}


interrupt void Timer1_isr(void)
{
    LCDupdate = 1;                            // Flag that new data has been read
    AdcaRegs.ADCSOCFRC1.all = 0x1;          // Force conversion on channel 0
    GpioDataRegs.GPATOGGLE.bit.GPIO31 = 1;  // Toggle blue LED
    AdcData0 = AdcaResultRegs.ADCRESULT0;    // Read ADC results into global variables
    AdcData1 = AdcaResultRegs.ADCRESULT1;    // Read ADC results into global variables
}

/*------------------------------  VOCODER HELPER FUNCTIONS ------------------------------------*/

//This function actually performs the phase vocoding
void phase_vocoder_fft(float frame[], float phi[], float psi[], float stretch)
{
    //Calculate Spectrum
    fftshift(frame);

    for(Uint16 i=0; i < FFT_SIZE; i++)
    {
        RFFTinBuff[i] = frame[i];
    }

    // perform RFFT
    RFFT_f32(&rfft);

    //calculate magnitude and phase
    RFFT_f32_mag(&rfft);
    RFFT_f32_phase(&rfft);

    //Initialize + calculate dphi
    float dphi[FFT_SIZE];
    for(int i = 0; i < FFT_SIZE; i++)
    {
        dphi[i] = RFFTphaseBuff[i];
        dphi[i] = dphi[i] - phi[i] - 2*pi*i;
    }

    //unwrap phase of dphi
    unwrap_phase(dphi,dphi,W_LEN);

    //update phi and psi using dphi
    for(int i = 0; i < W_LEN; i++)
    {
        phi[i] = RFFTphaseBuff[i];

        dphi[i] = dphi[i] + 2*pi*i;
        dphi[i] *= stretch;
        psi[i] = psi[i] + dphi[i];
    }
    unwrap_phase(psi,psi,W_LEN);

    //clean CFFT buffers (or else nothing works)
    for (Uint16 i = 0; i < 2*N; i++) {
        CFFTin1Buff[i] = 0;
        CFFToutBuff[i] = 0;
    }

    // fill CFFT input with output from RFFT
    //CFFT data is alternating real+imag
    // real = mag*cos(phase), imaginary = mag*sin(phase), use psi for phase buffer

    // regular fill
    for(Uint16 i=0; i<=FFT_SIZE/2; i++)
    {
        //first half of real
        CFFTin1Buff[2*(i)] = (RFFTmagBuff[i])*(cosf(psi[i]));

        //first half of imag
        CFFTin1Buff[(2*(i))+1] = (RFFTmagBuff[i])*sinf(psi[i]);
    }


    // Preserve DC value (just mag isn't good enough, DC can be negative)
    CFFTin1Buff[0] = RFFToutBuff[0];

    // Phase here is 0 (stolen from CFFT)
    CFFTin1Buff[N+1] = 0;

    //mirror second half
    for(Uint16 i=2; i<FFT_SIZE; i+=2)
    {
        //second half of real
        CFFTin1Buff[(FFT_SIZE*2)-i] = CFFTin1Buff[i];

        //fill and negate second half of imag
        CFFTin1Buff[(FFT_SIZE*2)-i+1] = (-1)*CFFTin1Buff[(i)+1];
    }

    // perform ICFFT
    ICFFT_f32(&cfft);

    for(int i = 0; i < FFT_SIZE*2; i+=2)
    {
        frame[i/2] = CFFToutBuff[i];
    }

    fftshift(frame);

    //Clean up FFT buffer
    clr_RFFT();
    clr_CFFT();
}

//This function will perform interpolation of an array x based on input length and stretch factor
void interpolation(float* x, int* x_L, float stretch)
{
    int L = (int)floor((float)*x_L/stretch);
    //Init t
    for(int i = 0; i < L; i++)
    {
        t[i] = i;
    }
    for(int i = 0; i < *x_L; i++)
    {
        x_ext[i] = x[i];
    }
    x_ext[*x_L] = 0;

    for(int i = 0; i < L; i++)
    {
        t[i] = 1 + t[i] * (float)*x_L/(float)L; //Generate t array for stretched indeces across N original size
        dt[i] = t[i]-floor(t[i]);
    }

    for(int i = 0; i < L; i++)
    {
        t[i] = floor(t[i]) - 1;
    }

    for(int i = 0; i <= L; i++)
    {
        float temp = (1.0-dt[i]);
        y[i] = x_ext[(int)t[i]] * (1.0-dt[i]) + x_ext[(int)t[i]+1] * dt[i];
    }
    *x_L = L;
    return;
}

//unwraps phase to interval [0, 2pi] for phase vocoder
void unwrap_phase(float phi[], float phase[],int L)
{
    for(int i = 0; i < L; i++)
    {
        phase[i] = fmod((phi[i]+pi),(-2*pi)) + pi;
    }
    return;
}

//Shifts DC component of an FFT to center, modified from matlab code definition
void fftshift(float frame[])
{
    for(int i = 0 ; i < N; i++)
    {
        temp[i] = frame[i];
    }

    if(N%2 == 0) //Even case, should always be this
    {
        int index = 0;
        for (int i = N/2; i < N; i++)
        {
            temp[index] = frame[i];
            index++;
        }
        index = N/2;
        for (int i = 0; i < N/2-1; i++)
        {
            temp[index] = frame[i];
            index++;
        }
    }
    //Copy temp array to frame
    for(int i = 0; i < N; i++)
    {
        frame[i] = temp[i];
    }
    return;
}

int inc_buff(int i)
{
    i++;
    if(i >= MAX_OUT_SIZE)
    {
        return 0;
    }
    return i;
}

void clr_RFFT(void)
{
    for(int i = 0; i < FFT_SIZE; i++)
    {
        RFFTinBuff[i] = 0;
        RFFToutBuff[i] = 0;
        if(i < FFT_SIZE/2)
        {
            RFFTphaseBuff[i] = 0;
            RFFTmagBuff[i] = 0;
        }
    }
}


void clr_CFFT(void)
{
    for(int i = 0; i < FFT_SIZE*2; i++)
    {
        CFFTin1Buff[i*2] = 0;
        //CFFTin2Buff[i*2] = 0;
        //CFFToutBuff[i*2] = 0;
    }
}

Uint16 inc_index(Uint16 i) //wrap around circular output buffer
{
    i++;
    if(i >= N_out)
    {
        i=0;
        wrapFlag = 1;
    }
    return i;
}

void init_testpin()
{
    EALLOW;

    GpioCtrlRegs.GPBGMUX2.bit.GPIO56 = 0;
    GpioCtrlRegs.GPBMUX2.bit.GPIO56 = 0;
    GpioCtrlRegs.GPBDIR.bit.GPIO56 = 1;//output
}

/************* My Functions **************/
void UpdateSystemState(void) {
    // get current state
    state_t next_state = GetState();
    // detect change of state
    if (next_state != current_state) {
        char* outputstr = "";
        Uint16 length = 0;
        LCD_Send_Command(CLEARDISPLAY);
        // change parameters based off state
        switch(next_state) {
            case VOCODER:
                outputstr = "Vocoder";
                length = 7;
                // set buffer pointer to mic
                // turn on mic
                MicOn();
                break;
            case THEREMIN_PS:
                outputstr = "Theremin";
                LCD_String("Pitch Shifted", 13);
                LCD_Send_Command(NEWLINE);
                length = 8;
                // set buffer pointer to line
                // turn off mic
                LineOn();
            case AUDIO_PS:
                outputstr = "Audio";
                LCD_String("Pitch Shifted", 13);
                LCD_Send_Command(NEWLINE);
                length = 5;
                // set buffer pointer to mic
                // turn on mic
                MicOn();
                break;
            case THEREMIN:
                outputstr = "Theremin";
                length = 8;
                // set buffer pointer to line
                // turn off mic
                break;
            case AUDIO:
                outputstr = "Audio";
                length = 5;
                // set buffer pointer to mic
                // turn on mic
                MicOn();
                break;
            default:
                outputstr = "Off";
                length = 3;
                break;
        }
        // write state to LCD
        soft_del(100);
        LCD_String(outputstr, length);
        soft_del(100);
        // update state
        current_state = next_state;
    }
}

void GetParameters(void) {
    // update parameters based on current state
    switch(current_state) {
        case VOCODER:
            volume = 2.0f - ((float32) AdcData0) * 0.0004884f;
            stretch = 2.0f / (1.0f + exp((3.0f - ((float32) AdcData1) * 0.0004884f) * pitch));
            break;
        case THEREMIN_PS:
            volume = 1.0f;
            //stretch =
            mix = 1.0f - ((float32) AdcData1)*0.0002442;
        case AUDIO_PS:
            break;
        case THEREMIN:
            volume = 2.0f - ((float32) AdcData0) * 0.0004884f;
            break;
        case AUDIO:
            volume = 2.0f - ((float32) AdcData0) * 0.0004884f;
            break;
        default:
            volume = 0.0f;
            break;
    }
}
/*****************************************/
