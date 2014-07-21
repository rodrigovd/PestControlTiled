//
//  GameScene.swift
//  PestControlTiled
//
//  Created by Rodrigo Villatoro on 7/17/14.
//  Copyright (c) 2014 RVD. All rights reserved.
//

import SpriteKit

enum PhysicsCategory {
    static let Boundary = 1 << 0 as UInt32      // 1
    static let Player = 1 << 1 as UInt32        // 2
    static let Bug = 1 << 2 as UInt32           // 4
    static let Tree = 1 << 3 as UInt32          // 8
    static let KillingPoint = 1 << 4 as UInt32  // 16
    static let Breakable = 1 << 5 as UInt32     // 32
    static let FireBug = 1 << 6 as UInt32       // 64
}

enum GameState {
    case StartingLevel
    case Playing
    case InLevelMenu
}

class GameScene: SKScene, SKPhysicsContactDelegate {

    var worldNode = SKNode()
    var bounds = SKNode()
    var map: JSTileMap!
    var player = Player()
    var mapSizeInPixels = CGSize()
    var gameState: GameState!
    var level = Int()
    
    init(coder aDecoder: NSCoder!) {
        super.init(coder: aDecoder);
    }
    
    init(size: CGSize, level: Int) {
        super.init(size: size)
        self.level = level
    }
    
    override func didMoveToView(view: SKView) {
        
        self.physicsWorld.gravity = CGVectorMake(0, 0)
        self.physicsWorld.contactDelegate = self
        
        map = JSTileMap(named: "level-\(level).tmx")
        
        addChild(worldNode)
        worldNode.addChild(map)
        
        mapSizeInPixels = CGSizeMake(map.mapSize.width * map.tileSize.width, map.mapSize.height * map.tileSize.height)
        
        bounds.physicsBody = SKPhysicsBody(edgeLoopFromRect: CGRectMake(0, 0, mapSizeInPixels.width, mapSizeInPixels.height))
        bounds.physicsBody.categoryBitMask = PhysicsCategory.Boundary
        bounds.physicsBody.friction = 0
        map.addChild(bounds)
        
        createCollisionAreas()
        createFireBugsKillingPoints()
        spawnPlayer()
        spawnBugs()
        spawnFireBugs()
        
        worldNode.enumerateChildNodesWithName("bug", usingBlock: {
            node, stop in
            (node as Bugs).walk()
            })
        
        worldNode.enumerateChildNodesWithName("firebug", usingBlock: {
            node, stop in
            (node as FireBug).walk()
            })
        
        createUserInterface()
        gameState = GameState.StartingLevel
        
    }
    
    func tileRectFromTileCoords(tileCoords: CGPoint) -> CGRect {
        let levelHeightInPixels = map.mapSize.height * map.tileSize.height
        let origin = CGPointMake(tileCoords.x * map.tileSize.width, levelHeightInPixels - ((tileCoords.y + 1) * map.tileSize.height))
        return CGRectMake(origin.x, origin.y, map.tileSize.width, map.tileSize.height)
    }
    
    func tileGIDAtTileCoord(coord: CGPoint, layer:TMXLayer) -> NSInteger {
        let layerInfo = layer.layerInfo
        return NSInteger(layerInfo.tileGidAtCoord(coord))
    }
    
    func centerCameraOnPlayer() {
        
        // Center camera on X
        if player.position.x < self.size.width/2 {
            worldNode.position.x = 0.0
        } else if player.position.x >= self.size.width/2 {
            worldNode.position.x = -player.position.x + self.size.width/2
            if player.position.x > mapSizeInPixels.width - self.size.width/2 {
                worldNode.position.x = -mapSizeInPixels.width + self.size.width
            }
        }
        
        // Center camera on Y
        if player.position.y < self.size.height/2 {
            worldNode.position.y = 0.0
        } else if player.position.y >= self.size.height/2 {
            worldNode.position.y = -player.position.y + self.size.height/2
            if player.position.y > mapSizeInPixels.height - self.size.height/2 {
                worldNode.position.y = -mapSizeInPixels.height + self.size.height
            }
        }
        
    }
    
