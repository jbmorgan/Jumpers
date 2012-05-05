//
//  JumpersLayer.mm
//  t6mb
//
//  Created by Ricardo Quesada on 3/24/11.
//  Copyright __MyCompanyName__ 2011. All rights reserved.
//


// Import the interfaces
#import "JumpersLayer.h"

//Pixel to metres ratio. Box2D uses metres as the unit for measurement.
//This ratio defines how many pixels correspond to 1 Box2D "metre"
//Box2D is optimized for objects of 1x1 metre therefore it makes sense
//to define the ratio so that your most common object type is 1x1 metre.
#define PTM_RATIO 16
#define PTM_RATIO_DEFAULT 32.0

#define KEYBOARD_A 97
#define KEYBOARD_SPACE 32

#define HIGH_ACCURACY

#define WORLD_BOUNDS_EXTRA_WIDTH 10000

// enums that will be used as tags
enum {
	kTagTileMap = 1,
	kTagBatchNode = 1,
	kTagAnimation1 = 1,
};

#define NUM_OF_JUMPERS 10

// JumpersLayer implementation
@implementation JumpersLayer

@synthesize actors, cursorSprite, cursorMode;

+(CCScene *) scene
{
	// 'scene' is an autorelease object.
	CCScene *scene = [CCScene node];
	
	// 'layer' is an autorelease object.
	JumpersLayer *layer = [JumpersLayer node];
	
	// add layer as a child to scene
	[scene addChild: layer];
	
	// return the scene
	return scene;
}

// on "init" you need to initialize your instance
-(id) init
{
	// always call "super" init
	// Apple recommends to re-assign "self" with the "super" return value
	if( (self=[super init])) {
		
		// enable touches
		self.isMouseEnabled = YES;
		
		actors = [[NSMutableArray alloc] initWithCapacity:50];
		
		CGSize screenSize = [CCDirector sharedDirector].winSize;
		CCLOG(@"Screen width %0.2f screen height %0.2f",screenSize.width,screenSize.height);
		
		// Define the gravity vector.
		b2Vec2 gravity;
		gravity.Set(0.0f, -30.0f);
		
		// Do we want to let bodies sleep?
		// This will speed up the physics simulation
		bool doSleep = true;
		
		// Construct a world object, which will hold and simulate the rigid bodies.
		world = new b2World(gravity, doSleep);
		
		world->SetContinuousPhysics(true);
		
		// Debug Draw functions
		m_debugDraw = new GLESDebugDraw( PTM_RATIO );
		world->SetDebugDraw(m_debugDraw);
		
		uint32 flags = 0;
		flags += b2DebugDraw::e_shapeBit;
		//		flags += b2DebugDraw::e_jointBit;
		//		flags += b2DebugDraw::e_aabbBit;
		//		flags += b2DebugDraw::e_pairBit;
		//		flags += b2DebugDraw::e_centerOfMassBit;
		m_debugDraw->SetFlags(flags);		
		
		
		// Define the ground body.
		b2BodyDef groundBodyDef;
		groundBodyDef.position.Set(0, 0); // bottom-left corner
		
		// Call the body factory which allocates memory for the ground body
		// from a pool and creates the ground box shape (also from a pool).
		// The body is also added to the world.
		b2Body* groundBody = world->CreateBody(&groundBodyDef);
		
		// Define the ground box shape.
		b2PolygonShape groundBox;		
		
		// bottom
		groundBox.SetAsEdge(b2Vec2(0,0), b2Vec2((screenSize.width+WORLD_BOUNDS_EXTRA_WIDTH)/PTM_RATIO,0));
		groundBody->CreateFixture(&groundBox,0);
		
		// top
		groundBox.SetAsEdge(b2Vec2(0,screenSize.height/PTM_RATIO), b2Vec2((screenSize.width+WORLD_BOUNDS_EXTRA_WIDTH)/PTM_RATIO,
																		  screenSize.height/PTM_RATIO));
		groundBody->CreateFixture(&groundBox,0);
		
		// left
		groundBox.SetAsEdge(b2Vec2(0,screenSize.height/PTM_RATIO), b2Vec2(0,0));
		groundBody->CreateFixture(&groundBox,0);
		
		// right
		groundBox.SetAsEdge(b2Vec2((screenSize.width+WORLD_BOUNDS_EXTRA_WIDTH)/PTM_RATIO,screenSize.height/PTM_RATIO), b2Vec2((screenSize.width+WORLD_BOUNDS_EXTRA_WIDTH)/PTM_RATIO,0));
		groundBody->CreateFixture(&groundBox,0);
		
		
		//Set up sprite
		
		CCSpriteBatchNode *batch = [CCSpriteBatchNode batchNodeWithFile:@"colors.png" capacity:150];
		[self addChild:batch z:0 tag:kTagBatchNode];
		
		//[self addNewSpriteWithCoords:ccp(screenSize.width/2, screenSize.height/2) andType:kBird];
		
		/*
		 CCLabelTTF *label = [CCLabelTTF labelWithString:@"Tap screen" fontName:@"Marker Felt" fontSize:32];
		 [self addChild:label z:0];
		 [label setColor:ccc3(0,0,255)];
		 label.position = ccp( screenSize.width/2, screenSize.height-50);
		 */
		[self initPopulationParameters];

		
		
		[self buildTower];
		
		
		cursorSprite = [[CCSprite alloc] initWithFile:@"stick.png"];
		cursorSprite.scale = PTM_RATIO / PTM_RATIO_DEFAULT;
		[self addChild:cursorSprite];
		cursorMode = kVertical;
		
		[[CCEventDispatcher sharedDispatcher] addKeyboardDelegate:self priority:0];
		
		[self schedule: @selector(tick:)];
	}
	return self;
}

