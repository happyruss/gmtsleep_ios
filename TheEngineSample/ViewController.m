//
//  ViewController.m
//  Guided Meditation Treks Sleep
//
//  Created by Russell Eric Dobda on 8/02/2015.
//  Copyright (c) 2015 Russell Eric Dobda. All rights reserved.
//

#import "ViewController.h"
#import "TheAmazingAudioEngine.h"
#import "TPOscilloscopeLayer.h"
#import "AEPlaythroughChannel.h"
#import "AEExpanderFilter.h"
#import "AELimiterFilter.h"
#import "AERecorder.h"
#import <QuartzCore/QuartzCore.h>
#import "IAPHelper.h"
#import "PickerCells.h"
#import "ParentViewController.h"

#define UIColorFromRGB(rgbValue) [UIColor \
colorWithRed:((float)((rgbValue & 0xFF0000) >> 16))/255.0 \
green:((float)((rgbValue & 0xFF00) >> 8))/255.0 \
blue:((float)(rgbValue & 0xFF))/255.0 alpha:1.0]

static const int kInputChannelsChangedContext;
#define kAuxiliaryViewTag 251
#define TAG_NATURE 1
#define TAG_DELTA 2
#define TAG_THETA 3
#define TAG_INTRO 4
#define TAG_SLEEP 5
#define TAG_SLEEP2 6
#define TAG_DREAM 7
#define TAG_NAP 8

static NSString * const ID_NATURE = @"nature";
static NSString * const ID_THETA = @"theta";
static NSString * const ID_DELTA = @"delta";
static NSString * const ID_INTRO = @"intro";
static NSString * const ID_SLEEP = @"sleep";
static NSString * const ID_SLEEP2 = @"sleep2";
static NSString * const ID_DREAM = @"dream";
static NSString * const ID_NAP = @"nap";

@interface ViewController () {

    float binauralTarget;
    
    UINavigationController *inAppNavigationController;
    UIPickerView *naturePicker;
    NSArray *pickerArray;
    NSString *currentMeditationTrack;
    BOOL isMeditationPlaying;
    BOOL isIsochronic;
    BOOL isIsoOn;
    NSUserDefaults *defaults;
    //UISwitch *playSwitch;
    UISwitch *tonesSwitch;
    UISwitch *natureSwitch;

    NSDictionary *natureDictionary;
    
    UILabel *timerLabel;
    UILabel *natureLabel;
    int timerCount;
    BOOL letNatureRun;
    BOOL isMeditationFinished;
    int thetaBetaNatureLimit;
    
    UIButton *gmtLink;
//    UIButton *reviewLink;
//    UIButton *sleepphonesLink;

    UIView *headerView;
    UIView *footerView;
    UIImageView *sleepImage;
    UIButton *playButton;
    
    UIButton *introButton;
    UIButton *sleepButton;
    UIButton *deltaButton;
    UIButton *thetaButton;
    UIButton *natureButton;
    UIButton *sleepTopButton;
    UIButton *lucidButton;
    UIButton *napButton;
    UIButton *rateButton;
    UIButton *phonesButton;

    UISlider *voiceSlider;
    UISlider *tonesSlider;
    UISlider *natureSlider;
    
    float carrierFrequency;
    float previousCarrierFrequency;
    float nextCarrierFrequency;
    float transFrequency;
    float binauralFrequency;
    float sampleRate;
    int portamentoFrames;
    int portamentoFramesHalf;
    bool isIsoSilent;
    
    float oscillatorRateIso;
    float oscillatorRateLeft;
    float oscillatorPositionIso;
    float oscillatorPositionLeft;
    float oscillatorPositionRight;
    float oscillatorRateRight;
    float amplitude;
    float napBreakVolumeShift;
    bool transitionPortamento;
    int multiplier;
    int sampleFrame;
    int transitionSampleFrame;
    int portamentoSampleFrame;
    bool napShiftStarted;
    
    NSTimer *theTimer;
    int gapPosition;
    NSMutableArray *audioMatrix;
    int currentAudioSection;
    BOOL isInGap;
    NSString *currentNatureKey;
    bool isInFadeOut;
}

@property (nonatomic, retain) AEAudioController *audioController;
@property (nonatomic, retain) AEAudioFilePlayer *voicePlayer;
@property (nonatomic, retain) AEAudioFilePlayer *naturePlayer;
@property (nonatomic, retain) AEBlockChannel *oscillator;
@property (nonatomic, retain) AEAudioUnitChannel *audioUnitPlayer;
@property (nonatomic, strong) PickerCellsController *pickersController;

@end

@implementation ViewController

- (UIStatusBarStyle)preferredStatusBarStyle
{
    return UIStatusBarStyleLightContent;
}

- (void)resetOscillator:(float)carrier binaural:(float)binaural  {
    multiplier = (sampleRate/2)/binaural;
    binaural = ((float)sampleRate/2.f)/(float)multiplier;
    
    previousCarrierFrequency = carrierFrequency;
    nextCarrierFrequency = carrier;
    binauralFrequency = binaural;
    transFrequency = (nextCarrierFrequency - previousCarrierFrequency) / portamentoFrames;
    
    transitionPortamento = YES;
}

- (void)initOscillator {
    // Create a block-based channel, with an implementation of an oscillator
    //Set the initial frequencies to whatever; they will be overridden
    previousCarrierFrequency = 200;
    carrierFrequency = 200;
    nextCarrierFrequency = 200;
    [self resetOscillator:200 binaural: 4];
    oscillatorRateLeft = (carrierFrequency + binauralFrequency / 2)/sampleRate;
    oscillatorRateRight = (carrierFrequency - binauralFrequency / 2)/sampleRate;
    oscillatorRateIso = carrierFrequency / sampleRate;
    
    amplitude = 1.0f;
    isIsoSilent = NO;
    portamentoSampleFrame = 0;
    transitionPortamento = NO;
    
    self.oscillator = [AEBlockChannel channelWithBlock:^(const AudioTimeStamp  *time,
                                                         UInt32           frames,
                                                         AudioBufferList *audio) {

        int fader = multiplier - 400;
        for ( int i=0; i<frames; i++ ) {
            
            if (transitionPortamento)
            {
                portamentoSampleFrame++;
                if (portamentoSampleFrame >= portamentoFrames)
                {
                    carrierFrequency = nextCarrierFrequency;
                    portamentoSampleFrame = 0;
                    transitionPortamento = NO;
                } else if (portamentoSampleFrame == portamentoFramesHalf) {
                    //volume adjust
                    float resetVolume = _oscillator.volume * previousCarrierFrequency / carrierFrequency;
                    if (resetVolume > 1) resetVolume = 1;
                    _oscillator.volume = resetVolume;
                } else {
                    carrierFrequency +=  transFrequency;
                }
                oscillatorRateLeft = (carrierFrequency + binauralFrequency / 2)/sampleRate;
                oscillatorRateRight = (carrierFrequency - binauralFrequency / 2)/sampleRate;
                oscillatorRateIso = carrierFrequency / sampleRate;
            }
            
            if (isIsochronic)
            {
                sampleFrame++;
                if (sampleFrame >= multiplier)
                {
                    isIsoSilent = !isIsoSilent;
                    if (!isIsoSilent)
                    {
                        amplitude = 1.0f;
                    }
                    else
                    {
                        amplitude = 0.0f;
                    }
                    sampleFrame = 0;
                }
                else if (sampleFrame >= fader) {
                    if (!isIsoSilent)
                    {
                        amplitude -= .0025f;

                    }
                    else {
                        amplitude += .0025f;
                    }
                }

                float x = oscillatorPositionIso;
                x *= x; x -= 1.0; x *= x;       // x now in the range 0...1
                x *= INT16_MAX;
                x -= INT16_MAX / 2;
                x *= amplitude ;//* transitionAmplitude;
                oscillatorPositionIso += oscillatorRateIso;
                if ( oscillatorPositionIso > 1.0 ) oscillatorPositionIso -= 2.0;
                ((SInt16*)audio->mBuffers[0].mData)[i] = x;
                ((SInt16*)audio->mBuffers[1].mData)[i] = x;
            }
            else
            {
                //Left Channel
                float x = oscillatorPositionLeft;
                x *= x; x -= 1.0; x *= x;       // x now in the range 0...1
                x *= INT16_MAX;
                x -= INT16_MAX / 2;
                //x *= transitionAmplitude;
                oscillatorPositionLeft += oscillatorRateLeft;
                if ( oscillatorPositionLeft > 1.0 ) oscillatorPositionLeft -= 2.0;
                
                //Right Channel
                float y = oscillatorPositionRight;
                y *= y; y -= 1.0; y *= y;       // y now in the range 0...1
                y *= INT16_MAX;
                y -= INT16_MAX / 2;
                //y *= transitionAmplitude;
                oscillatorPositionRight += oscillatorRateRight;
                if ( oscillatorPositionRight > 1.0 ) oscillatorPositionRight -= 2.0;
                
                ((SInt16*)audio->mBuffers[0].mData)[i] = x;
                ((SInt16*)audio->mBuffers[1].mData)[i] = y;
            }
        }
    }];
    _oscillator.audioDescription = [AEAudioController nonInterleaved16BitStereoAudioDescription];
    _oscillator.volume =[defaults floatForKey:@"tonesVolume"];
    _oscillator.channelIsPlaying = false;
    [_audioController addChannels:[NSArray arrayWithObjects: _oscillator, nil]];
}


