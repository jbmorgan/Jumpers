//
//  Jumper.m
//  JumpersBox2D
//
//  Created by JONATHAN B MORGAN on 4/18/12.
//  Copyright 2012 __MyCompanyName__. All rights reserved.
//

#import "Jumper.h"

@implementation Jumper

@synthesize sprite;

-(id)initWithSprite:(CCSprite *)jumperSprite {
	if(self = [super init]) {
		sprite = jumperSprite;
	}
	return self;
}

@end
