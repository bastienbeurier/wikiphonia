//
//  ViewController.m
//  wikiphonia
//
//  Created by Bastien Beurier on 4/24/15.
//  Copyright (c) 2015 bastien. All rights reserved.
//

#import "MainViewController.h"
#import <AVFoundation/AVFoundation.h>
#import "WikiApi.h"

@interface MainViewController ()

@property (strong, nonatomic) SKRecognizer* recognizer;
@property (strong, nonatomic) SKVocalizer* vocalizer;
@property BOOL isSpeaking;

@end

const unsigned char SpeechKitApplicationKey[] =
{
    0xe8, 0x5c, 0x7d, 0xe8, 0x1c, 0xf4, 0xe5, 0x9e, 0xbb,
    0x83, 0xf4, 0x91, 0x1e, 0x19, 0xdd, 0x7a, 0xfe, 0xab,
    0xe3, 0x82, 0xbf, 0xd0, 0x60, 0x6b, 0x62, 0x0e, 0x8b,
    0xfb, 0x2f, 0x41, 0x2f, 0x17, 0x9e, 0xac, 0xff, 0xba,
    0xa0, 0xe5, 0x58, 0x5b, 0x68, 0x4d, 0xec, 0x86, 0x66,
    0xc9, 0x00, 0x64, 0x75, 0xe3, 0xe6, 0x34, 0xb3, 0x46,
    0xa0, 0x16, 0x55, 0x2b, 0x11, 0x84, 0x6d, 0x40, 0x9c, 0x0b
};

@implementation MainViewController {
    enum {
        TS_IDLE,
        TS_INITIAL,
        TS_RECORDING,
        TS_PROCESSING,
    } transactionState;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [SpeechKit setupWithID:@"NMDPTRIAL_bastienbeurier_gmail_com20150424145836"
                      host:@"sandbox.nmdp.nuancemobility.net"
                      port:443
                    useSSL:NO
                  delegate:self];
    
    // Set earcons to play
    SKEarcon* earconStart	= [SKEarcon earconWithName:@"earcon_listening.wav"];
    SKEarcon* earconStop	= [SKEarcon earconWithName:@"earcon_done_listening.wav"];
    SKEarcon* earconCancel	= [SKEarcon earconWithName:@"earcon_cancel.wav"];
    
    [SpeechKit setEarcon:earconStart forType:SKStartRecordingEarconType];
    [SpeechKit setEarcon:earconStop forType:SKStopRecordingEarconType];
    [SpeechKit setEarcon:earconCancel forType:SKCancelRecordingEarconType];
    
//    NSString *str = @"Stack Overflow is a privately held website, the flagship site of the Stack Exchange Network, created in 2008 by Jeff Atwood and Joel Spolsky, as a more open alternative to earlier Q&A sites such as Experts-Exchange. The name for the website was chosen by voting in April 2008 by readers of Coding Horror, Atwood's popular programming blog.";
//    
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    SKEndOfSpeechDetection detectionType = SKShortEndOfSpeechDetection;
    NSString* recoType = SKSearchRecognizerType;
    NSString* langType = @"en_US";
    
    transactionState = TS_INITIAL;
    self.recognizer = [[SKRecognizer alloc] initWithType:recoType
                                               detection:detectionType
                                                language:langType
                                                delegate:self];
}

#pragma mark SKRecognizerDelegate methods

- (void)recognizerDidBeginRecording:(SKRecognizer *)recognizer
{
    transactionState = TS_RECORDING;
}

- (void)recognizerDidFinishRecording:(SKRecognizer *)recognizer
{
    transactionState = TS_PROCESSING;
}

- (void)recognizer:(SKRecognizer *)recognizer didFinishWithResults:(SKRecognition *)results
{
    long numOfResults = [results.results count];
    
    transactionState = TS_IDLE;
    
    if (numOfResults > 0) {
        [WikiApi getArticleContentWithTitle:[results firstResult] success:^(NSString *title, NSString *extract) {
            if (extract && [extract length] > 0) {
                [self speak:[NSString stringWithFormat:@"%@. %@", title, extract]];
            } else {
                [self speak:[NSString stringWithFormat:@"Nothing on Wikipedia corresponding to %@.", [results firstResult]]];
            }
        } failure:^{
            [self speak:@"Connection problem. Please try again."];
        }];
    } else if (results.suggestion  && [results.suggestion length] > 0) {
        [self speak:results.suggestion];
    } else {
        [self speak:@"Please repete."];
    }
}

- (void)recognizer:(SKRecognizer *)recognizer didFinishWithError:(NSError *)error suggestion:(NSString *)suggestion
{
    transactionState = TS_IDLE;
    
    if (suggestion && [suggestion length] > 0) {
        [self speak:suggestion];
    } else {
        [self speak:@"Please repete."];
    }
}

- (void)speak:(NSString *)str {
    AVSpeechSynthesizer *synthesizer = [[AVSpeechSynthesizer alloc] init];
    AVSpeechUtterance *utterance = [[AVSpeechUtterance alloc] initWithString:str];
    utterance.rate = 0.10;
    utterance.voice = [AVSpeechSynthesisVoice voiceWithLanguage:@"en-US"];
    [synthesizer speakUtterance:utterance];
}


@end
