//
//  IAPHelper.m
//  GuidedMeds
//
//  Created by Mr Russell on 1/20/15.
//  Copyright (c) 2015 Guided Meditation Treks. All rights reserved.
//

#import "IAPHelper.h"
#import <StoreKit/StoreKit.h>

@interface IAPHelper () //<SKProductsRequestDelegate, SKPaymentTransactionObserver>
@end


@implementation IAPHelper {
}

+ (NSString *) downloadableContentPath;
{
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSApplicationSupportDirectory, NSUserDomainMask, YES);
    NSString *directory = [paths objectAtIndex:0];
    directory = [directory stringByAppendingPathComponent:@"Downloads"];
    
    NSFileManager *fileManager = [NSFileManager defaultManager];
    
    if ([fileManager fileExistsAtPath:directory] == NO) {
        
        NSError *error;
        if ([fileManager createDirectoryAtPath:directory withIntermediateDirectories:YES attributes:nil error:&error] == NO) {
            NSLog(@"Error: Unable to create directory: %@", error);
        }
        
        NSURL *url = [NSURL fileURLWithPath:directory];
        // exclude downloads from iCloud backup
        if ([url setResourceValue:[NSNumber numberWithBool:YES] forKey:NSURLIsExcludedFromBackupKey error:&error] == NO) {
            NSLog(@"Error: Unable to exclude directory from backup: %@", error);
        }
    }
    return directory;
}

+ (BOOL) filesDownloaded:(NSArray*)fileNames
{
    bool returnVal = YES;
    for (NSURL *af in fileNames)
    {
        bool fileExists = [[NSFileManager defaultManager] fileExistsAtPath:[af path]];
        if (!fileExists)
        {
            returnVal = NO;
        }
    }
    return returnVal;
}

+ (BOOL) natureFilesDownloaded:(NSArray*)fileNames
{
    bool returnVal = YES;
    for (NSArray *aa in fileNames)
    {
        NSURL *af = [aa objectAtIndex:0];
        bool fileExists = [[NSFileManager defaultManager] fileExistsAtPath:[af path]];
        if (!fileExists)
        {
            returnVal = NO;
        }
    }
    return returnVal;
}


+ (BOOL) isMeditationDownloaded:(NSString*)trackId
{
    NSMutableArray* matrix =  [self getAudioMatrix:trackId];
    NSMutableArray *mutableFileNames = [[NSMutableArray alloc] init];
    
    for(NSMutableArray *track in matrix) {
        [mutableFileNames addObject:[track objectAtIndex:2]];
    }
    
    return [self filesDownloaded:mutableFileNames];
}

+ (NSArray*) getNatureFilenames {
    return [[IAPHelper getNatureDictionary].allKeys sortedArrayUsingSelector: @selector(caseInsensitiveCompare:)];
}