- (void)initNature {
    bool wasPlaying = false;
    
    if (self.naturePlayer != nil)
    {
        wasPlaying = self.naturePlayer.channelIsPlaying;
        [_audioController removeChannels:[NSArray arrayWithObjects:_naturePlayer, nil]];
        self.naturePlayer = nil;
    }
    
    NSArray *arr = [natureDictionary valueForKey:currentNatureKey];
    NSURL *natureUrl = [arr objectAtIndex:0];
    
    //NSString *natureFilename = [[IAPHelper getNatureDictionary] valueForKey:currentNatureKey];
    //NSURL *natureUrl = [[IAPHelper getNatureDictionary] valueForKey:currentNatureKey];
    //self.naturePlayer = [AEAudioFilePlayer audioFilePlayerWithURL:[[NSBundle mainBundle] URLForResource:natureFilename withExtension:@"m4a"] error:NULL];
    self.naturePlayer = [AEAudioFilePlayer audioFilePlayerWithURL:natureUrl error:NULL];
    _naturePlayer.volume = [defaults floatForKey:@"natureVolume"];
    _naturePlayer.loop = YES;
    _naturePlayer.channelIsPlaying = false;
    
    [_audioController addChannels:[NSArray arrayWithObjects:_naturePlayer, nil]];
    self.naturePlayer.channelIsPlaying = wasPlaying;
}

- (void)setToPlay:(int)setToPlay {
    if ([currentMeditationTrack isEqualToString:ID_INTRO]){
            _voicePlayer.channelIsPlaying = setToPlay;
            if (timerCount > 509) {
                _oscillator.channelIsPlaying = setToPlay;
                if (timerCount > 589) {
                    _naturePlayer.channelIsPlaying = setToPlay;
                }
            }
        }
    else {
        if (![currentMeditationTrack isEqualToString:ID_NATURE] &&
            ![currentMeditationTrack isEqualToString:ID_THETA] &&
            ![currentMeditationTrack isEqualToString:ID_DELTA])
        {
            if (!isInGap)
            {
                _voicePlayer.channelIsPlaying = setToPlay;
            }
        }
        if (![currentMeditationTrack isEqualToString:ID_NATURE]) {
            _oscillator.channelIsPlaying = setToPlay;
        }
        _naturePlayer.channelIsPlaying = setToPlay;
    }
}

-(void) resetControls {
    //Reset Controls to normal in case intro is interrupted
    [tonesSwitch setEnabled:YES];
    [natureSwitch setEnabled:YES];
    [natureSlider setEnabled:YES];
    [tonesSlider setEnabled:YES];
    
    [voiceSlider setValue:[defaults floatForKey:@"voiceVolume"]];
    [tonesSlider setValue: [defaults floatForKey:@"tonesVolume"]];
    [natureSlider setValue:[defaults floatForKey:@"natureVolume"]];
    tonesSwitch.on = [defaults boolForKey:@"useIsochronic"];
    currentNatureKey = [defaults objectForKey:@"natureSound"];
    natureSwitch.on = NO;
    letNatureRun = NO;
    isIsochronic = tonesSwitch.on;
    
    _voicePlayer.volume = voiceSlider.value;
    _oscillator.volume = tonesSlider.value;
    _naturePlayer.volume = natureSlider.value;
}

-(void) runIntro {
    [self setToPlay:NO];
    [voiceSlider setEnabled:YES];
    [tonesSlider setEnabled:NO];
    [natureSlider setEnabled:NO];
    [tonesSwitch setEnabled:NO];
    [natureSwitch setEnabled:NO];
    letNatureRun = NO;
    currentMeditationTrack = ID_INTRO;
    
    isInGap = NO;
    if (_voicePlayer != nil)
    {
        [_audioController removeChannels:[NSArray arrayWithObjects:_voicePlayer, nil]];
        self.voicePlayer = nil;
    }
    if (_oscillator != nil)
    {
        [_audioController removeChannels:[NSArray arrayWithObjects:_oscillator, nil]];
        self.oscillator = nil;
    }
    if (_naturePlayer != nil)
    {
        [_audioController removeChannels:[NSArray arrayWithObjects:_naturePlayer, nil]];
        self.naturePlayer = nil;
    }

    
    NSString *filename = [[NSBundle mainBundle] pathForResource: @"Intro" ofType:@"m4a"];

    [playButton setSelected:YES];
    playButton.hidden = NO;
    
    self.voicePlayer = [AEAudioFilePlayer audioFilePlayerWithURL:[NSURL fileURLWithPath:filename] error:NULL];
    
    self.voicePlayer.completionBlock = ^ {
        isMeditationPlaying = NO;
        isMeditationFinished = YES;
    };

    _voicePlayer.volume = [defaults floatForKey:@"voiceVolume"];
    _voicePlayer.loop = NO;
    
    [_audioController addChannels:[NSArray arrayWithObjects:_voicePlayer, nil]];
    [self setBinauralFrequency:NO];
    [self setToPlay:YES];
    
    isMeditationPlaying = YES;
    isMeditationFinished = NO;
    isInFadeOut = NO;
    
}

- (void)runMeditationProgram:(NSString *)trackId soundMatrix:(NSMutableArray*)soundMatrix {
    [self setToPlay:NO];
    [voiceSlider setEnabled:YES];
    [tonesSlider setEnabled:YES];
    currentMeditationTrack = trackId;
    currentAudioSection = 0;
    [voiceSlider setEnabled:YES];
    [tonesSlider setEnabled:YES];
    audioMatrix = soundMatrix;
    [self runNextMeditationSection];
    isMeditationPlaying = YES;
    isMeditationFinished = NO;
    isInFadeOut = NO;
}

- (void)launchInAppStoryboard {
    UIStoryboard *sb = [UIStoryboard storyboardWithName:@"iOSInAppPurchases" bundle:nil];
    inAppNavigationController = [sb instantiateViewControllerWithIdentifier:@"inappNavigation"];
    
    UIBarButtonItem *backButton = [[UIBarButtonItem alloc] initWithTitle:@"<Back" style:UIBarButtonItemStyleBordered target:nil action:@selector(backPressed:)];
    inAppNavigationController.navigationBar.topItem.leftBarButtonItem = backButton;
    
    [self presentViewController:inAppNavigationController animated:YES completion:NULL];
}

-(void)backPressed: (id)sender
{
    [inAppNavigationController dismissViewControllerAnimated:YES completion: nil];
    pickerArray = [IAPHelper getNatureFilenames];
    natureDictionary = [IAPHelper getNatureDictionary];
    [naturePicker reloadAllComponents];
}

