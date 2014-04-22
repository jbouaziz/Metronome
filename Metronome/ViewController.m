//
//  ViewController.m
//  Metronome
//
//  Created by Jonathan BOUAZIZ on 21/04/2014.
//  Copyright (c) 2014 jbouaziz. All rights reserved.
//

#import "ViewController.h"
#import <AVFoundation/AVFoundation.h>


static int MetronomeBPMMinValue   = 1;
static int MetronomeBPMMaxValue   = 220;
static int MetronomeBPCMinValue   = 1;
static int MetronomeBPCMaxValue   = 99;
static int MetronomeSoundDuration = .05;


@interface ViewController () <AVAudioPlayerDelegate>

@property (weak, nonatomic) IBOutlet UITextField *bpmTextField;
@property (weak, nonatomic) IBOutlet UITextField *bpcTextField;
@property (weak, nonatomic) IBOutlet UIStepper *bpmStepper;
@property (weak, nonatomic) IBOutlet UIStepper *bpcStepper;
@property (weak, nonatomic) IBOutlet UILabel *bpmName;
@property (weak, nonatomic) IBOutlet UIButton *playButton;

@property (strong, nonatomic) AVAudioPlayer *tickPlayer;
@property (strong, nonatomic) AVAudioPlayer *tockPlayer;
@property (assign, nonatomic) int bpmValue;
@property (assign, nonatomic) int bpcValue;
@property (nonatomic, getter = isPlaying) BOOL playing;


- (IBAction)bpmTextFieldValueChanged:(UITextField *)sender;
- (IBAction)bpcTextFieldValueChanged:(UITextField *)sender;
- (IBAction)bpmStepperValueChanged:(UIStepper *)sender;
- (IBAction)bpcStepperValueChanged:(UIStepper *)sender;
- (IBAction)playButtonAction:(UIButton *)sender;

@end


@implementation ViewController {
    int _tickCount;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    // Prepare players
    //
    [self.tickPlayer prepareToPlay];
    [self.tockPlayer prepareToPlay];
    
    
    // Defaults values
    //
    self.bpmValue = 120;
    self.bpcValue = 8;
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    // self.playing = YES;
}

- (void)dealloc {
    [_tickPlayer stop];
    _tickPlayer = nil;
    [_tockPlayer stop];
    _tockPlayer = nil;
}


#pragma mark - Getters / Setters

- (AVAudioPlayer *)tickPlayer {
    
    if (!_tickPlayer) {
        NSString *soundFilePath = [NSString stringWithFormat:@"%@/tick.mp3", [[NSBundle mainBundle]
                                                                          resourcePath]];
        NSURL *url = [NSURL fileURLWithPath:soundFilePath];
        NSError *error;
        _tickPlayer = [[AVAudioPlayer alloc] initWithContentsOfURL:url error:&error];
        _tickPlayer.delegate = self;
    }
    
    return _tickPlayer;
}

- (AVAudioPlayer *)tockPlayer {
    
    if (!_tockPlayer) {
        NSString *soundFilePath = [NSString stringWithFormat:@"%@/tock.mp3", [[NSBundle mainBundle]
                                                                          resourcePath]];
        NSURL *url = [NSURL fileURLWithPath:soundFilePath];
        NSError *error;
        _tockPlayer = [[AVAudioPlayer alloc] initWithContentsOfURL:url error:&error];
        _tockPlayer.delegate = self;
    }
    
    return _tockPlayer;
}

- (void)setBpmValue:(int)bpmValue {
    
    //
    // 1 <= BPM <= 220
    //
    bpmValue = MIN(MAX(bpmValue, MetronomeBPMMinValue), MetronomeBPMMaxValue);
    _bpmValue = bpmValue;
    
    
    // Update UI
    //
    self.bpmTextField.text = [NSString stringWithFormat:@"%d", bpmValue];
    self.bpmStepper.value = bpmValue;
    [self updateBpmName];
}

- (void)setBpcValue:(int)bpcValue {
    
    //
    // 1 <= BPC <= 99
    //
    bpcValue = MIN(MAX(bpcValue, MetronomeBPCMinValue), MetronomeBPCMaxValue);
    _bpcValue = bpcValue;
    
    
    // Update UI
    //
    self.bpcTextField.text = [NSString stringWithFormat:@"%d", bpcValue];
    self.bpcStepper.value = bpcValue;
}

- (BOOL)isPlaying {
    return [_tickPlayer isPlaying] || [_tockPlayer isPlaying];
}

- (void)setPlaying:(BOOL)playing {
    
    self.playButton.selected = playing;
    
    
    //
    // STOP players no matter what
    //
    [self.tickPlayer stop];
    [self.tockPlayer stop];
    _tickCount = 0;
    
    
    //
    // PLAY
    //
    if (playing) {
        
        // Start playing TICK
        //
        BOOL success = [self.tickPlayer play];
        NSLog(@"Started tick player :%d", success);
    }
}


#pragma mark - Private Methods

- (void)updateBpmName {
    int bpm = self.bpmValue;
    
    NSString *name;
    if (bpm <= 20) name       = @"Larghissimo";
    else if (bpm <= 40) name  = @"Largamente";
    else if (bpm <= 60) name  = @"Largo";
    else if (bpm <= 66) name  = @"Larghetto";
    else if (bpm <= 76) name  = @"Adagio";
    else if (bpm <= 80) name  = @"Adagietto";
    else if (bpm <= 108) name = @"Andante";
    else if (bpm <= 120) name = @"Moderato";
    else if (bpm <= 168) name = @"Allegro";
    else if (bpm <= 200) name = @"Presto";
    else if (bpm <= 300) name = @"Prestissimo";
    
    self.bpmName.text = name;
}


#pragma mark - AVAudioPlayerDelegate

- (void)audioPlayerDidFinishPlaying:(AVAudioPlayer *)player successfully:(BOOL)flag {
    if (!self.playButton.selected) return;
    
    
    // Calculate speed
    //
    float speed = (60 / (float)self.bpmValue) - MetronomeSoundDuration;

    if (player == self.tickPlayer) {
        
        //
        // If the Beat per circle is one, we only play the TICK
        //
        if (self.bpcValue == 1) {
            [self runPlayer:self.tickPlayer delay:speed];
        }
        
        //
        // Otherwise we play both TICK and TOCK sounds
        //
        else {

            AVAudioPlayer *player = (++_tickCount < self.bpcValue - 1) ? self.tickPlayer : self.tockPlayer;
            [self runPlayer:player delay:speed];
        }
    }
    
    else if (player == self.tockPlayer) {
        _tickCount = 0;
        [self runPlayer:self.tickPlayer delay:speed];
    }
}

- (void)runPlayer:(AVAudioPlayer *)player delay:(NSTimeInterval)delay {
    if (!player) return;
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delay * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        if (!self.playButton.selected) return;
        
        [player play];
    });
}


#pragma mark - Actions

- (IBAction)bpmTextFieldValueChanged:(UITextField *)sender {
    self.bpmValue = sender.text.intValue;
}

- (IBAction)bpcTextFieldValueChanged:(UITextField *)sender {
    self.bpcValue = sender.text.intValue;
}

- (IBAction)bpmStepperValueChanged:(UIStepper *)sender {
    self.bpmValue = sender.value;
}

- (IBAction)bpcStepperValueChanged:(UIStepper *)sender {
    self.bpcValue = sender.value;
}

- (IBAction)playButtonAction:(UIButton *)sender {
    
    /**
     *  If the button is selected, it means that it displays STOP.
     *  Otherwise it's on PLAY
     */
    self.playing = !sender.selected;
}

@end
