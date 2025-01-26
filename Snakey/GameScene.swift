import SpriteKit
import AVFoundation

class GameScene: SKScene {
    
    // MARK: - Game Elements
    private var snake = [SKSpriteNode]()
    private var food: SKSpriteNode!
    private var currentDirection = CGVector(dx: 1, dy: 0)
    private var nextDirection = CGVector(dx: 1, dy: 0)
    private var lastUpdateTime: TimeInterval = 0
    private var scoreLabel: SKLabelNode!
    private var isGamePaused = false  // Add this line
    
    // MARK: - Game Configuration
    private let gridSize: CGFloat = 20
    private var gameSpeed: TimeInterval = 0.1
    private var score = 0 {
        didSet { scoreLabel.text = "SCORE: \(score)" }
    }
    
    // MARK: - Sound Handling
    private var audioPlayer: AVAudioPlayer?
    private let eatSound = Bundle.main.url(forResource: "eat", withExtension: "wav")
    private let gameOverSound = Bundle.main.url(forResource: "game_over", withExtension: "wav")
    
    // MARK: - Screen Management
    private var playableRect: CGRect {
        let inset: CGFloat = gridSize
        return CGRect(x: inset, y: inset,
                     width: size.width - inset * 2,
                     height: size.height - inset * 2)
    }
    
    // MARK: - Lifecycle
    override func didMove(to view: SKView) {
        backgroundColor = SKColor(red: 0.1, green: 0.1, blue: 0.1, alpha: 1)
        scaleMode = .resizeFill
        anchorPoint = CGPoint(x: 0.5, y: 0.5) // Add this line
        
        // Add physics world setup
        physicsWorld.gravity = .zero
        physicsBody = SKPhysicsBody(edgeLoopFrom: playableRect)
        
        createGrid()
        setupGame()
    }
    
    // MARK: - Setup Methods
    private func setupGame() {
        setupScoreLabel()
        setupSnake()
        spawnFood()
        setupGestures()
        setupBoundaries()
    }
    
    private func createGrid() {
        for x in stride(from: 0, to: size.width, by: gridSize) {
            for y in stride(from: 0, to: size.height, by: gridSize) {
                let gridNode = SKSpriteNode(color: .darkGray, size: CGSize(width: 1, height: 1))
                gridNode.position = CGPoint(x: x, y: y)
                addChild(gridNode)
            }
        }
    }
    
    private func setupScoreLabel() {
        scoreLabel = SKLabelNode(fontNamed: "Avenir-Black")
        scoreLabel.text = "SCORE: 0"
        scoreLabel.fontSize = 24
        scoreLabel.position = CGPoint(x: size.width/2, y: size.height - 40)
        addChild(scoreLabel)
    }
    
    private func setupSnake() {
        let startPosition = CGPoint(x: playableRect.midX, y: playableRect.midY)
        for i in 0..<3 {
            let segment = createSegment()
            segment.position = CGPoint(x: startPosition.x - CGFloat(i) * gridSize, y: startPosition.y)
            snake.append(segment)
            addChild(segment)
        }
    }
    
    private func setupBoundaries() {
        let boundary = SKPhysicsBody(edgeLoopFrom: playableRect)
        boundary.categoryBitMask = 0x1 << 0
        physicsBody = boundary
    }
    
    // MARK: - Game Logic
    override func update(_ currentTime: TimeInterval) {
        guard !isGamePaused else { return }
        
        if lastUpdateTime == 0 {
            lastUpdateTime = currentTime
            return
        }
        
        let delta = currentTime - lastUpdateTime
        if delta < gameSpeed { return }
        
        lastUpdateTime = currentTime
        currentDirection = nextDirection
        moveSnake()
    }
    
    private func moveSnake() {
        guard let head = snake.first else { return }
        
        // Move body
        for i in (1..<snake.count).reversed() {
            snake[i].position = snake[i-1].position
        }
        
        // Move head
        head.position.x += currentDirection.dx * gridSize
        head.position.y += currentDirection.dy * gridSize
        
        checkCollisions()
    }
    