- (void)initalizeMeditation:(NSString *)trackId {
    
    if ([trackId isEqualToString:ID_NATURE])
    {
        isMeditationFinished = YES;
        if (letNatureRun)
        {
            [voiceSlider setEnabled:NO];
            [tonesSlider setEnabled:NO];
            isMeditationFinished = YES;
            isMeditationPlaying = NO;
            isInFadeOut = NO;
            currentMeditationTrack = trackId;
            currentAudioSection = 0;
            [self initNature];
            _naturePlayer.channelIsPlaying = YES;
            _oscillator.channelIsPlaying = NO;
            _voicePlayer.channelIsPlaying = NO;
            playButton.hidden = NO;
            [playButton setSelected:YES];
        }
        else
        {
            UIAlertView *alert = [[UIAlertView alloc]
                                  initWithTitle:@"PUT YOUR PHONE IN AIRPLANE MODE"
                                  message:@"Select the number of minutes"
                                  delegate:self
                                  cancelButtonTitle:@"Cancel"
                                  otherButtonTitles:@"20 min",@"45 min", @"1 hour",@"2 hours", nil];
            alert.tag = TAG_NATURE;
            [alert show];
        }
    }
    else if ([trackId isEqualToString:ID_DELTA])
    {
        UIAlertView *alert = [[UIAlertView alloc]
                              initWithTitle:@"PUT YOUR PHONE IN AIRPLANE MODE"
                              message:@"Select the number of minutes"
                              delegate:self
                              cancelButtonTitle:@"Cancel"
                              otherButtonTitles:@"5 min",@"10 min", @"20 min", @"35 min", @"45 min",@"1 hour", nil];
        alert.tag = TAG_DELTA;
        [alert show];
    }
    else if ([trackId isEqualToString:ID_THETA])
    {
        UIAlertView *alert = [[UIAlertView alloc]
                              initWithTitle:@"PUT YOUR PHONE IN AIRPLANE MODE"
                              message:@"Select the number of minutes"
                              delegate:self
                              cancelButtonTitle:@"Cancel"
                              otherButtonTitles:@"5 min",@"10 min", @"20 min",@"35 min",@"45 min",@"1 hour", nil];
        alert.tag = TAG_THETA;
        [alert show];
    }
    else if ([trackId isEqualToString:ID_DREAM]) {
            if ([IAPHelper isMeditationDownloaded:ID_DREAM])
            {
                UIAlertView *alert = [[UIAlertView alloc]
                                      initWithTitle:@"PUT YOUR PHONE IN AIRPLANE MODE"
                                      message:@"Get comfortable and select a length"
                                      delegate:self
                                      cancelButtonTitle:@"Cancel"
                                      otherButtonTitles:@"20 min - No Intro",@"30 min - No Intro",@"30 min",@"45 min",@"1 hour",nil];
                alert.tag = TAG_DREAM;
                [alert show];
            }
            else {
                [self launchInAppStoryboard];
            }
    }
    else if ([trackId isEqualToString:ID_NAP]) {
        if ([IAPHelper isMeditationDownloaded:ID_NAP])
        {
            UIAlertView *alert = [[UIAlertView alloc]
                                  initWithTitle:@"PUT YOUR PHONE IN AIRPLANE MODE"
                                  message:@"Select the length of your nap"
                                  delegate:self
                                  cancelButtonTitle:@"Cancel"
                                  otherButtonTitles:@"20 Minutes",@"1.5 Hours", @"3 Hours", nil];
            alert.tag = TAG_NAP;
            [alert show];
        }
        else {
            [self launchInAppStoryboard];
        }
    }  else if ([trackId isEqualToString:ID_SLEEP2]) {
        
        if ([IAPHelper isMeditationDownloaded:ID_SLEEP2])
        {
            UIAlertView *alert = [[UIAlertView alloc]
                                  initWithTitle:@"PUT YOUR PHONE IN AIRPLANE MODE"
                                  message:@"Get comfortable and select a length"
                                  delegate:self
                                  cancelButtonTitle:@"Cancel"
                                  otherButtonTitles:@"25 min",@"35 min",@"50 min",nil];
            alert.tag = TAG_SLEEP2;
            [alert show];
        }
        else {
            [self launchInAppStoryboard];
        }
    }
    else if ([trackId isEqualToString:ID_INTRO])
    {
        UIAlertView *alert = [[UIAlertView alloc]
                              initWithTitle:@"Introduction"
                              message:@"Click OK to learn about the app. Samples licensed under creative commons from OrangeFreeSounds, Juskiddink, GlorySunz, Zarabadeu, Lisa Redfern, Mike Koenig, Martin Lightning, Corsica_S, digifishmusic, 1jmorrisoncafe291, inchadney, martats, pashee, fridobeck, thaighaudio, vonfleisch, felix blume, ninifoletti, jillismolenaar, sophronsinesounddesign, soundbible, dobroide, timdrussell, qubodup, Russell Eric Dobda"
                              delegate:self
                              cancelButtonTitle:@"Cancel"
                              otherButtonTitles:@"OK",nil];
        alert.tag = TAG_INTRO;
        [alert show];
    }
    else if ([trackId isEqualToString:ID_SLEEP])
    {
        UIAlertView *alert = [[UIAlertView alloc]
                              initWithTitle:@"PUT YOUR PHONE IN AIRPLANE MODE"
                              message:@"Get comfortable and select a length"
                              delegate:self
                              cancelButtonTitle:@"Cancel"
                              otherButtonTitles:@"20 min",@"30 min",@"45 min",@"1 hour",nil];
        alert.tag = TAG_SLEEP;
        [alert show];
    }
}


- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    
    if (buttonIndex != 0)
    {
        [self resetControls];
        [self setToPlay:NO];
        [playButton setHidden:NO];
        [playButton setSelected:YES];
        currentAudioSection = 0;
        isMeditationFinished = NO;
        isInFadeOut = NO;
        NSString * medId;

        switch (alertView.tag) {
            case TAG_NATURE:
                    currentMeditationTrack = ID_NATURE;
                    [voiceSlider setEnabled:NO];
                    [tonesSlider setEnabled:NO];
                [natureSwitch setEnabled:YES];
                    isMeditationPlaying = NO;
                    currentAudioSection = 0;
                    _oscillator.channelIsPlaying = NO;
                    _voicePlayer.channelIsPlaying = NO;
                    switch (buttonIndex) {
                        case 1:
                            thetaBetaNatureLimit = 17;
                            break;
                        case 2:
                            thetaBetaNatureLimit = 42;
                            break;
                        case 3:
                            thetaBetaNatureLimit = 57;
                            break;
                        case 4:
                            thetaBetaNatureLimit = 117;
                            break;
                        default:
                            break;
                    }
                    thetaBetaNatureLimit = thetaBetaNatureLimit * 60;
                    [self initNature];
                    _naturePlayer.channelIsPlaying = YES;
                    _oscillator.channelIsPlaying = NO;
                    _voicePlayer.channelIsPlaying = NO;
                break;
            case TAG_DELTA:
            case TAG_THETA:
                [voiceSlider setEnabled:NO];
                isMeditationPlaying = NO;
                switch (buttonIndex) {
                    case 1:
                        thetaBetaNatureLimit = 3;
                        break;
                    case 2:
                        thetaBetaNatureLimit = 7;
                        break;
                    case 3:
                        thetaBetaNatureLimit = 17;
                        break;
                    case 4:
                        thetaBetaNatureLimit = 27;
                        break;
                    case 5:
                        thetaBetaNatureLimit = 42;
                        break;
                    case 6:
                        thetaBetaNatureLimit = 57;
                        break;
                    default:
                        break;
                }
                thetaBetaNatureLimit = thetaBetaNatureLimit * 60;
                _voicePlayer.channelIsPlaying = NO;
                [self initNature];
                _naturePlayer.channelIsPlaying = YES;
                [natureSwitch setEnabled:YES];
                [self initOscillator];
                _oscillator.channelIsPlaying = YES;
                if (alertView.tag == TAG_DELTA)
                {
                    currentMeditationTrack = ID_DELTA;
                    binauralTarget = 1.2f;
                    [self resetOscillator:160.0f binaural: 9.6f];
                }
                else {
                    currentMeditationTrack = ID_THETA;
                    binauralTarget =6.0f;
                    [self resetOscillator:197.0f binaural: 9.6f];
                }
                break;
            case TAG_INTRO:
                if (buttonIndex == 1)
                    [self runIntro];
                break;
            case TAG_SLEEP:
            case TAG_SLEEP2: {
                [natureSwitch setEnabled:YES];
                //Extend the final gap based on the user's selection
                int gapPad = 1;
                if (buttonIndex != 0) {
                    switch (alertView.tag) {
                        case TAG_SLEEP:
                            medId = ID_SLEEP;
                            if (buttonIndex == 2) gapPad = 6;
                            if (buttonIndex == 3) gapPad = 13;
                            if (buttonIndex == 4) gapPad = 19;
                            break;
                        case TAG_SLEEP2:
                            medId = ID_SLEEP2;
                            if (buttonIndex == 2) gapPad = 6;
                            if (buttonIndex == 3) gapPad = 13;
                            break;
                        default:
                            break;
                    }
                    NSMutableArray *soundMatrix = [IAPHelper getAudioMatrix:medId];

                    if (buttonIndex > 1)
                    {
                        NSMutableArray * item = [soundMatrix lastObject];
                        long gapLength = [[item objectAtIndex:5] integerValue] * gapPad;
                        [item replaceObjectAtIndex:5 withObject:[NSNumber numberWithInteger:gapLength]];
                    }
                    [self initNature];
                    [self initOscillator];
                    [self runMeditationProgram:medId soundMatrix:soundMatrix];
                }
                break; }
            case TAG_NAP:
                if (buttonIndex != 0) {
                    medId = ID_NAP;
                    [natureSwitch setEnabled:NO];
                    letNatureRun = NO;
                    NSMutableArray *soundMatrix = [IAPHelper getAudioMatrix:medId];
                    long gapLength = [[soundMatrix[2] objectAtIndex:5] integerValue];
                    if (buttonIndex == 2) gapLength *= 4.5f;
                    if (buttonIndex == 3) gapLength *= 9.0f;
                    [soundMatrix[2] replaceObjectAtIndex:5 withObject:[NSNumber numberWithInteger:gapLength]];
                    [self initNature];
                    [self initOscillator];
                    [self runMeditationProgram:medId soundMatrix:soundMatrix];
                }
                break;
            case TAG_DREAM:
                medId = ID_DREAM;
                [natureSwitch setEnabled:YES];

                NSMutableArray *soundMatrix = [IAPHelper getAudioMatrix:medId];

                int multipler;
                if (buttonIndex == 1 || buttonIndex == 2)
                {
                    //Truncate the intro
                    [soundMatrix removeObjectsInRange:NSMakeRange(0, 8)];
                    multipler = (int)buttonIndex;
                } else {
                    multipler = (int)buttonIndex - 2;
                }
                
                if (buttonIndex > 1)
                {
                    //Extend the final gap based on the user's selection
                    int gapPad = 1;
                    if (buttonIndex == 2) gapPad = 6; //30-min no intro over 20 min program
                    //if (buttonIndex == 3) gapPad = 1; //30 min with intro
                    if (buttonIndex == 4) gapPad = 7; //45 min with intro
                    if (buttonIndex == 5) gapPad = 12; //1 hr with intro
                    NSMutableArray * item = [soundMatrix lastObject];
                    long gapLength = [[item objectAtIndex:5] integerValue] * gapPad;
                    [item replaceObjectAtIndex:5 withObject:[NSNumber numberWithInteger:gapLength]];
                }

                [self initNature];
                [self initOscillator];
                [self runMeditationProgram:medId soundMatrix:soundMatrix];
                break;
        }

        //Begin timer
        timerCount = 0;
        if (theTimer != nil)
        {
            [theTimer invalidate];
            theTimer = nil;
        }
        if (alertView.tag == TAG_INTRO) //use other timer for intro meditation
        {
            theTimer = [NSTimer scheduledTimerWithTimeInterval:1.0f target:self selector:@selector(updateIntroTimer:) userInfo:nil repeats:YES];
        }
        else {
            theTimer = [NSTimer scheduledTimerWithTimeInterval:1.0f target:self selector:@selector(updateTimer:) userInfo:nil repeats:YES];
        }
    }
}

