//
//  ViewController.h
//  Audio Controller Test Suite
//
//  Created by Michael Tyson on 13/02/2012.
//  Copyright (c) 2012 A Tasty Pixel. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "PickerCells.h"

@class AEAudioController;
@interface ViewController : UITableViewController<UIAlertViewDelegate, PickerCellsDelegate, UIPickerViewDataSource, UIPickerViewDelegate>

- (id)initWithAudioController:(AEAudioController*)audioController;

@end
