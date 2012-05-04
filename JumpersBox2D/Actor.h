//
//  Actor.h
//  JumpersBox2D
//
//  Created by JONATHAN B MORGAN on 5/3/12.
//  Copyright 2012 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "cocos2d.h"

typedef enum ActorType {
	kBird = 1,
	kStick = 2,
} ActorType;

@interface Actor : CCNode {
    
}

-(id)initWithType:(ActorType)t;

@property (nonatomic, retain) CCSprite *sprite;
@property ActorType type;
@property Float32 bounciness;
@property Float32 density;

@end
