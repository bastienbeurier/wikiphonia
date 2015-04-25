//
//  ViewController.m
//  wikiphonia
//
//  Created by Bastien Beurier on 4/24/15.
//  Copyright (c) 2015 bastien. All rights reserved.
//

#import "MainViewController.h"
#import "WikiApi.h"
#import "WikiHelper.h"

@interface MainViewController ()

@property (strong, nonatomic) SKRecognizer* recognizer;
@property (strong, nonatomic) SKVocalizer* vocalizer;

@property BOOL isReading;

@property (strong, nonatomic) NSMutableArray *headers;
@property (strong, nonatomic) NSMutableArray *sections;

@property (strong, nonatomic) NSString *currentHeader;
@property (strong, nonatomic) NSString *currentSection;

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
    
    enum {
        SS_LISTEN_QUERY,
        SS_SECTION_INQUIRY,
        SS_SECTION_READING,
        SS_END_OF_ARTICLE,
        SS_INSTRUCTION_ERROR,
        SS_SPEECH_QUERY_ERROR
    } synthesizerSaid;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.isReading = NO;
    
    [SpeechKit setupWithID:@"NMDPTRIAL_bastienbeurier_gmail_com20150424145836"
                      host:@"sandbox.nmdp.nuancemobility.net"
                      port:443
                    useSSL:NO
                  delegate:self];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    [self listenQuery];
}

#pragma mark Reading

- (void)inquireAboutNextSection {
    self.isReading = YES;
    
    if (self.headers && [self.headers count] > 0 && self.sections && [self.sections count] > 0) {
        synthesizerSaid = SS_SECTION_INQUIRY;
        [self speak:[NSString stringWithFormat:@"Read %@?", [self.headers firstObject]]];
    } else {
        [self stopReading:NO];
    }
}

- (void)readNextSection {
    self.currentHeader = [self.headers firstObject];
    self.currentSection = [self.sections firstObject];
    
    [self.sections removeObjectAtIndex:0];
    [self.headers removeObjectAtIndex:0];
    
    synthesizerSaid = SS_SECTION_READING;
    [self speak:[NSString stringWithFormat:@"%@. %@", self.currentHeader, self.currentSection]];
}

- (void)repeatSection {
    if (self.currentHeader && self.currentSection) {
        synthesizerSaid = SS_SECTION_READING;
        [self speak:[NSString stringWithFormat:@"%@. %@", self.currentHeader, self.currentSection]];
    } else {
        synthesizerSaid = SS_INSTRUCTION_ERROR;
        [self speak:@"Nothing to repeat. Please say yes, no, or stop."];
    }
}

- (void)skipNextSection {
    [self.sections removeObjectAtIndex:0];
    [self.headers removeObjectAtIndex:0];
    
    [self inquireAboutNextSection];
}

- (void)stopReading:(BOOL)interrupted {
    self.isReading = NO;
    
    synthesizerSaid = SS_END_OF_ARTICLE;
    
    if (interrupted) {
        [self speak:@"Article dismissed."];
    } else {
        [self speak:@"End of article."];
    }
}

#pragma mark Recording

- (void)listenQuery {
    synthesizerSaid = SS_LISTEN_QUERY;
    [self speak:@"Listening."];
}

- (void)startRecording {
    SKEndOfSpeechDetection detectionType = SKShortEndOfSpeechDetection;
    NSString* recoType = SKSearchRecognizerType;
    NSString* langType = @"en_US";
    
    transactionState = TS_INITIAL;
    self.recognizer = [[SKRecognizer alloc] initWithType:recoType
                                               detection:detectionType
                                                language:langType
                                                delegate:self];
}

#pragma mark Synthetizing

- (void)speak:(NSString *)str {
    AVSpeechSynthesizer *synthesizer = [[AVSpeechSynthesizer alloc] init];
    AVSpeechUtterance *utterance = [[AVSpeechUtterance alloc] initWithString:str];
    utterance.rate = 0.10;
    utterance.voice = [AVSpeechSynthesisVoice voiceWithLanguage:@"en-US"];
    synthesizer.delegate = self;
    [synthesizer speakUtterance:utterance];
}

#pragma mark AVSpeechSynthesizer protocol

- (void)speechSynthesizer:(AVSpeechSynthesizer *)synthesizer didFinishSpeechUtterance:(AVSpeechUtterance *)utterance {
    if (synthesizerSaid == SS_LISTEN_QUERY || synthesizerSaid == SS_SECTION_INQUIRY) {
        [self startRecording];
    } else if (synthesizerSaid == SS_SECTION_READING || synthesizerSaid == SS_INSTRUCTION_ERROR) {
        [self inquireAboutNextSection];
    } else if (synthesizerSaid == SS_END_OF_ARTICLE || synthesizerSaid == SS_SPEECH_QUERY_ERROR) {
        [self listenQuery];
    }
}

#pragma mark Recognizing

- (void)instructionRecognized:(SKRecognition *)results {
    long numOfResults = [results.results count];
    
    transactionState = TS_IDLE;
    
    if (numOfResults > 0) {
        //Listening for yes or no answer.
        if ([[[results firstResult] lowercaseString] isEqualToString:@"yes"]) {
            [self readNextSection];
        } else if ([[[results firstResult] lowercaseString] isEqualToString:@"no"]) {
            [self skipNextSection];
        } else if ([[[results firstResult] lowercaseString] isEqualToString:@"repeat"]) {
            [self repeatSection];
        } else if ([[[results firstResult] lowercaseString] isEqualToString:@"stop"]) {
            [self stopReading:YES];
        } else {
            synthesizerSaid = SS_INSTRUCTION_ERROR;
            [self speak:@"Please say yes, no, stop, or repeat."];
        }

    } else {
        synthesizerSaid = SS_INSTRUCTION_ERROR;
        [self speak:@"Please say yes, no, stop, or repeat."];
    }
}

- (void)queryRecognized:(SKRecognition *)results {
    long numOfResults = [results.results count];
    
    transactionState = TS_IDLE;
    
    if (numOfResults > 0) {
        //Search query.
        [WikiApi getArticleContentWithTitle:[results firstResult] success:^(NSString *title, NSString *extract) {
            if (extract && [extract length] > 0) {
                NSArray *headersAndSections = [WikiHelper processArticleExtract:extract];
                self.headers = headersAndSections[0];
                self.sections = headersAndSections[1];
                
                [self inquireAboutNextSection];
            } else {
                synthesizerSaid = SS_SPEECH_QUERY_ERROR;
                [self speak:[NSString stringWithFormat:@"Nothing on Wikipedia corresponding to %@.", [results firstResult]]];
            }
        } failure:^{
            synthesizerSaid = SS_SPEECH_QUERY_ERROR;
            [self speak:@"Connection problem. Please try again."];
        }];
    } else {
        synthesizerSaid = SS_SPEECH_QUERY_ERROR;
        [self speak:@"Please repete."];
    }
}


#pragma mark SKRecognizer protocol

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
    if (self.isReading) {
        [self instructionRecognized:results];
    } else {
        [self queryRecognized:results];
    }
}

- (void)recognizer:(SKRecognizer *)recognizer didFinishWithError:(NSError *)error suggestion:(NSString *)suggestion {
    transactionState = TS_IDLE;
    
    if (self.isReading) {
        synthesizerSaid = SS_INSTRUCTION_ERROR;
        [self speak:@"Please say yes, no, stop, or repeat."];
    } else {
        synthesizerSaid = SS_SPEECH_QUERY_ERROR;
        [self speak:@"Please repete."];
    }
}


@end
