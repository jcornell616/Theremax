#ifndef PERIPHERALS_H_
#define PERIPHERALS_H_


    // type definition
    typedef enum {
        VOCODER,
        THEREMIN_PS,
        AUDIO_PS,
        THEREMIN_AUDIO,
        THEREMIN,
        AUDIO,
        UNDEF
    }state_t;

    // function declarations
    void MicOn(void);
    void InitADCA(void);
    void StartConversionADCA(void);
    void InitEncoder(void);
    state_t GetState(void);

#endif