- (void)runNextMeditationSection {
    isInGap = NO;
    if (_voicePlayer != nil)
    {
        [_audioController removeChannels:[NSArray arrayWithObjects:_voicePlayer, nil]];
        self.voicePlayer = nil;
    }

    NSURL *fileUrl;
    if (audioMatrix.count > currentAudioSection)
    {
        [playButton setHidden:NO];
        [playButton setSelected:YES];
        NSMutableArray *subArray = [audioMatrix objectAtIndex:currentAudioSection];
        fileUrl = [subArray objectAtIndex:2];
        self.voicePlayer = [AEAudioFilePlayer audioFilePlayerWithURL:fileUrl error:NULL];
        
        self.voicePlayer.completionBlock = ^ {
            gapPosition = 0;
            isInGap = YES;
        };
        
        _voicePlayer.volume = [defaults floatForKey:@"voiceVolume"];
        _voicePlayer.loop = NO;
        
        [_audioController addChannels:[NSArray arrayWithObjects:_voicePlayer, nil]];
        [self setBinauralFrequency:NO];
        [self setToPlay:YES];
    }
    else if ([currentMeditationTrack isEqualToString:ID_NAP]){
        NSURL *fileUrl = [[NSBundle mainBundle] URLForResource:@"alarm" withExtension:@"m4a"];
        self.voicePlayer = [AEAudioFilePlayer audioFilePlayerWithURL:fileUrl error:NULL];
        //self.voicePlayer.completionBlock = ^ { };
        _voicePlayer.volume = 0.0;
        _voicePlayer.loop = YES;
        [_audioController addChannels:[NSArray arrayWithObjects:_voicePlayer, nil]];
        isInFadeOut = YES;
    }
    else
    {
        //All done!
        isInFadeOut = YES;
    }
}

- (void) shutDownMeditation {
    [theTimer invalidate];
    theTimer = nil;

    [self setToPlay:NO];
    isMeditationPlaying = NO;
    //playSwitch.hidden = true;
    [playButton setHidden:YES];

    [voiceSlider setEnabled:YES];
    [tonesSlider setEnabled:YES];
    [natureSlider setEnabled:YES];
    [natureSwitch setEnabled:YES];

}

-(void) updateIntroTimer:(NSTimer *)tTimer {

    if (isMeditationFinished)
    {
        [self shutDownMeditation];
    }
    
    //play with controls
    if (playButton.isSelected)
    {
        timerCount++;
        int hours = timerCount / 3600;
        int minutes = (timerCount % 3600) / 60;
        int seconds = (timerCount %3600) % 60;
        timerLabel.text = [NSString stringWithFormat:@"%02d:%02d:%02d", hours, minutes, seconds];
        
        switch (timerCount) {
            case 421:
                [playButton setSelected:NO];
                isMeditationPlaying = NO;
                [self setToPlay:NO];
                break;
            case 423:
                [playButton setSelected:NO];
                isMeditationPlaying = NO;
                [self setToPlay:NO];
                break;
            case 497:
                [voiceSlider setValue:.3];
                _voicePlayer.volume = .3;
                break;
            case 499:
                [voiceSlider setValue:.7];
                _voicePlayer.volume = .7;
                break;
            case 502:
                [voiceSlider setValue:.2];
                _voicePlayer.volume = .2;
                break;
            case 505:
                [voiceSlider setValue:.95];
                _voicePlayer.volume = .95;
                break;
            case 508:
                [voiceSlider setValue:[defaults floatForKey:@"voiceVolume"]];
                _voicePlayer.volume = [defaults floatForKey:@"voiceVolume"];
                break;
            case 509:
                [tonesSlider setEnabled: YES];
                [tonesSwitch setEnabled:YES];
                [self initOscillator];
                _oscillator.channelIsPlaying = true;
                break;
            case 529:
                [tonesSlider setValue:.3];
                _oscillator.volume = .3;
                break;
            case 544:
                [tonesSlider setValue:[defaults floatForKey:@"tonesVolume"]];
                _oscillator.volume = [defaults floatForKey:@"tonesVolume"];
                break;
            case 551:
                [tonesSwitch setOn:NO];
                isIsochronic = NO;
                sampleFrame = 0;
                break;
            case 554:
                [tonesSwitch setOn:YES];
                isIsochronic = YES;
                sampleFrame = 0;
                break;
            case 560:
                [tonesSwitch setOn:NO];
                isIsochronic = NO;
                sampleFrame = 0;
                break;
            case 578:
                [tonesSwitch setOn:YES];
                isIsochronic = YES;
                sampleFrame = 0;
                break;
            case 588:
                [natureSlider setEnabled: YES];
                [natureSwitch setEnabled:YES];
                [self initNature];
                _naturePlayer.channelIsPlaying = YES;
                break;
            case 593:
                currentNatureKey =@"Rain Soft";
                [natureLabel setText:currentNatureKey];
                [self initNature];
                break;
            case 596:
                currentNatureKey =@"Waves Sea";
                [natureLabel setText:currentNatureKey];
                [self initNature];
                break;
            case 597:
                currentNatureKey =@"Noise Pink";
                [natureLabel setText:currentNatureKey];
                [self initNature];
                break;
            case 599:
                //expand nature picker
                //[natureLabel sendActionsForControlEvents: UIControlEventTouchUpInside];
                currentNatureKey = [defaults objectForKey:@"natureSound"];
                [natureLabel setText:currentNatureKey];
                [self initNature];
                break;
            case 607:
                //close nature picker
                break;
            case 622:
                [natureSlider setValue:.3];
                _naturePlayer.volume = .3;
                break;
            case 625:
                [natureSlider setValue:.9];
                _naturePlayer.volume = .9;
                break;
            case 629:
                [natureSlider setValue:[defaults floatForKey:@"natureVolume"]];
                _naturePlayer.volume = [defaults floatForKey:@"natureVolume"];
                break;
            case 634:
                [natureSwitch setOn:NO];
                break;
            case 644:
                [natureSwitch setOn:YES];
                break;
            case 658:
                [natureSwitch setOn:NO];
                break;
            case 661:
                //[playSwitch setOn:NO];
                [playButton setSelected:NO];
                isMeditationPlaying = NO;
                [self setToPlay:NO];
                break;
            default:
                break;
        }
    } else if (timerCount == 421 ||timerCount == 423 || timerCount == 661) {
        [playButton setSelected:YES];
        //[playSwitch setOn:YES];
        isMeditationPlaying = YES;
        [self setToPlay:YES];
    }
}

- (void)fadeOutMeditation:(bool)oscillatorRunning {
    
    float minVolume = .0005f;
    float volumeReduction = .98f;
    [voiceSlider setEnabled:NO];
    [tonesSlider setEnabled:NO];
    [natureSlider setEnabled:NO];
    [natureSwitch setEnabled:NO];
    
    if (oscillatorRunning && _oscillator.volume > minVolume) {
        _oscillator.volume = _oscillator.volume * volumeReduction;
    }
    else {
        _oscillator.channelIsPlaying = NO;
    }

    if (!letNatureRun)
    {
        if (_naturePlayer.volume > minVolume) {
            _naturePlayer.volume = _naturePlayer.volume * volumeReduction;
        }
        else {
            _naturePlayer.channelIsPlaying = NO;
//            [natureSlider setEnabled:NO];
//            [natureSwitch setEnabled:NO];
        }
    }
    
    if ([currentMeditationTrack isEqualToString:ID_NAP]){
        //increase volume of the alarm
        _voicePlayer.volume += .01;
    }
    
    if (_naturePlayer.volume < minVolume && (!oscillatorRunning || _oscillator.volume < minVolume))
    {
        [self shutDownMeditation];
    }
}