-(void)buildTower {
	int width = 5;
	cursorMode = kVertical;
	for(int i = 0; i < width; i++)
		[self addNewSpriteWithCoords:CGPointMake(800+i*64*2*PTM_RATIO/PTM_RATIO_DEFAULT, 32*2*PTM_RATIO/PTM_RATIO_DEFAULT) andType:kStick];
	
	width--;
	cursorMode = kHorizontal;
	for(int i = 0; i < width; i++)
		[self addNewSpriteWithCoords:CGPointMake(800+i*64*2*PTM_RATIO/PTM_RATIO_DEFAULT+32*2*PTM_RATIO/PTM_RATIO_DEFAULT, 70*2*PTM_RATIO/PTM_RATIO_DEFAULT) andType:kStick];
	
	cursorMode = kVertical;
	for(int i = 0; i < width; i++)
		[self addNewSpriteWithCoords:CGPointMake(800+(i+1)*64*2*PTM_RATIO/PTM_RATIO_DEFAULT-32*2*PTM_RATIO/PTM_RATIO_DEFAULT, 106*2*PTM_RATIO/PTM_RATIO_DEFAULT) andType:kStick];
	
	width--;
	cursorMode = kHorizontal;
	for(int i = 0; i < width; i++)
		[self addNewSpriteWithCoords:CGPointMake(800+i*64*2*PTM_RATIO/PTM_RATIO_DEFAULT+32*2*2*PTM_RATIO/PTM_RATIO_DEFAULT, 142*2*PTM_RATIO/PTM_RATIO_DEFAULT) andType:kStick];
	
	cursorMode = kVertical;
	for(int i = 0; i < width; i++)
		[self addNewSpriteWithCoords:CGPointMake(800+(i+1)*64*2*PTM_RATIO/PTM_RATIO_DEFAULT, 180*2*PTM_RATIO/PTM_RATIO_DEFAULT) andType:kStick];
	
	width--;
	cursorMode = kHorizontal;
	for(int i = 0; i < width; i++)
		[self addNewSpriteWithCoords:CGPointMake(800+i*64*2*PTM_RATIO/PTM_RATIO_DEFAULT+32*3*2*PTM_RATIO/PTM_RATIO_DEFAULT, 216*2*PTM_RATIO/PTM_RATIO_DEFAULT) andType:kStick];
	
	cursorMode = kVertical;
	for(int i = 0; i < width; i++)
		[self addNewSpriteWithCoords:CGPointMake(800+(i+2)*64*2*PTM_RATIO/PTM_RATIO_DEFAULT-32 *2*PTM_RATIO/PTM_RATIO_DEFAULT, 254*2*PTM_RATIO/PTM_RATIO_DEFAULT) andType:kStick];
	
	width--;
	cursorMode = kHorizontal;
	for(int i = 0; i < width; i++)
		[self addNewSpriteWithCoords:CGPointMake(800+i*64*2*PTM_RATIO/PTM_RATIO_DEFAULT+32*4*2*PTM_RATIO/PTM_RATIO_DEFAULT, 290*2*PTM_RATIO/PTM_RATIO_DEFAULT) andType:kStick];
	
	[self addNewSpriteWithCoords:CGPointMake(800+128*2*PTM_RATIO/PTM_RATIO_DEFAULT,318*2*PTM_RATIO/PTM_RATIO_DEFAULT) andType:kPig];

}

