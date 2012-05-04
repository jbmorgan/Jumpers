//
//  Actor.m
//  JumpersBox2D
//
//  Created by JONATHAN B MORGAN on 5/3/12.
//  Copyright 2012 __MyCompanyName__. All rights reserved.
//

#import "Actor.h"


@implementation Actor
@synthesize sprite, type, bounciness, density;

-(id)initWithType:(ActorType)t {
	if(self = [super init]) {
		type = t;
		switch (t) {
			case kBird:
				sprite = [[CCSprite alloc] initWithFile:@"tango.png"];
				bounciness = 0.6f;
				density = 2.0f;
				break;
			case kStick:
				sprite = [[CCSprite alloc] initWithFile:@"stick.png"];
				bounciness = 0.01f;
				density = 0.5f;
			default:
				break;
		}
	}
	return self;
}
@end