- (void)updateTimer:(NSTimer *)tTimer {

    if (playButton.isSelected) {
        timerCount++;
        int hours = timerCount / 3600;
        int minutes = (timerCount % 3600) / 60;
        int seconds = (timerCount %3600) % 60;
        timerLabel.text = [NSString stringWithFormat:@"%02d:%02d:%02d", hours, minutes, seconds];
    
        if ([currentMeditationTrack isEqualToString:ID_NATURE] ||
            [currentMeditationTrack isEqualToString:ID_DELTA] ||
            [currentMeditationTrack isEqualToString:ID_THETA])
        {
            if ([currentMeditationTrack isEqualToString:ID_DELTA] ||
                [currentMeditationTrack isEqualToString:ID_THETA]) {
                if (binauralFrequency > binauralTarget)
                {
                    binauralFrequency -= .1f;
                    multiplier = (sampleRate/2)/binauralFrequency;
                    oscillatorRateLeft = (carrierFrequency + binauralFrequency / 2)/sampleRate;
                    oscillatorRateRight = (carrierFrequency - binauralFrequency / 2)/sampleRate;
                    oscillatorRateIso = carrierFrequency / sampleRate;
                }
            }
            
            if (timerCount > thetaBetaNatureLimit)
            {
                if (!letNatureRun) {
                    //[self shutDownMeditation];
                    [self fadeOutMeditation:![currentMeditationTrack isEqualToString:ID_NATURE]];
                }
            }
        }
        else if (isInGap && audioMatrix.count > currentAudioSection)
        {
            NSMutableArray *subArray = [audioMatrix objectAtIndex:currentAudioSection];
            long gapLength = [[subArray objectAtIndex:5] integerValue];
            if (gapPosition == 0)
            {
                [self setBinauralFrequency:YES];
            }
            else if (gapPosition == gapLength)
            {
                currentAudioSection ++;
                [self runNextMeditationSection];
            }
            else if ([currentMeditationTrack isEqualToString:ID_NAP] && currentAudioSection == 2){

                //if in the middle gap, handle the fade ins and outs
                if (!napShiftStarted)
                {
                    napBreakVolumeShift = _oscillator.volume / 30;
                    napShiftStarted = YES;
                }

                if (gapPosition == gapLength - 1) {
                    //back to normal
                    [tonesSlider setEnabled:YES];
                    _oscillator.volume = napBreakVolumeShift * 30;
                } else if (gapPosition > (gapLength - 31)) {
                    //fade in
                    if (_oscillator.volume < napBreakVolumeShift * 30) {
                        _oscillator.volume += napBreakVolumeShift;
                    }
                }
                else if (gapPosition > 61 && gapPosition < 92) {
                    //fade out
                    [tonesSlider setEnabled:NO];
                    _oscillator.volume -= napBreakVolumeShift;
                }
            }
            if (isMeditationPlaying)
            {
                gapPosition++;
            }
        }
        
        if (isInFadeOut)
        {
            if (![currentMeditationTrack isEqualToString:ID_NAP]){
                _voicePlayer.channelIsPlaying = NO;
            }
            [voiceSlider setEnabled:NO];
            [self fadeOutMeditation:YES];
        }
    }
}


- (void)setBinauralFrequency:(BOOL)isGap {
    //handles frequency shifting based on position in the meditation
    
    NSMutableArray *subArray = [audioMatrix objectAtIndex:currentAudioSection];
    if (!isGap)
    {
        float freq = [[subArray objectAtIndex:0] floatValue];
        if(freq != 0)
        {
            [self resetOscillator:[[subArray objectAtIndex:0] floatValue] binaural: [[subArray objectAtIndex:1] floatValue]];
        }
    }
    else
    {
        float freq = [[subArray objectAtIndex:3] floatValue];
        if(freq != 0)
        {
            [self resetOscillator:[[subArray objectAtIndex:3] floatValue] binaural: [[subArray objectAtIndex:4] floatValue]];
        }
    }
}

- (id)initWithAudioController:(AEAudioController*)audioController {
    if ( !(self = [super initWithStyle:UITableViewStyleGrouped]) ) return nil;
    self.audioController = audioController;
    
    // Create an audio unit channel (a file player)
    self.audioUnitPlayer = [[AEAudioUnitChannel alloc] initWithComponentDescription:AEAudioComponentDescriptionMake(kAudioUnitManufacturer_Apple, kAudioUnitType_Generator, kAudioUnitSubType_AudioFilePlayer)];
    
    // Finally, add the audio unit player
    [_audioController addChannels:[NSArray arrayWithObjects:_audioUnitPlayer, nil]];
    
    [_audioController addObserver:self forKeyPath:@"numberOfInputChannels" options:0 context:(void*)&kInputChannelsChangedContext];
    
    return self;
}