    // MARK: - Collision Detection
    private func checkCollisions() {
        guard let head = snake.first else { return }
        
        // Food collision
        if head.frame.intersects(food.frame) {
            handleFoodCollision()
        }
        
        // Wall collision
        if !playableRect.contains(head.position) {
            gameOver()
        }
        
        // Self collision
        for segment in snake[1..<snake.count] where head.frame.intersects(segment.frame) {
            gameOver()
        }
    }
    
    private func handleFoodCollision() {
        score += 1
        playSound(eatSound)
        growSnake()
        spawnFood()
        increaseSpeed()
    }
    
    private func increaseSpeed() {
        gameSpeed *= 0.95  // Increase speed by 5% each food collected
    }
    
    // MARK: - Game Controls
    private func setupGestures() {
        let directions: [UISwipeGestureRecognizer.Direction] = [.up, .down, .left, .right]
        directions.forEach { direction in
            let gesture = UISwipeGestureRecognizer(target: self, action: #selector(handleSwipe))
            gesture.direction = direction
            view?.addGestureRecognizer(gesture)
        }
    }
    
    @objc private func handleSwipe(_ gesture: UISwipeGestureRecognizer) {
        switch gesture.direction {
        case .up where currentDirection.dy != -1:
            nextDirection = CGVector(dx: 0, dy: 1)
        case .down where currentDirection.dy != 1:
            nextDirection = CGVector(dx: 0, dy: -1)
        case .left where currentDirection.dx != 1:
            nextDirection = CGVector(dx: -1, dy: 0)
        case .right where currentDirection.dx != -1:
            nextDirection = CGVector(dx: 1, dy: 0)
        default: break
        }
    }
    
    // MARK: - Game State Management
    private func gameOver() {
        isGamePaused = true
        playSound(gameOverSound)
        
        let gameOverLabel = SKLabelNode(fontNamed: "Avenir-Black")
        gameOverLabel.text = "GAME OVER\nTap to Restart"
        gameOverLabel.numberOfLines = 2
        gameOverLabel.fontSize = 40
        gameOverLabel.position = CGPoint(x: size.width/2, y: size.height/2)
        addChild(gameOverLabel)
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        if isGamePaused {
            restartGame()
        }
    }
    
    private func restartGame() {
        removeAllChildren()
        snake.removeAll()
        currentDirection = CGVector(dx: 1, dy: 0)
        nextDirection = currentDirection
        score = 0
        isGamePaused = false
        
        createGrid()
        setupGame()
    }
    
    // MARK: - Helper Methods
    private func createSegment() -> SKSpriteNode {
        let segment = SKSpriteNode(color: .green, size: CGSize(width: gridSize-2, height: gridSize-2))
        segment.zPosition = 1
        return segment
    }
    
    private func spawnFood() {
        food?.removeFromParent()
        
        var position: CGPoint
        repeat {
            let cols = Int(playableRect.width / gridSize)
            let rows = Int(playableRect.height / gridSize)
            let x = playableRect.minX + CGFloat(Int.random(in: 0..<cols)) * gridSize
            let y = playableRect.minY + CGFloat(Int.random(in: 0..<rows)) * gridSize
            position = CGPoint(x: x, y: y)
        } while snake.contains { $0.frame.contains(position) }
        
        food = SKSpriteNode(color: .red, size: CGSize(width: gridSize-2, height: gridSize-2))
        food.position = position
        food.zPosition = 1
        addChild(food)
    }
    
    private func growSnake() {
        guard let last = snake.last else { return }
        let newSegment = createSegment()
        newSegment.position = last.position
        snake.append(newSegment)
        addChild(newSegment)
    }
    
    private func playSound(_ soundURL: URL?) {
        guard let url = soundURL else { return }
        
        do {
            audioPlayer = try AVAudioPlayer(contentsOf: url)
            audioPlayer?.prepareToPlay()
            audioPlayer?.play()
        } catch {
            print("Sound error: \(error.localizedDescription)")
        }
    }
}
extension GameScene {
    override func didChangeSize(_ oldSize: CGSize) {
        // Handle screen rotation/resizing
        removeAllChildren()
        createGrid()
        setupGame()
    }
}
