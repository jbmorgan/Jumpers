//
//  Jumper.h
//  JumpersBox2D
//
//  Created by JONATHAN B MORGAN on 4/18/12.
//  Copyright 2012 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "cocos2d.h"

@interface Jumper : CCNode {
    CCSprite *sprite;
}

-(id)initWithSprite:(CCSprite *)jumperSprite;

@property (nonatomic, retain) CCSprite *sprite;
@end
