//
//  JumpersLayer.mm
//  t6mb
//
//  Created by Ricardo Quesada on 3/24/11.
//  Copyright __MyCompanyName__ 2011. All rights reserved.
//


// Import the interfaces
#import "JumpersLayer.h"
#import "SimulationResult.h"

//Pixel to metres ratio. Box2D uses metres as the unit for measurement.
//This ratio defines how many pixels correspond to 1 Box2D "metre"
//Box2D is optimized for objects of 1x1 metre therefore it makes sense
//to define the ratio so that your most common object type is 1x1 metre.
#define PTM_RATIO 16
#define PTM_RATIO_DEFAULT 32.0

#define KEYBOARD_A 97
#define KEYBOARD_SPACE 32

#define ANGLE_STEP_SIZE 0.01
#define FORCE_STEP_SIZE 2

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

@synthesize actors, simulationResults, cursorSprite, cursorMode, averageHeight, heightLabel, currentAngle, currentForce, timeSinceBallLaunched, simulationState, lastSuccessor, maxLabel;

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

		srandom(time(NULL));
		CCLayerColor *colorLayer = [[CCLayerColor alloc] initWithColor:ccc4(135, 190, 224, 255)];
		[self addChild:colorLayer z:0];

		// enable touches
		//self.isMouseEnabled = YES;
		
		actors = [[NSMutableArray alloc] initWithCapacity:50];
		simulationResults = [[NSMutableArray alloc] initWithCapacity:50];
		
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
		
		
		[self buildTower];
		[self updateAverageHeight];

		heightLabel = [CCLabelTTF labelWithString:[NSString stringWithFormat:@"Avg height: %.2f", averageHeight] fontName:@"Marker Felt" fontSize:32];
		[self addChild:heightLabel z:0];
		[heightLabel setColor:ccc3(222,222,222)];
		heightLabel.position = ccp( 120,screenSize.height - 40);
		
		maxLabel = [CCLabelTTF labelWithString:[NSString stringWithFormat:@"Max found at ", averageHeight] fontName:@"Marker Felt" fontSize:32];
		[self addChild:maxLabel z:100];
		[maxLabel setColor:ccc3(222,222,222)];
		maxLabel.visible = FALSE;
		maxLabel.position = ccp( screenSize.width*0.5,screenSize.height*0.5);

		
		cursorSprite = [[CCSprite alloc] initWithFile:@"stick.png"];
		cursorSprite.scale = PTM_RATIO / PTM_RATIO_DEFAULT;
		//[self addChild:cursorSprite];
		cursorMode = kVertical;
		
		currentForce = 40+50*CCRANDOM_0_1();
		currentAngle =  (CCRANDOM_0_1()-.5) * M_PI/4+M_PI/8;

		simulationState = kInitialState;
		lastSuccessor = nil;
		
		[[CCEventDispatcher sharedDispatcher] addKeyboardDelegate:self priority:0];		
		
		[self schedule: @selector(tick:)];
	}
	return self;
}

-(void)buildTower {
	
	int width = 10;
	int height = width-1;
	int left = 600;
	
	for(int level = 0; level < height; level++) {
		
		cursorMode = kVertical;
		for(int i = 0; i < width; i++)
			[self addNewSpriteWithCoords:CGPointMake(left+(i+level*.5)*64*2*PTM_RATIO/PTM_RATIO_DEFAULT, (32+72*level)*2*PTM_RATIO/PTM_RATIO_DEFAULT) andType:kStick];
		
		width--;
		cursorMode = kHorizontal;
		for(int i = 0; i < width; i++)
			[self addNewSpriteWithCoords:CGPointMake(left+(i+level*.5)*64*2*PTM_RATIO/PTM_RATIO_DEFAULT+32*2*PTM_RATIO/PTM_RATIO_DEFAULT, (70+72*level)*2*PTM_RATIO/PTM_RATIO_DEFAULT) andType:kStick];
		
	}
	
	[self addNewSpriteWithCoords:CGPointMake(left+(height*.5)*64*2*PTM_RATIO/PTM_RATIO_DEFAULT,(-42+72*height)*2*PTM_RATIO/PTM_RATIO_DEFAULT) andType:kPig];
	timeSinceBallLaunched = -1;
}

-(void)updateAverageHeight {
	double totalHeight = 0;
	int countOfActors = 0;
	
	for (b2Body* b = world->GetBodyList(); b; b = b->GetNext()){
		Actor *userData = (Actor *)b->GetUserData();
		
		if(userData && [userData isKindOfClass:[Actor class]] && ((Actor *)(userData)).type != kBird) {
			totalHeight += b->GetPosition().y;
			countOfActors++;
		}
	}
	averageHeight = totalHeight/countOfActors;
}

-(void)resetSimulation {
		
	for (b2Body* b = world->GetBodyList(); b; b = b->GetNext()) {
		Actor *userData = (Actor *)b->GetUserData();
		
		if(userData && [userData isKindOfClass:[Actor class]]) {
			[self removeChild:userData.sprite cleanup:YES];
			world->DestroyBody(b);
		}
	}
	
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
	Actor *newActor = [[Actor alloc] initWithType:type];
	
	CCSprite *sprite = newActor.sprite;
	
	sprite.scale = PTM_RATIO / PTM_RATIO_DEFAULT;
	[self addChild:sprite];
	
	sprite.position = ccp( p.x, p.y);
		
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
	fixtureDef.friction = newActor.friction;
	fixtureDef.restitution = newActor.bounciness;
	
	body->CreateFixture(&fixtureDef);
	
	if(cursorMode == kHorizontal && newActor.type == kStick) {
		float angle = M_PI * 0.5; //or whatever your angle is
		b2Vec2 pos = body->GetPosition();
		body->SetTransform(pos, angle);
	}
	
	if(newActor.type == kBird) {
		
		double xForce = currentForce * cos(currentAngle);
		double yForce = currentForce * sin(currentAngle);
		
		b2Vec2 force = b2Vec2(xForce, yForce);
		body->ApplyLinearImpulse(force, body->GetPosition());
	}
	
	[actors addObject:newActor];
}



