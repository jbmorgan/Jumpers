//
//  JumpersLayer.h
//  t6mb
//
//  Created by Ricardo Quesada on 3/24/11.
//  Copyright __MyCompanyName__ 2011. All rights reserved.
//


// When you import this file, you import all the cocos2d classes
#import "cocos2d.h"
#import "Box2D.h"
#import "GLES-Render.h"

@class Jumper;

// JumpersLayer
@interface JumpersLayer : CCLayer
{
	b2World* world;
	GLESDebugDraw *m_debugDraw;
	NSMutableArray *jumpers;
	
	double jumping_probability;
	double jumping_strength;
	double jumping_angular_deviation;
}

// returns a CCScene that contains the JumpersLayer as the only child
+(CCScene *) scene;
// adds a new sprite at a given coordinate
-(void) addNewSpriteWithCoords:(CGPoint)p;
-(void)initPopulationParameters;

@end
