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
#import "Actor.h"
// JumpersLayer

typedef enum CursorMode {
	kVertical,
	kHorizontal
} CursorMode;

typedef enum SimulationState {
	kInitialState,
	kSuccessorAnglePlus,
	kSuccessorAngleMinus,
	kSuccessorForcePlus,
	kSuccessorForceMinus,
	kEvaluateSimulations
} SimulationState;

@interface JumpersLayer : CCLayer
{
	b2World* world;
	GLESDebugDraw *m_debugDraw;
}

// returns a CCScene that contains the JumpersLayer as the only child
+(CCScene *) scene;

// adds a new sprite at a given coordinate
-(void) addNewSpriteWithCoords:(CGPoint)p andType:(ActorType)type;
-(BOOL)isStationary:(b2Body *)b;

@property (nonatomic, retain) NSMutableArray *actors;
@property (nonatomic, retain) NSMutableArray *simulationResults;
@property (nonatomic, retain) CCSprite *cursorSprite;
@property (nonatomic, retain) CCLabelTTF *heightLabel;
@property CursorMode cursorMode;
@property SimulationState simulationState;
@property double averageHeight;
@property double currentAngle;
@property double currentForce;
@property double timeSinceBallLaunched;

@end