-(void)viewDidLoad {
    [super viewDidLoad];
    
    //sampleRate = 44100.0;
    sampleRate = 48000.0;
    portamentoFrames = 3 * sampleRate;
    portamentoFramesHalf = portamentoFrames / 2;
    
    //Set Defaults
    defaults = [NSUserDefaults standardUserDefaults];
    if (![defaults boolForKey:@"defaultsSaved"])
    {
        [defaults setBool:YES forKey:@"defaultsSaved"];
        [defaults setBool:NO forKey:@"useIsochronic"];
        [defaults setFloat:.5 forKey:@"voiceVolume"];
        [defaults setFloat:.5 forKey:@"natureVolume"];
        [defaults setFloat:.25 forKey:@"tonesVolume"];
        [defaults setObject:@"Rain Soft" forKey:@"natureSound"];
        [defaults synchronize];
    }
    
    [self.tableView setBackgroundColor:[UIColor blackColor]];
    
    //Picker Data
    currentNatureKey = [defaults objectForKey:@"natureSound"];
    pickerArray = [IAPHelper getNatureFilenames];
    natureDictionary = [IAPHelper getNatureDictionary];
    self.pickersController = [[PickerCellsController alloc] init];
    [self.pickersController attachToTableView:self.tableView tableViewsPriorDelegate:self withDelegate:self];
    naturePicker = [[UIPickerView alloc] init];
    //naturePicker = [[UIPickerView alloc] initWithFrame:CGRectMake(0.0, 0.0, 520.0, 220.0)];
    //naturePicker.transform = CGAffineTransformMakeScale(2, 2);
    naturePicker.delegate = self;
    naturePicker.dataSource = self;
    
    //Set to proper row in the table!
    NSIndexPath *pickerIP = [NSIndexPath indexPathForRow:2 inSection:0];
    [self.pickersController addPickerView:naturePicker forIndexPath:pickerIP];
    
    headerView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.tableView.bounds.size.width, 90)];
    headerView.backgroundColor = [UIColor blackColor];
    BOOL isiPad = [[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad;
    
    gmtLink = [UIButton buttonWithType:UIButtonTypeRoundedRect];
    [gmtLink setTitle:@"Guided Meditation Treks" forState:UIControlStateNormal];
    [gmtLink addTarget:self action:@selector(linkToWeb:) forControlEvents:UIControlEventTouchUpInside];
    [gmtLink setTitleColor:UIColorFromRGB(0x00ff00) forState:UIControlStateNormal];
    [gmtLink setTitleColor:UIColorFromRGB(0x00ff00) forState:UIControlStateSelected];
    gmtLink.frame = CGRectMake(headerView.bounds.size.width - (isiPad ? 250 : 210), 10, 200, 40);
    gmtLink.titleLabel.font = [UIFont systemFontOfSize:18.0];
    [headerView addSubview:gmtLink];

    //timerLabel = [[UILabel alloc]initWithFrame:CGRectMake(0, 5, 90, 20)];
    timerLabel = [[UILabel alloc]initWithFrame:CGRectMake(0, 0, 80, 20)];
    
    //timerLabel = [[UILabel alloc]init];
    //[timerLabel setBackgroundColor:[UIColor yellowColor]];
    timerLabel.text = @"00:00:00";
    [timerLabel setTextColor:[UIColor whiteColor]];
    [headerView addSubview:timerLabel];

    self.tableView.tableHeaderView = headerView;
    
    footerView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.tableView.bounds.size.width, 420)];
    [footerView setBackgroundColor:[UIColor blackColor]];
    
    sleepImage = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"SavasanaGlow.png"]];
    [footerView addSubview:sleepImage];
    sleepImage.frame = CGRectMake(headerView.bounds.size.width - (isiPad ? 250 : 210), 10, 350, 100);
    
    UIImage *playImage = [UIImage imageNamed:@"play.png"];
    UIImage *pauseImage = [UIImage imageNamed:@"pause.png"];
    playButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [playButton setImage:playImage forState:UIControlStateNormal];
    [playButton setImage:pauseImage forState:UIControlStateSelected];
    [playButton addTarget:self action:@selector(togglePlay) forControlEvents:UIControlEventTouchUpInside];
    playButton.frame = CGRectMake(headerView.bounds.size.width - (isiPad ? 250 : 210), 10, 120, 100);
    [footerView addSubview:playButton];
    //[playButton setHidden:YES];
    
    UIImage *introImage = [UIImage imageNamed:@"btnIntro.png"];
    introButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [introButton setTitle:@"INTRO" forState:UIControlStateNormal];
    [introButton setImage:introImage forState:UIControlStateNormal];
    introButton.tag = 1;
    [introButton addTarget:self action:@selector(beginMeditation:) forControlEvents:UIControlEventTouchUpInside];
    //introButton.frame = CGRectMake(footerView.bounds.size.width - (isiPad ? 250 : 210), 10, 100, 35);
    introButton.frame = CGRectMake(footerView.bounds.size.width - (isiPad ? 250 : 210), 10, 120, 60);
    //[introButton setTitleColor:[UIColor greenColor] forState:UIControlStateNormal];
    //[introButton setBackgroundColor: [UIColor redColor]];
    introButton.titleLabel.font = [UIFont systemFontOfSize:32.0];
    [footerView addSubview:introButton];

    UIImage *sleepBtnImage = [UIImage imageNamed:@"btnSleep.png"];
    sleepButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [sleepButton setTitle:@"SLEEP" forState:UIControlStateNormal];
    sleepButton.tag = 2;
    [sleepButton addTarget:self action:@selector(beginMeditation:) forControlEvents:UIControlEventTouchUpInside];
    sleepButton.frame = CGRectMake(headerView.bounds.size.width - (isiPad ? 250 : 210), 10, 120, 60);
    [sleepButton setImage:sleepBtnImage forState:UIControlStateNormal];
    //[sleepButton setTitleColor:[UIColor greenColor] forState:UIControlStateNormal];
    //[sleepButton setBackgroundColor: [UIColor redColor]];
    sleepButton.titleLabel.font = [UIFont systemFontOfSize:32.0];
    [footerView addSubview:sleepButton];

    UIImage *deltaBtnImage = [UIImage imageNamed:@"btnDelta.png"];
    //deltaButton = [UIButton buttonWithType:UIButtonTypeRoundedRect];
    deltaButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [deltaButton setTitle:@"DELTA" forState:UIControlStateNormal];
    deltaButton.tag = 3;
    [deltaButton addTarget:self action:@selector(beginMeditation:) forControlEvents:UIControlEventTouchUpInside];
    deltaButton.frame = CGRectMake(headerView.bounds.size.width - (isiPad ? 250 : 210), 10, 120, 60);
    [deltaButton setImage:deltaBtnImage forState:UIControlStateNormal];
    //[deltaButton setTitleColor:UIColorFromRGB(0xFFFF00) forState:UIControlStateNormal];
    //[deltaButton setBackgroundColor: [UIColor greenColor]];
    deltaButton.titleLabel.font = [UIFont systemFontOfSize:32.0];
    [footerView addSubview:deltaButton];

    UIImage *thetaBtnImage = [UIImage imageNamed:@"btnTheta.png"];
    thetaButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [thetaButton setTitle:@"THETA" forState:UIControlStateNormal];
    thetaButton.tag = 4;
    [thetaButton addTarget:self action:@selector(beginMeditation:) forControlEvents:UIControlEventTouchUpInside];
    thetaButton.frame = CGRectMake(headerView.bounds.size.width - (isiPad ? 250 : 210), 10, 120, 60);
    [thetaButton setImage:thetaBtnImage forState:UIControlStateNormal];
    //[thetaButton setTitleColor:UIColorFromRGB(0xFFFF00) forState:UIControlStateNormal];
    //[thetaButton setBackgroundColor: [UIColor redColor]];
    thetaButton.titleLabel.font = [UIFont systemFontOfSize:32.0];
    [footerView addSubview:thetaButton];

    UIImage *natureBtnImage = [UIImage imageNamed:@"btnNature.png"];
    natureButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [natureButton setTitle:@"NATURE" forState:UIControlStateNormal];
    natureButton.tag = 5;
    [natureButton addTarget:self action:@selector(beginMeditation:) forControlEvents:UIControlEventTouchUpInside];
    natureButton.frame = CGRectMake(headerView.bounds.size.width - (isiPad ? 250 : 210), 10, 120, 60);
    [natureButton setImage:natureBtnImage forState:UIControlStateNormal];
    //[natureButton setTitleColor:UIColorFromRGB(0xFF8000) forState:UIControlStateNormal];
    //[natureButton setBackgroundColor: [UIColor redColor]];
    natureButton.titleLabel.font = [UIFont systemFontOfSize:32.0];
    [footerView addSubview:natureButton];
    
    UIImage *sleep2BtnImage = [UIImage imageNamed:@"btnSleep2.png"];
    sleepTopButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [sleepTopButton setTitle:@"SLEEP 2" forState:UIControlStateNormal];
    sleepTopButton.tag = 6;
    [sleepTopButton addTarget:self action:@selector(beginMeditation:) forControlEvents:UIControlEventTouchUpInside];
    sleepTopButton.frame = CGRectMake(headerView.bounds.size.width - (isiPad ? 250 : 210), 10, 120, 60);
    [sleepTopButton setImage:sleep2BtnImage forState:UIControlStateNormal];
    //[sleepTopButton setTitleColor:UIColorFromRGB(0xFF8000) forState:UIControlStateNormal];
    //[sleepTopButton setBackgroundColor: [UIColor greenColor]];
    sleepTopButton.titleLabel.font = [UIFont systemFontOfSize:32.0];
    [footerView addSubview:sleepTopButton];

    UIImage *lucidBtnImage = [UIImage imageNamed:@"btnDream.png"];
    lucidButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [lucidButton setTitle:@"DREAM" forState:UIControlStateNormal];
    lucidButton.tag = 7;
    [lucidButton addTarget:self action:@selector(beginMeditation:) forControlEvents:UIControlEventTouchUpInside];
    lucidButton.frame = CGRectMake(headerView.bounds.size.width - (isiPad ? 250 : 210), 10, 120, 60);
    [lucidButton setImage:lucidBtnImage forState:UIControlStateNormal];
    //[lucidButton setBackgroundColor: [UIColor greenColor]];
    //[lucidButton setTitleColor:UIColorFromRGB(0xFF0000) forState:UIControlStateNormal];
    lucidButton.titleLabel.font = [UIFont systemFontOfSize:32.0];
    [footerView addSubview:lucidButton];
    
    UIImage *napBtnImage = [UIImage imageNamed:@"btnNap.png"];
    napButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [napButton setTitle:@"NAP" forState:UIControlStateNormal];
    napButton.tag = 8;
    [napButton addTarget:self action:@selector(beginMeditation:) forControlEvents:UIControlEventTouchUpInside];
    napButton.frame = CGRectMake(headerView.bounds.size.width - (isiPad ? 250 : 210), 10, 120, 60);
    [napButton setImage:napBtnImage forState:UIControlStateNormal];
    //[napButton setTitleColor:UIColorFromRGB(0xFF0000) forState:UIControlStateNormal];
    //[napButton setBackgroundColor: [UIColor greenColor]];
    napButton.titleLabel.font = [UIFont systemFontOfSize:32.0];
    [footerView addSubview:napButton];
    
    UIImage *rateBtnImage = [UIImage imageNamed:@"btnRate.png"];
    rateButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [rateButton setTitle:@"RATE" forState:UIControlStateNormal];
    rateButton.tag = 7;
    [rateButton addTarget:self action:@selector(linkToReview:) forControlEvents:UIControlEventTouchUpInside];
    rateButton.frame = CGRectMake(headerView.bounds.size.width - (isiPad ? 250 : 210), 10, 120, 60);
    [rateButton setImage:rateBtnImage forState:UIControlStateNormal];
    rateButton.titleLabel.font = [UIFont systemFontOfSize:32.0];
    [footerView addSubview:rateButton];

    UIImage *phonesBtnImage = [UIImage imageNamed:@"btnPhones.png"];
    phonesButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [phonesButton setTitle:@"RATE" forState:UIControlStateNormal];
    phonesButton.tag = 8;
    [phonesButton addTarget:self action:@selector(linkToSleepphones:) forControlEvents:UIControlEventTouchUpInside];
    phonesButton.frame = CGRectMake(headerView.bounds.size.width - (isiPad ? 250 : 210), 10, 120, 60);
    [phonesButton setImage:phonesBtnImage forState:UIControlStateNormal];
    phonesButton.titleLabel.font = [UIFont systemFontOfSize:32.0];
    [footerView addSubview:phonesButton];

    
    /*
    reviewLink = [UIButton buttonWithType:UIButtonTypeRoundedRect];
    [reviewLink setTitle:@"Review this App" forState:UIControlStateNormal];
    [reviewLink addTarget:self action:@selector(linkToReview:) forControlEvents:UIControlEventTouchUpInside];
    [reviewLink setTitleColor:UIColorFromRGB(0x00ff00) forState:UIControlStateNormal];
    [reviewLink setTitleColor:UIColorFromRGB(0x00ff00) forState:UIControlStateSelected];
    reviewLink.frame = CGRectMake(headerView.bounds.size.width - (isiPad ? 250 : 210), 10, 200, 20);
    [footerView addSubview:reviewLink];

    sleepphonesLink = [UIButton buttonWithType:UIButtonTypeRoundedRect];
    [sleepphonesLink setTitle:@"Get SleepPhones" forState:UIControlStateNormal];
    [sleepphonesLink addTarget:self action:@selector(linkToSleepphones:) forControlEvents:UIControlEventTouchUpInside];
    [sleepphonesLink setTitleColor:UIColorFromRGB(0x00ff00) forState:UIControlStateNormal];
    [sleepphonesLink setTitleColor:UIColorFromRGB(0x00ff00) forState:UIControlStateSelected];
    sleepphonesLink.frame = CGRectMake(headerView.bounds.size.width - (isiPad ? 250 : 210), 10, 200, 20);
    [footerView addSubview:sleepphonesLink];
    */
    
    
    self.tableView.tableFooterView = footerView;
    [self resetCenters];
}