-(void)initPopulationParameters {
	/*
	 jumping_probability = 0.1;
	 jumping_strength = 300;
	 jumping_angular_deviation = 0.9;
	 bounciness = 0.1f;
	 */
}

-(void)resetSimulation {
	
	//NSMutableArray *bodiesToDestroy = [[NSMutableArray alloc] initWithCapacity:100];
	
	for (b2Body* b = world->GetBodyList(); b; b = b->GetNext()){
		Actor *userData = (Actor *)b->GetUserData();
		
		if(userData && [userData isKindOfClass:[Actor class]]) {
			[self removeChild:userData.sprite cleanup:YES];
			world->DestroyBody(b);
		}
	}
	/*
	while(bodiesToDestroy.count > 0) {
		b2Body *b = (b2Body *)[bodiesToDestroy objectAtIndex:0];
		[bodiesToDestroy removeObjectAtIndex:0];
		world->DestroyBody(b);		
	}*/
	
	[self buildTower];
}

-(void) draw
{
	// Default GL states: GL_TEXTURE_2D, GL_VERTEX_ARRAY, GL_COLOR_ARRAY, GL_TEXTURE_COORD_ARRAY
	// Needed states:  GL_VERTEX_ARRAY, 
	// Unneeded states: GL_TEXTURE_2D, GL_COLOR_ARRAY, GL_TEXTURE_COORD_ARRAY
	glDisable(GL_TEXTURE_2D);
	glDisableClientState(GL_COLOR_ARRAY);
	glDisableClientState(GL_TEXTURE_COORD_ARRAY);
	
	//world->DrawDebugData();
	
	// restore default GL states
	glEnable(GL_TEXTURE_2D);
	glEnableClientState(GL_COLOR_ARRAY);
	glEnableClientState(GL_TEXTURE_COORD_ARRAY);
	
}

-(void) addNewSpriteWithCoords:(CGPoint)p andType:(ActorType)type
{
	//CCLOG(@"Add sprite %0.2f x %02.f",p.x,p.y);
	//CCSpriteBatchNode *batch = (CCSpriteBatchNode*) [self getChildByTag:kTagBatchNode];
	
	//We have a 64x64 sprite sheet with 4 different 32x32 images.  The following code is
	//just randomly picking one of the images
	//int idx = (CCRANDOM_0_1() > .5 ? 0:1);
	//int idx = (int)(CCRANDOM_0_1() * 5);
	//int idy = (CCRANDOM_0_1() > .5 ? 0:1);
	/*
	 CCSprite *sprite = [CCSprite spriteWithBatchNode:batch rect:CGRectMake(32 * idx,32 * idy,32,32)];
	 sprite = [[CCSprite alloc] initWithFile:@"tango.png"];
	 sprite = [[CCSprite alloc] initWithFile:@"stick.png"];
	 */
	
	Actor *newActor = [[Actor alloc] initWithType:type];
	
	CCSprite *sprite = newActor.sprite;
	
	sprite.scale = PTM_RATIO / PTM_RATIO_DEFAULT;
	[self addChild:sprite];
	
	sprite.position = ccp( p.x, p.y);
	
	//Jumper *jumper = [[Jumper alloc] initWithSprite:sprite];
	
	// Define the dynamic body.
	//Set up a 1m squared box in the physics world
	b2BodyDef bodyDef;
	bodyDef.type = b2_dynamicBody;
	
	bodyDef.position.Set(p.x/PTM_RATIO, p.y/PTM_RATIO);
	bodyDef.userData = newActor;
	
	b2Body *body = world->CreateBody(&bodyDef);
	
	// Define another box shape for our dynamic body.
	b2PolygonShape dynamicBox;
	dynamicBox.SetAsBox(.5f, .5f);//These are mid points for our 1m box
	
	b2PolygonShape stickBox;
	stickBox.SetAsBox(0.25f, 2.0f);
	
	b2CircleShape circle;
	circle.m_radius = 0.45f;
	
	b2CircleShape pigShape;
	pigShape.m_radius = 0.9f;
	
	// Define the dynamic body fixture.
	b2FixtureDef fixtureDef;
	
	switch (newActor.type) {
		case kBird:
			fixtureDef.shape = &circle;	
			break;
		case kStick:
			fixtureDef.shape = &stickBox;
			break;
		case kPig:
			fixtureDef.shape = &pigShape;
			break;
		default:
			break;
	}
	
	
	fixtureDef.density = newActor.density;
	fixtureDef.friction = 0.3f;
	fixtureDef.restitution = newActor.bounciness;
	
	body->CreateFixture(&fixtureDef);
	
	
	if(cursorMode == kHorizontal) {
		float angle = M_PI * 0.5; //or whatever you angle is
		b2Vec2 pos = body->GetPosition();
		body->SetTransform(pos, angle);
	}
	
	if(newActor.type == kBird) {
		double theta =  CCRANDOM_0_1() * M_PI * 0.25;
		
		double xForce = 100 * cos(theta);
		double yForce = 100 * sin(theta);
		
		b2Vec2 force = b2Vec2(xForce, yForce);
		body->ApplyLinearImpulse(force, body->GetPosition());
	}
	
	[actors addObject:newActor];
}



