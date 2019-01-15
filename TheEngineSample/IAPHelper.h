//
//  IAPHelper.h
//  GuidedMeds
//
//  Created by Mr Russell on 1/20/15.
//  Copyright (c) 2015 Guided Meditation Treks. All rights reserved.
//

#import <Foundation/Foundation.h>
//#import <StoreKit/StoreKit.h>

@interface IAPHelper : NSObject

+ (NSString *) downloadableContentPath;

+ (NSMutableArray*) getAudioMatrix:(NSString*)trackId;

+ (NSArray*) getNatureFilenames;
+ (NSDictionary*) getNatureDictionary;
+ (BOOL) isMeditationDownloaded:(NSString*)trackId;

@end