-(void)dealloc {
    [_audioController removeObserver:self forKeyPath:@"numberOfInputChannels"];
    
    NSMutableArray *channelsToRemove = [NSMutableArray arrayWithObjects:_voicePlayer, _naturePlayer, nil];
    [_audioController removeChannels:channelsToRemove];
    
    self.voicePlayer = nil;
    self.naturePlayer = nil;
    self.audioController = nil;
}

- (IBAction)linkToWeb:(UIButton *)selectedButton
{
    [[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"http://www.guidedmeditationtreks.com/sleep.html"]];
}

- (IBAction)linkToReview:(UIButton *)selectedButton
{
    [[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"itms-apps://itunes.apple.com/app/id1036406627"]];
}

- (IBAction)linkToSleepphones:(UIButton *)selectedButton
{
    [[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"https://www.sleepphones.com/?aff=69"]];
}


-(void)resetCenters {
    [gmtLink setCenter:CGPointMake(headerView.frame.size.width / 2, headerView.frame.size.height / 2 - 5)];
    [timerLabel setCenter:CGPointMake(headerView.frame.size.width / 2 + 7, headerView.frame.size.height / 2 + 20)];

    [sleepImage setCenter:CGPointMake(footerView.frame.size.width / 2, footerView.frame.size.height / 2 - 150)];
    [playButton setCenter:CGPointMake(footerView.frame.size.width / 2, footerView.frame.size.height / 2 - 150)];
    
    [introButton setCenter:CGPointMake(footerView.frame.size.width / 4, footerView.frame.size.height / 2 - 80)];
    [sleepButton setCenter:CGPointMake(footerView.frame.size.width / 4 + footerView.frame.size.width / 2, footerView.frame.size.height / 2 - 80)];
    
    [deltaButton setCenter:CGPointMake(footerView.frame.size.width / 4, footerView.frame.size.height / 2 - 10)];
    [thetaButton setCenter:CGPointMake(footerView.frame.size.width / 4 + footerView.frame.size.width / 2, footerView.frame.size.height / 2 - 10)];
    
    [natureButton setCenter:CGPointMake(footerView.frame.size.width / 4, footerView.frame.size.height / 2 + 60)];
    [sleepTopButton setCenter:CGPointMake(footerView.frame.size.width / 4 + footerView.frame.size.width / 2, footerView.frame.size.height / 2 + 60)];
    
    [lucidButton setCenter:CGPointMake(footerView.frame.size.width / 4, footerView.frame.size.height / 2 + 130)];
    [napButton setCenter:CGPointMake(footerView.frame.size.width / 4 + footerView.frame.size.width / 2, footerView.frame.size.height / 2 + 130)];

    [rateButton setCenter:CGPointMake(footerView.frame.size.width / 4, footerView.frame.size.height / 2 + 200)];
    [phonesButton setCenter:CGPointMake(footerView.frame.size.width / 4 + footerView.frame.size.width / 2, footerView.frame.size.height / 2 + 200)];
    

    /*
    [rateButton setCenter:CGPointMake(footerView.frame.size.width / 2, footerView.frame.size.height / 2 + 180)];
    [sleepphonesLink setCenter:CGPointMake(footerView.frame.size.width / 2, footerView.frame.size.height / 2 + 210)];
*/
}

-(void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
}

-(void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
}

-(void)viewDidLayoutSubviews {
    [self resetCenters];
}

-(BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation {
    return YES;
}

-(NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    switch ( section ) {
        case 0:
            return 3;
        default:
            return 0;
    }
}

-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    BOOL isiPad = [[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad;
    
    //static NSString *cellIdentifier = @"cell";
    NSString *cellIdentifier = [NSString stringWithFormat:@"cell%ld", (long)indexPath.item];
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
    
    if ( !cell ) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cellIdentifier];
    }
    [cell setBackgroundColor: [UIColor blackColor]];
    [cell.textLabel setBackgroundColor:[UIColor blackColor]];
    [cell.textLabel setTextColor:[UIColor whiteColor]];
    
    //[cell setBackgroundColor:[UIColor brownColor]];
    
    cell.accessoryType = UITableViewCellAccessoryNone;
    cell.accessoryView = nil;
    cell.selectionStyle = UITableViewCellSelectionStyleNone;
    [[cell viewWithTag:kAuxiliaryViewTag] removeFromSuperview];
    
    switch ( indexPath.section ) {
        case 0: {
            
            switch ( indexPath.row ) {
                case 0: {
                    cell.textLabel.text = @"Voice";
                    voiceSlider = [[UISlider alloc] initWithFrame:CGRectMake((isiPad ? 235 : 150), 0, (isiPad ? 400 : 100), cell.bounds.size.height)];
                    voiceSlider.tag = kAuxiliaryViewTag;
                    voiceSlider.maximumValue = 1.0;
                    voiceSlider.minimumValue = 0.0;
                    [cell addSubview:voiceSlider];
                    voiceSlider.value = [defaults floatForKey:@"voiceVolume"];
                    [voiceSlider addTarget:self action:@selector(loop1VolumeChanged:) forControlEvents:UIControlEventValueChanged];
                    break;
                }
                case 1: {
                    tonesSlider = [[UISlider alloc] initWithFrame:CGRectMake((isiPad ? 235 : 150), 0, (isiPad ? 400 : 100), cell.bounds.size.height)];
                    //tonesSlider = [[UISlider alloc] initWithFrame:CGRectZero];
                    tonesSlider.tag = kAuxiliaryViewTag;
                    
                    [tonesSlider setMaximumValue:.75f];
                    tonesSlider.minimumValue = 0.0;

                    cell.textLabel.text = @"Tones";
                    
                    [cell addSubview:tonesSlider];
                    tonesSlider.value = [defaults floatForKey:@"tonesVolume"];
                    [tonesSlider addTarget:self action:@selector(oscillatorVolumeChanged:) forControlEvents:UIControlEventValueChanged];
                    
                    cell.accessoryView = [[UISwitch alloc] initWithFrame:CGRectZero];
                    tonesSwitch = ((UISwitch*)cell.accessoryView);
                    ((UISwitch*)cell.accessoryView).on = [defaults boolForKey:@"useIsochronic"];
                    [((UISwitch*)cell.accessoryView) setOnTintColor: [UIColor purpleColor]];
                    [((UISwitch*)cell.accessoryView) setTintColor: [UIColor purpleColor]];

                    isIsochronic = [defaults boolForKey:@"useIsochronic"];
                    [((UISwitch*)cell.accessoryView) addTarget:self action:@selector(oscillatorSwitchChanged:) forControlEvents:UIControlEventValueChanged];
                    break;
                }
                case 2: {
                    //natureSlider = [[UISlider alloc] initWithFrame:CGRectMake(cell.bounds.size.width - (isiPad ? 250 : 210), 0, 100, cell.bounds.size.height)];
                    //natureSlider.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin;
                    
                    natureSlider = [[UISlider alloc] initWithFrame:CGRectMake((isiPad ? 235 : 150), 0, (isiPad ? 400 : 100), cell.bounds.size.height)];
                    natureSlider.tag = kAuxiliaryViewTag;
                    natureSlider.maximumValue = 1.0;
                    natureSlider.minimumValue = 0.0;
                    cell.textLabel.text = @"Nature";
                    natureSlider.value = [defaults floatForKey:@"natureVolume"];
                    [natureSlider addTarget:self action:@selector(loop2VolumeChanged:) forControlEvents:UIControlEventValueChanged];
                    [cell addSubview:natureSlider];
                    
                    id picker = [self.pickersController pickerForOwnerCellIndexPath:indexPath];
                    if (picker) {
                        cell.textLabel.textColor = UIColorFromRGB(0x4b0082);
                        if ([picker isKindOfClass:UIPickerView.class]) {
                            UIPickerView *pickerView = (UIPickerView *)picker;
                            [pickerView setBackgroundColor:[UIColor blackColor]];
                            //Pre-select
                            NSUInteger currentIndex = [pickerArray indexOfObject:currentNatureKey];
                            if (currentIndex != 2147483647)
                            {
                                [pickerView selectRow:currentIndex inComponent:0 animated:YES];
                            }
                            else
                            {
                                //currentNatureKey = [self pickerView:pickerView titleForRow:0 forComponent:0];
                                NSAttributedString *pickerAttString = [self pickerView:pickerView attributedTitleForRow:0 forComponent:0];
                                currentNatureKey = pickerAttString.string;
                                [defaults setObject:currentNatureKey forKey:@"natureSound"];
                                [defaults synchronize];
                            }
                            natureLabel = cell.textLabel;
                            natureLabel.textColor = UIColorFromRGB(0x00ff00);
                            cell.textLabel.text = currentNatureKey;
                        }
                    } else {
                        cell.textLabel.textColor = [UIColor lightGrayColor];
                        cell.textLabel.text = [NSString stringWithFormat:@"Section: %ld row: %ld", (long)indexPath.section, (long)indexPath.row];
                    }
                    cell.accessoryView = [[UISwitch alloc] initWithFrame:CGRectZero];
                    natureSwitch = ((UISwitch*)cell.accessoryView);
                    ((UISwitch*)cell.accessoryView).on = letNatureRun;
                    [((UISwitch*)cell.accessoryView) addTarget:self action:@selector(setLetNatureRun:) forControlEvents:UIControlEventValueChanged];
                    break;
                }
            }
            break;
        }
    }
    return cell;
}