+ (NSDictionary*) getNatureDictionary {
    
    NSArray *rainSoft = @[[[NSBundle mainBundle] URLForResource:@"Raining-noise" withExtension:@"m4a"], [UIImage imageNamed:@"nRain.png"]];
    NSArray *rainHard = @[[[NSBundle mainBundle] URLForResource:@"Rain_Background-Mike_Koenig-1681389445" withExtension:@"m4a"], [UIImage imageNamed:@"nRain.png"]];
    NSArray *noisePink = @[[[NSBundle mainBundle] URLForResource:@"pinkNoise" withExtension:@"m4a"], [UIImage imageNamed:@"nNoise.png"]];
    NSArray *noiseWhite = @[[[NSBundle mainBundle] URLForResource:@"whiteNoise" withExtension:@"m4a"], [UIImage imageNamed:@"nNoise.png"]];
    NSArray *birds = @[[[NSBundle mainBundle] URLForResource:@"Birds-chirping-sound-morning-bird-sounds" withExtension:@"m4a"], [UIImage imageNamed:@"nBird.png"]];
    NSArray *cardinals = @[[[NSBundle mainBundle] URLForResource:@"Cardinal-sounds" withExtension:@"m4a"], [UIImage imageNamed:@"nBird.png"]];
    NSArray *frogs = @[[[NSBundle mainBundle] URLForResource:@"Frogs-Lisa_Redfern-1150052170" withExtension:@"m4a"], [UIImage imageNamed:@"nGrass.png"]];
    NSArray *rainforest = @[[[NSBundle mainBundle] URLForResource:@"rainforest_ambience-GlorySunz-1938133500" withExtension:@"m4a"], [UIImage imageNamed:@"nRain.png"]];
    NSArray *wavesLake = @[[[NSBundle mainBundle] URLForResource:@"60507_juskiddink_waves" withExtension:@"m4a"], [UIImage imageNamed:@"nWaves.png"]];
    NSArray *heartbeat = @[[[NSBundle mainBundle] URLForResource:@"Heart_Beat-Zarabadeu-1492122436" withExtension:@"m4a"], [UIImage imageNamed:@"nHeart.png"]];
    NSArray *fallsDeep = @[[[NSBundle mainBundle] URLForResource:@"184731_corsica-s_2013-04-12-falls-creek-falls" withExtension:@"m4a"], [UIImage imageNamed:@"nWaterfall.png"]];
    NSArray *wavesSea = @[[[NSBundle mainBundle] URLForResource:@"194478__inchadney__northsea-denmark" withExtension:@"m4a"], [UIImage imageNamed:@"nWaves.png"]];
    NSArray *crickets = @[[[NSBundle mainBundle] URLForResource:@"162786_mark-ian_cricketfx" withExtension:@"m4a"], [UIImage imageNamed:@"nGrass.png"]];
    

    NSDictionary *included = [[NSDictionary alloc] initWithObjectsAndKeys:
                              rainSoft, @"Rain Soft",
                              rainHard, @"Rain Hard",
                              noisePink, @"Noise Pink",
                              noiseWhite, @"Noise White",
                              birds, @"Birds",
                              cardinals, @"Cardinals",
                              frogs, @"Frogs",
                              rainforest, @"Rainforest",
                              wavesLake, @"Waves Lake",
                              heartbeat, @"Heartbeat",
                              fallsDeep, @"Falls Deep",
                              wavesSea, @"Waves Sea",
                              crickets, @"Crickets",
                              
                              nil];

    
    NSMutableDictionary *ret = [included mutableCopy];
    NSString *downloadPath = [IAPHelper downloadableContentPath];
    
    NSArray *noiseBrown = @[[[NSURL alloc] initFileURLWithPath:[downloadPath stringByAppendingPathComponent:[NSString stringWithFormat:@"brownNoise.m4a"]]], [UIImage imageNamed:@"nNoise.png"]];
    NSArray *thunderstorm = @[[[NSURL alloc] initFileURLWithPath:[downloadPath stringByAppendingPathComponent:[NSString stringWithFormat:@"16480__martin-lightning__severe-thunderstorm.m4a"]]], [UIImage imageNamed:@"nThunder.png"]];
    NSArray *fallsMedium = @[[[NSURL alloc] initFileURLWithPath:[downloadPath stringByAppendingPathComponent:[NSString stringWithFormat:@"28657_corsica-s_latourelle-falls-in-winter.m4a"]]], [UIImage imageNamed:@"nWaterfall.png"]];
    NSArray *fallsBright = @[[[NSURL alloc] initFileURLWithPath:[downloadPath stringByAppendingPathComponent:[NSString stringWithFormat:@"38569__digifishmusic__atherton-tablelands-malanda-falls.m4a"]]], [UIImage imageNamed:@"nWaterfall.png"]];
    NSArray *fallsMid = @[[[NSURL alloc] initFileURLWithPath:[downloadPath stringByAppendingPathComponent:[NSString stringWithFormat:@"117191__1jmorrisoncafe291__waterfall-1.m4a"]]], [UIImage imageNamed:@"nWaterfall.png"]];
    NSArray *fallsSoft = @[[[NSURL alloc] initFileURLWithPath:[downloadPath stringByAppendingPathComponent:[NSString stringWithFormat:@"124698_inchadney_waterfall-in-the-harz-mountains.m4a"]]], [UIImage imageNamed:@"nWaterfall.png"]];
    NSArray *fallsHiss = @[[[NSURL alloc] initFileURLWithPath:[downloadPath stringByAppendingPathComponent:[NSString stringWithFormat:@"127840_martats_waterfall-cycle.m4a"]]], [UIImage imageNamed:@"nWaterfall.png"]];
    NSArray *fallsRage = @[[[NSURL alloc] initFileURLWithPath:[downloadPath stringByAppendingPathComponent:[NSString stringWithFormat:@"128049_martats_big-waterfall.m4a"]]], [UIImage imageNamed:@"nWaterfall.png"]];
    NSArray *cityChina = @[[[NSURL alloc] initFileURLWithPath:[downloadPath stringByAppendingPathComponent:[NSString stringWithFormat:@"187356_pashee_street-ambience-in-china.m4a"]]], [UIImage imageNamed:@"nCity.png"]];
    NSArray *river = @[[[NSURL alloc] initFileURLWithPath:[downloadPath stringByAppendingPathComponent:[NSString stringWithFormat:@"191695_fridobeck_water.m4a"]]], [UIImage imageNamed:@"nRiver.png"]];
    NSArray *cityChicago = @[[[NSURL alloc] initFileURLWithPath:[downloadPath stringByAppendingPathComponent:[NSString stringWithFormat:@"194898__thaighaudio__072013-chicago-skyline-facing-south-above-ohio-st.m4a"]]], [UIImage imageNamed:@"nCity.png"]];
    NSArray *stream = @[[[NSURL alloc] initFileURLWithPath:[downloadPath stringByAppendingPathComponent:[NSString stringWithFormat:@"196699__vonfleisch__river-running-water.m4a"]]], [UIImage imageNamed:@"nRiver.png"]];
    NSArray *wavesCove = @[[[NSURL alloc] initFileURLWithPath:[downloadPath stringByAppendingPathComponent:[NSString stringWithFormat:@"204845__corsica-s__seaside-cove-waves.m4a"]]], [UIImage imageNamed:@"nWaves.png"]];
    NSArray *wind = @[[[NSURL alloc] initFileURLWithPath:[downloadPath stringByAppendingPathComponent:[NSString stringWithFormat:@"217506__felix-blume__wind-blowing-in-a-field-in-texas-usa.m4a"]]], [UIImage imageNamed:@"nWind.png"]];
    NSArray *fallsRiver = @[[[NSURL alloc] initFileURLWithPath:[downloadPath stringByAppendingPathComponent:[NSString stringWithFormat:@"250770_ninafoletti_river-waterfall-2.m4a"]]], [UIImage imageNamed:@"nWaterfall.png"]];
    NSArray *wavesLight = @[[[NSURL alloc] initFileURLWithPath:[downloadPath stringByAppendingPathComponent:[NSString stringWithFormat:@"251981_jillismolenaar_gentle-surf-rolling-on-sandy.m4a"]]], [UIImage imageNamed:@"nWaves.png"]];
    NSArray *wavesBeach = @[[[NSURL alloc] initFileURLWithPath:[downloadPath stringByAppendingPathComponent:[NSString stringWithFormat:@"320306_sophronsinesounddesign_beach-9.m4a"]]], [UIImage imageNamed:@"nWaves.png"]];
    NSArray *chickadee = @[[[NSURL alloc] initFileURLWithPath:[downloadPath stringByAppendingPathComponent:[NSString stringWithFormat:@"Chickadee.m4a"]]], [UIImage imageNamed:@"nBird.png"]];
    NSArray *rainBalcony = @[[[NSURL alloc] initFileURLWithPath:[downloadPath stringByAppendingPathComponent:[NSString stringWithFormat:@"Rain-falling-on-balcony-roof-birds-singing-in-the-background.m4a"]]], [UIImage imageNamed:@"nRain.png"]];
    NSArray *rainWoods = @[[[NSURL alloc] initFileURLWithPath:[downloadPath stringByAppendingPathComponent:[NSString stringWithFormat:@"Rain-falling-sound.m4a"]]], [UIImage imageNamed:@"nRain.png"]];
    NSArray *rainPatter = @[[[NSURL alloc] initFileURLWithPath:[downloadPath stringByAppendingPathComponent:[NSString stringWithFormat:@"Sleep-sounds-rain.m4a"]]], [UIImage imageNamed:@"nRain.png"]];
    NSArray *wetlands = @[[[NSURL alloc] initFileURLWithPath:[downloadPath stringByAppendingPathComponent:[NSString stringWithFormat:@"Wetlands-SoundBible.com-1972469419.m4a"]]], [UIImage imageNamed:@"nGrass.png"]];
    NSArray *birdsForest = @[[[NSURL alloc] initFileURLWithPath:[downloadPath stringByAppendingPathComponent:[NSString stringWithFormat:@"Natural-bird-sounds.m4a"]]], [UIImage imageNamed:@"nBird.png"]];
    NSArray *owl = @[[[NSURL alloc] initFileURLWithPath:[downloadPath stringByAppendingPathComponent:[NSString stringWithFormat:@"Night-Sounds-scops-owl.m4a"]]], [UIImage imageNamed:@"nBird.png"]];
    NSArray *rainBirds = @[[[NSURL alloc] initFileURLWithPath:[downloadPath stringByAppendingPathComponent:[NSString stringWithFormat:@"Rain-falling-bird-sound-in-background.m4a"]]], [UIImage imageNamed:@"nBird.png"]];
    NSArray *boxFanFast = @[[[NSURL alloc] initFileURLWithPath:[downloadPath stringByAppendingPathComponent:[NSString stringWithFormat:@"48936_dobroide_20060221-box-fan-fast.m4a"]]], [UIImage imageNamed:@"nHouse.png"]];
    NSArray *boxFan = @[[[NSURL alloc] initFileURLWithPath:[downloadPath stringByAppendingPathComponent:[NSString stringWithFormat:@"51833_timdrussell_boxfan.m4a"]]], [UIImage imageNamed:@"nHouse.png"]];
    NSArray *noiseGray = @[[[NSURL alloc] initFileURLWithPath:[downloadPath stringByAppendingPathComponent:[NSString stringWithFormat:@"186706_qubodup_gray-noise.m4a"]]], [UIImage imageNamed:@"nNoise.png"]];
    NSArray *noiseBlue = @[[[NSURL alloc] initFileURLWithPath:[downloadPath stringByAppendingPathComponent:[NSString stringWithFormat:@"186708_qubodup_blue-noise.m4a"]]], [UIImage imageNamed:@"nNoise.png"]];
    NSArray *noisePurple = @[[[NSURL alloc] initFileURLWithPath:[downloadPath stringByAppendingPathComponent:[NSString stringWithFormat:@"186707_qubodup_purple-noise.m4a"]]], [UIImage imageNamed:@"nNoise.png"]];
    
    
    NSDictionary *inApp = [[NSDictionary alloc] initWithObjectsAndKeys:
                           noiseBrown, @"Noise Brown",
                           thunderstorm, @"Thunderstorm",
                           fallsMedium, @"Falls Medium",
                           fallsBright, @"Falls Bright",
                           fallsMid, @"Falls Mid",
                           fallsSoft, @"Falls Soft",
                           fallsHiss, @"Falls Hiss",
                           fallsRage, @"Falls Rage",
                           cityChina, @"City China",
                           river, @"River",
                           cityChicago, @"City Chicago",
                           stream, @"Stream",
                           wavesCove, @"Waves Cove",
                           wind, @"Wind",
                           fallsRiver, @"Falls River",
                           wavesLight, @"Waves Light",
                           wavesBeach, @"Waves Beach",
                           chickadee, @"Chickadee",
                           rainBalcony, @"Rain Balcony",
                           rainWoods, @"Rain Woods",
                           rainPatter, @"Rain Patter",
                           wetlands, @"Wetlands",
                           birdsForest, @"Birds Forest",
                           owl, @"Owl",
                           rainBirds, @"Rain Birds",
                           boxFanFast, @"Box Fan Fast",
                           boxFan, @"Boxfan",
                           noiseGray, @"Noise Gray",
                           noiseBlue, @"Noise Blue",
                           noisePurple, @"Noise Purple",
                           
   
                           nil];
    
    NSArray *buy = @[[NSObject alloc], [UIImage imageNamed:@"nRain.png"]];
    NSDictionary *buyMore = @{
                              @"Xpand Nature Collection" : buy
                            };

    if ([self natureFilesDownloaded:inApp.allValues])
    {
        [ret addEntriesFromDictionary:inApp];
    }
    else {
        [ret addEntriesFromDictionary:buyMore];
    }
    return ret;
}