-(void) tick: (ccTime) dt
{
	//It is recommended that a fixed time step is used with Box2D for stability
	//of the simulation, however, we are using a variable time step here.
	//You need to make an informed choice, the following URL is useful
	//http://gafferongames.com/game-physics/fix-your-timestep/
	
	int32 velocityIterations = 128;
	int32 positionIterations = 128;

	world->Step(dt*0.5, velocityIterations, positionIterations);
	
	b2Body *highestStationaryBody = NULL;
	CGPoint positionOfHighest = CGPointMake(0, -9999);
	
	for (b2Body* b = world->GetBodyList(); b; b = b->GetNext()){
		if(b->GetPosition().y > positionOfHighest.y && [self isStationary:b]) {
			highestStationaryBody = b;
			positionOfHighest = CGPointMake(b->GetPosition().x, b->GetPosition().y);
		}
	}
	
	//Iterate over the bodies in the physics world
	for (b2Body* b = world->GetBodyList(); b; b = b->GetNext()) {
		
		if (b->GetUserData() != NULL) {
			Actor *actor = (Actor *)(b->GetUserData());
			
			//Synchronize the AtlasSprites position and rotation with the corresponding body
			actor.sprite.position = CGPointMake( b->GetPosition().x * PTM_RATIO, b->GetPosition().y * PTM_RATIO);
			actor.sprite.rotation = -1 * CC_RADIANS_TO_DEGREES(b->GetAngle());
		}	
	}
}

//not yet implemented
//should return TRUE is the body is 1) not moving and 2)has at least one edge in contact
//with another body that is not moving 
-(BOOL)isStationary:(b2Body *)b {
	
	if( b->GetLinearVelocity().Length() < 0.1)
		return TRUE;
	else
		return FALSE;
}

-(BOOL) ccMouseMoved:(NSEvent *)event {
	CGPoint location = [(CCDirectorMac*)[CCDirector sharedDirector] convertEventToGL:event];
	cursorSprite.position = ccp(location.x,location.y);
	return YES;
}

- (BOOL) ccMouseDown:(NSEvent *)event
{
	CGPoint location = [(CCDirectorMac*)[CCDirector sharedDirector] convertEventToGL:event];
	[self addNewSpriteWithCoords: location andType:kStick];
	
	return YES;
}

-(BOOL)ccKeyDown:(NSEvent *)event {
	NSNumber *keyPressed = [NSNumber numberWithUnsignedInt:[[event characters] characterAtIndex:0]];
	b2Vec2 gravity;
	gravity.Set(0.0f, 50-CCRANDOM_0_1()*100);
	
	NSLog(@"%i",[keyPressed intValue]);
	switch ([keyPressed intValue]) {
		case KEYBOARD_A:
			[self changeCursorOrientation];
			break;
		case 103:
			world->SetGravity(gravity);
			break;
		case 114:
			[self resetSimulation];
			break;
		case KEYBOARD_SPACE:
			[self fireBird];
			break;
		default:
			break;
	}
	
	return TRUE;
}

-(void)fireBird {
	[self addNewSpriteWithCoords:CGPointMake(50, 50) andType:kBird];
}

-(void)changeCursorOrientation {
	if(cursorMode == kVertical) {
		cursorMode = kHorizontal;
		cursorSprite.rotation = 90;
	} else {
		cursorMode = kVertical;
		cursorSprite.rotation = 0;
		
	}
}

// on "dealloc" you need to release all your retained objects
- (void) dealloc
{
	// in case you have something to dealloc, do it in this method
	delete world;
	world = NULL;
	
	delete m_debugDraw;
	
	// don't forget to call "super dealloc"
	[super dealloc];
}
@end