    // For collision areas with width and height
    func createFireBugsKillingPoints() {
        
        let collisionsGroup = map.groupNamed("KillingPoints")
        
        for (var i = 0; i < collisionsGroup.objects.count; ++i) {
            
            let collisionObject = collisionsGroup.objects.objectAtIndex(i) as NSDictionary
            
            let width = collisionObject.objectForKey("width") as String
            let height = collisionObject.objectForKey("height") as String
            let someObstacleSize = CGSize(width: CGFloat(width.toInt()!) * 0.50, height: CGFloat(height.toInt()!) * 0.50)
            
            let someObstacle = SKSpriteNode(color: UIColor.clearColor(), size: someObstacleSize);
            
            let y = collisionObject.objectForKey("y") as Int;
            let x = collisionObject.objectForKey("x") as Int;
            
            someObstacle.position = CGPoint(x: x + width.toInt()!/2, y: y + height.toInt()!/2);
            someObstacle.physicsBody = SKPhysicsBody(rectangleOfSize: someObstacleSize);
            someObstacle.physicsBody.affectedByGravity = false;
            someObstacle.physicsBody.categoryBitMask = PhysicsCategory.KillingPoint
            someObstacle.physicsBody.dynamic = false
            someObstacle.physicsBody.friction = 0
            someObstacle.physicsBody.restitution = 1
            someObstacle.name = "someObstacle"
            
            worldNode.addChild(someObstacle)
        }
        
    }
    
    // For collision areas with width and height
    func createCollisionAreas() {
        
        let collisionsGroup = map.groupNamed("CollisionAreas")
        
        for (var i = 0; i < collisionsGroup.objects.count; ++i) {
            
            let collisionObject = collisionsGroup.objects.objectAtIndex(i) as NSDictionary
            
            let width = collisionObject.objectForKey("width") as String
            let height = collisionObject.objectForKey("height") as String
            let someObstacleSize = CGSize(width: width.toInt()!, height: height.toInt()!)
            
            let someObstacle = SKSpriteNode(color: UIColor.clearColor(), size: someObstacleSize);
            
            let y = collisionObject.objectForKey("y") as Int;
            let x = collisionObject.objectForKey("x") as Int;
            
            someObstacle.position = CGPoint(x: x + width.toInt()!/2, y: y + height.toInt()!/2);
            someObstacle.physicsBody = SKPhysicsBody(rectangleOfSize: someObstacleSize);
            someObstacle.physicsBody.affectedByGravity = false;
            someObstacle.physicsBody.categoryBitMask = PhysicsCategory.Tree
            someObstacle.physicsBody.dynamic = false
            someObstacle.physicsBody.friction = 0
            someObstacle.physicsBody.restitution = 1
            
            map.addChild(someObstacle)
            
        }
        
    }
    
    // For spawn points (without width and height)
    func spawnPlayer() {
        let collisionsGroup = map.groupNamed("Player")
        for (var i = 0; i < collisionsGroup.objects.count; ++i) {
            let collisionObject = collisionsGroup.objects.objectAtIndex(i) as NSDictionary
            let y = collisionObject.objectForKey("y") as Int;
            let x = collisionObject.objectForKey("x") as Int;
            player.position = CGPoint(x: x, y: y);
            worldNode.addChild(player)
        }
    }
    
    func createUserInterface() {
        let startMsg = SKLabelNode(fontNamed: "HelveticaNeue")
        startMsg.name = "msgLabel"
        startMsg.text = "Tap screen to run!!"
        startMsg.fontSize = 32
        startMsg.position = CGPointMake(self.size.width/2, self.size.height/2)
        addChild(startMsg)
        
    }
    
    func endLevelWithSuccess(won: Bool) {
        let label = self.childNodeWithName("msgLabel") as SKLabelNode
        label.text = won ? "You win!!!" : "Too slow!!!"
        label.hidden = false
        
        let nextLevel = SKLabelNode(fontNamed: "HelveticaNeue")
        nextLevel.name = "nextLevelLabel"
        nextLevel.text = "Next level?"
        nextLevel.fontSize = 24
        nextLevel.position = CGPointMake(self.size.width/2, self.size.height/2 - 40)
        addChild(nextLevel)
        
        player.physicsBody.linearDamping = 1
        gameState = GameState.InLevelMenu
        
    }
    