-(void) tick: (ccTime) dt
{
	if(timeSinceBallLaunched >= 0)
		timeSinceBallLaunched += 1.0/90.0;
	
	int32 velocityIterations = 8;
	int32 positionIterations = 1;

	world->Step(1.0/90.0, velocityIterations, positionIterations);
	
	//Iterate over the bodies in the physics world
	for (b2Body* b = world->GetBodyList(); b; b = b->GetNext()) {
		
		if (b->GetUserData() != NULL) {
			Actor *actor = (Actor *)(b->GetUserData());
			
			//Synchronize the AtlasSprites position and rotation with the corresponding body
			actor.sprite.position = CGPointMake( b->GetPosition().x * PTM_RATIO, b->GetPosition().y * PTM_RATIO);
			actor.sprite.rotation = -1 * CC_RADIANS_TO_DEGREES(b->GetAngle());
		}	
	}
	
	[self updateAverageHeight];
	heightLabel.string =[NSString stringWithFormat:@"Avg height: %.2f", averageHeight];
	
	if(timeSinceBallLaunched > 7) 
		[self runNextSuccessor];
}

-(void)recordResults {
	NSLog(@" ");
	NSLog(@"Height\t%.2f", averageHeight);
	NSLog(@"Angle\t%.2f", currentAngle);
	NSLog(@"Force\t%.2f", currentForce);
	
	SimulationResult *result = [[SimulationResult alloc] init];
	result.angle = currentAngle;
	result.force = currentForce;
	result.heightAfterSimulation = averageHeight;
	[simulationResults addObject:result];
}

-(void)runNextSuccessor {
	if(simulationState == kCompleted)
		return;
	
	timeSinceBallLaunched = 0;
	[self recordResults];
	
	switch (simulationState) {
		case kInitialState:
			simulationState = kSuccessorAnglePlus;
			currentAngle += ANGLE_STEP_SIZE;
			break;
		case kSuccessorAnglePlus:
			simulationState = kSuccessorAngleMinus;
			currentAngle -= 2 * ANGLE_STEP_SIZE;
			break;
		case kSuccessorAngleMinus:
			simulationState = kSuccessorForcePlus;
			currentAngle += ANGLE_STEP_SIZE;
			currentForce += FORCE_STEP_SIZE;
			break;
		case kSuccessorForcePlus:
			simulationState = kSuccessorForceMinus;
			currentForce -= 2 * FORCE_STEP_SIZE;
			break;
		case kSuccessorForceMinus:
			simulationState = kInitialState;
			[self selectBestSuccessor];
			break;
		default:
			break;
	}
	
	[self resetSimulation];
	[self fireBird];
}

-(void)selectBestSuccessor {
	SimulationResult *bestResult = nil;
	
	for(SimulationResult *s in simulationResults)
		if(bestResult == nil || s.heightAfterSimulation < bestResult.heightAfterSimulation)
			bestResult = s;
	
	currentAngle = bestResult.angle;
	currentForce = bestResult.force;
	
	NSLog(@"Selecting result with height %f", bestResult.heightAfterSimulation);
	
	if(!lastSuccessor || bestResult.heightAfterSimulation < lastSuccessor.heightAfterSimulation)
		lastSuccessor = bestResult;
	else {
		NSLog(@"Local maximum found!");
		NSLog(@"Height\t%.2f", lastSuccessor.heightAfterSimulation);
		NSLog(@"Angle\t%.2f", lastSuccessor.angle);
		NSLog(@"Force\t%.2f", lastSuccessor.force);
		simulationState = kCompleted;
		maxLabel.string = [NSString stringWithFormat:@"Local max found at %.2f radians with force %.2f", currentAngle, currentForce];
		maxLabel.visible = YES;
	}
}

-(void)generateNextSuccessors {
	[self recordResults];
	[self resetSimulation];
}

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
	//CGPoint location = [(CCDirectorMac*)[CCDirector sharedDirector] convertEventToGL:event];
	//[self addNewSpriteWithCoords: location andType:kStick];
	
	return YES;
}

-(BOOL)ccKeyDown:(NSEvent *)event {
	NSNumber *keyPressed = [NSNumber numberWithUnsignedInt:[[event characters] characterAtIndex:0]];
	b2Vec2 gravity;
	gravity.Set(0.0f, 50-CCRANDOM_0_1()*100);
	
	//NSLog(@"%i",[keyPressed intValue]);
	switch ([keyPressed intValue]) {
		case KEYBOARD_A:
			[self changeCursorOrientation];
			break;
		case 103:
			world->SetGravity(gravity);
			break;
		case 114:
			[self resetSimulation];
			maxLabel.visible = NO;
			lastSuccessor = nil;
			currentForce = 40+50*CCRANDOM_0_1();
			currentAngle =  (CCRANDOM_0_1()-.5) * M_PI/4+M_PI/8;
			break;
		case KEYBOARD_SPACE:
			[self fireBird];
			//currentAngle =  (CCRANDOM_0_1()-.5) * M_PI/4+M_PI/8;
			break;
		default:
			break;
	}
	
	return TRUE;
}

-(void)fireBird {
	[self addNewSpriteWithCoords:CGPointMake(50, 50) andType:kBird];
	timeSinceBallLaunched = 0;
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