// The number of columns of data
- (long)numberOfComponentsInPickerView:(UIPickerView *)pickerView
{
    return (long)1;
}

// The number of rows of data
- (long)pickerView:(UIPickerView *)pickerView numberOfRowsInComponent:(NSInteger)component
{
    return (long)pickerArray.count;
}

// The data to return for the row and component (column) that's being passed in
//- (NSString*)pickerView:(UIPickerView *)pickerView titleForRow:(NSInteger)row forComponent:(NSInteger)component
//{
//    return pickerArray[row];
//}

/*
- (NSAttributedString *)pickerView:(UIPickerView *)pickerView attributedTitleForRow:(NSInteger)row forComponent:(NSInteger)component
{
    NSString *title = pickerArray[row];
    NSAttributedString *attString = [[NSAttributedString alloc] initWithString:title attributes:@{NSForegroundColorAttributeName:[UIColor whiteColor]}];
    return attString;
}
 */


- (UIView *)pickerView:(UIPickerView *)pickerView viewForRow:(NSInteger)row forComponent:(NSInteger)component reusingView:(UIView *)view{
    

    //UIImage *img = [UIImage imageNamed:[NSString stringWithFormat:@"nRain.png"]];
    NSArray *arr = [natureDictionary valueForKey:pickerArray[row]];
    UIImage *img = arr[1];
    UIImageView *temp = [[UIImageView alloc] initWithImage:img];
    temp.frame = CGRectMake(0, 0, 40, 40);
    [temp setBackgroundColor:[UIColor blueColor]];
    
    UILabel *channelLabel = [[UILabel alloc] initWithFrame:CGRectMake(50, 0, 250, 40)];
    channelLabel.adjustsFontSizeToFitWidth = YES;
    channelLabel.text = [NSString stringWithFormat:@"%@", pickerArray[row]];
    //channelLabel.textAlignment = UITextAlignmentLeft;
    channelLabel.backgroundColor = [UIColor blackColor];
    channelLabel.textColor = [UIColor whiteColor];
    
    UIView *tmpView = [[UIView alloc] initWithFrame:CGRectMake(50, 0, 250, 40)];
    [tmpView setBackgroundColor:[UIColor blackColor]];
    [tmpView insertSubview:temp atIndex:0];
    [tmpView insertSubview:channelLabel atIndex:1];
    
    return tmpView;
}



- (void)pickerView:(UIPickerView *)pickerView didSelectRow:(NSInteger)row inComponent:(NSInteger)component
{
    NSIndexPath *ip = [self.pickersController indexPathForPicker:pickerView];
    if (ip) {
        UIView *v = [self pickerView:pickerView viewForRow:row forComponent:0 reusingView:nil];
        UILabel * channelLabel = [v.subviews objectAtIndex:1];
        NSString * labelName = channelLabel.text;
        
        //NSAttributedString *pickerAttString = [self pickerView:pickerView attributedTitleForRow:row forComponent:0];
        //if ([pickerAttString.string isEqualToString:@"Xpand Nature Collection"])
        if ([labelName isEqualToString:@"Xpand Nature Collection"])
        {
            [self launchInAppStoryboard];
        } else {
            currentNatureKey = labelName;
            [defaults setObject:currentNatureKey forKey:@"natureSound"];
            [defaults synchronize];
            [self initNature];
            [self.tableView reloadRowsAtIndexPaths:@[ip] withRowAnimation:UITableViewRowAnimationAutomatic];
        }
    }
}

- (void)loop1VolumeChanged:(UISlider*)sender {
    if (_voicePlayer != nil)
        _voicePlayer.volume = sender.value;
    [defaults setFloat:sender.value forKey:@"voiceVolume"];
    [defaults synchronize];
}

- (void)loop2VolumeChanged:(UISlider*)sender {
    if (_naturePlayer != nil)
        _naturePlayer.volume = sender.value;
    [defaults setFloat:sender.value forKey:@"natureVolume"];
    [defaults synchronize];
}

- (void)oscillatorSwitchChanged:(UISwitch*)sender {
    isIsochronic = sender.isOn;
    sampleFrame = 0;
    [defaults setBool:sender.isOn forKey:@"useIsochronic"];
    [defaults synchronize];
}

- (void) setLetNatureRun:(UISwitch*) sender {
    letNatureRun = sender.isOn;
    if (!letNatureRun && isMeditationFinished)
    {
        [self shutDownMeditation];
    }
}

- (void)oscillatorVolumeChanged:(UISlider*)sender {
    if (_oscillator != nil) _oscillator.volume = sender.value;
    [defaults setFloat:sender.value forKey:@"tonesVolume"];
    [defaults synchronize];

}

- (void) beginMeditation:(UIButton*) sender {
    switch (sender.tag) {
        case 1: //intro
            [self initalizeMeditation:ID_INTRO];
            break;
        case 2: //sleep
            [self initalizeMeditation:ID_SLEEP];
            break;
        case 3: //delta
            [self initalizeMeditation:ID_DELTA];
            break;
        case 4: //theta
            [self initalizeMeditation:ID_THETA];
            break;
        case 5: //Nature
            [self initalizeMeditation:ID_NATURE];
            break;
        case 6: //sleep 2
            [self initalizeMeditation:ID_SLEEP2];
            break;
        case 7: //dream
            [self initalizeMeditation:ID_DREAM];
            break;
        case 8: //nap
            napShiftStarted = NO;
            [self initalizeMeditation:ID_NAP];
            break;
        default:
            break;
    }
}

-(void)togglePlay {
    [playButton setSelected:!playButton.isSelected];
    
    if (currentMeditationTrack == nil && !isMeditationPlaying)
    {
        letNatureRun = YES;
        [natureSwitch setOn:YES];
        [self initalizeMeditation:ID_NATURE];
    } else {
        if (letNatureRun && isMeditationFinished)
        {
            _naturePlayer.channelIsPlaying = playButton.isSelected;
            
        }
        else
        {
            isMeditationPlaying = playButton.isSelected;
            [self setToPlay:isMeditationPlaying];
        }
    }
}

-(void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    if ( context == &kInputChannelsChangedContext ) {
        [self.tableView reloadSections:[NSIndexSet indexSetWithIndex:3] withRowAnimation:UITableViewRowAnimationFade];
    }
}


#pragma mark - PickerCellsDelegate

- (void)pickerCellsController:(PickerCellsController *)controller willExpandTableViewContent:(UITableView *)tableView forHeight:(CGFloat)expandHeight {
    NSLog(@"expand height = %.f", expandHeight);
}

- (void)pickerCellsController:(PickerCellsController *)controller willCollapseTableViewContent:(UITableView *)tableView forHeight:(CGFloat)expandHeight {
    NSLog(@"collapse height = %.f", expandHeight);
}


@end