    // For spawn points (without width and height)
    func spawnBugs() {
        let collisionsGroup = map.groupNamed("Bugs")
        for (var i = 0; i < collisionsGroup.objects.count; ++i) {
            let collisionObject = collisionsGroup.objects.objectAtIndex(i) as NSDictionary
            let y = collisionObject.objectForKey("y") as Int;
            let x = collisionObject.objectForKey("x") as Int;
            let bugNode = Bugs()
            bugNode.position = CGPoint(x: x, y: y);
            worldNode.addChild(bugNode)
        }
    }
    
    // For spawn points (without width and height)
    func spawnFireBugs() {
        let collisionsGroup = map.groupNamed("FireBugs")
        for (var i = 0; i < collisionsGroup.objects.count; ++i) {
            let collisionObject = collisionsGroup.objects.objectAtIndex(i) as NSDictionary
            let y = collisionObject.objectForKey("y") as Int;
            let x = collisionObject.objectForKey("x") as Int;
            let bugNode = FireBug()
            bugNode.position = CGPoint(x: x, y: y);
            worldNode.addChild(bugNode)
        }
    }
  
    override func touchesBegan(touches: NSSet, withEvent event: UIEvent!) {
        
        for touch : AnyObject in touches {
            
            switch gameState! {
            case .StartingLevel:
                childNodeWithName("msgLabel").hidden = true
                gameState = GameState.Playing
                self.paused = false
                fallthrough
            case .Playing:
                let location = touch.locationInNode(worldNode)
                player.moveToward(location)
            case .InLevelMenu:
//                println("hello!")
                let location = touch.locationInNode(self)
                let node = self.childNodeWithName("nextLevelLabel")
                if node.containsPoint(location) {
                    println("hello!!!")
                    ++level
                    let newScene = GameScene(size: self.size, level: level)
                    self.view.presentScene(newScene, transition: SKTransition.flipVerticalWithDuration(0.5))
                }
            }
        }
    }
    
    override func didSimulatePhysics() {
        centerCameraOnPlayer()
        
    }
    
    func didBeginContact(contact: SKPhysicsContact) {
        
        if contact.bodyA.categoryBitMask == PhysicsCategory.Player || contact.bodyB.categoryBitMask == PhysicsCategory.Player {
            let other = contact.bodyA.categoryBitMask == PhysicsCategory.Player ? contact.bodyB : contact.bodyA
            if other.categoryBitMask == PhysicsCategory.Bug {
                other.node.removeFromParent()
            }
        } else if contact.bodyA.categoryBitMask == PhysicsCategory.KillingPoint || contact.bodyB.categoryBitMask == PhysicsCategory.KillingPoint {
            let other = contact.bodyA.categoryBitMask == PhysicsCategory.KillingPoint ? contact.bodyB : contact.bodyA
            if other.categoryBitMask == PhysicsCategory.FireBug {
                other.node.removeFromParent()
            }
        }
        
        
    }
    
    func didEndContact(contact: SKPhysicsContact) {
        let other = contact.bodyA.categoryBitMask == PhysicsCategory.Player ? contact.bodyB : contact.bodyA
        // other category bitmask is 1, 8, 16, etc., player collision bitmask is 25
        if other.categoryBitMask & player.physicsBody.collisionBitMask != 0 {
            player.faceCurrentDirection()
            player.defineFacingDirection(player.facingDirection)
        }
    }
   
    override func update(currentTime: CFTimeInterval) {
        
        if gameState == GameState.StartingLevel && !self.paused {
            self.paused = true
        }
        
        if gameState != GameState.Playing {
            return
        }
        
        // Check if FireBug is in Killing Point, if so, remove from Parent
        worldNode.enumerateChildNodesWithName("someObstacle", usingBlock: {
            node, stop in
            self.worldNode.enumerateChildNodesWithName("firebug", usingBlock: {
                anotherNode, stop in
                if anotherNode.intersectsNode(node) {
                    anotherNode.runAction(SKAction.sequence([SKAction.scaleTo(0.0, duration: 0.3), SKAction.removeFromParent()]))
                }
                })
            })
        
        if !worldNode.childNodeWithName("bug") && !worldNode.childNodeWithName("firebug") {
            endLevelWithSuccess(true)
        }
        
        
    }
}