+ (NSMutableArray*) getAudioMatrix:(NSString*)trackId
{
    NSString *downloadPath = [IAPHelper downloadableContentPath];
    NSMutableArray *audioMatrix = [[NSMutableArray alloc] initWithCapacity: 4];

    if([trackId isEqualToString:@"sleep"])  {
    
        [audioMatrix insertObject:[NSMutableArray arrayWithObjects:
                               [NSNumber numberWithFloat:174.0f],                //carrier for voice
                               [NSNumber numberWithFloat:8.6f],                  //binaural for voice
                               //[[NSBundle mainBundle] pathForResource:@"Sleep101" ofType:@"m4a"],
                               [[NSBundle mainBundle] URLForResource:@"Sleep101" withExtension:@"m4a"],
                               [NSNumber numberWithFloat:174.0f],                //carrier for gap
                               [NSNumber numberWithFloat:7.83f],                 //binaural for gap
                               [NSNumber numberWithInteger:15],nil] atIndex:0]; //gap length

        [audioMatrix insertObject:[NSMutableArray arrayWithObjects:
                                   [NSNumber numberWithFloat:174.0f],                //carrier for voice
                                   [NSNumber numberWithFloat:6.1f],                  //binaural for voice
                                   [[NSBundle mainBundle] URLForResource:@"Sleep102" withExtension:@"m4a"],
                                   [NSNumber numberWithFloat:174.0f],                //carrier for gap
                                   [NSNumber numberWithFloat:7.1f],                 //binaural for gap
                                   [NSNumber numberWithInteger:10],nil] atIndex:1]; //gap length

        [audioMatrix insertObject:[NSMutableArray arrayWithObjects:
                                   [NSNumber numberWithFloat:174.0f],                //carrier for voice
                                   [NSNumber numberWithFloat:6.3f],                  //binaural for voice
                                   [[NSBundle mainBundle] URLForResource:@"Sleep103" withExtension:@"m4a"],
                                   [NSNumber numberWithFloat:174.0f],                //carrier for gap
                                   [NSNumber numberWithFloat:5.5f],                 //binaural for gap
                                   [NSNumber numberWithInteger:15],nil] atIndex:2]; //gap length

        [audioMatrix insertObject:[NSMutableArray arrayWithObjects:
                                   [NSNumber numberWithFloat:174.0f],                //carrier for voice
                                   [NSNumber numberWithFloat:6.0f],                  //binaural for voice
                                   [[NSBundle mainBundle] URLForResource:@"Sleep104" withExtension:@"m4a"],
                                   [NSNumber numberWithFloat:174.0f],                //carrier for gap
                                   [NSNumber numberWithFloat:5.0f],                 //binaural for gap
                                   [NSNumber numberWithInteger:18],nil] atIndex:3]; //gap length

        [audioMatrix insertObject:[NSMutableArray arrayWithObjects:
                                   [NSNumber numberWithFloat:174.0f],                //carrier for voice
                                   [NSNumber numberWithFloat:5.5f],                  //binaural for voice
                                   [[NSBundle mainBundle] URLForResource:@"Sleep105" withExtension:@"m4a"],
                                   [NSNumber numberWithFloat:174.0f],                //carrier for gap
                                   [NSNumber numberWithFloat:4.3f],                 //binaural for gap
                                   [NSNumber numberWithInteger:10],nil] atIndex:4]; //gap length

        [audioMatrix insertObject:[NSMutableArray arrayWithObjects:
                                   [NSNumber numberWithFloat:194.18f],                //carrier for voice
                                   [NSNumber numberWithFloat:4.5f],                  //binaural for voice
                                   [[NSBundle mainBundle] URLForResource:@"Sleep106" withExtension:@"m4a"],
                                   [NSNumber numberWithFloat:194.18f],                //carrier for gap
                                   [NSNumber numberWithFloat:4.0f],                 //binaural for gap
                                   [NSNumber numberWithInteger:10],nil] atIndex:5]; //gap length

        [audioMatrix insertObject:[NSMutableArray arrayWithObjects:
                                   [NSNumber numberWithFloat:210.42f],                //carrier for voice
                                   [NSNumber numberWithFloat:4.0f],                  //binaural for voice
                                   [[NSBundle mainBundle] URLForResource:@"Sleep107" withExtension:@"m4a"],
                                   [NSNumber numberWithFloat:210.42f],                //carrier for gap
                                   [NSNumber numberWithFloat:3.2f],                 //binaural for gap
                                   [NSNumber numberWithInteger:14],nil] atIndex:6]; //gap length

        [audioMatrix insertObject:[NSMutableArray arrayWithObjects:
                                   [NSNumber numberWithFloat:126.22f],                //carrier for voice
                                   [NSNumber numberWithFloat:3.5f],                  //binaural for voice
                                   [[NSBundle mainBundle] URLForResource:@"Sleep108" withExtension:@"m4a"],
                                   [NSNumber numberWithFloat:136.10],                //carrier for gap
                                   [NSNumber numberWithFloat:3.0f],                 //binaural for gap
                                   [NSNumber numberWithInteger:10],nil] atIndex:7]; //gap length

        [audioMatrix insertObject:[NSMutableArray arrayWithObjects:
                                   [NSNumber numberWithFloat:136.10f],                //carrier for voice
                                   [NSNumber numberWithFloat:3.4f],                  //binaural for voice
                                   [[NSBundle mainBundle] URLForResource:@"Sleep109" withExtension:@"m4a"],
                                   [NSNumber numberWithFloat:136.10],                //carrier for gap
                                   [NSNumber numberWithFloat:2.0f],                 //binaural for gap
                                   [NSNumber numberWithInteger:14],nil] atIndex:8]; //gap length

        [audioMatrix insertObject:[NSMutableArray arrayWithObjects:
                                   [NSNumber numberWithFloat:136.10f],                //carrier for voice
                                   [NSNumber numberWithFloat:2.5f],                  //binaural for voice
                                   [[NSBundle mainBundle] URLForResource:@"Sleep110" withExtension:@"m4a"],
                                   [NSNumber numberWithFloat:141.27f],                //carrier for gap
                                   [NSNumber numberWithFloat:1.8f],                 //binaural for gap
                                   [NSNumber numberWithInteger:14],nil] atIndex:9]; //gap length

        [audioMatrix insertObject:[NSMutableArray arrayWithObjects:
                                   [NSNumber numberWithFloat:141.27f],                //carrier for voice
                                   [NSNumber numberWithFloat:2.0f],                  //binaural for voice
                                   [[NSBundle mainBundle] URLForResource:@"Sleep111" withExtension:@"m4a"],
                                   [NSNumber numberWithFloat:141.27f],                //carrier for gap
                                   [NSNumber numberWithFloat:1.5f],                 //binaural for gap
                                   [NSNumber numberWithInteger:20],nil] atIndex:10]; //gap length

        [audioMatrix insertObject:[NSMutableArray arrayWithObjects:
                                   [NSNumber numberWithFloat:172.06],                //carrier for voice
                                   [NSNumber numberWithFloat:1.0f],                  //binaural for voice
                                   [[NSBundle mainBundle] URLForResource:@"Sleep112" withExtension:@"m4a"],
                                   [NSNumber numberWithFloat:172.06],                //carrier for gap
                                   [NSNumber numberWithFloat:1.5f],                 //binaural for gap
                                   [NSNumber numberWithInteger:130],nil] atIndex:11]; //gap length

    } else if ([trackId isEqualToString:@"sleep2"]) {
        
        [audioMatrix insertObject:[NSMutableArray arrayWithObjects:
                                   [NSNumber numberWithFloat:172.06f],                //carrier for voice
                                   [NSNumber numberWithFloat:8.6f],
                                    [[NSURL alloc] initFileURLWithPath:[downloadPath stringByAppendingPathComponent:[NSString stringWithFormat:@"sleep201.m4a"]]],
                                   [NSNumber numberWithFloat:172.06f],                //carrier for gap
                                   [NSNumber numberWithFloat:7.83f],                 //binaural for gap
                                   [NSNumber numberWithInteger:5],nil] atIndex:0]; //gap length
        
        [audioMatrix insertObject:[NSMutableArray arrayWithObjects:
                                   [NSNumber numberWithFloat:172.06f],                //carrier for voice
                                   [NSNumber numberWithFloat:6.1f],                  //binaural for voice
 [[NSURL alloc] initFileURLWithPath:[downloadPath stringByAppendingPathComponent:[NSString stringWithFormat:@"sleep202.m4a"]]],
                                   [NSNumber numberWithFloat:172.06f],                //carrier for gap
                                   [NSNumber numberWithFloat:7.1f],                 //binaural for gap
                                   [NSNumber numberWithInteger:10],nil] atIndex:1]; //gap length
        
        [audioMatrix insertObject:[NSMutableArray arrayWithObjects:
                                   [NSNumber numberWithFloat:172.06f],                //carrier for voice
                                   [NSNumber numberWithFloat:6.3f],                  //binaural for voice
                                   [[NSURL alloc] initFileURLWithPath:[downloadPath stringByAppendingPathComponent:[NSString stringWithFormat:@"sleep203.m4a"]]],
                                   [NSNumber numberWithFloat:172.06f],                //carrier for gap
                                   [NSNumber numberWithFloat:5.5f],                 //binaural for gap
                                   [NSNumber numberWithInteger:10],nil] atIndex:2]; //gap length
        
        [audioMatrix insertObject:[NSMutableArray arrayWithObjects:
                                   [NSNumber numberWithFloat:221.23f],                //carrier for voice
                                   [NSNumber numberWithFloat:6.0f],                  //binaural for voice
                                   [[NSURL alloc] initFileURLWithPath:[downloadPath stringByAppendingPathComponent:[NSString stringWithFormat:@"sleep204.m4a"]]],
                                   [NSNumber numberWithFloat:221.23f],                //carrier for gap
                                   [NSNumber numberWithFloat:5.0f],                 //binaural for gap
                                   [NSNumber numberWithInteger:10],nil] atIndex:3]; //gap length
        
        [audioMatrix insertObject:[NSMutableArray arrayWithObjects:
                                   [NSNumber numberWithFloat:141.27f],                //carrier for voice
                                   [NSNumber numberWithFloat:5.5f],                  //binaural for voice
                                   [[NSURL alloc] initFileURLWithPath:[downloadPath stringByAppendingPathComponent:[NSString stringWithFormat:@"sleep205.m4a"]]],
                                   [NSNumber numberWithFloat:136.10f],                //carrier for gap
                                   [NSNumber numberWithFloat:4.3f],                 //binaural for gap
                                   [NSNumber numberWithInteger:10],nil] atIndex:4]; //gap length
        
        [audioMatrix insertObject:[NSMutableArray arrayWithObjects:
                                   [NSNumber numberWithFloat:136.10f],                //carrier for voice
                                   [NSNumber numberWithFloat:4.5f],                  //binaural for voice
                                   [[NSURL alloc] initFileURLWithPath:[downloadPath stringByAppendingPathComponent:[NSString stringWithFormat:@"sleep206.m4a"]]],
                                   [NSNumber numberWithFloat:136.10f],                //carrier for gap
                                   [NSNumber numberWithFloat:4.0f],                 //binaural for gap
                                   [NSNumber numberWithInteger:10],nil] atIndex:5]; //gap length
        
        [audioMatrix insertObject:[NSMutableArray arrayWithObjects:
                                   [NSNumber numberWithFloat:136.10f],                //carrier for voice
                                   [NSNumber numberWithFloat:4.0f],                  //binaural for voice
                                   [[NSURL alloc] initFileURLWithPath:[downloadPath stringByAppendingPathComponent:[NSString stringWithFormat:@"sleep207.m4a"]]],
                                   [NSNumber numberWithFloat:136.10f],                //carrier for gap
                                   [NSNumber numberWithFloat:3.2f],                 //binaural for gap
                                   [NSNumber numberWithInteger:20],nil] atIndex:6]; //gap length
        
        [audioMatrix insertObject:[NSMutableArray arrayWithObjects:
                                   [NSNumber numberWithFloat:136.10f],                //carrier for voice
                                   [NSNumber numberWithFloat:3.5f],                  //binaural for voice
                                   [[NSURL alloc] initFileURLWithPath:[downloadPath stringByAppendingPathComponent:[NSString stringWithFormat:@"sleep208.m4a"]]],
                                   [NSNumber numberWithFloat:136.10f],                //carrier for gap
                                   [NSNumber numberWithFloat:3.0f],                 //binaural for gap
                                   [NSNumber numberWithInteger:30],nil] atIndex:7]; //gap length
        
        [audioMatrix insertObject:[NSMutableArray arrayWithObjects:
                                   [NSNumber numberWithFloat:136.10f],                //carrier for voice
                                   [NSNumber numberWithFloat:3.4f],                  //binaural for voice
                                   [[NSURL alloc] initFileURLWithPath:[downloadPath stringByAppendingPathComponent:[NSString stringWithFormat:@"sleep209.m4a"]]],
                                   [NSNumber numberWithFloat:136.10f],                //carrier for gap
                                   [NSNumber numberWithFloat:2.0f],                 //binaural for gap
                                   [NSNumber numberWithInteger:30],nil] atIndex:8]; //gap length
        
        [audioMatrix insertObject:[NSMutableArray arrayWithObjects:
                                   [NSNumber numberWithFloat:136.10f],                //carrier for voice
                                   [NSNumber numberWithFloat:2.5f],                  //binaural for voice
                                   [[NSURL alloc] initFileURLWithPath:[downloadPath stringByAppendingPathComponent:[NSString stringWithFormat:@"sleep210.m4a"]]],
                                   [NSNumber numberWithFloat:136.10f],                //carrier for gap
                                   [NSNumber numberWithFloat:1.8f],                 //binaural for gap
                                   [NSNumber numberWithInteger:20],nil] atIndex:9]; //gap length
        
        [audioMatrix insertObject:[NSMutableArray arrayWithObjects:
                                   [NSNumber numberWithFloat:136.10f],                //carrier for voice
                                   [NSNumber numberWithFloat:2.0f],                  //binaural for voice
                                   [[NSURL alloc] initFileURLWithPath:[downloadPath stringByAppendingPathComponent:[NSString stringWithFormat:@"sleep211.m4a"]]],
                                   [NSNumber numberWithFloat:136.10f],                //carrier for gap
                                   [NSNumber numberWithFloat:1.5f],                 //binaural for gap
                                   [NSNumber numberWithInteger:60],nil] atIndex:10]; //gap length
        
        [audioMatrix insertObject:[NSMutableArray arrayWithObjects:
                                   [NSNumber numberWithFloat:136.10f],                //carrier for voice
                                   [NSNumber numberWithFloat:2.0f],                  //binaural for voice
                                   [[NSURL alloc] initFileURLWithPath:[downloadPath stringByAppendingPathComponent:[NSString stringWithFormat:@"sleep212.m4a"]]],
                                   [NSNumber numberWithFloat:136.10f],                //carrier for gap
                                   [NSNumber numberWithFloat:1.5f],                 //binaural for gap
                                   [NSNumber numberWithInteger:60],nil] atIndex:11]; //gap length
        
        [audioMatrix insertObject:[NSMutableArray arrayWithObjects:
                                   [NSNumber numberWithFloat:136.10f],                //carrier for voice
                                   [NSNumber numberWithFloat:1.5f],                  //binaural for voice
                                   [[NSURL alloc] initFileURLWithPath:[downloadPath stringByAppendingPathComponent:[NSString stringWithFormat:@"sleep213.m4a"]]],
                                   [NSNumber numberWithFloat:136.10f],                //carrier for gap
                                   [NSNumber numberWithFloat:1.0f],                 //binaural for gap
                                   [NSNumber numberWithInteger:120],nil] atIndex:12]; //gap length

        
    } else if ([trackId isEqualToString:@"dream"]) {
        
        [audioMatrix insertObject:[NSMutableArray arrayWithObjects:
                                   [NSNumber numberWithFloat:211.44f],                //carrier for voice
                                   [NSNumber numberWithFloat:12.3f],                  //binaural for voice
                                   [[NSURL alloc] initFileURLWithPath:[downloadPath stringByAppendingPathComponent:[NSString stringWithFormat:@"dream01.m4a"]]],
                                   [NSNumber numberWithFloat:211.44f],                //carrier for gap
                                   [NSNumber numberWithFloat:11.5f],                 //binaural for gap
                                   [NSNumber numberWithInteger:5],nil] atIndex:0]; //gap length
        
        [audioMatrix insertObject:[NSMutableArray arrayWithObjects:
                                   [NSNumber numberWithFloat:211.44f],                //carrier for voice
                                   [NSNumber numberWithFloat:12.3f],                  //binaural for voice
                                   [[NSURL alloc] initFileURLWithPath:[downloadPath stringByAppendingPathComponent:[NSString stringWithFormat:@"dream02.m4a"]]],
                                   [NSNumber numberWithFloat:211.44f],                //carrier for gap
                                   [NSNumber numberWithFloat:11.5f],                 //binaural for gap
                                   [NSNumber numberWithInteger:10],nil] atIndex:1]; //gap length
        
        [audioMatrix insertObject:[NSMutableArray arrayWithObjects:
                                   [NSNumber numberWithFloat:211.44f],                //carrier for voice
                                   [NSNumber numberWithFloat:11.5f],                  //binaural for voice
                                   [[NSURL alloc] initFileURLWithPath:[downloadPath stringByAppendingPathComponent:[NSString stringWithFormat:@"dream03.m4a"]]],
                                   [NSNumber numberWithFloat:211.44f],                //carrier for gap
                                   [NSNumber numberWithFloat:10.5f],                 //binaural for gap
                                   [NSNumber numberWithInteger:7],nil] atIndex:2]; //gap length
        
        [audioMatrix insertObject:[NSMutableArray arrayWithObjects:
                                   [NSNumber numberWithFloat:211.44f],                //carrier for voice
                                   [NSNumber numberWithFloat:11.0f],                  //binaural for voice
                                   [[NSURL alloc] initFileURLWithPath:[downloadPath stringByAppendingPathComponent:[NSString stringWithFormat:@"dream04.m4a"]]],
                                   [NSNumber numberWithFloat:211.44f],                //carrier for gap
                                   [NSNumber numberWithFloat:10.0f],                 //binaural for gap
                                   [NSNumber numberWithInteger:7],nil] atIndex:3]; //gap length
        
        [audioMatrix insertObject:[NSMutableArray arrayWithObjects:
                                   [NSNumber numberWithFloat:211.44f],                //carrier for voice
                                   [NSNumber numberWithFloat:10.5f],                  //binaural for voice
                                   [[NSURL alloc] initFileURLWithPath:[downloadPath stringByAppendingPathComponent:[NSString stringWithFormat:@"dream05.m4a"]]],
                                   [NSNumber numberWithFloat:211.44f],                //carrier for gap
                                   [NSNumber numberWithFloat:9.8f],                 //binaural for gap
                                   [NSNumber numberWithInteger:7],nil] atIndex:4]; //gap length
        
        [audioMatrix insertObject:[NSMutableArray arrayWithObjects:
                                   [NSNumber numberWithFloat:211.44f],                //carrier for voice
                                   [NSNumber numberWithFloat:10.0f],                  //binaural for voice
                                   [[NSURL alloc] initFileURLWithPath:[downloadPath stringByAppendingPathComponent:[NSString stringWithFormat:@"dream06.m4a"]]],
                                   [NSNumber numberWithFloat:211.44f],                //carrier for gap
                                   [NSNumber numberWithFloat:9.0f],                 //binaural for gap
                                   [NSNumber numberWithInteger:7],nil] atIndex:5]; //gap length
        
        [audioMatrix insertObject:[NSMutableArray arrayWithObjects:
                                   [NSNumber numberWithFloat:211.44f],                //carrier for voice
                                   [NSNumber numberWithFloat:9.41f],                  //binaural for voice
                                   [[NSURL alloc] initFileURLWithPath:[downloadPath stringByAppendingPathComponent:[NSString stringWithFormat:@"dream07.m4a"]]],
                                   [NSNumber numberWithFloat:211.44f],                //carrier for gap
                                   [NSNumber numberWithFloat:8.0f],                 //binaural for gap
                                   [NSNumber numberWithInteger:7],nil] atIndex:6]; //gap length
        
        [audioMatrix insertObject:[NSMutableArray arrayWithObjects:
                                   [NSNumber numberWithFloat:211.44f],                //carrier for voice
                                   [NSNumber numberWithFloat:8.6f],                  //binaural for voice
                                   [[NSURL alloc] initFileURLWithPath:[downloadPath stringByAppendingPathComponent:[NSString stringWithFormat:@"dream08.m4a"]]],
                                   [NSNumber numberWithFloat:211.44f],                //carrier for gap
                                   [NSNumber numberWithFloat:7.5f],                 //binaural for gap
                                   [NSNumber numberWithInteger:10],nil] atIndex:7]; //gap length
        
        [audioMatrix insertObject:[NSMutableArray arrayWithObjects:
                                   [NSNumber numberWithFloat:211.44f],                //carrier for voice
                                   [NSNumber numberWithFloat:8.0f],                  //binaural for voice
                                   [[NSURL alloc] initFileURLWithPath:[downloadPath stringByAppendingPathComponent:[NSString stringWithFormat:@"dream09.m4a"]]],
                                   [NSNumber numberWithFloat:211.44f],                //carrier for gap
                                   [NSNumber numberWithFloat:7.0f],                 //binaural for gap
                                   [NSNumber numberWithInteger:10],nil] atIndex:8]; //gap length
        
        [audioMatrix insertObject:[NSMutableArray arrayWithObjects:
                                   [NSNumber numberWithFloat:211.44f],                //carrier for voice
                                   [NSNumber numberWithFloat:7.5f],                  //binaural for voice
                                   [[NSURL alloc] initFileURLWithPath:[downloadPath stringByAppendingPathComponent:[NSString stringWithFormat:@"dream10.m4a"]]],
                                   [NSNumber numberWithFloat:211.44f],                //carrier for gap
                                   [NSNumber numberWithFloat:7.0f],                 //binaural for gap
                                   [NSNumber numberWithInteger:10],nil] atIndex:9]; //gap length
        
        [audioMatrix insertObject:[NSMutableArray arrayWithObjects:
                                   [NSNumber numberWithFloat:211.44f],                //carrier for voice
                                   [NSNumber numberWithFloat:7.5f],                  //binaural for voice
                                   [[NSURL alloc] initFileURLWithPath:[downloadPath stringByAppendingPathComponent:[NSString stringWithFormat:@"dream11.m4a"]]],
                                   [NSNumber numberWithFloat:211.44f],                //carrier for gap
                                   [NSNumber numberWithFloat:6.5f],                 //binaural for gap
                                   [NSNumber numberWithInteger:30],nil] atIndex:10]; //gap length
        
        [audioMatrix insertObject:[NSMutableArray arrayWithObjects:
                                   [NSNumber numberWithFloat:211.44f],                //carrier for voice
                                   [NSNumber numberWithFloat:7.0f],                  //binaural for voice
                                   [[NSURL alloc] initFileURLWithPath:[downloadPath stringByAppendingPathComponent:[NSString stringWithFormat:@"dream12.m4a"]]],
                                   [NSNumber numberWithFloat:211.44f],                //carrier for gap
                                   [NSNumber numberWithFloat:6.5f],                 //binaural for gap
                                   [NSNumber numberWithInteger:20],nil] atIndex:11]; //gap length

        [audioMatrix insertObject:[NSMutableArray arrayWithObjects:
                                   [NSNumber numberWithFloat:211.44f],                //carrier for voice
                                   [NSNumber numberWithFloat:6.8f],                  //binaural for voice
                                   [[NSURL alloc] initFileURLWithPath:[downloadPath stringByAppendingPathComponent:[NSString stringWithFormat:@"dream13.m4a"]]],
                                   [NSNumber numberWithFloat:211.44f],                //carrier for gap
                                   [NSNumber numberWithFloat:6.3f],                 //binaural for gap
                                   [NSNumber numberWithInteger:60],nil] atIndex:12]; //gap length

        [audioMatrix insertObject:[NSMutableArray arrayWithObjects:
                                   [NSNumber numberWithFloat:172.06],                //carrier for voice
                                   [NSNumber numberWithFloat:6.5f],                  //binaural for voice
                                   [[NSURL alloc] initFileURLWithPath:[downloadPath stringByAppendingPathComponent:[NSString stringWithFormat:@"dream14.m4a"]]],
                                   [NSNumber numberWithFloat:172.06],                //carrier for gap
                                   [NSNumber numberWithFloat:6.15f],                 //binaural for gap
                                   [NSNumber numberWithInteger:30],nil] atIndex:13]; //gap length

        [audioMatrix insertObject:[NSMutableArray arrayWithObjects:
                                   [NSNumber numberWithFloat:172.06],                //carrier for voice
                                   [NSNumber numberWithFloat:6.3f],                  //binaural for voice
                                   [[NSURL alloc] initFileURLWithPath:[downloadPath stringByAppendingPathComponent:[NSString stringWithFormat:@"dream15.m4a"]]],
                                   [NSNumber numberWithFloat:172.06],                //carrier for gap
                                   [NSNumber numberWithFloat:5.5f],                 //binaural for gap
                                   [NSNumber numberWithInteger:30],nil] atIndex:14]; //gap length

        [audioMatrix insertObject:[NSMutableArray arrayWithObjects:
                                   [NSNumber numberWithFloat:172.06],                //carrier for voice
                                   [NSNumber numberWithFloat:6.0f],                  //binaural for voice
                                   [[NSURL alloc] initFileURLWithPath:[downloadPath stringByAppendingPathComponent:[NSString stringWithFormat:@"dream16.m4a"]]],
                                   [NSNumber numberWithFloat:172.06],                //carrier for gap
                                   [NSNumber numberWithFloat:4.9f],                 //binaural for gap
                                   [NSNumber numberWithInteger:30],nil] atIndex:15]; //gap length

        [audioMatrix insertObject:[NSMutableArray arrayWithObjects:
                                   [NSNumber numberWithFloat:172.06],                //carrier for voice
                                   [NSNumber numberWithFloat:5.5f],                  //binaural for voice
                                   [[NSURL alloc] initFileURLWithPath:[downloadPath stringByAppendingPathComponent:[NSString stringWithFormat:@"dream17.m4a"]]],
                                   [NSNumber numberWithFloat:172.06],                //carrier for gap
                                   [NSNumber numberWithFloat:4.9f],                 //binaural for gap
                                   [NSNumber numberWithInteger:10],nil] atIndex:16]; //gap length

        [audioMatrix insertObject:[NSMutableArray arrayWithObjects:
                                   [NSNumber numberWithFloat:172.06],                //carrier for voice
                                   [NSNumber numberWithFloat:4.9f],                  //binaural for voice
                                   [[NSURL alloc] initFileURLWithPath:[downloadPath stringByAppendingPathComponent:[NSString stringWithFormat:@"dream18.m4a"]]],
                                   [NSNumber numberWithFloat:172.06],                //carrier for gap
                                   [NSNumber numberWithFloat:3.9f],                 //binaural for gap
                                   [NSNumber numberWithInteger:20],nil] atIndex:17]; //gap length

        [audioMatrix insertObject:[NSMutableArray arrayWithObjects:
                                   [NSNumber numberWithFloat:172.06],                //carrier for voice
                                   [NSNumber numberWithFloat:4.5f],                  //binaural for voice
                                   [[NSURL alloc] initFileURLWithPath:[downloadPath stringByAppendingPathComponent:[NSString stringWithFormat:@"dream19.m4a"]]],
                                   [NSNumber numberWithFloat:172.06],                //carrier for gap
                                   [NSNumber numberWithFloat:4.9f],                 //binaural for gap
                                   [NSNumber numberWithInteger:120],nil] atIndex:18]; //gap length

    } else if ([trackId isEqualToString:@"nap"]) {
        
        [audioMatrix insertObject:[NSMutableArray arrayWithObjects:
                                   [NSNumber numberWithFloat:136.10f],                //carrier for voice
                                   [NSNumber numberWithFloat:10.3f],                  //binaural for voice
                                   [[NSURL alloc] initFileURLWithPath:[downloadPath stringByAppendingPathComponent:[NSString stringWithFormat:@"Nap01.m4a"]]],
                                   [NSNumber numberWithFloat:136.10f],                //carrier for gap
                                   [NSNumber numberWithFloat:9.0f],                 //binaural for gap
                                   [NSNumber numberWithInteger:30],nil] atIndex:0]; //gap length

        [audioMatrix insertObject:[NSMutableArray arrayWithObjects:
                                   [NSNumber numberWithFloat:136.10f],                //carrier for voice
                                   [NSNumber numberWithFloat:7.83f],                  //binaural for voice
                                   [[NSURL alloc] initFileURLWithPath:[downloadPath stringByAppendingPathComponent:[NSString stringWithFormat:@"Nap02.m4a"]]],
                                   [NSNumber numberWithFloat:136.10f],                //carrier for gap
                                   [NSNumber numberWithFloat:5.0f],                 //binaural for gap
                                   [NSNumber numberWithInteger:30],nil] atIndex:1]; //gap length

        
        [audioMatrix insertObject:[NSMutableArray arrayWithObjects:
                                   [NSNumber numberWithFloat:136.10f],                //carrier for voice
                                   [NSNumber numberWithFloat:5.7f],                  //binaural for voice
                                   [[NSURL alloc] initFileURLWithPath:[downloadPath stringByAppendingPathComponent:[NSString stringWithFormat:@"Nap03.m4a"]]],
                                   [NSNumber numberWithFloat:136.10f],                //carrier for gap
                                   [NSNumber numberWithFloat:4.5f],                 //binaural for gap
                                   [NSNumber numberWithInteger:1200],nil] atIndex:2]; //gap length
        
        [audioMatrix insertObject:[NSMutableArray arrayWithObjects:
                                   [NSNumber numberWithFloat:136.10f],                //carrier for voice
                                   [NSNumber numberWithFloat:7.0f],                  //binaural for voice
                                   [[NSURL alloc] initFileURLWithPath:[downloadPath stringByAppendingPathComponent:[NSString stringWithFormat:@"Nap04.m4a"]]],
                                   [NSNumber numberWithFloat:136.10f],                //carrier for gap
                                   [NSNumber numberWithFloat:12.0f],                 //binaural for gap
                                   [NSNumber numberWithInteger:20],nil] atIndex:3]; //gap length
        
        [audioMatrix insertObject:[NSMutableArray arrayWithObjects:
                                   [NSNumber numberWithFloat:136.10f],                //carrier for voice
                                   [NSNumber numberWithFloat:12.5f],                  //binaural for voice
                                   [[NSURL alloc] initFileURLWithPath:[downloadPath stringByAppendingPathComponent:[NSString stringWithFormat:@"Nap05.m4a"]]],
                                   [NSNumber numberWithFloat:136.10f],                //carrier for gap
                                   [NSNumber numberWithFloat:14.0f],                 //binaural for gap
                                   [NSNumber numberWithInteger:10],nil] atIndex:4]; //gap length
        
    }
    
    return audioMatrix;
}


@end
